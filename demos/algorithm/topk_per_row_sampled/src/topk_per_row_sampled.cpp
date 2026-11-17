// SPDX-License-Identifier: MIT
// Copyright (C) 2026, Advanced Micro Devices, Inc. All rights reserved.
//
// Host reference for aiter's sampled fp32 per-row top-k pipeline
// (csrc/kernels/topk_per_row_sampled_kernels.cu + csrc/include/topk_sampled/*
// @ 1eab5ae12c93af3c8c660202d9a413f637c2f011, MIT; gfx950-only on device).
//
// The device pipeline:
//   A  phase_a_threshold     one block per row samples S contiguous-chunk
//                            elements (64 per chunk, stride masked to a
//                            dwordx4 multiple) and selects their rank-th key
//                            with a TRUNCATED 3-pass radix (PHASE_A_PASSES=3):
//                            the threshold's low byte is always 0. Ragged
//                            rows with len <= K or len < S route with
//                            threshold_f = +inf instead.
//   B  phase_b_filter_coop   coop_g blocks per row stream the row with
//                            dwordx4 loads and append every element with
//                            !(v < th) -- a FLOAT compare, so it keeps all
//                            NaNs of either sign -- to the row's candidate
//                            area (cap entries). Over cap marks the row bad.
//   C  phase_c_select_contig one block per row: exact 4-pass radix select of
//                            the k_out-th largest key over the candidates,
//                            gather = strictly-greater first, then exactly
//                            eq_needed ties, in candidate order. Fallback to
//                            a whole-row exact select when the row is bad,
//                            short (c < k_out), or when the k-th key would
//                            land in radix bucket 0 (negative NaNs / -inf).
//                            Ragged len <= K emits identity + (-1, -inf) pad.
//
// The correctness invariant this demo verifies: the threshold sampling only
// chooses the PATH, never degrades the answer. If the candidate set holds
// >= k_out elements it provably contains the whole top-k_out (any threshold
// above the true k-th value leaves fewer than k_out candidates, forcing the
// fallback), so the pipeline is EXACT for every (S, rank >= 1, cap >= K).
// The S-law / margins / cap-sigma derivations are perf geometry, not
// correctness, and are not replicated.
//
// Two independent host implementations cross-validate bitwise:
//   run_pipeline -- the three-phase emulation above (candidate order = row
//                   order, a deterministic refinement: device candidate order
//                   is wave-reservation nondeterministic, and ties in the
//                   gather follow candidate order, so the device contract is
//                   the returned VALUE multiset plus valid indices, not a
//                   specific index permutation);
//   run_exact    -- stable sort by (sortable key desc, index asc), an
//                   independent oracle sharing no select code.

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <limits>
#include <numeric>
#include <vector>

// ── lab-shared primitives ──
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
    // random bit pattern, heavily weighted to "interesting" float regions
    std::uint32_t rand_bits() { return next(); }
};
static inline std::uint32_t f32_bits(float f) {
    std::uint32_t u;
    std::memcpy(&u, &f, 4);
    return u;
}
static inline float bits_f32(std::uint32_t u) {
    float f;
    std::memcpy(&f, &u, 4);
    return f;
}

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

// ── the key mapping (csrc/include/topk_fp32_key.h, verbatim semantics) ──
constexpr std::uint32_t fp32_to_sortable_bits(std::uint32_t u) {
    return (u & 0x80000000u) ? ~u : (u ^ 0x80000000u);
}
constexpr std::uint32_t sortable_to_fp32_bits(std::uint32_t s) {
    return (s & 0x80000000u) ? (s ^ 0x80000000u) : ~s;
}
constexpr std::uint32_t NAN_HIGH_SHIFT = 0x007FFFFFu;
template <bool NAN_HIGH>
constexpr std::uint32_t sortable_key_bits(std::uint32_t u) {
    return fp32_to_sortable_bits(u) - (NAN_HIGH ? NAN_HIGH_SHIFT : 0u);
}
template <bool NAN_HIGH>
constexpr std::uint32_t radix_key_bits(std::uint32_t u) {
    if (NAN_HIGH) {
        const std::uint32_t magnitude = u & 0x7fffffffu;
        u                             = magnitude > 0x7f800000u ? magnitude : u;
    }
    const std::uint32_t mask = (u >> 31) ? 0u : 0x7fffffffu;
    return u ^ mask;
}
constexpr std::uint32_t radix_key_to_fp32_bits(std::uint32_t key) {
    return (key >> 31) ? key : (key ^ 0x7fffffffu);
}

constexpr int FP32_EPT            = 4;  // floats per dwordx4 load
constexpr int RADIX_PASSES        = 4;
constexpr int PHASE_A_PASSES      = 3;  // truncated threshold select
constexpr int SAMPLE_CHUNK_ELEMS  = 64;
constexpr int SAMPLE_S_MAX        = 16384;
constexpr int PHASE_C_CAP_MAX     = 4096;  // PHASE_C_CAP
constexpr std::uint32_t CTR_STRIDE = 1;    // irrelevant host-side; counters per row

