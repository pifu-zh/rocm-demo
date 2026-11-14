// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2026, Advanced Micro Devices, Inc. All rights reserved.
//
// Host reference for aiter's MXFP4 MoE aux scheduling pipeline
// (csrc/kernels/mxfp4_moe/moe_aux/*.cuh @ 1eab5ae12, MIT), covering three
// independently-extractable designs plus the epilogue:
//
// [1] 3-stage multi-CTA sort (moe_3stage_sort.cuh): N_CTAS count CTAs write
//     a partial-histogram matrix block_offsets[e][cta]; a single-CTA cumsum
//     kernel folds it into per-(expert,cta) start offsets and MB-padded
//     expert segments; place+pad CTAs fill slots via atomicAdd cursors and
//     pad tails with the M sentinel.
// [2] single-CTA sort (moe_sort_quant.cuh sort_subkernel): int4-vectorized
//     counting, a two-level DPP inclusive scan (emulated semantically — the
//     dpp instructions themselves are warp_sync's domain), atomicAdd cursor
//     placement, EP support via num_local_tokens (pairs past valid_pairs get
//     reverse_sorted = -1).
// [3] fused quant (quant_impl): bf16 amax via bit-pattern max (abs = mask
//     0x7FFF, monotonic bf16 ordering), a 4-lane DPP max reduce (emulated),
//     and the BRANCHLESS ceil scale: byte = ((bits(amax*(1/6)) + 0x7FFFFF)
//     >> 23) & 0xFF, clamped [0, 254] — the float-bit-rounding trick computes
//     ceil(log2) in one integer add. NOTE: for f32-subnormal amax the trick
//     over-estimates (loose but never clipping). The E2M1 nibble encode uses
//     the lab RNE encoder as the documented substitute for the gfx950
//     hardware cvt (aiter emits __builtin_trap() on non-gfx950 targets).
//
// Shared conventions pinned by the tests:
// - sorted_token_ids packs (token & 0xFFFFFF) | (topk & 0xFF) << 24.
// - m_indices = token for real slots, = M (the sentinel) for PAD slots; the
//   sentinel makes the downstream GEMM's buffer_load voff exceed the operand
//   extent so the hardware drops the load (documented at moe_3stage_sort.cuh
//   :150-152 and moe_sort_quant.cuh fill_padding_gaps).
// - reverse_sorted is the inverse permutation; -1 for un-routed pairs.
// - Expert segments are padded to MB multiples; per-expert slot order comes
//   from atomicAdd cursors on the device (nondeterministic) — host reference
//   is ascending-deterministic; on-card comparison must be per-segment
//   multiset, never element-wise (same discipline as moe_align).
// - scatter_reduce (moe_scatter_reduce.cuh): output[t] = sum over the
//   token's TOPK routes of sorted_weights[reverse[t,i]] * flat_out[...],
//   skipping reverse < 0; bf16 via (bits & 0xFFFF) << 16 decode + FMA;
//   mxfp4 via e8m0 scales packed 4-per-u32 (byte = (blk & 3) of the u32 at
//   blk & ~3) and 8-nibble u32 decode. IMPLICIT UPSTREAM CONSTRAINT (found
//   by violation, not documented upstream): the scale u32 read spans 4
//   consecutive 32-col blocks (blk & ~3), so d_hidden/32 must be a multiple
//   of 4 (d_hidden % 128 == 0); aiter only static-asserts D % 8 == 0 —
//   D_HIDDEN = 32 would read the next row's scales / OOB.
//
// Both sort variants produce IDENTICAL outputs on this deterministic host
// (two independent implementations of one contract — stronger than one
// implementation vs a reference).
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <cstdlib>
#include <vector>

#define MAIN_RETURN_BAD 1

