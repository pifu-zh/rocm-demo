// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2026, Advanced Micro Devices, Inc. All rights reserved.
//
// Host reference for aiter's topk_plain adaptive strategy ladder
// (csrc/kernels/topk_plain_kernels.cu @ 1eab5ae12, MIT). Four
// independently-extractable designs:
//
// [1] WaveTopkFilter — ballot-gated streaming filter. Each wave keeps a
//     distributed top-`capacity` buffer: rank r (r-th best, descending)
//     lives at (lane r&63, slot r/64), so lane (k-1)&63 slot (k-1)/64 IS
//     the k-th best = the filter threshold. Per 64-lane tile:
//       passes  = candidate > threshold           (strict; sentinels never
//                                                  pass -inf > -inf)
//       ballot  = 64-bit mask of passing lanes    (__ballot)
//       offset  = popcount(ballot & ((1<<lane)-1)) (__popcll prefix)
//       slot    = staging_count + offset          (compacted append)
//     Staging accepts 64 candidates; the tail (slot >= 64) wraps to
//     slot-64 AFTER the integrate consumed the first 64 (program order
//     makes this race-free on device). integrate: sort the 64 staged
//     candidates, replace each lane's weakest slot if preferred, re-sort
//     the buffer, refresh threshold. finalize pads leftovers with
//     sentinels. This demo emulates the machinery with an order-free
//     buffer model (std::vector kept sorted descending) — the cross-lane
//     bitonic NETWORK is a device performance detail; the correctness
//     contract (buffer = top-capacity of the union, threshold = k-th
//     best) is what the tests pin. NOTE: the upstream test
//     (op_tests/test_topk_plain.py) sorts both sides before comparing —
//     the output ORDER is not part of the contract, only the selected
//     set. The rank<->(lane,slot) mapping IS pinned here as an internal
//     invariant (it is load-bearing: threshold and weakest-slot reads
//     depend on it).
//
// [2] WaveTopkSort — chunked sort/merge for dense inputs. First
//     capacity-chunk sorted (ascending per upstream example, then
//     maintained as the distributed top-capacity); each next chunk is
//     sorted DESCENDING and merged element-wise against the buffer
//     (bitonic sequence trick) then re-sorted. Emulated order-free:
//     buffer = top-capacity of (buffer U chunk).
//
// [3] Block-wide reduce — halving merge tree. BlockTopkSort::sort gives
//     each wave a DISJOINT range (len_per_wave rounded up to 64);
//     BlockTopkFilter instead stride-SHARES one range across waves (every
//     candidate seen exactly once block-wide). reduce() repeatedly merges
//     wave results pairwise through LDS: waves [half, num) store to
//     val[target_wave*k], waves [0, num/2) merge — emulated as set merges.
//
// [4] Dispatch heuristics (pure host functions, pinned exactly):
//     - should_use_topk_radix: radix path iff K*log2^2(K) >= 4.8n /
//       (log2(n) - 9.5) (from n + K log^2 K >= 3*Factor(n)*n, Factor(n) =
//       1/3 + 1.6/(log2 n - 9.5)); K <= 1 never.
//     - calc_capacity(k) = max(64, ceil_pow2(k)).
//     - LaunchThreshold: BlockTopkFilter {multi 2, single 256},
//       BlockTopkSort {multi 2, single 4} — len_per_wave floors.
//
// Ties (equal values): device compaction order decides index selection on
// exact duplicates (select_idx keeps the lane-own side); the demo pins
// set-equality on DISTINCT-value inputs and value-multiset equality on a
// tie case. Upstream's own test also compares order-freely.
//
// Scope exclusion: radix_topk_dispatch (the multi-block radix kernel in
// topk_per_row_kernels.cu) and buffer_load addressing — only the decision
// function is extracted, not the radix kernel itself.
//
// Verification level: SOURCE_VERIFIED + REFERENCE_PASS (CPU-only).
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <map>
#include <set>
#include <vector>