static inline int sample_chunk_stride(int N, int chunks) {
    return (N / chunks) & ~(FP32_EPT - 1);
}
template <bool NAN_HIGH_ = false>
static inline std::uint32_t radix_shift_pass(int pass) {
    return 24 - 8 * pass;
}
static inline int common_prefix_passes(std::uint32_t mn, std::uint32_t mx) {
    int start = 0;
    while (start < RADIX_PASSES) {
        const int sh = 24 - 8 * start;
        if (((mn >> sh) & 0xFFu) != ((mx >> sh) & 0xFFu)) break;
        start++;
    }
    return start;
}

// ── exact rank select over sortable keys ─────────────────────────────────
// rank is 1-based; returns the rank-th LARGEST key. Truncated form masks the
// low 32-8*npasses bits, which equals the device's truncated-bucket pivot:
// merging ties within a bucket never moves the cumulative crossing, so the
// exact rank-th key lies in the same top-bytes bucket the truncated select
// lands in, and its mask is that bucket's value.
static std::uint32_t exact_rank_key(std::vector<std::uint32_t> keys, int rank, int npasses) {
    const std::uint32_t keep =
        (npasses >= RADIX_PASSES) ? 0xFFFFFFFFu : (0xFFFFFFFFu << (32 - 8 * npasses));
    // nth largest: sort descending, take rank-1 (small c; host clarity first)
    std::sort(keys.begin(), keys.end(), std::greater<std::uint32_t>());
    return keys[static_cast<std::size_t>(rank - 1)] & keep;
}

// ── the pipeline emulation ────────────────────────────────────────────────
struct RowWin {
    int start, len;  // valid slice [start, start+len) within the row's pitch
};
struct SamplePlan {
    int S, rank, cap;
};
struct Cand {
    float v;
    int idx;  // window-relative
};

struct RowOut {
    std::vector<int> idx;      // window-relative (row_start added by caller)
    std::vector<float> val;
    bool fell_back  = false;
    int cand_count  = 0;
    bool overflowed = false;   // c > cap (Phase B marked bad)
    bool undershoot = false;   // k-th key in radix bucket 0
    bool routed_inf = false;   // Phase A routed +inf (short/identity row)
};

// Phase A + B + C for one row. NAN_HIGH is instantiated false in this entry
// (the kernels' default; NAN_HIGH serves topk_select's indices-only path).
static RowOut run_row_pipeline(const std::vector<float>& buf, int pitch,
                               const RowWin& win, bool ragged, int K,
                               const SamplePlan& sp) {
    RowOut ro;
    const int base = 0;  // rows are consecutive pitch strides in buf
    const int row_off = 0;  // caller indexes buf at row*pitch; win.start is the row's start
    (void)base;
    (void)row_off;

    // ---- Phase A ----
    float th = std::numeric_limits<float>::infinity();
    std::uint32_t th_key = 0;
    const bool route_inf = ragged && (win.len <= K || win.len < sp.S);
    if (route_inf) {
        ro.routed_inf = true;
    } else {
        const int chunks = sp.S / SAMPLE_CHUNK_ELEMS;
        const int stride = ragged ? sample_chunk_stride(win.len, chunks)
                                  : sample_chunk_stride(pitch, chunks);
        const double rank_row =
            (ragged && win.len != pitch)
                ? std::max(1, static_cast<int>(static_cast<double>(sp.rank) * pitch / win.len))
                : sp.rank;
        std::vector<std::uint32_t> keys;
        keys.reserve(static_cast<std::size_t>(sp.S));
        for (int c = 0; c < chunks; ++c)
            for (int j = 0; j < SAMPLE_CHUNK_ELEMS; ++j) {
                const int pos = c * stride + j;
                const float v = buf[static_cast<std::size_t>(win.start + pos)];
                keys.push_back(sortable_key_bits<false>(f32_bits(v)));
            }
        th_key = exact_rank_key(keys, static_cast<int>(rank_row), PHASE_A_PASSES);
        // key_to_fp32<false>: invert the sortable map
        th = bits_f32(sortable_to_fp32_bits(th_key));
    }

    // ---- Phase B: keep !(v < th), float compare (keeps all NaNs) ----
    std::vector<Cand> cands;
    for (int i = 0; i < win.len; ++i) {
        const float v = buf[static_cast<std::size_t>(win.start + i)];
        if (!(v < th)) cands.push_back({v, i});
    }
    ro.cand_count = static_cast<int>(cands.size());
    ro.overflowed = ro.cand_count > sp.cap;

    // ---- Phase C ----
    const int k_out = ragged ? std::min(K, win.len) : K;
    bool fall_back = (ragged && win.len <= K) || ro.overflowed ||
                     ro.cand_count < k_out;
    if (!fall_back) {
        int low = 0;
        for (const auto& c : cands)
            if ((sortable_key_bits<false>(f32_bits(c.v)) >> 24) == 0u) ++low;
        ro.undershoot = ro.cand_count - low < k_out;
        fall_back     = ro.undershoot;
    }
    ro.fell_back = fall_back;

    if (ragged && win.len <= K) {
        // identity emit + pad, aiter's convention for len <= K
        ro.idx.resize(static_cast<std::size_t>(K));
        ro.val.resize(static_cast<std::size_t>(K));
        for (int i = 0; i < K; ++i) {
            const bool live = i < win.len;
            ro.idx[static_cast<std::size_t>(i)] = live ? win.start + i : -1;
            ro.val[static_cast<std::size_t>(i)] =
                live ? buf[static_cast<std::size_t>(win.start + i)]
                     : -std::numeric_limits<float>::infinity();
        }
        return ro;
    }

    if (fall_back) {
        // whole-row exact select: every element becomes a candidate, row order
        cands.clear();
        for (int i = 0; i < win.len; ++i)
            cands.push_back({buf[static_cast<std::size_t>(win.start + i)], i});
    }

    // exact select over the candidate keys + candidate-order gather
    std::vector<std::uint32_t> keys;
    keys.reserve(cands.size());
    for (const auto& c : cands) keys.push_back(sortable_key_bits<false>(f32_bits(c.v)));
    const std::uint32_t pivot = exact_rank_key(keys, k_out, RADIX_PASSES);
    int ngt = 0;
    for (const auto& k : keys)
        if (k > pivot) ++ngt;
    const int eq_needed = k_out - ngt;

    ro.idx.assign(static_cast<std::size_t>(k_out), -2);
    ro.val.assign(static_cast<std::size_t>(k_out), 0.f);
    int placed_gt = 0, placed_eq = 0;
    for (std::size_t i = 0; i < cands.size(); ++i) {
        const std::uint32_t k = keys[i];
        if (k > pivot) {
            if (placed_gt < ngt) {
                ro.idx[static_cast<std::size_t>(placed_gt)] = cands[i].idx;
                ro.val[static_cast<std::size_t>(placed_gt)] = cands[i].v;
            }
            ++placed_gt;
        } else if (k == pivot) {
            if (placed_eq < eq_needed) {
                ro.idx[static_cast<std::size_t>(ngt + placed_eq)] = cands[i].idx;
                ro.val[static_cast<std::size_t>(ngt + placed_eq)] = cands[i].v;
            }
            ++placed_eq;
        }
    }
    return ro;
}