// ── bit helpers ──
static inline float bits_to_f32(std::uint32_t u) {
    float f;
    std::memcpy(&f, &u, 4);
    return f;
}
static inline float bf16_to_f32(std::uint16_t bits) {
    return bits_to_f32(static_cast<std::uint32_t>(bits) << 16);
}
static inline std::uint16_t bf16_round(float f) {
    std::uint32_t x;
    std::memcpy(&x, &f, 4);
    const std::uint32_t lsb = (x >> 16) & 1;
    return static_cast<std::uint16_t>((x + 0x7FFFu + lsb) >> 16);
}
static inline std::uint32_t bit_cast_u32(float f) {
    std::uint32_t u;
    std::memcpy(&u, &f, 4);
    return u;
}
static inline std::uint32_t load_u32_le(const std::vector<std::uint8_t>& v, long byte_off) {
    std::uint32_t u;
    std::memcpy(&u, v.data() + byte_off, 4);
    return u;
}
static float e2m1_decode(std::uint8_t code) {
    static const double vals[8] = {0.0, 0.5, 1.0, 1.5, 2.0, 3.0, 4.0, 6.0};
    const double v = vals[code & 0x7];
    return static_cast<float>((code & 0x8) ? -v : v);
}

// E2M1 RNE encoder (lab-shared semantics; substitute for the gfx950 cvt)
static std::uint8_t e2m1_encode_rne(float x) {
    if (std::isnan(x)) return 0x7;
    if (std::fabs(x) >= 6.0f) return std::signbit(x) ? 0xF : 0x7;
    const int neg = std::signbit(x);
    const double mag = std::fabs(static_cast<double>(x));
    std::uint8_t best = 0;
    double best_d = 1e300;
    static const double vals[8] = {0.0, 0.5, 1.0, 1.5, 2.0, 3.0, 4.0, 6.0};
    for (int c = 0; c < 8; ++c) {
        // NEAREST code: minimum ABSOLUTE distance. (Comparing the signed
        // distance walks to the FARTHEST code — the bug this line once was.)
        const double d = std::fabs(mag - vals[c]);
        // RNE tie: midpoint between two codes -> the even code (LSB 0).
        if (d < best_d || (d == best_d && ((best & 1) != 0))) {
            best_d = d;
            best = static_cast<std::uint8_t>(c);
        }
    }
    return neg ? static_cast<std::uint8_t>(best | 0x8) : best;
}

static constexpr std::int32_t MASK_TOKEN = 0x00FFFFFF;
static std::int32_t pack_token_topk(int token, int topk) {
    return (token & MASK_TOKEN) | ((topk & 0xFF) << 24);
}

// ── shared inputs/outputs ──
struct SortInputs {
    int M = 0, TOPK = 0, NE = 0, MB = 0;
    std::vector<std::int32_t> topk_ids;      // [M*TOPK]; out-of-range/-1 = no route
    std::vector<float> topk_weight;          // [M*TOPK]
    std::vector<std::int32_t> num_local_tokens;  // optional [1]; EP (variant B)
};

struct SortOutputs {
    long long total_padded = 0;
    std::vector<std::int32_t> sorted_token_ids;
    std::vector<std::int32_t> sorted_expert_ids;
    std::vector<std::int32_t> cumsum_tensor;   // [2] = {total_padded, valid_tokens}
    std::vector<std::int32_t> reverse_sorted;
    std::vector<float> sorted_weights;
    std::vector<std::int32_t> m_indices;
};

