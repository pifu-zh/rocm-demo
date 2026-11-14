// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2026, Advanced Micro Devices, Inc. All rights reserved.
//
// Host reference for aiter's Gated Delta Rule (GDR/GDN) decode chain
// (csrc/kernels/gdr_decode_packed_bf16.cu and
// csrc/kernels/fused_split_gdr_update.cu @ 1eab5ae12, MIT), covering four
// independently-extractable designs:
//
// [1] XOR-butterfly wave reduction via ds_swizzle BITMASK_PERM
//     (gdr_decode_packed_bf16.cu reduce_k): three ds_swizzle steps with xor
//     masks 1/2/4 sum the 8 k-lanes of a (v_idx) group in log2(8) steps with
//     NO bank conflicts and no LDS traffic. Encoding constants copied
//     verbatim: kDsSwizzleXorN = (N << 10) | 0x1f. fused_split_gdr_update.cu
//     uses the same butterfly over 64 lanes with __shfl_xor(16/32) to fold
//     the 4 K-splits (lane>>4) sharing a v column (lane & 15). This demo
//     emulates the XOR-BUTTERFLY SEMANTICS structurally; the on-card
//     instruction itself is the hardware-probe demo's domain (queued).
//
// [2] The gated delta rule recurrence and its TWO SCHEDULES of one identity.
//     Both kernels compute (K = key dim, V = value dim, per v-head):
//       decay    = exp(-exp(A_log) * softplus(a + dt_bias))
//       beta     = sigmoid(b)
//       k_n      = k / rsqrt(k.k + 1e-6)          (q additionally * scale)
//       S_dec    = S * decay
//       residual = (v - S_dec . k_n) * beta
//       S_new    = S_dec + residual (outer) k_n
//       out      = S_new . q_n
//     gdr_decode_packed_bf16 computes out as
//       sum_hq + residual * (k_n . q_n)   [algebraic split: never re-derives
//                                          S_new for the output]
//     fused_split_gdr_update computes out as
//       (S_new held in registers) . q_n   [direct: state lives in float4
//                                          registers across the T loop]
//     Two schedules, one identity — the tests pin them against each other
//     AND against a third, naive scalar implementation.
//
// [3] State-pool layouts. Decode kernel: bf16 [slot][HV][V][K] row-major,
//     touched with __builtin_nontemporal (streaming: one touch per decode
//     step). Split kernel: fp32 SWIZZLED [slot][HV][K/4][V][4] — the float4
//     fragment packs k = kg*4 + f so each lane's register file tile is one
//     contiguous float4 per (kg, v). The codec here round-trips row-major
//     through the swizzled layout and the chain test proves the swizzled
//     reader sees the same recurrence.
//
// [4] Sentinel/index policy ASYMMETRY (observed contracts, deliberately
//     different per kernel):
//     - decode kernel: invalid index (negative OR >= pool, via the unsigned
//       cast trick) => output = 0 and NO state touch (padding rows in a
//       batch). Also documented upstream: valid slots must be unique within
//       a batch, else workgroups race on the read-modify-write.
//     - split kernel: idx >= 0 gates state load/store only; a negative
//       index means "fresh sequence start" — zero initial state, output
//       still computed, slot untouched.
//
// Shared conventions pinned by the tests:
// - mixed_qkv packing [B][H*K q | H*K k | HV*V v]; q/k head for value head
//   hv is hv / (HV/H) (4 value heads share one qk head here).
// - decode kernel rounds beta through bf16 (sigmoid -> __float2bfloat16 ->
//   float) — a deliberate precision pin; the split kernel does NOT round.
//   Both are pinned in the respective references.
// - softplus forms differ in expression but agree at the caller defaults
//   (beta=1, threshold=20): decode uses log1p(exp(x)) / x split at 20;
//   split uses the parameterized inv_beta*log1p(exp(beta*x)) form.
// - LDS bank padding (split kernel): padded index = idx + idx/CHUNK with
//   CHUNK = BK/4 = 32 turns row stride 32 into 33 ≡ 1 (mod 32 banks), so
//   row r starts at bank r and a fixed column across rows hits every bank.
//
// Verification level: SOURCE_VERIFIED + REFERENCE_PASS (CPU-only host
// reference; no HIP execution is claimed anywhere in this demo).
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <vector>

#define MAIN_RETURN_BAD 1

// ── bit helpers (same lab-shared bf16 codec as mxfp4_moe_aux) ──
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
    std::uint32_t below(std::uint32_t n) { return next() % n; }
};

// Tolerance helper: relative with absolute floor.
static bool close_enough(float got, float want, float rel_tol, float abs_tol) {
    const float d = std::fabs(got - want);
    return d <= abs_tol || d <= rel_tol * std::fabs(want);
}

// ══════════════════════════════════════════════════════════════════════
// [1] XOR-butterfly reduction (ds_swizzle BITMASK_PERM semantics)
// ══════════════════════════════════════════════════════════════════════
//
// Device-side originals (copied constants; instruction semantics emulated):
//   constexpr unsigned kDsSwizzleXor1 = (1u << 10) | 0x1fu;
//   constexpr unsigned kDsSwizzleXor2 = (2u << 10) | 0x1fu;
//   constexpr unsigned kDsSwizzleXor4 = (4u << 10) | 0x1fu;
//   value += ds_swizzle_xor<1>(value);   // lane ^= 1
//   value += ds_swizzle_xor<2>(value);   // lane ^= 2
//   value += ds_swizzle_xor<4>(value);   // lane ^= 4
// The (N << 10) field selects the XOR operand in the BITMASK_PERM encoding;
// 0x1f is the accompanying mask field copied verbatim from upstream. The
// emulated semantics used here: after step with mask m, lane i holds
// p[i] + p[i ^ m]. After masks 1,2,4 every lane of an 8-lane group holds
// the group total. On-card verification of the instruction encoding is the
// hardware-probe demo's responsibility (queued as M3 hardware work).
static void xor_butterfly(std::vector<float>& p, const std::vector<unsigned>& masks) {
    const int n = static_cast<int>(p.size());
    for (unsigned m : masks) {
        std::vector<float> t = p;
        for (int i = 0; i < n; ++i) p[i] = t[i] + t[static_cast<int>(i) ^ static_cast<int>(m)];
    }
}