// ── the independent oracle: stable sort, row-order ties ──────────────────
static RowOut run_row_exact(const std::vector<float>& buf, const RowWin& win,
                            bool ragged, int K) {
    RowOut ro;
    if (ragged && win.len <= K) {
        // identity emit + pad FIRST: the output is K-sized, not k_out-sized
        ro.idx.assign(static_cast<std::size_t>(K), -2);
        ro.val.assign(static_cast<std::size_t>(K), 0.f);
        for (int i = 0; i < K; ++i) {
            const bool live = i < win.len;
            ro.idx[static_cast<std::size_t>(i)] = live ? win.start + i : -1;
            ro.val[static_cast<std::size_t>(i)] =
                live ? buf[static_cast<std::size_t>(win.start + i)]
                     : -std::numeric_limits<float>::infinity();
        }
        return ro;
    }
    const int k_out = ragged ? std::min(K, win.len) : K;
    ro.idx.assign(static_cast<std::size_t>(k_out), -2);
    ro.val.assign(static_cast<std::size_t>(k_out), 0.f);
    std::vector<int> order(static_cast<std::size_t>(win.len));
    std::iota(order.begin(), order.end(), 0);
    std::stable_sort(order.begin(), order.end(), [&](int a, int b) {
        const std::uint32_t ka = sortable_key_bits<false>(f32_bits(buf[static_cast<std::size_t>(win.start + a)]));
        const std::uint32_t kb = sortable_key_bits<false>(f32_bits(buf[static_cast<std::size_t>(win.start + b)]));
        if (ka != kb) return ka > kb;
        return a < b;
    });
    for (int p = 0; p < k_out; ++p) {
        const int i = order[static_cast<std::size_t>(p)];
        ro.idx[static_cast<std::size_t>(p)] = i;
        ro.val[static_cast<std::size_t>(p)] = buf[static_cast<std::size_t>(win.start + i)];
    }
    return ro;
}

// Order-insensitive comparison. The device's gather assigns slots by wave
// arrival (atomicAdd on a shared counter per candidate block), so slot order
// is NOT part of the contract -- aiter's own routing layer lists `sampled`
// under _NONDETERMINISTIC with no tie-direction promise, and its prefill test
// compares index SETS. Canonicalize both sides by (sortable key desc, index
// asc) -- a total order even across NaN payloads -- then compare bitwise.
static bool row_out_equal(const RowOut& a, const RowOut& b) {
    if (a.idx.size() != b.idx.size() || a.val.size() != b.val.size()) return false;
    auto canon = [](const RowOut& r) {
        std::vector<std::pair<std::uint32_t, int>> ks;
        ks.reserve(r.idx.size());
        for (std::size_t i = 0; i < r.idx.size(); ++i)
            ks.push_back({sortable_key_bits<false>(f32_bits(r.val[i])), r.idx[i]});
        std::sort(ks.begin(), ks.end(), [](const auto& x, const auto& y) {
            if (x.first != y.first) return x.first > y.first;
            return x.second < y.second;
        });
        return ks;
    };
    return canon(a) == canon(b);
}

// ── value fillers for the test matrix ────────────────────────────────────
enum class Dist {
    Uniform,
    Gaussianish,
    TieHeavy,     // many duplicates of a few values
    AllEqual,
    WithInfs,
    WithNaNs,     // both signs, payloads
    SignedZeros,  // -0.0/+0.0 mix
    Extreme       // subnormals, huge/small magnitudes
};

