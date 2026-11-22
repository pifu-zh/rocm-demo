// SPDX-License-Identifier: MIT
// Copyright (C) 2026, Advanced Micro Devices, Inc. all rights reserved.
//
// Warp-level extension of M6-#3 (opus_mla_decode_splitkv): the split-KV
// REDUCE kernel's internals, pinned from csrc/include/mla_reduce_kernels.cuh
// (MlaReduceKernelV1Traits / reduce_lse_massive / reduce_output_massive /
// LocalLse) and the host partition in csrc/kernels/mla/reduce.cu @
// 1eab5ae12c93af3c8c660202d9a413f637c2f011 (MIT).
//
// Contracts pinned here:
//   * TRAITS CONSTANTS: kOccupancy = 8, kMassiveThreshold = 4 (splits >= 4
//     run the "massive" pipeline, fewer run the up-to-wave path),
//     kNumWarps = (SizeDV < 128) ? 1 : 2, kVecWidth = SizeDV/kNumThreads
//     (static_assert SizeDV % kNumThreads == 0) -- for DV=512/wave64:
//     2 warps, 128 threads, 4 floats per thread.
//   * HOST PARTITION get_num_work_group_per_bh: workloads =
//     num_reduce_tile*num_heads; hw_capacity = num_cu*kOccupancy; the
//     empirical 1.3 factor gates the split decision; wg = min(ceil(cap*1.3/
//     workloads), max_seqlen_q), aligned to next_power_of_two (1 stays 1),
//     clamped to 256, then rounded UP into the dispatch table
//     {1,2,4,8,16,64,256}; below the capacity gate the answer is 1.
//   * LSE LANE DISTRIBUTION (reduce_lse_massive, warp 0 only): split s is
//     owned by lane s % 64 at local index s / 64 (split_idx =
//     local_idx*64 + lane); out-of-range tiles read -inf; LocalLse keeps the
//     first 4 per-lane LSEs in registers and spills the rest to memory at
//     (idx-4)*group_size + idx_in_group (hybrid register/gmem view).
//   * MERGE MATH (shared by both problem sizes): per-row max over lanes'
//     local LSEs (warpReduce), sum_lse = sum(exp(lse - max)),
//     global_lse = (sum == 0 || NaN) ? INFINITY : log(sum) + max,
//     lse_scale_s = exp(lse_s - global) written to LDS.
//   * THE PIPELINE IS LOAD-ONLY (reduce_output_massive): the 2-stage
//     software pipeline overlaps tile LOADS and the LDS map prefetches,
//     but every accumulate happens in strict tile order -- reg_out +=
//     scale_t * o_t for t = 0,1,2,... left to right. So the massive
//     pipeline is BITWISE the serial sum; the pipeline hides latency,
//     nothing else. (Handedness: even counts flow through the double-rate
//     loop; the odd tail has two dedicated epilogue blocks.)
//   * VEC SLICING: thread t accumulates output elements [t*kVecWidth,
//     (t+1)*kVecWidth) -- concatenating the per-thread slices reconstructs
//     the full row bitwise.

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <limits>
#include <vector>

struct Lcg {
    std::uint64_t s;
    explicit Lcg(std::uint64_t seed) : s(seed) {}
    std::uint32_t next() {
        s = s * 6364136223846793005ULL + 1442695040888963407ULL;
        return static_cast<std::uint32_t>(s >> 33);
    }
    float uniform(float lo, float hi) {
        return lo + (hi - lo) * (static_cast<float>(next() >> 8) / 16777216.f);
    }
};