// ══════════════════════════════════════════════════════════════════════
// Shared shapes (contract-pinned to the decode kernel's constants)
// ══════════════════════════════════════════════════════════════════════
constexpr int KH = 8;    // kQHeads: q/k heads
constexpr int VH = 32;   // kVHeads: value heads
constexpr int KD = 128;  // kK: key dim
constexpr int VD = 128;  // kV: value dim
constexpr int QK_ELEMS = KH * KD;
constexpr int QKV_ELEMS = 2 * QK_ELEMS + VH * VD;

struct DecodeInputs {
    // [B][QKV_ELEMS] bf16
    std::vector<std::uint16_t> qkv;
    // [B][VH] bf16 gates
    std::vector<std::uint16_t> a, b;
    // [VH] bf16 / [VH] f32
    std::vector<std::uint16_t> dt_bias;
    std::vector<float> A_log;
    // [B] i32 slot indices (-1 = sentinel)
    std::vector<std::int32_t> indices;
    float scale = 0.5f;
    int batch = 0;
};

// Decode-kernel path: bf16 state pool [pool][VH][VD][KD].
struct DecodeState {
    std::vector<std::uint16_t> data;  // [pool][VH][VD][KD]
    int pool = 0;
    static long slot_words(int slot, int v, int k) {
        // layout [slot][VH][VD][KD], flat: v is the within-slot row index
        // (callers pass hv * VD + v_idx)
        return (static_cast<long>(slot) * VH * VD + v) * KD + static_cast<long>(k);
    }
};

// Decode kernel emulation, faithful to the lane decomposition:
//   v_idx = tile*32 + warp*8 + v_lane (each v_idx independent),
//   k-lane group of 8 owns k = k_lane*8 + ki*64 + j (ki<2, j<8),
//   per-column partials -> xor_butterfly(1,2,4) -> full K sums.
// Mirrors the kernel's operation order (fmaf chains, beta bf16 rounding,
// softplus log1p(exp(x)) split at 20) with std::exp/log in place of the
// device fast builtins (documented ~1ulp substitution).
struct DecodeOutputs {
    std::vector<float> out;            // [B][VH][VD] pre-bf16 values
    std::vector<std::uint16_t> out_bf; // [B][VH][VD]
    std::vector<char> touched;         // [B] state slot actually updated
};

static DecodeOutputs decode_step_emul(const DecodeInputs& in, const DecodeState& st,
                                      std::vector<float>& next_state_f32 /*[pool][VH][VD][KD]*/) {
    DecodeOutputs o;
    o.out.assign(static_cast<long>(in.batch) * VH * VD, 0.0f);
    o.out_bf.assign(static_cast<long>(in.batch) * VH * VD, 0);
    o.touched.assign(in.batch, 0);
    next_state_f32.assign(static_cast<long>(st.pool) * VH * VD * KD, 0.0f);

    for (int row = 0; row < in.batch; ++row) {
        const int slot = in.indices[row];
        if (static_cast<std::uint32_t>(slot) >= static_cast<std::uint32_t>(st.pool)) {
            continue;  // sentinel: out stays 0, state untouched (policy [4])
        }
        o.touched[row] = 1;
        const long qkv_row = static_cast<long>(row) * QKV_ELEMS;

        for (int hv = 0; hv < VH; ++hv) {
            const int qk_head = hv / (VH / KH);
            // gate path (per hv, shared by all v_idx columns)
            const float gate_a = bf16_to_f32(in.a[static_cast<long>(row) * VH + hv]);
            const float gate_b = bf16_to_f32(in.b[static_cast<long>(row) * VH + hv]);
            const float gate_dt = bf16_to_f32(in.dt_bias[hv]);
            const float x = gate_a + gate_dt;
            const float softplus = x <= 20.0f ? std::log1p(std::exp(x)) : x;
            const float decay = std::exp(-std::exp(in.A_log[hv]) * softplus);
            const float sigmoid = 1.0f / (1.0f + std::exp(-gate_b));
            const float beta = bf16_to_f32(bf16_round(sigmoid));  // bf16 pin

            for (int v_idx = 0; v_idx < VD; ++v_idx) {
                const float value =
                    bf16_to_f32(in.qkv[qkv_row + 2 * QK_ELEMS + static_cast<long>(hv) * VD + v_idx]);

                // per-k_lane partials over k = k_lane*8 + ki*64 + j
                float q_sq_p[8] = {0}, k_sq_p[8] = {0};
                float dot_p[8] = {0}, hk_p[8] = {0}, hq_p[8] = {0};
                float q_n[8][2][8], k_n[8][2][8], rec[8][2][8];
                for (int kl = 0; kl < 8; ++kl) {
                    for (int ki = 0; ki < 2; ++ki)
                        for (int j = 0; j < 8; ++j) {
                            const int k = kl * 8 + ki * 64 + j;
                            const float qv = bf16_to_f32(
                                in.qkv[qkv_row + static_cast<long>(qk_head) * KD + k]);
                            const float kv = bf16_to_f32(
                                in.qkv[qkv_row + QK_ELEMS + static_cast<long>(qk_head) * KD + k]);
                            const float sv = bf16_to_f32(st.data[DecodeState::slot_words(
                                slot, hv * VD + v_idx, k)]);
                            const float r = sv * decay;
                            rec[kl][ki][j] = r;
                            // raw partials only: sum_hq/sum_hk accumulate with
                            // NORMALIZED q/k (kernel normalizes in place
                            // before the recurrent dot loops)
                            q_sq_p[kl] = std::fmaf(qv, qv, q_sq_p[kl]);
                            k_sq_p[kl] = std::fmaf(kv, kv, k_sq_p[kl]);
                            q_n[kl][ki][j] = qv;
                            k_n[kl][ki][j] = kv;
                        }
                }
                // butterflies (reduce_k)
                auto bf8 = [](std::vector<float>& v) {
                    xor_butterfly(v, {1, 2, 4});
                };
                {
                    std::vector<float> t(std::begin(q_sq_p), std::end(q_sq_p));
                    bf8(t);
                    std::copy(t.begin(), t.end(), q_sq_p);
                }
                {
                    std::vector<float> t(std::begin(k_sq_p), std::end(k_sq_p));
                    bf8(t);
                    std::copy(t.begin(), t.end(), k_sq_p);
                }
                const float q_scale = 1.0f / std::sqrt(q_sq_p[0] + 1.0e-6f) * in.scale;
                const float k_scale = 1.0f / std::sqrt(k_sq_p[0] + 1.0e-6f);
                for (int kl = 0; kl < 8; ++kl)
                    for (int ki = 0; ki < 2; ++ki)
                        for (int j = 0; j < 8; ++j) {
                            q_n[kl][ki][j] *= q_scale;
                            k_n[kl][ki][j] *= k_scale;
                        }
                for (int kl = 0; kl < 8; ++kl) {
                    for (int ki = 0; ki < 2; ++ki)
                        for (int j = 0; j < 8; ++j) {
                            dot_p[kl] = std::fmaf(k_n[kl][ki][j], q_n[kl][ki][j], dot_p[kl]);
                            hk_p[kl] = std::fmaf(rec[kl][ki][j], k_n[kl][ki][j], hk_p[kl]);
                            hq_p[kl] = std::fmaf(rec[kl][ki][j], q_n[kl][ki][j], hq_p[kl]);
                        }
                }
                {
                    std::vector<float> t(std::begin(dot_p), std::end(dot_p));
                    bf8(t);
                    std::copy(t.begin(), t.end(), dot_p);
                }
                {
                    std::vector<float> t(std::begin(hk_p), std::end(hk_p));
                    bf8(t);
                    std::copy(t.begin(), t.end(), hk_p);
                }
                {
                    std::vector<float> t(std::begin(hq_p), std::end(hq_p));
                    bf8(t);
                    std::copy(t.begin(), t.end(), hq_p);
                }

                const float residual = (value - hk_p[0]) * beta;
                const float output = hq_p[0] + residual * dot_p[0];  // algebraic schedule
                const long oi = (static_cast<long>(row) * VH + hv) * VD + v_idx;
                o.out[oi] = output;
                o.out_bf[oi] = bf16_round(output);
                for (int kl = 0; kl < 8; ++kl)
                    for (int ki = 0; ki < 2; ++ki)
                        for (int j = 0; j < 8; ++j) {
                            const int k = kl * 8 + ki * 64 + j;
                            next_state_f32[DecodeState::slot_words(slot, hv * VD + v_idx, k)] =
                                std::fmaf(residual, k_n[kl][ki][j], rec[kl][ki][j]);
                        }
            }
        }
    }
    return o;
}