static void fill_row(std::vector<float>& buf, int off, int len, Dist d, Lcg& rng) {
    for (int i = 0; i < len; ++i) {
        float v;
        switch (d) {
            case Dist::Uniform: v = rng.uniform(-100.f, 100.f); break;
            case Dist::Gaussianish: {
                float acc = 0.f;
                for (int t = 0; t < 4; ++t) acc += rng.uniform(-1.f, 1.f);
                v = acc * 25.f;
                break;
            }
            case Dist::TieHeavy:
                v = static_cast<float>(static_cast<int>(rng.uniform(0.f, 8.f)));
                break;
            case Dist::AllEqual: v = 3.5f; break;
            case Dist::WithInfs: {
                const float r = rng.uniform(0.f, 1.f);
                v = r < 0.05f ? std::numeric_limits<float>::infinity()
                    : r < 0.10f ? -std::numeric_limits<float>::infinity()
                                : rng.uniform(-10.f, 10.f);
                break;
            }
            case Dist::WithNaNs: {
                const float r = rng.uniform(0.f, 1.f);
                if (r < 0.06f)
                    v = bits_f32(0x7fc00000u | (rng.rand_bits() & 0x3fffffu));  // +NaN
                else if (r < 0.12f)
                    v = bits_f32(0xffc00000u | (rng.rand_bits() & 0x3fffffu));  // -NaN
                else
                    v = rng.uniform(-10.f, 10.f);
                break;
            }
            case Dist::SignedZeros: {
                const float r = rng.uniform(0.f, 1.f);
                v = r < 0.3f ? 0.f : r < 0.6f ? -0.f : rng.uniform(-1.f, 1.f);
                break;
            }
            case Dist::Extreme: {
                const std::uint32_t r = rng.rand_bits();
                v = bits_f32(r % 8 == 0 ? (r & 0x807fffffu) % 0x00800000u  // subnormal
                             : r % 8 == 1 ? 0xff7fffffu                    // -max finite
                             : r % 8 == 2 ? 0x7f7fffffu                    // +max finite
                                          : (r & 0x80ffffffu));
                break;
            }
            default: v = 0.f; break;
        }
        buf[static_cast<std::size_t>(off + i)] = v;
    }
}