// ── [1] 3-stage multi-CTA sort (deterministic host emulation) ──
static SortOutputs sort_3stage(const SortInputs& in, int n_ctas) {
    const int NE = in.NE, TOPK = in.TOPK, M = in.M, MB = in.MB;
    const int total_pairs = M * TOPK;
    SortOutputs out;

    // stage 1: per-CTA partial histograms → block_offsets[e][cta]
    std::vector<std::int32_t> block_offsets(static_cast<long>(NE) * n_ctas, 0);
    {
        const int per_cta = (total_pairs + n_ctas - 1) / n_ctas;
        for (int cta = 0; cta < n_ctas; ++cta) {
            const int start = cta * per_cta;
            const int end = std::min(start + per_cta, total_pairs);
            std::vector<std::int32_t> local(NE, 0);
            for (int i = start; i < end; ++i) {
                const int eid = in.topk_ids[i];
                if (static_cast<unsigned>(eid) < static_cast<unsigned>(NE)) ++local[eid];
            }
            for (int e = 0; e < NE; ++e)
                block_offsets[static_cast<long>(e) * n_ctas + cta] = local[e];
        }
    }

    // stage 2 (single CTA): fold, pad to MB, expert_starts, sorted_expert_ids,
    // in-place rewrite of block_offsets into per-(e,cta) start offsets
    std::vector<std::int32_t> real_counts(NE), expert_starts(NE + 1);
    {
        std::int32_t acc = 0;
        for (int e = 0; e < NE; ++e) {
            std::int32_t sum = 0;
            for (int c = 0; c < n_ctas; ++c)
                sum += block_offsets[static_cast<long>(e) * n_ctas + c];
            real_counts[e] = sum;
            expert_starts[e] = acc;
            acc += (sum + MB - 1) / MB * MB;
            std::int32_t a = expert_starts[e];
            for (int c = 0; c < n_ctas; ++c) {
                const std::int32_t cnt = block_offsets[static_cast<long>(e) * n_ctas + c];
                block_offsets[static_cast<long>(e) * n_ctas + c] = a;
                a += cnt;
            }
        }
        expert_starts[NE] = acc;
        for (int e = 0; e < NE; ++e) {
            const int b0 = expert_starts[e] / MB, b1 = expert_starts[e + 1] / MB;
            for (int b = b0; b < b1; ++b) out.sorted_expert_ids.push_back(e);
        }
    }
    out.total_padded = expert_starts[NE];
    out.cumsum_tensor = {expert_starts[NE], M};
    out.sorted_token_ids.assign(expert_starts[NE], 0);
    out.sorted_weights.assign(expert_starts[NE], 0.0f);
    out.m_indices.assign(expert_starts[NE], 0);
    out.reverse_sorted.assign(total_pairs, -1);

    // stage 3: place via per-CTA cursors, then pad tails (M sentinel)
    {
        const int per_cta = (total_pairs + n_ctas - 1) / n_ctas;
        std::vector<std::int32_t> local_offsets(block_offsets);
        std::vector<std::int32_t> row_starts(expert_starts.begin(), expert_starts.end() - 1);
        for (int cta = 0; cta < n_ctas; ++cta) {
            const int start = cta * per_cta;
            const int end = std::min(start + per_cta, total_pairs);
            for (int i = start; i < end; ++i) {
                const int eid = in.topk_ids[i];
                if (static_cast<unsigned>(eid) >= static_cast<unsigned>(NE)) {
                    out.reverse_sorted[i] = -1;
                    continue;
                }
                const int sp = local_offsets[static_cast<long>(eid) * n_ctas + cta]++;
                const int token_id = i / TOPK, topk_id = i % TOPK;
                out.sorted_token_ids[sp] = pack_token_topk(token_id, topk_id);
                out.m_indices[sp] = token_id & MASK_TOKEN;
                out.sorted_weights[sp] = in.topk_weight[i];
                out.reverse_sorted[i] = sp;
            }
        }
        const std::int32_t pad_val = M & MASK_TOKEN;
        for (int e = 0; e < NE; ++e) {
            const int real_end = row_starts[e] + real_counts[e];
            const int padded_end = row_starts[e + 1];
            for (int j = real_end; j < padded_end; ++j) {
                out.sorted_token_ids[j] = pad_val;
                out.m_indices[j] = pad_val;
                out.sorted_weights[j] = 0.0f;
            }
        }
    }
    return out;
}