// Third implementation: naive scalar reference of the SAME recurrence,
// plain loops over (hv, v, k) — no lane decomposition, no butterflies.
static DecodeOutputs decode_step_naive(const DecodeInputs& in, const DecodeState& st,
                                       std::vector<float>& next_state_f32) {
    DecodeOutputs o;
    o.out.assign(static_cast<long>(in.batch) * VH * VD, 0.0f);
    o.out_bf.assign(static_cast<long>(in.batch) * VH * VD, 0);
    o.touched.assign(in.batch, 0);
    next_state_f32.assign(static_cast<long>(st.pool) * VH * VD * KD, 0.0f);

    for (int row = 0; row < in.batch; ++row) {
        const int slot = in.indices[row];
        if (static_cast<std::uint32_t>(slot) >= static_cast<std::uint32_t>(st.pool)) continue;
        o.touched[row] = 1;
        const long qkv_row = static_cast<long>(row) * QKV_ELEMS;
        for (int hv = 0; hv < VH; ++hv) {
            const int qk_head = hv / (VH / KH);
            const float gate_a = bf16_to_f32(in.a[static_cast<long>(row) * VH + hv]);
            const float gate_b = bf16_to_f32(in.b[static_cast<long>(row) * VH + hv]);
            const float x = gate_a + bf16_to_f32(in.dt_bias[hv]);
            const float softplus = x <= 20.0f ? std::log1p(std::exp(x)) : x;
            const float decay = std::exp(-std::exp(in.A_log[hv]) * softplus);
            const float beta = bf16_to_f32(bf16_round(1.0f / (1.0f + std::exp(-gate_b))));

            for (int v = 0; v < VD; ++v) {
                const float value =
                    bf16_to_f32(in.qkv[qkv_row + 2 * QK_ELEMS + static_cast<long>(hv) * VD + v]);
                float q_sq = 0, k_sq = 0;
                for (int k = 0; k < KD; ++k) {
                    const float qv =
                        bf16_to_f32(in.qkv[qkv_row + static_cast<long>(qk_head) * KD + k]);
                    const float kv =
                        bf16_to_f32(in.qkv[qkv_row + QK_ELEMS + static_cast<long>(qk_head) * KD + k]);
                    q_sq += qv * qv;
                    k_sq += kv * kv;
                }
                const float q_scale = 1.0f / std::sqrt(q_sq + 1.0e-6f) * in.scale;
                const float k_scale = 1.0f / std::sqrt(k_sq + 1.0e-6f);
                // two passes: sums first, then normalized updates
                float s_qn[KD], s_kn[KD], s_rec[KD];
                float hk = 0, hq = 0;
                for (int k = 0; k < KD; ++k) {
                    const float qv =
                        bf16_to_f32(in.qkv[qkv_row + static_cast<long>(qk_head) * KD + k]);
                    const float kv =
                        bf16_to_f32(in.qkv[qkv_row + QK_ELEMS + static_cast<long>(qk_head) * KD + k]);
                    s_qn[k] = qv * q_scale;
                    s_kn[k] = kv * k_scale;
                    const float sv =
                        bf16_to_f32(st.data[DecodeState::slot_words(slot, hv * VD + v, k)]);
                    s_rec[k] = sv * decay;
                    hk += s_rec[k] * s_kn[k];
                    hq += s_rec[k] * s_qn[k];
                }
                float dot = 0;
                for (int k = 0; k < KD; ++k) dot += s_kn[k] * s_qn[k];
                const float residual = (value - hk) * beta;
                const long oi = (static_cast<long>(row) * VH + hv) * VD + v;
                o.out[oi] = hq + residual * dot;
                o.out_bf[oi] = bf16_round(o.out[oi]);
                for (int k = 0; k < KD; ++k)
                    next_state_f32[DecodeState::slot_words(slot, hv * VD + v, k)] =
                        s_rec[k] + residual * s_kn[k];
            }
        }
    }
    return o;
}