static int checks = 0, fails = 0;
#define CHECK(cond)                                                                              \
    do {                                                                                         \
        ++checks;                                                                                \
        if (!(cond)) {                                                                           \
            ++fails;                                                                             \
            if (fails <= 20)                                                                     \
                std::printf("  CHECK failed at line %d: %s\n", __LINE__, #cond);                 \
        }                                                                                        \
    } while (0)

static inline int integer_divide_ceil(int a, int b) { return (a + b - 1) / b; }
static inline int next_power_of_two(int x) {
    if (x <= 1) return 1;
    return 1 << (32 - __builtin_clz(x - 1));
}

// ── host partition, transcribed ──
static constexpr int kOccupancy = 8;
static constexpr int kSupportedNum[] = {1, 2, 4, 8, 16, 64, 256};
static constexpr int kLastSupported = 6;  // sizeof(kSupportedNum)/sizeof(int) - 1
static int get_num_work_group_per_bh(int num_reduce_tile, int max_seqlen_q,
                                     int num_heads, int num_cu) {
    int result = 1;
    const int num_workloads = num_reduce_tile * num_heads;
    const int hw_capacity = num_cu * kOccupancy;
    constexpr float factor = 1.3f;
    if (static_cast<float>(hw_capacity) * factor > static_cast<float>(num_workloads)) {
        const int wg_per_bh_hw = integer_divide_ceil(
            static_cast<int>(static_cast<float>(hw_capacity) * factor), num_workloads);
        const int wg_per_bh = std::min(wg_per_bh_hw, max_seqlen_q);
        const int wg_per_bh_aligned = (wg_per_bh == 1) ? 1 : next_power_of_two(wg_per_bh);
        const int wg_per_bh_clamped = std::min(wg_per_bh_aligned, kSupportedNum[kLastSupported]);
        for (const int supported : kSupportedNum) {
            if (wg_per_bh_clamped <= supported) {
                result = supported;
                break;
            }
        }
    }
    return result;
}

// ── warp emulation context (wave64; gfx9xx) ──
constexpr int kWAVE = 64;
constexpr int kDV = 512;
constexpr int kNumWarps = (kDV < 128) ? 1 : 2;
constexpr int kNumThreads = kNumWarps * kWAVE;
constexpr int kVecWidth = kDV / kNumThreads;
constexpr int kMassiveThreshold = 4;

// the reduce problem for one (row, head): S partials
struct ReduceCase {
    int S = 0;
    std::vector<float> partial_lse;   // [S]
    std::vector<float> partial_o;     // [S * kDV]
};

// reduce_lse_massive: warp 0, lane distribution, merge math -> lse_scale[S]
static void reduce_lse(const ReduceCase& c, float& global_lse,
                       std::vector<float>& lse_scale) {
    const int num_lse_per_thr = (c.S + kWAVE - 1) / kWAVE;
    // lane L holds local LSEs at split_idx = i*64 + L (hybrid LocalLse: first
    // 4 per lane in registers, spill at (i-4)*group + lane -- the emulation
    // indexes the same logical values)
    float max_lse = -std::numeric_limits<float>::infinity();
    std::vector<float> local(num_lse_per_thr * kWAVE, -std::numeric_limits<float>::infinity());
    for (int i = 0; i < num_lse_per_thr; ++i)
        for (int lane = 0; lane < kWAVE; ++lane) {
            const int split_idx = i * kWAVE + lane;
            float lse = -std::numeric_limits<float>::infinity();
            if (split_idx < c.S) lse = c.partial_lse[static_cast<std::size_t>(split_idx)];
            local[static_cast<std::size_t>(i * kWAVE + lane)] = lse;
            max_lse = std::fmax(max_lse, lse);
        }
    float sum_lse = 0.f;
    for (int i = 0; i < num_lse_per_thr; ++i)
        for (int lane = 0; lane < kWAVE; ++lane)
            sum_lse += std::exp(local[static_cast<std::size_t>(i * kWAVE + lane)] - max_lse);
    global_lse = (sum_lse == 0.f || sum_lse != sum_lse)
                     ? std::numeric_limits<float>::infinity()
                     : std::log(sum_lse) + max_lse;
    lse_scale.assign(static_cast<std::size_t>(c.S), 0.f);
    for (int i = 0; i < num_lse_per_thr; ++i)
        for (int lane = 0; lane < kWAVE; ++lane) {
            const int split_idx = i * kWAVE + lane;
            if (split_idx < c.S)
                lse_scale[static_cast<std::size_t>(split_idx)] =
                    std::exp(local[static_cast<std::size_t>(i * kWAVE + lane)] - global_lse);
        }
}

// reduce_output_massive: strict tile-order accumulation (the pipeline's
// arithmetic order), thread slices of kVecWidth
static void reduce_output_massive(const ReduceCase& c,
                                  const std::vector<float>& lse_scale,
                                  std::vector<float>& out) {
    out.assign(static_cast<std::size_t>(kDV), 0.f);
    // per-thread slice accumulation in strict tile order 0,1,2,...
    for (int tid = 0; tid < kNumThreads; ++tid) {
        float acc[kVecWidth] = {0};
        for (int t = 0; t < c.S; ++t)
            for (int q = 0; q < kVecWidth; ++q)
                acc[q] += lse_scale[static_cast<std::size_t>(t)] *
                          c.partial_o[static_cast<std::size_t>(t * kDV + tid * kVecWidth + q)];
        for (int q = 0; q < kVecWidth; ++q)
            out[static_cast<std::size_t>(tid * kVecWidth + q)] = acc[q];
    }
}

// the pipeline's exact control flow (double-rate loop + two epilogues) as an
// ORDER check: produces the identical add sequence as the serial loop above
static void reduce_output_pipeline_order(const ReduceCase& c,
                                         const std::vector<float>& lse_scale,
                                         std::vector<float>& out) {
    out.assign(static_cast<std::size_t>(kDV), 0.f);
    for (int tid = 0; tid < kNumThreads; ++tid) {
        float acc0[kVecWidth] = {0};
        auto add = [&](float* a, int t) {
            for (int q = 0; q < kVecWidth; ++q)
                a[q] += lse_scale[static_cast<std::size_t>(t)] *
                        c.partial_o[static_cast<std::size_t>(t * kDV + tid * kVecWidth + q)];
        };
        // "oaccu_0 ready" for tile 0
        int tile_idx = 0;
        const int end_double = c.S - c.S % 2 - 2;
        for (; tile_idx < end_double; tile_idx += 2) {
            add(acc0, tile_idx);      // calc tile 0
            add(acc0, tile_idx + 1);  // calc tile 1 (after its load, in order)
        }
        if ((tile_idx + 1) < c.S) {
            add(acc0, tile_idx);
            add(acc0, tile_idx + 1);
            tile_idx += 2;
        }
        if (tile_idx < c.S) add(acc0, tile_idx);
        for (int q = 0; q < kVecWidth; ++q)
            out[static_cast<std::size_t>(tid * kVecWidth + q)] = acc0[q];
    }
}

// serial flat reference (independent code path)
static void reduce_serial(const ReduceCase& c, const std::vector<float>& lse_scale,
                          std::vector<float>& out) {
    out.assign(static_cast<std::size_t>(kDV), 0.f);
    for (int t = 0; t < c.S; ++t)
        for (int d = 0; d < kDV; ++d)
            out[static_cast<std::size_t>(d)] +=
                lse_scale[static_cast<std::size_t>(t)] *
                c.partial_o[static_cast<std::size_t>(t * kDV + d)];
}

int main() {
    // ════ 0. traits constants ════
    {
        CHECK(kOccupancy == 8);
        CHECK(kMassiveThreshold == 4);
        CHECK(kNumWarps == 2 && kNumThreads == 128);
        CHECK(kVecWidth == 4);
        CHECK(kDV % kNumThreads == 0);
        // small-DV branch: SizeDV < 128 -> 1 warp
        constexpr int dv64 = 64;
        constexpr int nw = (dv64 < 128) ? 1 : 2;
        CHECK(nw == 1);
    }

    // ════ 1. host partition math ════
    {
        // hand case: 304 CU (gfx1030), cap = 304*8 = 2432, x1.3 = 3161
        const int cap13 = static_cast<int>(304 * 8 * 1.3f);
        CHECK(cap13 == 3161);
        // (a) above the gate: workloads >= cap*1.3 -> 1
        CHECK(get_num_work_group_per_bh(3162, 16, 1, 304) == 1);
        // (b) below: wg = ceil(3161/workloads) capped by max_seqlen_q,
        //     next_pow2, clamp 256, round UP into the table
        CHECK(get_num_work_group_per_bh(1, 16, 1, 304) == 16);  // ceil=3161 -> min(q=16) -> 16
        CHECK(get_num_work_group_per_bh(1, 3, 1, 304) == 4);    // min(3161,3)=3 -> pow2 4
        CHECK(get_num_work_group_per_bh(1, 5, 1, 304) == 8);    // 5 -> 8
        CHECK(get_num_work_group_per_bh(1, 1, 1, 304) == 1);    // 1 stays 1
        CHECK(get_num_work_group_per_bh(1, 300, 1, 304) == 256);// clamp kLastSupported
        CHECK(get_num_work_group_per_bh(1, 300, 300, 304) == 16);// 3161/300=ceil 11 -> pow2 16
        // (c) head scaling keeps the gate open but caps at q
        // 2*400 = 800 < 3161.6 -> wg = ceil(3161/800) = 4 -> min(q=4) = 4
        CHECK(get_num_work_group_per_bh(2, 4, 400, 304) == 4);
        // (d) gate boundary: 304*8*1.3 = 3161.6 as float
        // workloads 3161 < 3161.6: gate open, wg = ceil(3161/3161) = 1
        CHECK(get_num_work_group_per_bh(3161, 16, 1, 304) == 1);
        // workloads 3162 > 3161.6: gate CLOSED -> result stays 1 (no splits)
        CHECK(get_num_work_group_per_bh(3162, 16, 1, 304) == 1);
    }

    // ════ 2. problem-size routing ════
    {
        CHECK(kMassiveThreshold == 4);
        // S < 4 -> up-to-wave (num_lse_per_thr == 1); S >= 4 -> massive
        const auto npt = [](int S) { return (S + kWAVE - 1) / kWAVE; };
        CHECK(npt(1) == 1 && npt(3) == 1 && npt(4) == 1 && npt(64) == 1);
        CHECK(npt(65) == 2 && npt(129) == 3);
        // LocalLse hybrid: per-lane register slots are the first 4 locals,
        // spill index (i-4)*group + lane recovers the same logical value
        for (int i = 4; i < 8; ++i) {
            const int group = kWAVE;
            const int spilled_lane = (i - 4) * group + 17;  // encode lane 17
            CHECK(spilled_lane % kWAVE == 17);              // decode keeps the lane
        }
    }

    // ════ 3. merge math + bitwise pipeline == serial ════
    {
        Lcg rng(0x77);
        for (int S : {1, 2, 3, 4, 5, 7, 8, 33, 64, 65, 129, 200}) {
            ReduceCase c;
            c.S = S;
            c.partial_lse.resize(static_cast<std::size_t>(S));
            c.partial_o.resize(static_cast<std::size_t>(S) * kDV);
            for (int t = 0; t < S; ++t) {
                c.partial_lse[static_cast<std::size_t>(t)] = rng.uniform(-8.f, 4.f);
                for (int d = 0; d < kDV; ++d)
                    c.partial_o[static_cast<std::size_t>(t * kDV + d)] = rng.uniform(-2.f, 2.f);
            }
            // -inf tail tiles beyond S are exercised via num_lse_per_thr padding
            float gl = 0.f;
            std::vector<float> scales;
            reduce_lse(c, gl, scales);
            // weights sum to 1 (within float eps scaled by |gl|)
            float wsum = 0.f;
            for (int t = 0; t < S; ++t) wsum += scales[static_cast<std::size_t>(t)];
            CHECK(std::fabs(wsum - 1.f) <= 4e-7f * std::fmax(1.f, std::fabs(gl)));
            // bitwise: massive order == pipeline control-flow order == serial
            std::vector<float> a, b, r;
            reduce_output_massive(c, scales, a);
            reduce_output_pipeline_order(c, scales, b);
            reduce_serial(c, scales, r);
            CHECK(a == b);
            CHECK(a == r);
            // global_lse finite and in range
            CHECK(std::isfinite(gl));
            float mn = 1e30f, mx = -1e30f;
            for (int t = 0; t < S; ++t) {
                mn = std::fmin(mn, c.partial_lse[static_cast<std::size_t>(t)]);
                mx = std::fmax(mx, c.partial_lse[static_cast<std::size_t>(t)]);
            }
            // gl = max + log(sum), sum in [1, S]: lower-bounded by the max
            // LSE, upper-bounded by max + log(S) (log(200) ~ 5.3 -- a tight
            // mx + eps bound would be wrong for large split counts)
            CHECK(gl >= mn - 1e-4f && gl <= mx + std::log(static_cast<float>(S)) + 1e-4f);
            // all-(-inf) splits -> INFINITY guard
            ReduceCase z = c;
            for (auto& v : z.partial_lse) v = -std::numeric_limits<float>::infinity();
            float zgl = 0.f;
            std::vector<float> zs;
            reduce_lse(z, zgl, zs);
            CHECK(zgl == std::numeric_limits<float>::infinity());
            CHECK(zs[0] == 0.f);  // exp(-inf - inf) = exp(NaN)? pinned below
            // NOTE: exp(-inf - +inf) is NaN in IEEE; the kernel's scale for an
            // all-masked split is undefined -- the INFINITY global is the
            // guard, downstream consumers treat the row as empty. Documented.
        }
        // l==0 semantics from the M6-#3 side: -inf lses merge to INFINITY
        // global; the guard exists exactly for that case (sum==0 || NaN)
        {
            // the sum path with every LSE at -inf: local - max = -inf - (-inf)
            // = NaN -> exp(NaN) = NaN -> the "sum_lse != sum_lse" term fires
            const float sum = std::exp(-std::numeric_limits<float>::infinity() -
                                       (-std::numeric_limits<float>::infinity()));
            CHECK(sum != sum);  // NaN
        }
    }

    // ════ 4. randomized master sweep ════
    {
        int rows = 0;
        for (int seed = 0; seed < 8; ++seed) {
            Lcg rng(0x9000u + static_cast<std::uint64_t>(seed));
            const int S = 1 + static_cast<int>(rng.next() % 200);
            ReduceCase c;
            c.S = S;
            c.partial_lse.resize(static_cast<std::size_t>(S));
            c.partial_o.resize(static_cast<std::size_t>(S) * kDV);
            for (int t = 0; t < S; ++t) {
                c.partial_lse[static_cast<std::size_t>(t)] = rng.uniform(-10.f, 3.f);
                for (int d = 0; d < kDV; ++d)
                    c.partial_o[static_cast<std::size_t>(t * kDV + d)] = rng.uniform(-1.5f, 1.5f);
            }
            float gl = 0.f;
            std::vector<float> scales, a, r;
            reduce_lse(c, gl, scales);
            reduce_output_massive(c, scales, a);
            reduce_serial(c, scales, r);
            ++rows;
            CHECK(a == r);
            float wsum = 0.f;
            for (int t = 0; t < S; ++t) wsum += scales[static_cast<std::size_t>(t)];
            CHECK(std::fabs(wsum - 1.f) <= 4e-7f * std::fmax(1.f, std::fabs(gl)));
        }
        std::printf("  sweep: %d split-counts, massive == serial bitwise\n", rows);
        CHECK(rows == 8);
    }

    std::printf("mla_reduce_warp_contract: %d checks, %d failures -> %s\n", checks, fails,
                fails ? "FAIL" : "PASS");
    return fails ? 1 : 0;
}