// ── [2] single-CTA sort (DPP-scan design; EP via num_local_tokens) ──
static SortOutputs sort_single_cta(const SortInputs& in) {
    const int NE = in.NE, TOPK = in.TOPK, M = in.M, MB = in.MB;
    const int total_pairs = M * TOPK;
    const int valid_tokens = in.num_local_tokens.empty()
                                 ? M
                                 : std::max(0, std::min(M, in.num_local_tokens[0]));
    const int valid_pairs = valid_tokens * TOPK;
    SortOutputs out;

    // count_tokens_per_expert (int4-vectorized on device; same semantics)
    std::vector<std::int32_t> count(NE, 0);
    for (int i = 0; i < valid_pairs; ++i) {
        const int eid = in.topk_ids[i];
        if (static_cast<unsigned>(eid) < static_cast<unsigned>(NE)) ++count[eid];
    }

    // parallel_cumsum: round_up(count, MB) per expert; the two-level DPP scan
    // computes the same prefix sums (emulated semantically)
    std::vector<std::int32_t> cumsum(NE + 1, 0), counter(NE, 0);
    {
        std::int32_t acc = 0;
        for (int e = 0; e < NE; ++e) {
            cumsum[e] = acc;
            acc += (count[e] + MB - 1) / MB * MB;
        }
        cumsum[NE] = acc;
    }

    out.total_padded = cumsum[NE];
    out.cumsum_tensor = {cumsum[NE], valid_tokens};
    out.sorted_token_ids.assign(cumsum[NE], 0);
    out.sorted_expert_ids.assign(cumsum[NE] / MB, 0);
    out.sorted_weights.assign(cumsum[NE], 0.0f);
    out.m_indices.assign(cumsum[NE], 0);
    out.reverse_sorted.assign(total_pairs, -1);

    // place_tokens: atomicAdd cursors (host: ascending deterministic)
    for (int i = 0; i < total_pairs; ++i) {
        const int eid = i < valid_pairs ? in.topk_ids[i] : -1;
        int sp = -1;
        if (static_cast<unsigned>(eid) < static_cast<unsigned>(NE)) {
            sp = cumsum[eid] + counter[eid]++;
            const int token_id = i / TOPK, topk_id = i % TOPK;
            out.sorted_token_ids[sp] = pack_token_topk(token_id, topk_id);
            out.m_indices[sp] = token_id & MASK_TOKEN;
            out.sorted_weights[sp] = in.topk_weight[i];
        }
        out.reverse_sorted[i] = sp;
    }

    // fill_padding_gaps
    for (int e = 0; e < NE; ++e) {
        const int start = cumsum[e], end = cumsum[e + 1];
        const std::int32_t pad_val = M & MASK_TOKEN;
        for (int j = start + count[e]; j < end; ++j) {
            out.sorted_token_ids[j] = pad_val;
            out.m_indices[j] = pad_val;
            out.sorted_weights[j] = 0.0f;
        }
        for (int b = start / MB; b < end / MB; ++b)
            out.sorted_expert_ids[b] = e;
    }
    return out;
}

// ── [3] fused quant ──
struct QuantOutputs {
    std::vector<std::uint8_t> a_quant;  // [M * K/2] packed nibbles
    std::vector<std::uint8_t> a_scale;  // [M * K/32] e8m0 bytes
};

static QuantOutputs mxfp4_quant(const std::vector<std::uint16_t>& hidden_bf16, int m, int k) {
    QuantOutputs out;
    out.a_quant.assign(static_cast<long>(m) * k / 2, 0);
    out.a_scale.assign(static_cast<long>(m) * (k / 32), 0);
    constexpr int LANES_PER_BLOCK = 4;
    for (int blk = 0; blk < m * (k / 32); ++blk) {
        const int kb = blk * 32;
        std::uint16_t lane_amax[4] = {0, 0, 0, 0};
        for (int ln = 0; ln < LANES_PER_BLOCK; ++ln)
            for (int j = 0; j < 8; ++j) {
                const int col = kb + ln * 8 + j;
                lane_amax[ln] = std::max(lane_amax[ln],
                                         static_cast<std::uint16_t>(hidden_bf16[col] & 0x7FFF));
            }
        std::uint16_t amax = 0;
        for (int ln = 0; ln < LANES_PER_BLOCK; ++ln) amax = std::max(amax, lane_amax[ln]);

        // branchless ceil: bf16 → f32 exact by <<16; multiply by f32(1/6)
        // (≥ real 1/6, no under-scale); round the BIT PATTERN up to the next
        // 2^23 multiple = ceil to the next exponent boundary. Subnormal amax
        // over-estimates (documented quirk; never clips).
        const std::uint32_t f32bits = static_cast<std::uint32_t>(amax) << 16;
        const float a = bits_to_f32(f32bits);
        const std::uint32_t wbits = bit_cast_u32(a * (1.0f / 6.0f));
        const int bexp = static_cast<int>(((wbits + 0x7FFFFFu) >> 23) & 0xFF);
        const std::uint8_t scale = static_cast<std::uint8_t>(std::min(254, std::max(0, bexp)));
        const float qs = std::ldexp(1.0f, scale - 127);  // 2^(scale-127)

        for (int ln = 0; ln < 4; ++ln) {
            std::uint32_t pk = 0;
            for (int j = 0; j < 8; ++j) {
                const int col = kb + ln * 8 + j;
                const float x = bf16_to_f32(hidden_bf16[col]);
                const std::uint8_t nib = e2m1_encode_rne(x / qs);
                pk |= static_cast<std::uint32_t>(nib) << (4 * j);  // lane 0 = low nibble
            }
            for (int b = 0; b < 4; ++b)
                out.a_quant[static_cast<long>(blk) * 16 + ln * 4 + b] =
                    static_cast<std::uint8_t>((pk >> (8 * b)) & 0xFF);
        }
        out.a_scale[blk] = scale;
    }
    return out;
}