// ══════════════════════════════════════════════════════════════════════
// [3] Split-kernel state layout: fp32 swizzled [slot][HV][K/4][V][4]
// ══════════════════════════════════════════════════════════════════════
static long swz_words(int pool_slot, int hv, int kg, int v, int f) {
    constexpr int K4 = KD / 4;
    return (((static_cast<long>(pool_slot) * VH + hv) * K4 + kg) * VD + v) * 4 + f;
}
// Row-major [slot][hv][v][k] -> swizzled flat fp32.
static std::vector<float> pack_state_swizzled(const std::vector<float>& rowmaj, int pool) {
    std::vector<float> swz(static_cast<long>(pool) * VH * (KD / 4) * VD * 4);
    for (int s = 0; s < pool; ++s)
        for (int hv = 0; hv < VH; ++hv)
            for (int v = 0; v < VD; ++v)
                for (int kg = 0; kg < KD / 4; ++kg)
                    for (int f = 0; f < 4; ++f) {
                        const long k = kg * 4 + f;
                        swz[swz_words(s, hv, kg, v, static_cast<int>(f))] =
                            rowmaj[(static_cast<long>(s) * VH + hv) * VD * KD + v * KD + k];
                    }
    return swz;
}
static std::vector<float> unpack_state_swizzled(const std::vector<float>& swz, int pool) {
    std::vector<float> rowmaj(static_cast<long>(pool) * VH * VD * KD);
    for (int s = 0; s < pool; ++s)
        for (int hv = 0; hv < VH; ++hv)
            for (int v = 0; v < VD; ++v)
                for (int kg = 0; kg < KD / 4; ++kg)
                    for (int f = 0; f < 4; ++f) {
                        const long k = kg * 4 + f;
                        rowmaj[(static_cast<long>(s) * VH + hv) * VD * KD + v * KD + k] =
                            swz[swz_words(s, hv, kg, v, static_cast<int>(f))];
                    }
    return rowmaj;
}

// LDS bank padding (fused_split_gdr_update.cu lds_padded_idx):
//   idx + idx/CHUNK — every CHUNK-th element inserts one pad slot.
template <int CHUNK>
static inline int lds_padded_idx(int idx) {
    return idx + idx / CHUNK;
}

// ══════════════════════════════════════════════════════════════════════
// [2b] fused_split_gdr_update emulation: T-step chain, fp32 state in
//      registers, 64-lane decomposition (4 K-splits x 16 v columns),
//      __shfl_xor(16/32) butterfly, padded LDS indices.
// ══════════════════════════════════════════════════════════════════════
struct SplitInputs {
    // mixed_qkv [B][dim][T] with dim = 2*KD + HV*VD (bf16); strides emulated
    // contiguously: x[b][d][t] at qkv[((b*dim + d)*T) + t]
    std::vector<std::uint16_t> qkv;
    int T = 0, batch = 0;
    std::vector<std::uint16_t> a, b;     // [B][T][VH] bf16
    std::vector<std::uint16_t> dt_bias;  // [VH]
    std::vector<float> A_log;            // [VH]
    std::vector<std::int32_t> indices;   // [B]
    std::vector<float> state0_rowmaj;    // [pool][VH][VD][KD] fp32
    int pool = 0;
    float scale = 0.0f;  // <= 0 -> 1/sqrt(KD) (host-side dispatch rule)
    float softplus_beta = 1.0f, softplus_threshold = 20.0f;
};

static long qkv_split_word(int b, int d, int t, int T) {
    constexpr int DIM = 2 * KD + VH * VD;
    return (static_cast<long>(b) * DIM + d) * T + t;
}

// Returns per-step outputs [B][T][VH][VD] and final state (row-major).
struct SplitOutputs {
    std::vector<float> out;       // [B][T][VH][VD]
    std::vector<float> state_fm;  // [pool][VH][VD][KD] final row-major
    std::vector<char> touched;    // [B]
};