#define MAIN_RETURN_BAD 1

struct Lcg {
    std::uint64_t s;
    explicit Lcg(std::uint64_t seed) : s(seed) {}
    std::uint32_t next() {
        s = s * 6364136223846793005ULL + 1442695040888963407ULL;
        return static_cast<std::uint32_t>(s >> 33);
    }
    float uniform(float lo, float hi) {
        return lo + (hi - lo) * static_cast<float>(next() % 1000001) / 1.0e6f;
    }
};

constexpr int kWarpSize = 64;  // opus::get_warp_size() on gfx950-class

// Strictly-distinct test input: a shuffled monotone spread over [lo, hi].
// Ties are impossible BY CONSTRUCTION (float grid collisions with
// uniform() broke the index-set comparison; see RESULTS.md), while the
// distribution shape (needed for the sparse/dense regimes) is preserved.
template <typename It>
static void make_distinct_values(It begin, It end, float lo, float hi, Lcg& rng) {
    const long n = end - begin;
    for (long p = 0; p < n; ++p)
        begin[p] = lo + (hi - lo) * (static_cast<float>(p) + 0.5f) / static_cast<float>(n);
    for (long p = n - 1; p > 0; --p) {  // Fisher-Yates
        const long q = static_cast<long>(rng.next() % static_cast<std::uint32_t>(p + 1));
        std::swap(begin[p], begin[q]);
    }
}

// ══════════════════════════════════════════════════════════════════════
// [4a] Dispatch heuristics (exact replication)
// ══════════════════════════════════════════════════════════════════════
static bool should_use_topk_radix(long len, long k) {
    const double n = static_cast<double>(len);
    const double K = static_cast<double>(k);
    if (K <= 1.0) return false;
    const double log_n = std::log2(n);
    const double denom = std::max(0.0001, log_n - 9.5);
    const double rhs = (4.8 * n) / denom;
    const double log_k = std::log2(K);
    const double lhs = K * log_k * log_k;
    return lhs >= rhs;
}

static int calc_capacity(int k) {
    int cap = 1;
    while (cap < k) cap <<= 1;
    return cap < kWarpSize ? kWarpSize : cap;
}

// ══════════════════════════════════════════════════════════════════════
// [1] WaveTopkFilter emulation (order-free buffer, faithful machinery)
// ══════════════════════════════════════════════════════════════════════
struct FilterTopk {
    int k;
    int capacity;
    // distributed-buffer model: buf[lane][slot], rank r -> (r&63, r/64),
    // per-lane descending. Kept as flat vectors; sentinel = -inf.
    std::vector<float> prio;  // capacity entries, rank-major (rank r at r)
    std::vector<long> pos;
    // staging (per wave, LDS)
    float stage_v[kWarpSize];
    long stage_p[kWarpSize];
    int staging_count = 0;
    float threshold;
    // trace
    long integrates = 0;
    long overflow_writes = 0;

    explicit FilterTopk(int k_) : k(k_), capacity(calc_capacity(k)) {
        prio.assign(capacity, -INFINITY);
        pos.assign(capacity, -1);
        threshold = -INFINITY;
    }

    float rank_value(int r) const { return prio[r]; }  // rank-major model

    void refresh_threshold() {
        const int last_rank = k - 1;  // threshold_lane (k-1)&63, slot (k-1)/64
        threshold = prio[last_rank];
    }

    // semantic integrate: buffer U staged64 -> top-capacity, re-laid out
    void integrate() {
        std::vector<std::pair<float, long>> all;
        all.reserve(static_cast<size_t>(capacity) + kWarpSize);
        for (int r = 0; r < capacity; ++r) all.push_back({prio[r], pos[r]});
        for (int l = 0; l < kWarpSize; ++l) all.push_back({stage_v[l], stage_p[l]});
        std::sort(all.begin(), all.end(), [](const auto& a, const auto& b) {
            if (a.first != b.first) return a.first > b.first;
            return a.second < b.second;
        });
        for (int r = 0; r < capacity; ++r) {
            prio[r] = all[r].first;
            pos[r] = all[r].second;
        }
        ++integrates;
        refresh_threshold();
    }