// ── [4] scatter_reduce: bf16 int4 path + mxfp4 path ──
static void scatter_reduce_bf16(const std::vector<std::uint16_t>& flat_out_bf16,
                                const std::vector<std::int32_t>& reverse_sorted,
                                const std::vector<float>& sorted_weights, int topk,
                                long long max_sorted, std::vector<float>& out /*[M*8]*/) {
    for (std::size_t t = 0; t < out.size() / 8; ++t) {
        float acc[8] = {0, 0, 0, 0, 0, 0, 0, 0};
        for (int i = 0; i < topk; ++i) {
            const int sp = reverse_sorted[t * topk + i];
            if (sp < 0 || sp >= max_sorted) continue;
            const float w = sorted_weights[sp];
            for (int j = 0; j < 8; ++j) {
                const std::uint16_t bits = flat_out_bf16[static_cast<long>(sp) * 8 + j];
                const float d = bits_to_f32(static_cast<std::uint32_t>(bits) << 16);
                acc[j] = std::fmaf(d, w, acc[j]);
            }
        }
        for (int j = 0; j < 8; ++j) out[t * 8 + j] = acc[j];
    }
}

static void scatter_reduce_mxfp4(const std::vector<std::uint8_t>& flat_q,
                                 const std::vector<std::uint8_t>& flat_s,
                                 const std::vector<std::int32_t>& reverse_sorted,
                                 const std::vector<float>& sorted_weights, int topk, int d_hidden,
                                 long long max_sorted, std::vector<float>& out /*[M*d_hidden]*/) {
    // IMPLICIT UPSTREAM CONSTRAINT (found by violation, not documented): the
    // scale u32 read spans 4 consecutive 32-col blocks (blk & ~3), so
    // d_hidden/32 must be a multiple of 4 (d_hidden % 128 == 0); aiter only
    // static-asserts D % 8 == 0 — D_HIDDEN = 32 would read the next row's
    // scales / OOB.
    const int scols = d_hidden / 32;
    const int qcols = d_hidden / 2;
    for (std::size_t t = 0; t < out.size() / static_cast<std::size_t>(d_hidden); ++t) {
        for (int col = 0; col < d_hidden; col += 8) {  // one kernel thread-unit
            const int blk = col / 32;
            float acc[8] = {0, 0, 0, 0, 0, 0, 0, 0};
            for (int i = 0; i < topk; ++i) {
                const int sp = reverse_sorted[t * topk + i];
                if (sp < 0 || sp >= max_sorted) continue;
                const float w = sorted_weights[sp];
                const std::uint32_t sw =
                    load_u32_le(flat_s, static_cast<long>(sp) * scols + (blk & ~3u));
                const std::uint8_t e8 = static_cast<std::uint8_t>(sw >> ((blk & 3) * 8));
                const float s = std::ldexp(1.0f, static_cast<int>(e8) - 127);
                const std::uint32_t u0 = load_u32_le(flat_q, static_cast<long>(sp) * qcols + col / 2);
                for (int kcol = 0; kcol < 8; ++kcol) {
                    const std::uint8_t nib = static_cast<std::uint8_t>((u0 >> (4 * kcol)) & 0xF);
                    const float dv = e2m1_decode(nib);
                    acc[kcol] = std::fmaf(dv * s, w, acc[kcol]);
                }
            }
            for (int j = 0; j < 8; ++j)
                out[static_cast<long>(t) * d_hidden + col + j] = acc[j];
        }
    }
}

// ── deterministic input generator (LCG; benchmark_data_init philosophy) ──
struct Lcg {
    unsigned s;
    explicit Lcg(unsigned seed) : s(seed) {}
    unsigned next() { return s = s * 1664525u + 1013904223u; }
    unsigned below(unsigned n) { return next() % n; }
};