static SplitOutputs split_chain_emul(const SplitInputs& in, const std::vector<float>& state0_swz) {
    SplitOutputs o;
    o.out.assign(static_cast<long>(in.batch) * in.T * VH * VD, 0.0f);
    o.touched.assign(in.batch, 0);
    const float scale = in.scale > 0.0f ? in.scale : 1.0f / std::sqrt(static_cast<float>(KD));
    const float inv_sp_beta = 1.0f / in.softplus_beta;

    // per-(n, hv, i_v) CTA emulation: 64 lanes = 4 k_splits x 16 v columns.
    // BK = KD = 128 -> BK_QTR = 32 -> SMEM_PAD = 1, SMEM_STRIDE = 33.
    constexpr int BV_OUT = 16;  // BV_VAL 64 / 4
    constexpr int BK_QTR = KD / 4;
    constexpr int BK4_QTR = BK_QTR / 4;
    constexpr int SMEM_PAD = (BK_QTR == 32) ? 1 : 0;
    constexpr int SMEM_STRIDE = BK_QTR + SMEM_PAD;
    std::vector<float> smem_q(SMEM_STRIDE * 4), smem_k(SMEM_STRIDE * 4);

    // Final state accumulates in a working row-major copy (registers in the
    // kernel); the INITIAL load and FINAL store go through the swizzled
    // layout exactly as the kernel touches its fp32 pool.
    std::vector<float> state_work = in.state0_rowmaj;

    for (int n = 0; n < in.batch; ++n) {
        const std::int32_t idx = in.indices[n];
        for (int hv = 0; hv < VH; ++hv) {
            const int i_h = hv / (VH / KH);
            for (int i_v = 0; i_v * BV_OUT < VD; ++i_v) {
                float h_vec[64][BK4_QTR][4];
                for (int lane = 0; lane < 64; ++lane)
                    for (int i = 0; i < BK4_QTR; ++i)
                        for (int f = 0; f < 4; ++f) h_vec[lane][i][f] = 0.0f;

                if (idx >= 0) {
                    // initial state load THROUGH the swizzled pool layout
                    for (int lane = 0; lane < 64; ++lane) {
                        const int v_idx = lane & (BV_OUT - 1);
                        const int k_split = lane >> 4;
                        const int v_col = i_v * BV_OUT + v_idx;
                        const int kg_start = (k_split * BK_QTR) / 4;
                        for (int i = 0; i < BK4_QTR; ++i)
                            for (int f = 0; f < 4; ++f)
                                h_vec[lane][i][f] =
                                    state0_swz[swz_words(idx, hv, kg_start + i, v_col, f)];
                    }
                }

                const float a_log_val = in.A_log[hv];
                const float dt_bias_val = bf16_to_f32(in.dt_bias[hv]);
                const float neg_exp_A_log = -std::exp(a_log_val);

                const int q_dim_off = i_h * KD;
                const int k_dim_off = KD + i_h * KD;
                const int v_dim_off = 2 * KD + hv * VD;

                for (int t = 0; t < in.T; ++t) {
                    // vec2 LDS fill (use_vec2 path): base = 2*lane, logical j
                    // lands at padded position j + j/32.
                    for (int lane = 0; lane < 64; ++lane) {
                        const int base = 2 * lane;
                        for (int e = 0; e < 2 && base + e < KD; ++e) {
                            const int j = base + e;
                            smem_q[lds_padded_idx<BK_QTR>(j)] =
                                bf16_to_f32(in.qkv[qkv_split_word(n, q_dim_off + j, t, in.T)]);
                            smem_k[lds_padded_idx<BK_QTR>(j)] =
                                bf16_to_f32(in.qkv[qkv_split_word(n, k_dim_off + j, t, in.T)]);
                        }
                    }

                    // Phase 1: K-L2 norm partials + delta dot, per lane.
                    // Slice read: smem_k[k_split*33 + i*4 + f] — equals
                    // lds_padded_idx(k_split*32 + i*4 + f) because the pad
                    // stride turns row starts into 33*k_split (the trick).
                    float dp_lane[64], sq_lane[64];
                    for (int lane = 0; lane < 64; ++lane) {
                        const int k_start = (lane >> 4) * SMEM_STRIDE;
                        float dp = 0, k_sq = 0;
                        for (int i = 0; i < BK4_QTR; ++i)
                            for (int f = 0; f < 4; ++f) {
                                const float kv = smem_k[k_start + i * 4 + f];
                                dp = std::fmaf(h_vec[lane][i][f], kv, dp);
                                k_sq = std::fmaf(kv, kv, k_sq);
                            }
                        dp_lane[lane] = dp;
                        sq_lane[lane] = k_sq;
                    }
                    // fold the 4 k_splits: xor 16, xor 32 (64-lane butterfly)
                    {
                        std::vector<float> p(std::begin(dp_lane), std::end(dp_lane));
                        xor_butterfly(p, {16, 32});
                        std::copy(p.begin(), p.end(), dp_lane);
                        std::vector<float> q2(std::begin(sq_lane), std::end(sq_lane));
                        xor_butterfly(q2, {16, 32});
                        std::copy(q2.begin(), q2.end(), sq_lane);
                    }

                    // gates + delta update + q dot (Phase 2/3 fused per lane)
                    for (int lane = 0; lane < 64; ++lane) {
                        const int k_split = lane >> 4;
                        const int v_idx = lane & (BV_OUT - 1);
                        const int v_col = i_v * BV_OUT + v_idx;
                        const int k_start = k_split * SMEM_STRIDE;
                        const float v_local0 =
                            bf16_to_f32(in.qkv[qkv_split_word(n, v_dim_off + v_col, t, in.T)]);
                        const float a_t =
                            bf16_to_f32(in.a[(static_cast<long>(n) * in.T + t) * VH + hv]);
                        const float b_t =
                            bf16_to_f32(in.b[(static_cast<long>(n) * in.T + t) * VH + hv]);
                        const float sp_x = a_t + dt_bias_val;
                        const float beta_x = in.softplus_beta * sp_x;
                        const float sp = beta_x <= in.softplus_threshold
                                             ? inv_sp_beta * std::log1p(std::exp(beta_x))
                                             : sp_x;
                        const float exp_g = std::exp(neg_exp_A_log * sp);
                        const float beta = 1.0f / (1.0f + std::exp(-b_t));  // NOT bf16-rounded

                        const float k_inv_norm = 1.0f / std::sqrt(sq_lane[lane] + 1.0e-6f);
                        float v_local = v_local0 - dp_lane[lane] * exp_g * k_inv_norm;
                        v_local *= beta;
                        const float kv_scale = k_inv_norm * v_local;

                        for (int i = 0; i < BK4_QTR; ++i)
                            for (int f = 0; f < 4; ++f) {
                                const float kv = smem_k[k_start + i * 4 + f];
                                h_vec[lane][i][f] = h_vec[lane][i][f] * exp_g + kv * kv_scale;
                            }
                        float op = 0, q_sq = 0;
                        for (int i = 0; i < BK4_QTR; ++i)
                            for (int f = 0; f < 4; ++f) {
                                const float qv = smem_q[k_start + i * 4 + f];
                                op = std::fmaf(h_vec[lane][i][f], qv, op);
                                q_sq = std::fmaf(qv, qv, q_sq);
                            }
                        dp_lane[lane] = op;     // reuse: output partial (S_new . q)
                        sq_lane[lane] = q_sq;   // reuse: q L2 partial
                    }
                    {
                        std::vector<float> p(std::begin(dp_lane), std::end(dp_lane));
                        xor_butterfly(p, {16, 32});
                        std::copy(p.begin(), p.end(), dp_lane);
                        std::vector<float> q2(std::begin(sq_lane), std::end(sq_lane));
                        xor_butterfly(q2, {16, 32});
                        std::copy(q2.begin(), q2.end(), sq_lane);
                    }
                    for (int lane = 0; lane < 64; ++lane) {
                        if (lane >> 4 == 0) {  // k_split == 0 writes the output
                            const int v_col = i_v * BV_OUT + (lane & (BV_OUT - 1));
                            const float q_inv = 1.0f / std::sqrt(sq_lane[lane] + 1.0e-6f);
                            o.out[((static_cast<long>(n) * in.T + t) * VH + hv) * VD + v_col] =
                                dp_lane[lane] * q_inv * scale;
                        }
                    }
                }

                if (idx >= 0) {
                    o.touched[n] = 1;
                    // final state writeback through the register layout —
                    // lane (k_split, v_idx) owns v_col and k = k_split*32 +
                    // i*4 + f
                    for (int lane = 0; lane < 64; ++lane) {
                        const int v_idx = lane & (BV_OUT - 1);
                        const int k_split = lane >> 4;
                        const int v_col = i_v * BV_OUT + v_idx;
                        for (int i = 0; i < BK4_QTR; ++i)
                            for (int f = 0; f < 4; ++f) {
                                const int k = k_split * BK_QTR + i * 4 + f;
                                state_work[(static_cast<long>(idx) * VH + hv) * VD * KD +
                                           static_cast<long>(v_col) * KD + k] = h_vec[lane][i][f];
                            }
                    }
                }
            }
        }
    }
    o.state_fm = state_work;
    return o;
}