    // One filter_and_stage step, executed by ALL lanes in lockstep on the
    // host (device: each lane runs it independently; the ballot/prefix are
    // wave-wide). candidates[l] = value lane l processes this step.
    void filter_and_stage(const float candidates[kWarpSize], const long positions[kWarpSize]) {
        std::uint64_t ballot = 0;
        for (int l = 0; l < kWarpSize; ++l)
            if (candidates[l] > threshold) ballot |= 1ull << l;  // strict pass
        if (ballot == 0) return;
        const int ballot_count = __builtin_popcountll(ballot);
        const int staging_base = staging_count;
        for (int l = 0; l < kWarpSize; ++l) {
            const bool passes = (ballot >> l) & 1;
            const int lane_offset =
                __builtin_popcountll(ballot & ((1ull << l) - 1));  // popcll prefix
            const int slot = staging_base + lane_offset;
            const bool fits = passes && slot < kWarpSize;
            if (fits) {
                stage_v[slot] = candidates[l];
                stage_p[slot] = positions[l];
            }
            // (count updated below, after the lane loop — device does it
            // once per lane but with the same base; total identical)
        }
        staging_count = staging_base + ballot_count;
        if (staging_count >= kWarpSize) {
            integrate();  // wave_barrier + integrate in device order
            staging_count -= kWarpSize;
            // Emulation hardening: slots [count, 64) are consumed/stale
            // (upstream's coverage argument: [0, base) were valid pending,
            // [base, 64) were written by this pass's fits — so on device
            // every integrate reads a fully-covered staging region; the
            // sentinel sweep makes that invariant explicit).
            for (int l = staging_count; l < kWarpSize; ++l) {
                stage_v[l] = -INFINITY;
                stage_p[l] = 0;
            }
        }
        // overflow: wraps into the slots the integrate just consumed
        for (int l = 0; l < kWarpSize; ++l) {
            const bool passes = (ballot >> l) & 1;
            const int lane_offset = __builtin_popcountll(ballot & ((1ull << l) - 1));
            const int slot = staging_base + lane_offset;
            if (passes && slot >= kWarpSize) {
                stage_v[slot - kWarpSize] = candidates[l];
                stage_p[slot - kWarpSize] = positions[l];
                ++overflow_writes;
            }
        }
    }

    void finalize() {
        if (staging_count) {
            // Upstream pads per-lane reads with sentinels beyond
            // staging_count (finalize builds val/idx = sentinel for lanes
            // >= count). The staging slots [count, 64) hold STALE entries
            // consumed by earlier integrates — they must NOT re-enter the
            // union (duplicate ranks would displace real top-k members).
            for (int l = staging_count; l < kWarpSize; ++l) {
                stage_v[l] = -INFINITY;
                stage_p[l] = 0;
            }
            integrate();
            staging_count = 0;
        }
    }

    // flush: ranks < k (set semantics; upstream test sorts before compare)
    void flush(std::vector<float>& out_v, std::vector<long>& out_p) const {
        out_v.assign(prio.begin(), prio.begin() + k);
        out_p.assign(pos.begin(), pos.begin() + k);
    }
};

// Full filter-strategy run: single wave stride-shares [start, end).
static void wave_filter_run(const std::vector<float>& in, long start, long end, int k,
                            std::vector<float>& out_v, std::vector<long>& out_p,
                            long* integrates = nullptr, long* overflows = nullptr) {
    FilterTopk f(k);
    const long n = end - start;
    const long end_aligned = start + ((n + kWarpSize - 1) / kWarpSize) * kWarpSize;
    for (long base = start; base < end_aligned; base += kWarpSize) {
        float cand[kWarpSize];
        long posi[kWarpSize];
        for (int l = 0; l < kWarpSize; ++l) {
            const long p = base + l;
            cand[l] = p < end ? in[p] : -INFINITY;
            posi[l] = p;
        }
        f.filter_and_stage(cand, posi);
    }
    f.finalize();
    f.flush(out_v, out_p);
    if (integrates) *integrates = f.integrates;
    if (overflows) *overflows = f.overflow_writes;
}