int main() {
    int checks = 0, fails = 0;
    const int M = 48, TOPK = 6, NE = 16, MB = 32;

    Lcg rng(0x4F24);
    SortInputs in;
    in.M = M; in.TOPK = TOPK; in.NE = NE; in.MB = MB;
    in.topk_ids.resize(M * TOPK);
    in.topk_weight.resize(M * TOPK);
    for (int i = 0; i < M * TOPK; ++i) {
        in.topk_ids[i] = static_cast<std::int32_t>(rng.below(NE + 2)) - 1;  // -1..NE
        in.topk_weight[i] = 0.5f + 0.5f * static_cast<float>(rng.below(16));
    }
    in.num_local_tokens = {M};  // full routing for the variant comparison
    // (the 3-stage variant rejects EP upstream: AITER_CHECK "num_local_tokens
    // is unsupported" in moe_mxfp4_aux.cu — EP is variant-B-only, tested below)

    // ── 1. both sort variants produce identical outputs ──
    const SortOutputs A = sort_3stage(in, 4);
    const SortOutputs B = sort_single_cta(in);
    ++checks;
    {
        const bool same = A.total_padded == B.total_padded &&
                          A.sorted_token_ids == B.sorted_token_ids &&
                          A.sorted_expert_ids == B.sorted_expert_ids &&
                          A.cumsum_tensor == B.cumsum_tensor &&
                          A.sorted_weights == B.sorted_weights &&
                          A.m_indices == B.m_indices &&
                          A.reverse_sorted == B.reverse_sorted;
        if (!same && fails++ < 3) std::printf("  variant A != B\n");
    }
    std::printf("1. 3-stage vs single-CTA identical: %s\n", fails ? "FAIL" : "PASS");

    // ── 2. sort invariants (variant B with EP: last 5 tokens unrouted) ──
    {
        SortInputs inb = in;
        inb.num_local_tokens = {M - 5};
        const SortOutputs A = sort_single_cta(inb);
        int f = 0;
        const int routed_pairs = (M - 5) * TOPK;
        for (int i = 0; i < M * TOPK; ++i) {
            const int sp = A.reverse_sorted[i];
            const bool routed = static_cast<unsigned>(inb.topk_ids[i]) < static_cast<unsigned>(NE) &&
                                i < routed_pairs;
            ++checks;
            if (routed) {
                if (sp < 0 || pack_token_topk(i / TOPK, i % TOPK) != A.sorted_token_ids[sp]) {
                    if (f++ < 3) std::printf("  inverse perm broken at pair %d\n", i);
                }
            } else if (sp != -1 && f++ < 3) {
                std::printf("  non-routed pair %d has slot %d\n", i, sp);
            }
        }
        fails += f > 0;
        std::printf("2a. reverse_sorted inverse permutation: %s\n", f ? "FAIL" : "PASS");

        f = 0;
        std::vector<int> routed_count(NE, 0), real_count(NE, 0);
        for (int i = 0; i < routed_pairs; ++i) {
            const int eid = inb.topk_ids[i];
            if (static_cast<unsigned>(eid) < static_cast<unsigned>(NE)) ++routed_count[eid];
        }
        for (long j = 0; j < A.total_padded; ++j) {
            const int e = A.sorted_expert_ids[j / MB];
            if (A.m_indices[j] != M) ++real_count[e];
            ++checks;
            if (A.m_indices[j] == M && A.sorted_weights[j] != 0.0f && f++ < 3)
                std::printf("  pad slot %ld weight != 0\n", j);
        }
        for (int e = 0; e < NE; ++e) {
            ++checks;
            if (real_count[e] != routed_count[e] && f++ < 3)
                std::printf("  expert %d real=%d routed=%d\n", e, real_count[e], routed_count[e]);
        }
        // per-expert multiset of token ids
        std::vector<std::vector<int>> seg_pairs(NE), want_pairs(NE);
        for (long j = 0; j < A.total_padded; ++j)
            if (A.m_indices[j] != M)
                seg_pairs[A.sorted_expert_ids[j / MB]].push_back(A.sorted_token_ids[j] & MASK_TOKEN);
        for (int i = 0; i < routed_pairs; ++i) {
            const int eid = inb.topk_ids[i];
            if (static_cast<unsigned>(eid) < static_cast<unsigned>(NE))
                want_pairs[eid].push_back(i / TOPK);
        }
        for (int e = 0; e < NE; ++e) {
            std::sort(seg_pairs[e].begin(), seg_pairs[e].end());
            std::sort(want_pairs[e].begin(), want_pairs[e].end());
            ++checks;
            if (seg_pairs[e] != want_pairs[e] && f++ < 3)
                std::printf("  multiset mismatch expert %d\n", e);
        }
        fails += f > 0;
        std::printf("2b. segment multiset + pad sentinel + block consistency: %s\n",
                    f ? "FAIL" : "PASS");
    }

    // ── 3. quant: scale contract + decode round trip ──
    {
        const int m = 8, k = 128;
        std::vector<std::uint16_t> hid(m * k);
        Lcg rng(0x1337);
        for (auto& v : hid) {
            // Finite bf16 only (Inf/NaN make the amax→scale contract murky —
            // real activations are finite): exponents up to 0x7E (|x| < 3e38).
            const unsigned bits = rng.below(0x10000);
            v = static_cast<std::uint16_t>((bits & 0x8000u) | ((bits % 0x7F80u)));
        }
        const auto q = mxfp4_quant(hid, m, k);
        int f = 0;
        double worst = 0.0;
        for (int blk = 0; blk < m * (k / 32); ++blk) {
            const std::uint8_t sb = q.a_scale[blk];
            ++checks;
            if (sb > 254 && f++ < 3) std::printf("  scale byte %u > 254\n", sb);
            const float qs = std::ldexp(1.0f, static_cast<int>(sb) - 127);
            for (int j = 0; j < 32; ++j) {
                const int col = blk * 32 + j;
                const float x = bf16_to_f32(hid[col]);
                const std::uint8_t b = q.a_quant[static_cast<long>(blk) * 16 + j / 2];
                const std::uint8_t nib = (j % 2 == 0) ? (b & 0xF) : (b >> 4);
                const float dv = e2m1_decode(nib) * qs;
                const float err = std::fabs(x - dv);
                ++checks;
                // |x/qs| <= 6 by the ceil contract -> |x - dec*qs| <= 3*qs
                // (largest e2m1 half-gap is 1.0 in units of qs, between 4 and 6)
                if (err > 3.0f * qs && f++ < 5)
                    std::printf("  quant err col=%d: %g > 3*qs=%g\n", col, err, 3.0f * qs);
                worst = std::fmax(worst, err / (3.0f * qs));
            }
        }
        // Directed RNE pins (random data almost never lands on exact
        // midpoints): a tie goes to the EVEN code; -0 keeps its sign bit;
        // |x| >= 6 saturates (satfinite).
        {
            struct Case {
                float x;
                std::uint8_t want;
            };
            static const Case cases[] = {
                // vals[] = {0, .5, 1, 1.5, 2, 3, 4, 6} = codes 0..7. Ties go
                // to the code with mantissa LSB 0: 0.25 -> code 0, 0.75 ->
                // code 2 (1.0), 1.25 -> code 2, 1.75 -> code 4 (2.0), 2.5 ->
                // code 4, 3.5 -> code 6 (4.0), 5.0 -> code 6.
                {0.25f, 0x0}, {0.75f, 0x2}, {1.25f, 0x2}, {1.75f, 0x4},
                {2.5f, 0x4},  {3.5f, 0x6},  {5.0f, 0x6},
                {-0.0f, 0x8}, {6.0f, 0x7},  {-6.0f, 0xF}, {6.5f, 0x7}, {-6.5f, 0xF},
            };
            for (const auto& c : cases) {
                ++checks;
                const std::uint8_t got = e2m1_encode_rne(c.x);
                if (got != c.want && f++ < 8)
                    std::printf("  rne pin x=%g got 0x%x want 0x%x\n", c.x, got, c.want);
            }
        }
        fails += f > 0;
        std::printf("3. quant scale/round-trip contract (worst err/3qs = %.3f): %s\n", worst,
                    f ? "FAIL" : "PASS");
    }

    // ── 4. end-to-end: sort -> synthetic expert output -> scatter_reduce ──
    {
        const SortOutputs A = sort_3stage(in, 4);
        const long max_sorted = A.total_padded;
        std::vector<std::uint16_t> flat(static_cast<long>(max_sorted) * 8);
        for (long i = 0; i < static_cast<long>(flat.size()); ++i)
            flat[i] = bf16_round(static_cast<float>(i % 37));
        std::vector<float> out(static_cast<long>(M) * 8, 0.0f);
        scatter_reduce_bf16(flat, A.reverse_sorted, A.sorted_weights, TOPK, max_sorted, out);

        int f = 0;
        for (int t = 0; t < M; ++t) {
            float ex[8] = {0, 0, 0, 0, 0, 0, 0, 0};
            for (int i = 0; i < TOPK; ++i) {
                const int pair = t * TOPK + i;
                const int eid = in.topk_ids[pair];
                if (static_cast<unsigned>(eid) >= static_cast<unsigned>(NE)) continue;
                if (pair >= in.num_local_tokens[0] * TOPK) continue;
                const int sp = A.reverse_sorted[pair];
                if (sp < 0) continue;
                const float w = in.topk_weight[pair];
                for (int j = 0; j < 8; ++j) {
                    const float d = bf16_to_f32(flat[static_cast<long>(sp) * 8 + j]);
                    ex[j] = std::fmaf(d, w, ex[j]);
                }
            }
            for (int j = 0; j < 8; ++j) {
                ++checks;
                if (bf16_round(out[static_cast<long>(t) * 8 + j]) != bf16_round(ex[j]) && f++ < 5)
                    std::printf("  scatter t=%d j=%d got %g want %g\n", t, j,
                                out[static_cast<long>(t) * 8 + j], ex[j]);
            }
        }
        fails += f > 0;
        std::printf("4a. scatter_reduce bf16 vs oracle: %s\n", f ? "FAIL" : "PASS");

        // mxfp4: quantize the flat data (per-32 blocks), scatter, compare
        // exact in the quantized domain. D_HIDDEN = 128 (the implicit scale-
        // read constraint).
        const int KD = 128;
        std::vector<std::uint16_t> flatq(static_cast<long>(max_sorted) * KD);
        for (long i = 0; i < static_cast<long>(flatq.size()); ++i)
            flatq[i] = bf16_round(static_cast<float>(i % 23));
        const auto q = mxfp4_quant(flatq, static_cast<int>(max_sorted), KD);
        std::vector<float> outm(static_cast<long>(M) * KD, 0.0f);
        scatter_reduce_mxfp4(q.a_quant, q.a_scale, A.reverse_sorted, A.sorted_weights, TOPK, KD,
                             max_sorted, outm);
        f = 0;
        for (int t = 0; t < M; ++t)
            for (int col = 0; col < KD; ++col) {
                const int blk = col / 32;
                float ex = 0.0f;
                for (int i = 0; i < TOPK; ++i) {
                    const int pair = t * TOPK + i;
                    const int sp = A.reverse_sorted[pair];
                    if (sp < 0) continue;
                    const float w = in.topk_weight[pair];
                    const std::uint32_t sw = load_u32_le(
                        q.a_scale, static_cast<long>(sp) * (KD / 32) + (blk & ~3u));
                    const std::uint8_t e8 = static_cast<std::uint8_t>(sw >> ((blk & 3) * 8));
                    const float s = std::ldexp(1.0f, static_cast<int>(e8) - 127);
                    const std::uint32_t u0 = load_u32_le(
                        q.a_quant, static_cast<long>(sp) * (KD / 2) + (col / 8) * 4);
                    const int jn = col % 8;
                    const std::uint8_t nib = static_cast<std::uint8_t>((u0 >> (4 * jn)) & 0xF);
                    ex = std::fmaf(e2m1_decode(nib) * s, w, ex);
                }
                ++checks;
                if (std::fabs(outm[static_cast<long>(t) * KD + col] - ex) > 1e-4 && f++ < 5)
                    std::printf("  mxfp4 scatter t=%d col=%d got %g want %g\n", t, col,
                                outm[static_cast<long>(t) * KD + col], ex);
            }
        fails += f > 0;
        std::printf("4b. scatter_reduce mxfp4 (quantized-domain exact, D=128): %s\n",
                    f ? "FAIL" : "PASS");
    }

    std::printf("mxfp4_moe_aux: %d checks, %d failures -> %s\n", checks, fails,
                fails ? "FAIL" : "PASS");
    return fails ? MAIN_RETURN_BAD : 0;
}