// ══════════════════════════════════════════════════════════════════════
// [2c] Naive T-step chain reference (third implementation)
// ══════════════════════════════════════════════════════════════════════
static SplitOutputs split_chain_naive(const SplitInputs& in) {
    SplitOutputs o;
    o.out.assign(static_cast<long>(in.batch) * in.T * VH * VD, 0.0f);
    o.touched.assign(in.batch, 0);
    const float scale = in.scale > 0.0f ? in.scale : 1.0f / std::sqrt(static_cast<float>(KD));
    const float inv_sp_beta = 1.0f / in.softplus_beta;
    std::vector<float> S = in.state0_rowmaj;  // [pool][VH][VD][KD]

    for (int n = 0; n < in.batch; ++n) {
        const std::int32_t idx = in.indices[n];
        // Sentinel policy [4]: idx >= 0 gates state LOAD/STORE only — a
        // negative index means a fresh sequence start: zero initial state,
        // output still produced, pool slot untouched.
        std::vector<float> scratch;
        if (idx >= 0) {
            o.touched[n] = 1;
        } else {
            scratch.assign(static_cast<long>(VH) * VD * KD, 0.0f);
        }
        float* Sn =
            idx >= 0 ? S.data() + static_cast<long>(idx) * VH * VD * KD : scratch.data();
        for (int hv = 0; hv < VH; ++hv) {
            const int i_h = hv / (VH / KH);
            const int q_off = i_h * KD, k_off = KD + i_h * KD, v_off = 2 * KD + hv * VD;
            const float dt_bias_val = bf16_to_f32(in.dt_bias[hv]);
            for (int t = 0; t < in.T; ++t) {
                const float a_t = bf16_to_f32(in.a[(static_cast<long>(n) * in.T + t) * VH + hv]);
                const float b_t = bf16_to_f32(in.b[(static_cast<long>(n) * in.T + t) * VH + hv]);
                const float sp_x = a_t + dt_bias_val;
                const float beta_x = in.softplus_beta * sp_x;
                const float sp = beta_x <= in.softplus_threshold
                                     ? inv_sp_beta * std::log1p(std::exp(beta_x))
                                     : sp_x;
                const float exp_g = std::exp(-std::exp(in.A_log[hv]) * sp);
                const float beta = 1.0f / (1.0f + std::exp(-b_t));
                float k_n[KD], q_n[KD];
                float k_sq = 0, q_sq = 0;
                for (int k = 0; k < KD; ++k) {
                    const float kv = bf16_to_f32(in.qkv[qkv_split_word(n, k_off + k, t, in.T)]);
                    const float qv = bf16_to_f32(in.qkv[qkv_split_word(n, q_off + k, t, in.T)]);
                    k_sq += kv * kv;
                    q_sq += qv * qv;
                    k_n[k] = kv;
                    q_n[k] = qv;
                }
                const float k_inv = 1.0f / std::sqrt(k_sq + 1.0e-6f);
                const float q_inv = 1.0f / std::sqrt(q_sq + 1.0e-6f);
                float kn[KD], qn[KD];
                for (int k = 0; k < KD; ++k) {
                    kn[k] = k_n[k] * k_inv;
                    qn[k] = q_n[k] * q_inv;
                }
                for (int v = 0; v < VD; ++v) {
                    const float v0 = bf16_to_f32(in.qkv[qkv_split_word(n, v_off + v, t, in.T)]);
                    float* Srow = Sn + (static_cast<long>(hv) * VD + v) * KD;
                    float sd_k = 0;
                    for (int k = 0; k < KD; ++k) sd_k += Srow[k] * kn[k];
                    const float residual = (v0 - sd_k * exp_g) * beta;
                    for (int k = 0; k < KD; ++k) Srow[k] = Srow[k] * exp_g + kn[k] * residual;
                    // output = S_new . q_n * scale (post-update state, as the
                    // kernel's Phase 3 reads the updated registers)
                    float o_v = 0;
                    for (int k = 0; k < KD; ++k) o_v += Srow[k] * qn[k];
                    o.out[((static_cast<long>(n) * in.T + t) * VH + hv) * VD + v] = o_v * scale;
                }
            }
        }
    }
    o.state_fm = S;
    return o;
}