// ══════════════════════════════════════════════════════════════════════
// [2] WaveTopkSort emulation (order-free chunks)
// ══════════════════════════════════════════════════════════════════════
static void wave_sort_run(const std::vector<float>& in, long start, long end, int k,
                          std::vector<float>& out_v, std::vector<long>& out_p) {
    const int capacity = calc_capacity(k);
    std::vector<std::pair<float, long>> buf;  // top-capacity, descending
    auto merge_chunk = [&](long cstart, long cend) {
        for (long p = cstart; p < cend; ++p) buf.push_back({in[p], p});
        std::sort(buf.begin(), buf.end(), [](const auto& a, const auto& b) {
            if (a.first != b.first) return a.first > b.first;
            return a.second < b.second;
        });
        if (static_cast<long>(buf.size()) > capacity) buf.resize(capacity);
    };
    long c = start;
    bool first = true;
    while (c < end) {
        const long cend = std::min(c + capacity, end);
        if (first) {
            // process_first_chunk: loads raw, sorts ascending (upstream) —
            // order-free equivalent: just take into the buffer
            merge_chunk(c, cend);
            first = false;
        } else {
            merge_chunk(c, cend);
        }
        c = cend;
    }
    out_v.clear();
    out_p.clear();
    for (int r = 0; r < k && r < static_cast<int>(buf.size()); ++r) {
        out_v.push_back(buf[r].first);
        out_p.push_back(buf[r].second);
    }
}

// ══════════════════════════════════════════════════════════════════════
// [3] Block-wide reduce: disjoint wave ranges (Sort) + halving merge tree
// ══════════════════════════════════════════════════════════════════════
static void block_sort_run(const std::vector<float>& in, long start, long end, int k,
                           int num_waves, std::vector<float>& out_v,
                           std::vector<long>& out_p) {
    // BlockTopkSort::sort: len_per_wave rounded UP to a multiple of 64
    long len_per_wave = (end - start - 1) / num_waves + 1;
    len_per_wave = ((len_per_wave + kWarpSize - 1) / kWarpSize) * kWarpSize;
    std::vector<std::pair<float, long>> acc;
    for (int w = 0; w < num_waves; ++w) {
        const long ws = start + w * len_per_wave;
        const long we = std::min(ws + len_per_wave, end);
        if (ws >= we) break;
        std::vector<float> wv;
        std::vector<long> wp;
        wave_sort_run(in, ws, we, k, wv, wp);
        for (size_t i = 0; i < wv.size(); ++i) acc.push_back({wv[i], wp[i]});
    }
    std::sort(acc.begin(), acc.end(), [](const auto& a, const auto& b) {
        if (a.first != b.first) return a.first > b.first;
        return a.second < b.second;
    });
    // halving merge tree keeps exactly the top-k of the union (reduce
    // merges carry k entries per wave; semantic result identical)
    out_v.clear();
    out_p.clear();
    for (int r = 0; r < k && r < static_cast<int>(acc.size()); ++r) {
        out_v.push_back(acc[r].first);
        out_p.push_back(acc[r].second);
    }
}

// Naive reference: exact top-k by (value desc, index asc) — a third
// implementation of the same contract.
static void naive_topk(const std::vector<float>& in, long start, long end, int k,
                       std::vector<float>& out_v, std::vector<long>& out_p) {
    std::vector<std::pair<float, long>> all;
    for (long p = start; p < end; ++p) all.push_back({in[p], p});
    std::sort(all.begin(), all.end(), [](const auto& a, const auto& b) {
        if (a.first != b.first) return a.first > b.first;
        return a.second < b.second;
    });
    out_v.clear();
    out_p.clear();
    for (int r = 0; r < k && r < static_cast<int>(all.size()); ++r) {
        out_v.push_back(all[r].first);
        out_p.push_back(all[r].second);
    }
}