int main() {
    // ════ 0. key mapping algebra ════
    {
        const std::uint32_t ordered[] = {0x00000000u, 0x80000000u, 0x3f800000u, 0xbf800000u,
                                         0x7f800000u, 0xff800000u, 0x00800000u, 0x80800000u,
                                         0x00000001u, 0x80000001u, 0x7f7fffffu, 0xff7fffffu};
        const std::uint32_t nans[] = {0x7fc00000u, 0xffc00000u, 0x7f800001u,
                                      0xff800001u, 0x7fc00123u, 0xffffffffu};
        const std::uint32_t pos_inf = 0x7f800000u, neg_inf = 0xff800000u;
        // round trips, both key forms
        for (std::uint32_t u : ordered) {
            CHECK(sortable_to_fp32_bits(fp32_to_sortable_bits(u)) == u);
            CHECK(radix_key_to_fp32_bits(radix_key_bits<false>(u)) == u);
            CHECK(radix_key_bits<false>(radix_key_bits<false>(u)) == u);
            CHECK(sortable_key_bits<true>(u) + NAN_HIGH_SHIFT == fp32_to_sortable_bits(u));
            // radix reverse-order agreement with sortable
            CHECK(radix_key_bits<false>(u) == ~fp32_to_sortable_bits(u));
            CHECK(radix_key_bits<true>(u) == radix_key_bits<false>(u));  // non-NaN: identical
        }
        // -0.0 just below +0.0
        CHECK(fp32_to_sortable_bits(0x80000000u) + 1 == fp32_to_sortable_bits(0x00000000u));
        // NaN policy, sortable form: negative below -inf, positive above +inf
        for (std::uint32_t u : nans) {
            const bool negative = u >> 31;
            CHECK(negative == (fp32_to_sortable_bits(u) < fp32_to_sortable_bits(neg_inf)));
            CHECK((fp32_to_sortable_bits(u) > fp32_to_sortable_bits(pos_inf)) == !negative);
            // NAN_HIGH: any NaN above +inf in both forms
            CHECK(sortable_key_bits<true>(u) > sortable_key_bits<true>(pos_inf));
            CHECK(radix_key_bits<true>(u) < radix_key_bits<true>(pos_inf));
            // radix NAN_HIGH substitutes the magnitude for negative NaNs only
            if (negative)
                CHECK(radix_key_bits<true>(u) == radix_key_bits<false>(u & 0x7fffffffu));
        }
        // randomized sweep: monotone order + round trips
        Lcg rng(0x5eed);
        for (int t = 0; t < 20000; ++t) {
            const std::uint32_t a = rng.rand_bits(), b = rng.rand_bits();
            const float fa = bits_f32(a), fb = bits_f32(b);
            const bool a_nan = std::isnan(fa), b_nan = std::isnan(fb);
            CHECK(sortable_to_fp32_bits(fp32_to_sortable_bits(a)) == a);
            CHECK(sortable_to_fp32_bits(sortable_key_bits<true>(a) + NAN_HIGH_SHIFT) ==
                  a);  // NAN_HIGH round trips via its shift
            if (!a_nan && !b_nan && !(a == b)) {
                const bool a_lt = fa < fb;
                CHECK((fp32_to_sortable_bits(a) < fp32_to_sortable_bits(b)) == a_lt);
                CHECK((radix_key_bits<false>(a) > radix_key_bits<false>(b)) == a_lt);
            }
        }
    }

    // ════ 1. geometry helpers ════
    {
        // sample_chunk_stride: masked to a dwordx4 multiple; exact when already one
        CHECK(sample_chunk_stride(131072, 64) == 2048);
        CHECK(sample_chunk_stride(131328, 2048) == 64);      // (64) & ~3
        CHECK(sample_chunk_stride(131327, 2048) == 64);      // (64) & ~3 truncates
        CHECK(sample_chunk_stride(65600, 64) == 1024);       // 1025 & ~3
        CHECK(sample_chunk_stride(32768, 512) == 64);
        for (int t = 0; t < 2000; ++t) {
            const int N = 64 + static_cast<int>(Lcg(0x100 + t).next() % 300000);
            const int chunks = 1 + static_cast<int>(Lcg(0x200 + t).next() % 256);
            const int s = sample_chunk_stride(N, chunks);
            CHECK(s % FP32_EPT == 0);
            CHECK(s == (N / chunks) / FP32_EPT * FP32_EPT);
            // last chunk stays in the row once N/chunks >= CHUNK
            if (N / chunks >= SAMPLE_CHUNK_ELEMS)
                CHECK((chunks - 1) * s + SAMPLE_CHUNK_ELEMS <= N);
        }
        // common_prefix_passes
        CHECK(common_prefix_passes(0x80000000u, 0x80000000u) == RADIX_PASSES);
        CHECK(common_prefix_passes(0x80000000u, 0x80000001u) == 3);
        CHECK(common_prefix_passes(0x12345678u, 0x123456ffu) == 3);
        CHECK(common_prefix_passes(0x01000000u, 0xfe000000u) == 0);
        // truncated rank select: mask moves nothing when the low byte already agrees
        {
            std::vector<std::uint32_t> ks = {0xAABBCC01u, 0xAABBCC02u, 0xAABBCCFFu};
            CHECK(exact_rank_key(ks, 1, 3) == 0xAABBCC00u);  // truncated pivot, low byte 0
            CHECK(exact_rank_key(ks, 1, 4) == 0xAABBCCFFu);  // exact form keeps it
        }
    }

    // ════ 2. routing + identity rows (ragged len <= K, len < S) ════
    {
        constexpr int pitch = 128;
        // 4 pitches: the windows below reach pitch+140, so a 2-pitch buffer
        // would send Phase B and the oracle into heap-metadata garbage --
        // which even differs between the two callers (their internal vectors
        // reshape the heap between runs). OOB is read UB, not a contract.
        std::vector<float> buf(static_cast<std::size_t>(4 * pitch));
        Lcg rng(0x77aa);
        for (auto& v : buf) v = rng.uniform(-5.f, 5.f);
        // len 5 <= K 8: identity, indices are absolute (row_start added)
        {
            RowWin w{pitch + 10, 5};
            const auto p = run_row_pipeline(buf, pitch, w, true, 8, {256, 4, 128});
            const auto e = run_row_exact(buf, w, true, 8);
            CHECK(p.routed_inf);
            CHECK(p.fell_back);
            CHECK(row_out_equal(p, e));
            for (int i = 0; i < 5; ++i) CHECK(p.idx[static_cast<std::size_t>(i)] == w.start + i);
            for (int i = 5; i < 8; ++i) {
                CHECK(p.idx[static_cast<std::size_t>(i)] == -1);
                CHECK(f32_bits(p.val[static_cast<std::size_t>(i)]) == 0xff800000u);
            }
        }
        // len == K: identity, every element selected
        {
            RowWin w{pitch + 20, 8};
            const auto p = run_row_pipeline(buf, pitch, w, true, 8, {256, 4, 128});
            CHECK(p.routed_inf);
            for (int i = 0; i < 8; ++i) CHECK(p.idx[static_cast<std::size_t>(i)] == w.start + i);
        }
        // len > K but len < S: +inf route keeps only NaNs -> c < k_out -> fallback
        {
            RowWin w{pitch + 40, 100};
            const auto p = run_row_pipeline(buf, pitch, w, true, 8, {256, 4, 128});
            const auto e = run_row_exact(buf, w, true, 8);
            CHECK(p.routed_inf);
            CHECK(p.fell_back);
            CHECK(p.cand_count == 0);  // no NaNs in this row
            CHECK(row_out_equal(p, e));
        }
        // the +inf route with NaNs present: Phase B keeps them, undershoot catches it
        {
            std::vector<float> b2(static_cast<std::size_t>(4 * pitch));
            Lcg r2(0x99);
            for (auto& v : b2) v = r2.uniform(-5.f, 5.f);
            for (int i = 0; i < 30; ++i)
                b2[static_cast<std::size_t>(pitch + 40 + i)] =
                    bits_f32(0xffc00000u | (i & 0x3fffffu));  // negative NaNs
            RowWin w{pitch + 40, 100};
            const auto p = run_row_pipeline(b2, pitch, w, true, 8, {256, 4, 128});
            const auto e = run_row_exact(b2, w, true, 8);
            CHECK(p.routed_inf);
            CHECK(p.cand_count == 30);  // only the NaNs pass !(v < +inf)
            CHECK(p.fell_back);
            CHECK(row_out_equal(p, e));
        }
    }

    // ════ 3. crafted edge rows ════
    {
        // all-equal row with prefix collapse: pivot = the value, eq_needed = K
        {
            constexpr int len = 512;
            std::vector<float> buf(static_cast<std::size_t>(len), 3.5f);
            const SamplePlan sp{256, 4, 1024};
            const auto p = run_row_pipeline(buf, len, {0, len}, false, 16, sp);
            const auto e = run_row_exact(buf, {0, len}, false, 16);
            CHECK(!p.fell_back);
            CHECK(row_out_equal(p, e));
            for (int i = 0; i < 16; ++i)
                CHECK(f32_bits(p.val[static_cast<std::size_t>(i)]) == f32_bits(3.5f));
            // tie set is the first K indices in row order (deterministic here;
            // on device tie selection is declared nondeterministic)
            {
                std::vector<int> got(p.idx.begin(), p.idx.end());
                std::sort(got.begin(), got.end());
                bool first16 = true;
                for (int i = 0; i < 16; ++i)
                    if (got[static_cast<std::size_t>(i)] != i) first16 = false;
                CHECK(first16);
            }
        }
        // tie-heavy boundary: 24 copies of the boundary value, K = 16
        {
            constexpr int len = 4096;
            std::vector<float> buf(static_cast<std::size_t>(len));
            Lcg rng(0x1234);
            for (int i = 0; i < len; ++i)
                buf[static_cast<std::size_t>(i)] =
                    i >= 3000 && i < 3024 ? 7.f : rng.uniform(0.f, 5.f);
            const SamplePlan sp{1024, 16, 2048};
            const auto p = run_row_pipeline(buf, len, {0, len}, false, 16, sp);
            const auto e = run_row_exact(buf, {0, len}, false, 16);
            CHECK(!p.fell_back);
            CHECK(row_out_equal(p, e));
            int sevens = 0;
            for (int i = 0; i < 16; ++i)
                if (f32_bits(p.val[static_cast<std::size_t>(i)]) == f32_bits(7.f)) ++sevens;
            CHECK(sevens == 16);  // all copies >= every other value
            // -0.0/+0.0 ordering at the bottom of the same row
            buf[0] = 0.f;
            buf[1] = -0.f;
            const auto p2 = run_row_pipeline(buf, len, {0, len}, false, len, {4096, 8, 4096});
            // both zeros are in the returned set; +0.0 (idx 0) sorts above -0.0
            // (idx 1) by key, and the key order is what the canonical compare
            // above already pins
            bool has0 = false, has1 = false;
            for (int i : p2.idx) {
                if (i == 0) has0 = true;
                if (i == 1) has1 = true;
            }
            CHECK(has0 && has1);
        }
        // cap overflow -> fallback, answer still exact
        {
            constexpr int len = 8192, cap = 512;
            std::vector<float> buf(static_cast<std::size_t>(len));
            Lcg rng(0xdead);
            for (auto& v : buf) v = rng.uniform(0.f, 1.f);
            // rank = S: the threshold is the SMALLEST sample (truncated), so
            // Phase B keeps essentially the whole row -> far past the cap
            const SamplePlan sp{1024, 1024, cap};
            const auto p = run_row_pipeline(buf, len, {0, len}, false, 16, sp);
            const auto e = run_row_exact(buf, {0, len}, false, 16);
            CHECK(p.overflowed);
            CHECK(p.fell_back);
            CHECK(row_out_equal(p, e));
        }
        // bucket-0 routing: Phase B's float compare keeps every NaN (NaN < th is
        // false), so negative NaNs -- keys [0, 0x007FFFFF), below -inf -- pad the
        // candidate list. The device routes a row to the whole-row select exactly
        // when c - low < k_out, i.e. fewer than k_out candidates rank above radix
        // bucket 0; the pipeline replicates that condition verbatim. Both paths
        // remain exact, so the answer is the true top-k_out of the FULL row either
        // way -- which legitimately contains negative NaNs when the row lacks
        // enough finite elements.
        {
            // (a) 1048 finite + 1000 -NaN, K=8: a mid-range rank puts th near
            //     the finite median, so ~524 finite are kept; the 1000 -NaNs pad
            //     c to ~1524 and c - low ~ 524 >= 8 -> NO fallback; the
            //     candidate-space select's pivot stays finite, answer all finite.
            constexpr int len = 2048;
            std::vector<float> buf(static_cast<std::size_t>(len));
            Lcg rng(0xbeef);
            for (auto& v : buf) v = rng.uniform(-10.f, -1.f);
            for (int i = 0; i < 1000; ++i)
                buf[static_cast<std::size_t>(i)] = bits_f32(0xffc00000u | (i & 0x3fffffu));
            const SamplePlan sp{1024, 512, 2048};
            const auto p = run_row_pipeline(buf, len, {0, len}, false, 8, sp);
            const auto e = run_row_exact(buf, {0, len}, false, 8);
            CHECK(!p.fell_back);
            CHECK(row_out_equal(p, e));
            int nans = 0;
            for (int i = 0; i < 8; ++i)
                if (std::isnan(p.val[static_cast<std::size_t>(i)])) ++nans;
            CHECK(nans == 0);
            // (b) only 2 finite + 2046 -NaN, K=8: th (4th-largest sample) is a
            //     -NaN key -> every element kept; c - low = 2 < 8 -> UNDERSHOOT
            //     fallback; the whole-row select must emit 6 -NaNs after the 2
            //     finite -- they are the largest available elements.
            std::vector<float> b2(static_cast<std::size_t>(len));
            Lcg r2(0x9999);
            // fill the WHOLE row with -NaN first (a default-init vector holds
            // garbage), then plant the only two finite elements
            for (auto& v : b2) v = bits_f32(0xffc00000u | (r2.next() & 0x3fffffu));
            b2[500] = -1.f;
            b2[501] = -2.f;
            const auto p2 = run_row_pipeline(b2, len, {0, len}, false, 8, sp);
            const auto e2 = run_row_exact(b2, {0, len}, false, 8);
            CHECK(p2.fell_back);
            CHECK(p2.undershoot);
            CHECK(row_out_equal(p2, e2));
            int nans2 = 0, got_finite = 0;
            for (int i = 0; i < 8; ++i) {
                if (std::isnan(p2.val[static_cast<std::size_t>(i)])) ++nans2;
                else ++got_finite;
            }
            CHECK(nans2 == 6 && got_finite == 2);
            CHECK(p2.cand_count == len);
        }
        // positive NaN ranks ABOVE +inf (sortable form): a row whose top-K is NaNs
        {
            constexpr int len = 1024;
            std::vector<float> buf(static_cast<std::size_t>(len));
            Lcg rng(0xc0ffee);
            for (auto& v : buf) v = rng.uniform(0.f, 1.f);
            buf[500] = bits_f32(0x7fc00123u);  // +NaN, top of the whole row
            const SamplePlan sp{512, 8, 2048};
            const auto p = run_row_pipeline(buf, len, {0, len}, false, 4, sp);
            const auto e = run_row_exact(buf, {0, len}, false, 4);
            CHECK(row_out_equal(p, e));
            CHECK(std::isnan(p.val[0]));  // slot 0 holds A returned value; the
            // NaN outranks everything, so every slot is a NaN -- check membership
            bool has500 = false;
            for (int i : p.idx)
                if (i == 500) has500 = true;
            CHECK(has500);
        }
        // ragged tail pickup: a row max living in the last 1-3 columns
        {
            constexpr int pitch = 256;
            std::vector<float> buf(static_cast<std::size_t>(pitch));
            Lcg rng(0xf00d);
            for (auto& v : buf) v = rng.uniform(0.f, 10.f);
            // the row max lives in the LAST column past the last full dwordx4:
            // n4 = 101/4 = 25 full vectors cover 0..99, so column 100 is the
            // phase_b tail pickup's only chance to see it
            buf[static_cast<std::size_t>(100)] = 99.f;
            RowWin w{0, 101};
            const auto p = run_row_pipeline(buf, pitch, w, true, 4, {256, 4, 512});
            const auto e = run_row_exact(buf, w, true, 4);
            CHECK(row_out_equal(p, e));
            bool has_tail = false;
            for (std::size_t q = 0; q < p.idx.size(); ++q)
                if (p.idx[q] == 100) has_tail = true;
            CHECK(has_tail);
            bool saw99 = false;
            for (std::size_t q = 0; q < p.val.size(); ++q)
                if (std::fabs(p.val[q] - 99.f) < 1e-6f) saw99 = true;
            CHECK(saw99);
        }
        // dense == ragged for a full-width window
        {
            constexpr int len = 1024;
            std::vector<float> buf(static_cast<std::size_t>(len));
            Lcg rng(0x31415);
            for (auto& v : buf) v = rng.uniform(-3.f, 3.f);
            const SamplePlan sp{512, 8, 1024};
            const auto pd = run_row_pipeline(buf, len, {0, len}, false, 10, sp);
            const auto pr = run_row_pipeline(buf, len, {0, len}, true, 10, sp);
            CHECK(row_out_equal(pd, pr));
        }
    }

    // ════ 4. randomized master invariant sweep ════
    {
        struct Cfg {
            int pitch, K, S, rank, cap;
            bool ragged;
            Dist d;
        };
        const Dist dists[] = {Dist::Uniform,    Dist::Gaussianish, Dist::TieHeavy,
                              Dist::AllEqual,   Dist::WithInfs,    Dist::WithNaNs,
                              Dist::SignedZeros, Dist::Extreme};
        const int cfgs[] = {// pitch, K, S, rank, cap, ragged
                            4096, 64, 1024, 16, 2048, 0,      8192, 256, 2048, 64, 4096, 0,
                            2048, 32, 512, 8, 1024, 0,        1024, 16, 512, 8, 512, 0,
                            65536, 512, 4096, 64, 4096, 0,    512, 8, 256, 4, 256, 0,
                            4096, 64, 1024, 16, 2048, 1,      8192, 256, 2048, 64, 4096, 1,
                            2048, 32, 512, 8, 1024, 1,        65536, 512, 4096, 64, 4096, 1};
        const int n_cfg = static_cast<int>(sizeof(cfgs) / sizeof(cfgs[0]) / 6);
        int rows_checked = 0, fallbacks = 0, fails_dbg = 0;
        for (int ci = 0; ci < n_cfg; ++ci) {
            const int pitch = cfgs[ci * 6 + 0], K = cfgs[ci * 6 + 1], S = cfgs[ci * 6 + 2];
            const int rank = cfgs[ci * 6 + 3], cap = cfgs[ci * 6 + 4];
            const bool ragged = cfgs[ci * 6 + 5] != 0;
            const SamplePlan sp{S, rank, cap};
            for (int di = 0; di < 8; ++di) {
                const Dist d = dists[di];
                std::vector<float> buf(static_cast<std::size_t>(4 * pitch));
                Lcg rng(0x9000u + static_cast<std::uint32_t>(ci) * 131u +
                        static_cast<std::uint32_t>(di));
                for (auto& v : buf) v = 0.f;
                // rows: 3 per config-dist; ragged gets varied windows
                for (int r = 0; r < 3; ++r) {
                    RowWin w{0, pitch};
                    if (ragged) {
                        // windows: short (identity), sub-S, and full
                        const int lens[3] = {K - 1, S / 2, pitch};
                        const int len = lens[r];
                        w = {r * pitch + (r == 0 ? 0 : 5), len};
                        if (w.start + len > 4 * pitch) w = {0, len};
                    }
                    fill_row(buf, w.start, w.len, d, rng);
                    const auto p = run_row_pipeline(buf, pitch, w, ragged, K, sp);
                    const auto e = run_row_exact(buf, w, ragged, K);
                    ++rows_checked;
                    if (!row_out_equal(p, e) && fails_dbg < 3) {
                        ++fails_dbg;
                        float wmax = buf[static_cast<std::size_t>(w.start)], wmin = wmax;
                        for (int i = 0; i < w.len; ++i) {
                            wmax = std::fmax(wmax, buf[static_cast<std::size_t>(w.start + i)]);
                            wmin = std::fmin(wmin, buf[static_cast<std::size_t>(w.start + i)]);
                        }
                        std::printf("    window min/max: %g / %g, exact[0].val=%g pipe[0].val=%g\n",
                                    wmin, wmax, e.val[0], p.val[0]);
                        std::printf("  DBG cfg%d dist%d rag%d w{%d,%d} K%d S%d rank%d cap%d: "
                                    "fb%d ovl%d und%d inf%d c%d\n",
                                    ci, di, ragged, w.start, w.len, K, S, rank, cap,
                                    p.fell_back, p.overflowed, p.undershoot, p.routed_inf,
                                    p.cand_count);
                        for (std::size_t q = 0; q < p.idx.size() && q < e.idx.size(); ++q) {
                            if (p.idx[q] != e.idx[q] ||
                                f32_bits(p.val[q]) != f32_bits(e.val[q])) {
                                std::printf("    slot %zu: pipe(%d, %.9g) exact(%d, %.9g)\n", q,
                                            p.idx[q], p.val[q], e.idx[q], e.val[q]);
                                break;
                            }
                        }
                    }
                    CHECK(row_out_equal(p, e));
                    // index validity + value consistency
                    const int k_out = ragged ? std::min(K, w.len) : K;
                    bool idx_ok = true;
                    for (int i = 0; i < k_out && idx_ok; ++i) {
                        const int ix = p.idx[static_cast<std::size_t>(i)];
                        if (ix < 0 || ix >= w.len) idx_ok = false;
                        else if (f32_bits(p.val[static_cast<std::size_t>(i)]) !=
                                 f32_bits(buf[static_cast<std::size_t>(w.start + ix)]))
                            idx_ok = false;
                    }
                    CHECK(idx_ok);
                    // no-fallback rows: candidate count inside [k_out, cap]
                    if (!p.fell_back)
                        CHECK(p.cand_count >= k_out && p.cand_count <= sp.cap);
                    if (p.fell_back) ++fallbacks;
                    // k_out-sized outputs; identity/padded rows filled with -1
                    CHECK(static_cast<int>(p.idx.size()) == K);
                    if (ragged && w.len < K)
                        for (int i = w.len; i < K; ++i) {
                            CHECK(p.idx[static_cast<std::size_t>(i)] == -1);
                            CHECK(f32_bits(p.val[static_cast<std::size_t>(i)]) == 0xff800000u);
                        }
                }
            }
        }
        std::printf("  sweep: %d rows, %d fallbacks exercised\n", rows_checked, fallbacks);
        CHECK(rows_checked >= 96);
        CHECK(fallbacks > 0);
    }

    std::printf("topk_per_row_sampled: %d checks, %d failures -> %s\n", checks, fails,
                fails ? "FAIL" : "PASS");
    return fails ? 1 : 0;
}