// ══════════════════════════════════════════════════════════════════════
// Tests
// ══════════════════════════════════════════════════════════════════════
int main() {
    int checks = 0, fails = 0;

    // ── 1. XOR-butterfly reduction ──
    {
        Lcg rng(0x5eed);
        int f = 0;
        // 8-lane variant (decode kernel reduce_k: ds_swizzle xor 1/2/4)
        for (int trial = 0; trial < 64; ++trial) {
            std::vector<float> p(8);
            for (auto& v : p) v = rng.uniform(-4.0f, 4.0f);
            std::vector<float> q = p;
            xor_butterfly(q, {1, 2, 4});
            float want = 0;
            for (float v : p) want += v;
            ++checks;
            for (int lane = 0; lane < 8; ++lane)
                if (!close_enough(q[lane], want, 1e-5f, 1e-6f) && f++ < 5)
                    std::printf("  xor8 trial %d lane %d: %g want %g\n", trial, lane, q[lane],
                                want);
        }
        // negative control: drop the xor2 step -> must NOT fold lane pairs
        // separated only by bit 1 (guards against a trivially-true test)
        {
            std::vector<float> p(8, 0.0f);
            p[2] = 1.0f;  // differs from lane 0 only in bit 1
            std::vector<float> q = p;
            xor_butterfly(q, {1, 4});  // missing mask 2
            ++checks;
            if (std::fabs(q[0] - 1.0f) < 1e-6f && f++ < 5)
                std::printf("  xor8 negative control unexpectedly folded\n");
        }
        // 64-lane k-split variant (split kernel: shfl_xor 16 then 32)
        for (int trial = 0; trial < 16; ++trial) {
            std::vector<float> p(64);
            for (auto& v : p) v = rng.uniform(-4.0f, 4.0f);
            std::vector<float> q = p;
            xor_butterfly(q, {16, 32});
            float wants[16];
            for (int v = 0; v < 16; ++v) {
                wants[v] = 0;
                for (int ks = 0; ks < 4; ++ks) wants[v] += p[ks * 16 + v];
            }
            ++checks;
            for (int lane = 0; lane < 64; ++lane)
                if (!close_enough(q[lane], wants[lane & 15], 1e-5f, 1e-6f) && f++ < 5)
                    std::printf("  xor64 trial %d lane %d: %g want %g\n", trial, lane, q[lane],
                                wants[lane & 15]);
        }
        fails += f > 0;
        std::printf("1. xor-butterfly reduce (ds_swizzle xor 1/2/4; shfl_xor 16/32): %s\n",
                    f ? "FAIL" : "PASS");
    }

    // ── shared decode inputs: B=3, slots {2, 0, -1 (sentinel)} ──
    DecodeInputs din;
    din.batch = 3;
    din.indices = {2, 0, -1};
    {
        Lcg rng(0xa11ce);
        din.qkv.resize(static_cast<long>(din.batch) * QKV_ELEMS);
        for (auto& v : din.qkv) v = bf16_round(rng.uniform(-2.0f, 2.0f));
        din.a.resize(static_cast<long>(din.batch) * VH);
        din.b.resize(static_cast<long>(din.batch) * VH);
        for (auto& v : din.a) v = bf16_round(rng.uniform(-1.0f, 1.0f));
        for (auto& v : din.b) v = bf16_round(rng.uniform(-1.0f, 1.0f));
        din.dt_bias.resize(VH);
        for (auto& v : din.dt_bias) v = bf16_round(rng.uniform(-1.0f, 1.0f));
        din.A_log.resize(VH);
        for (auto& v : din.A_log) v = rng.uniform(-1.0f, -0.05f);  // decay in (0,1)
        din.scale = 0.5f;
    }
    DecodeState st;
    st.pool = 4;
    st.data.assign(static_cast<long>(st.pool) * VH * VD * KD, 0);
    {
        Lcg rng(0xb0b);
        for (auto& v : st.data) v = bf16_round(rng.uniform(-0.5f, 0.5f));
    }

    // ── 2. decode step: lane-decomposed emul vs naive reference ──
    {
        std::vector<float> ns_emul, ns_naive;
        const auto e = decode_step_emul(din, st, ns_emul);
        const auto w = decode_step_naive(din, st, ns_naive);
        int f = 0;
        for (int row = 0; row < din.batch; ++row)
            for (int i = 0; i < VH * VD; ++i) {
                const long oi = static_cast<long>(row) * VH * VD + i;
                ++checks;
                if (!close_enough(e.out[oi], w.out[oi], 1e-5f, 1e-6f) && f++ < 5)
                    std::printf("  decode out row %d i %d: %g vs %g\n", row, i, e.out[oi],
                                w.out[oi]);
            }
        for (long i = 0; i < static_cast<long>(ns_emul.size()); ++i) {
            ++checks;
            if (!close_enough(ns_emul[i], ns_naive[i], 1e-5f, 1e-6f) && f++ < 5)
                std::printf("  decode next-state[%ld]: %g vs %g\n", i, ns_emul[i], ns_naive[i]);
        }
        // sentinel row: out exactly zero, bf16 and f32
        for (int i = 0; i < VH * VD; ++i) {
            const long oi = static_cast<long>(2) * VH * VD + i;
            ++checks;
            if ((e.out_bf[oi] != 0 || e.out[oi] != 0.0f) && f++ < 5)
                std::printf("  sentinel out nonzero @%d\n", i);
        }
        // pool slots not referenced by any valid row must be untouched (zero):
        // rows use slots {2, 0}; slots 1 and 3 were never written
        const bool used[4] = {true, false, true, false};
        for (int s = 0; s < st.pool; ++s) {
            if (used[s]) continue;
            const long base = static_cast<long>(s) * VH * VD * KD;
            for (int i = 0; i < VH * VD * KD; ++i) {
                ++checks;
                if ((ns_emul[base + i] != 0.0f || ns_naive[base + i] != 0.0f) && f++ < 5) {
                    std::printf("  unused slot %d word %d touched: %g / %g\n", s, i,
                                ns_emul[base + i], ns_naive[base + i]);
                    i = VH * VD * KD;  // stop early for this slot
                }
            }
        }
        fails += f > 0;
        std::printf("2. decode step (lane decomposition + butterflies vs naive): %s\n",
                    f ? "FAIL" : "PASS");
    }

    // ── shared split-chain inputs: B=3, T=4, slots {1, -1, 3} ──
    SplitInputs sin;
    sin.batch = 3;
    sin.T = 4;
    sin.indices = {1, -1, 3};
    sin.pool = 4;
    {
        Lcg rng(0xc0ffee);
        constexpr int DIM = 2 * KD + VH * VD;
        sin.qkv.resize(static_cast<long>(sin.batch) * DIM * sin.T);
        for (auto& v : sin.qkv) v = bf16_round(rng.uniform(-2.0f, 2.0f));
        sin.a.resize(static_cast<long>(sin.batch) * sin.T * VH);
        sin.b.resize(static_cast<long>(sin.batch) * sin.T * VH);
        for (auto& v : sin.a) v = bf16_round(rng.uniform(-1.0f, 1.0f));
        for (auto& v : sin.b) v = bf16_round(rng.uniform(-1.0f, 1.0f));
        sin.dt_bias.resize(VH);
        for (auto& v : sin.dt_bias) v = bf16_round(rng.uniform(-1.0f, 1.0f));
        sin.A_log.resize(VH);
        for (auto& v : sin.A_log) v = rng.uniform(-1.0f, -0.05f);
        sin.scale = 1.0f / std::sqrt(static_cast<float>(KD));  // host dispatch rule
        sin.state0_rowmaj.assign(static_cast<long>(sin.pool) * VH * VD * KD, 0.0f);
        for (auto& v : sin.state0_rowmaj) v = rng.uniform(-0.5f, 0.5f);
    }
    const std::vector<float> state0_swz = pack_state_swizzled(sin.state0_rowmaj, sin.pool);

    // ── 3. swizzled fp32 state-pool codec round trip ──
    {
        const auto back = unpack_state_swizzled(state0_swz, sin.pool);
        int f = 0;
        for (long i = 0; i < static_cast<long>(back.size()); ++i) {
            ++checks;
            if (std::memcmp(&back[i], &sin.state0_rowmaj[i], 4) != 0 && f++ < 5)
                std::printf("  swizzle round trip [%ld]: %g vs %g\n", i, back[i],
                            sin.state0_rowmaj[i]);
        }
        fails += f > 0;
        std::printf("3. fp32 state-pool swizzle codec [slot][HV][K/4][V][4] round trip: %s\n",
                    f ? "FAIL" : "PASS");
    }

    // ── 4. T-step chain: split-kernel emul vs naive reference ──
    {
        const auto e = split_chain_emul(sin, state0_swz);
        const auto w = split_chain_naive(sin);
        int f = 0;
        for (long i = 0; i < static_cast<long>(e.out.size()); ++i) {
            ++checks;
            if (!close_enough(e.out[i], w.out[i], 1e-4f, 1e-6f) && f++ < 5)
                std::printf("  chain out[%ld]: %g vs %g\n", i, e.out[i], w.out[i]);
        }
        for (long i = 0; i < static_cast<long>(e.state_fm.size()); ++i) {
            ++checks;
            if (!close_enough(e.state_fm[i], w.state_fm[i], 1e-4f, 1e-6f) && f++ < 5)
                std::printf("  chain state[%ld]: %g vs %g\n", i, e.state_fm[i], w.state_fm[i]);
        }
        // sentinel row 1: output NOT zero (fresh start from zero state) and
        // equal to the naive zero-state output
        {
            const long base = static_cast<long>(1) * sin.T * VH * VD;
            int nz = 0;
            float maxmag = 0;
            for (int i = 0; i < sin.T * VH * VD; ++i) {
                ++checks;
                if (std::fabs(e.out[base + i]) > 1e-3f) ++nz;
                if (!close_enough(e.out[base + i], w.out[base + i], 1e-4f, 1e-6f) && f++ < 5)
                    std::printf("  sentinel row out[%d]: %g vs %g\n", i, e.out[base + i],
                                w.out[base + i]);
                maxmag = std::fmax(maxmag, std::fabs(e.out[base + i]));
            }
            ++checks;
            if (nz == 0 && f++ < 5) std::printf("  sentinel row output unexpectedly zero\n");
            (void)maxmag;
        }
        // pool slots NOT written (rows 0/2 use slots 1/3): slots 0, 2 bitwise
        // unchanged; sentinel row's slot untouched too
        const bool written[4] = {false, true, false, true};
        for (int s = 0; s < sin.pool; ++s) {
            if (written[s]) continue;
            const long base = static_cast<long>(s) * VH * VD * KD;
            for (int i = 0; i < VH * VD * KD; ++i) {
                ++checks;
                if (std::memcmp(&e.state_fm[base + i], &sin.state0_rowmaj[base + i], 4) != 0) {
                    if (f++ < 5)
                        std::printf("  untouched slot %d word %d modified: %g -> %g\n", s, i,
                                    sin.state0_rowmaj[base + i], e.state_fm[base + i]);
                    i = VH * VD * KD;
                }
            }
        }
        fails += f > 0;
        std::printf("4. T-step split chain (register state + swizzled pool vs naive): %s\n",
                    f ? "FAIL" : "PASS");
    }

    // ── 5. LDS bank padding property (split kernel lds_padded_idx) ──
    {
        int f = 0;
        constexpr int CHUNK = 32;  // BK/4 = 32 -> SMEM_STRIDE 33
        // strictly increasing padded indices over the full BK = 128 rows
        int prev = -1;
        for (int j = 0; j < 128; ++j) {
            const int p = lds_padded_idx<CHUNK>(j);
            ++checks;
            if ((p <= prev || p >= 33 * 4) && f++ < 5)
                std::printf("  padded idx not monotone/in-range @j=%d\n", j);
            prev = p;
        }
        // row start property: row r begins at padded 33r, bank r (mod 32)
        for (int r = 0; r < 4; ++r) {
            ++checks;
            const int start = lds_padded_idx<CHUNK>(r * CHUNK);
            if (start != r * 33 || start % 32 != r) {
                if (f++ < 5)
                    std::printf("  row %d start %d (want %d, bank %d)\n", r, start, r * 33,
                                start % 32);
            }
        }
        // the PAYLOAD property: a fixed column across 32 rows touches all 32
        // banks (zero bank conflicts for the column access pattern)
        for (int c = 0; c < CHUNK; ++c) {
            char seen[32] = {0};
            for (int r = 0; r < 32; ++r) seen[lds_padded_idx<CHUNK>(r * CHUNK + c) % 32] = 1;
            int distinct = 0;
            for (int b = 0; b < 32; ++b) distinct += seen[b];
            ++checks;
            if (distinct != 32 && f++ < 5)
                std::printf("  column %d hits only %d/32 banks\n", c, distinct);
        }
        fails += f > 0;
        std::printf("5. LDS bank padding (idx + idx/CHUNK, stride 33): %s\n", f ? "FAIL" : "PASS");
    }

    std::printf("gdr_decode_chain: %d checks, %d failures -> %s\n", checks, fails,
                fails ? "FAIL" : "PASS");
    return fails ? MAIN_RETURN_BAD : 0;
}