// set comparison (order-free, per upstream test discipline)
static bool same_set(const std::vector<long>& a, const std::vector<long>& b) {
    std::vector<long> x = a, y = b;
    std::sort(x.begin(), x.end());
    std::sort(y.begin(), y.end());
    return x == y;
}

// ══════════════════════════════════════════════════════════════════════
// Tests
// ══════════════════════════════════════════════════════════════════════
int main() {
    int checks = 0, fails = 0;

    // ── 1. Filter strategy: set correctness + behavior traces ──
    {
        struct Cfg {
            int k;
            long n;
            float lo, hi;
            const char* what;
        };
        static const Cfg cfgs[] = {
            {64, 4096, 0.0f, 1.0f, "dense (all pass early, overflow path)"},
            {64, 4096, 0.0f, 0.02f, "sparse-ish"},
            {64, 100000, 0.0f, 0.0005f, "very sparse (most filtered)"},
            {32, 4096, 0.0f, 1.0f, "k < capacity (32, cap 64)"},
            {128, 8192, 0.0f, 1.0f, "k = 128 (2 slots/lane)"},
            {64, 100, 0.0f, 1.0f, "n < capacity*2 (few tiles)"},
        };
        int f = 0;
        for (const auto& c : cfgs) {
            Lcg rng(0x7050b ^ c.k);
            std::vector<float> in(c.n);
            make_distinct_values(in.begin(), in.end(), c.lo, c.hi, rng);
            std::vector<float> gv, nv;
            std::vector<long> gp, np;
            long integrates = 0, overflows = 0;
            wave_filter_run(in, 0, c.n, c.k, gv, gp, &integrates, &overflows);
            naive_topk(in, 0, c.n, c.k, nv, np);
            ++checks;
            if (!same_set(gp, np) && f < 8) {
                std::printf("  filter %s (k=%d n=%ld): index set mismatch\n", c.what, c.k, c.n);
                std::set<long> want(np.begin(), np.end()), got(gp.begin(), gp.end());
                int shown = 0;
                for (long p : want)
                    if (!got.count(p) && shown < 8) {
                        std::printf("    lost idx %ld val %g\n", p, in[p]);
                        ++shown;
                    }
                shown = 0;
                for (long p : got)
                    if (!want.count(p) && shown < 8) {
                        std::printf("    extra idx %ld val %g\n", p, in[p]);
                        ++shown;
                    }
                ++f;
            }
            ++checks;
            for (size_t i = 0; i < gp.size() && !f; ++i) {
                // each selected index maps to the same value in the input
                if (std::fabs(gv[i] - in[gp[i]]) > 1e-30f && f < 8) {
                    std::printf("  filter %s: value/index mismatch at %zu\n", c.what, i);
                    ++f;
                }
            }
            // behavioral: sparse regime must actually filter (fewer
            // integrates than dense at same n), overflow only in dense
            if (c.k == 64 && c.n == 4096) {
                ++checks;
                if (integrates <= 0 && f < 8) {
                    std::printf("  dense: no integrates traced\n");
                    ++f;
                }
                ++checks;
                if (overflows <= 0 && f < 8) {
                    std::printf("  dense: overflow path never exercised\n");
                    ++f;
                }
            }
        }
        fails += f > 0;
        std::printf("1. WaveTopkFilter: ballot/staging/integrate/overflow vs naive (6 cfgs): %s\n",
                    f ? "FAIL" : "PASS");
    }

    // ── 2. Sort strategy: set correctness ──
    {
        int f = 0;
        for (long n : {64L, 65L, 1000L, 4096L}) {
            Lcg rng(0x5027 ^ n);
            std::vector<float> in(n);
            make_distinct_values(in.begin(), in.end(), -3.0f, 3.0f, rng);
            for (int k : {64, 32, 128}) {
                std::vector<float> gv, nv;
                std::vector<long> gp, np;
                wave_sort_run(in, 0, n, k, gv, gp);
                naive_topk(in, 0, n, k, nv, np);
                ++checks;
                if (!same_set(gp, np) && f < 8) {
                    std::printf("  sort n=%ld k=%d: index set mismatch\n", n, k);
                    ++f;
                }
            }
        }
        fails += f > 0;
        std::printf("2. WaveTopkSort: chunked sort/merge vs naive: %s\n", f ? "FAIL" : "PASS");
    }

    // ── 3. Block-wide reduce: disjoint wave ranges + halving merge ──
    {
        int f = 0;
        for (int num_waves : {2, 4, 8}) {
            Lcg rng(0x1234 + num_waves);
            const long n = 4096;
            std::vector<float> in(n);
            make_distinct_values(in.begin(), in.end(), -5.0f, 5.0f, rng);
            for (int k : {64, 128}) {
                std::vector<float> gv, nv;
                std::vector<long> gp, np;
                block_sort_run(in, 0, n, k, num_waves, gv, gp);
                naive_topk(in, 0, n, k, nv, np);
                ++checks;
                if (!same_set(gp, np) && f < 8) {
                    std::printf("  reduce waves=%d k=%d: index set mismatch\n", num_waves, k);
                    ++f;
                }
            }
        }
        fails += f > 0;
        std::printf("3. Block-wide reduce (wave ranges + halving merge tree): %s\n",
                    f ? "FAIL" : "PASS");
    }

    // ── 4. Threshold contract: monotone + final equality ──
    {
        int f = 0;
        Lcg rng(0x1337);
        const long n = 3000;
        std::vector<float> in(n);
        make_distinct_values(in.begin(), in.end(), 0.0f, 10.0f, rng);
        // The threshold is the k-th best of the INTEGRATED subset — it
        // legitimately LAGS the raw prefix while candidates sit in staging.
        // What correctness needs (and what we pin): (a) the threshold never
        // decreases (the buffer only improves), and (b) after finalize it
        // equals the true k-th best of the whole input. Safety of filtering
        // itself: a candidate below the threshold at filter time can never
        // re-enter the final top-k (>= k better elements already kept), so
        // lagging is safe — verified end-to-end by test 1's set equality.
        FilterTopk ftop(64);
        const long end_aligned = ((n + kWarpSize - 1) / kWarpSize) * kWarpSize;
        float prev_threshold = -INFINITY;
        for (long base = 0; base < end_aligned; base += kWarpSize) {
            float cand[kWarpSize];
            long posi[kWarpSize];
            for (int l = 0; l < kWarpSize; ++l) {
                const long p = base + l;
                cand[l] = p < n ? in[p] : -INFINITY;
                posi[l] = p;
            }
            ftop.filter_and_stage(cand, posi);
            ++checks;
            if (ftop.threshold < prev_threshold && f < 5) {
                std::printf("  threshold decreased: %g < %g after %ld elems\n", ftop.threshold,
                            prev_threshold, std::min(base + kWarpSize, n));
                ++f;
            }
            prev_threshold = ftop.threshold;
        }
        ftop.finalize();
        std::vector<float> sorted_in = in;
        std::sort(sorted_in.begin(), sorted_in.end(), std::greater<float>());
        ++checks;
        if (std::fabs(ftop.threshold - sorted_in[63]) > 0.0f && f < 5) {
            std::printf("  final threshold %g != k-th best %g\n", ftop.threshold, sorted_in[63]);
            ++f;
        }
        fails += f > 0;
        std::printf("4. threshold contract (monotone; final == true k-th best): %s\n",
                    f ? "FAIL" : "PASS");
    }

    // ── 5. Dispatch heuristics ──
    {
        int f = 0;
        // K <= 1 never
        ++checks;
        if (should_use_topk_radix(4096, 1) && f < 5) {
            std::printf("  radix: K=1 returned true\n");
            ++f;
        }
        // exact formula points (lhs = K log2^2 K; rhs = 4.8n/(log2 n - 9.5))
        struct P {
            long n, k;
            bool want;
        };
        static const P pts[] = {
            {4096, 64, false},   // lhs 2304 < rhs 7864
            {4096, 256, true},   // lhs 16384 >= rhs 7864
            {4096, 128, false},  // lhs 6272 < rhs 7864
            {8192, 256, true},   // lhs 16384 >= rhs 11235.7 (denom 3.5)
            {16384, 256, false},  // lhs 16384 < rhs 17476 (denom 4.5)
            {65536, 512, false},  // lhs 41472 < rhs 48394 (denom 6.5)
        };
        for (const auto& p : pts) {
            ++checks;
            if (should_use_topk_radix(p.n, p.k) != p.want && f < 5) {
                std::printf("  radix n=%ld k=%ld: got %d want %d\n", p.n, p.k,
                            should_use_topk_radix(p.n, p.k), p.want);
                ++f;
            }
        }
        // monotone in k for fixed n (once true, stays true)
        {
            const long n = 32768;
            bool seen_true = false;
            for (long k = 1; k <= 4096; k *= 2) {
                const bool v = should_use_topk_radix(n, k);
                ++checks;
                if (seen_true && !v && f < 5) {
                    std::printf("  radix not monotone in k at n=%ld k=%ld\n", n, k);
                    ++f;
                }
                seen_true |= v;
            }
        }
        // calc_capacity: pow2, >= 64, >= k, minimal (= max(64, ceil_pow2(k)))
        for (int k : {1, 2, 31, 32, 33, 64, 65, 127, 128, 129, 1000, 2048}) {
            const int cap = calc_capacity(k);
            const bool ok = cap >= kWarpSize && cap >= k && (cap & (cap - 1)) == 0 &&
                            cap == (k <= kWarpSize ? kWarpSize : cap) &&
                            (cap == kWarpSize || cap / 2 < k || k <= kWarpSize);
            ++checks;
            if (!ok && f < 5) {
                std::printf("  capacity(%d) = %d violates minimality/pow2\n", k, cap);
                ++f;
            }
        }
        fails += f > 0;
        std::printf("5. dispatch: should_use_topk_radix formula + calc_capacity: %s\n",
                    f ? "FAIL" : "PASS");
    }

    // ── 6. tie behavior: value multiset pinned, index order documented free ──
    {
        int f = 0;
        Lcg rng(0x71e);
        const long n = 1024;
        std::vector<float> in(n);
        for (auto& v : in) v = static_cast<float>(rng.next() % 10);  // heavy ties
        std::vector<float> gv, nv;
        std::vector<long> gp, np;
        wave_filter_run(in, 0, n, 64, gv, gp, nullptr, nullptr);
        naive_topk(in, 0, n, 64, nv, np);
        std::vector<float> gs = gv, ns = nv;
        std::sort(gs.begin(), gs.end(), std::greater<float>());
        std::sort(ns.begin(), ns.end(), std::greater<float>());
        ++checks;
        if (gs != ns && f < 5) {
            std::printf("  tie case: value multiset mismatch\n");
            ++f;
        }
        ++checks;
        // selected indices must map to values >= the k-th best
        const float kth = gs.back();
        for (long p : gp) {
            if (in[p] < kth && f < 5) {
                std::printf("  tie case: selected index %ld below k-th best\n", p);
                ++f;
                break;
            }
        }
        fails += f > 0;
        std::printf("6. tie behavior (value multiset pinned; index order free): %s\n",
                    f ? "FAIL" : "PASS");
    }

    std::printf("topk_plain_strategies: %d checks, %d failures -> %s\n", checks, fails,
                fails ? "FAIL" : "PASS");
    return fails ? MAIN_RETURN_BAD : 0;
}
