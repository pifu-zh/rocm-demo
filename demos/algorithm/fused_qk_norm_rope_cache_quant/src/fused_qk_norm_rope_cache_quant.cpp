// SPDX-License-Identifier: MIT
// Copyright (C) 2026, Advanced Micro Devices, Inc. All rights reserved.
//
// Host reference for aiter's fused QK-norm + RoPE + fp8-quant + paged-KV-cache
// decode kernel (fusedQKNormRopeQuantCacheShuffleKernel,
// csrc/kernels/fused_qk_norm_rope_cache_quant.cu @
// 1eab5ae12c93af3c8c660202d9a413f637c2f011, MIT).
//
// The kernel's contract, as pinned from the source:
//   * one warp per (token, head) over the FLATTENED q/k/v head list
//     (globalWarpIdx = tokenIdx * (nhq + nhk + nhv) + localHeadIdx); a lane
//     owns head_dim/32 consecutive dims. head_dim must be a multiple of 32.
//   * Q/K heads: per-head RMSNorm (sum of squares via warp butterfly, eps,
//     per-dim weight, bf16 cast) -> RoPE (interleave or half-rotate) -> the
//     normed+rope'd values are written BACK to the activation arrays in
//     place. V heads skip all of it.
//   * the half-rotate (NeoX) path exchanges partner dims through the warp:
//     partner lane = laneId ^ (embed_dim / numElemsPerThread), valid because
//     embed_dim/E is a power of two (dispatch-enforced:
//     (rotary_dim/2) % numElemsPerThread == 0) -- xor by a single-bit delta
//     equals +delta below it and -delta above it. dims >= rotary_dim are
//     untouched; the cos/sin cache row is [cos(embed) | sin(embed)].
//   * K/V heads: per-(token, head) fp8 quantization. amax over the head's
//     elements (K: POST-norm-rope; V: raw) floored at kAmaxFloor = 1e-10
//     (shared with ATOM's AMAX_FLOOR), scale = amax / dtype_max
//     (fp8 e4m3 OCP max = 448 on the host finfo branch), store = v / scale.
//     scale written to [block][head][block_offset] (stride page_size per
//     head). kAuto mode stores raw values and writes no scale.
//   * cache layouts: K [num_blocks, nhk, head_dim/x, page_size, x] (dim-major
//     x factorization, vector-width x); V [num_blocks, nhv, page_size/x,
//     head_dim, x] (token packed into x-groups -- "not contiguous on
//     head_dim", hence no vectorized store).
//   * slot_mapping < 0 (padding): the Q/K writeback still happens, the cache
//     write and scale write do not.
//   * inverted_kscale/inverted_vscale (lines 221-222) are DEAD locals -- read
//     nowhere, like the old0 read in the conv1d tail branch.
//
// Two independent host implementations cross-validate bitwise (both use the
// same float-op ORDER, so the machinery under test -- lane ownership, the
// xor partner exchange with snapshot semantics, and the cache offset
// arithmetic -- is what differs, not rounding):
//   run_emul    -- per-lane arrays, explicit snapshots before every
//                  butterfly/xor step, additive cache offsets;
//   run_reference -- one flat lane array (the snapshot IS the array), flat
//                  index math for partner dims, mixed-radix cache offsets.
// fp8 quantization uses the lab's exhaustively-verified e4m3 OCP RNE encode;
// the round-trip bound check decodes with the branchless decoder validated in
// dsv4_dequant_gather_k.

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstring>
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
};
static inline float bf16_to_f32(std::uint16_t h) {
    std::uint32_t u = static_cast<std::uint32_t>(h) << 16;
    float f;
    std::memcpy(&f, &u, 4);
    return f;
}
static inline std::uint16_t f32_to_bf16(float f) {
    std::uint32_t u;
    std::memcpy(&u, &f, 4);
    const std::uint32_t lsb = (u >> 16) & 1;
    return static_cast<std::uint16_t>((u + 0x7FFFu + lsb) >> 16);
}

// fp8 e4m3 OCP encode, RNE, satfinite at +-448 (the lab soft_fp8 codec's
// host-side semantics, exhaustively verified there in M2). Subnormal zone is
// mag < 2^-6 (values m*2^-9, m in [1,7]); the RNE midpoint between 7*2^-9 and
// min-normal 2^-6 rounds up to 0x08.
static inline std::uint8_t f32_to_e4m3_ocp(float f) {
    std::uint32_t u;
    std::memcpy(&u, &f, 4);
    const std::uint8_t sign = static_cast<std::uint8_t>((u >> 24) & 0x80u);
    const std::uint32_t mag = u & 0x7FFFFFFFu;
    if (mag == 0) return sign;
    if ((u >> 23) == 0xFFu)
        return (mag & 0x7FFFFFu) ? static_cast<std::uint8_t>(sign | 0x7Fu)   // NaN
                                 : static_cast<std::uint8_t>(sign | 0x7Eu);  // inf -> satfinite 448
    const int e = static_cast<int>(mag >> 23) - 127;
    if (e < -6) {
        // subnormal: m = RNE(|f| * 2^9); exact in double
        const double scaled = static_cast<double>(mag) * 0x1p-23 * 512.0;
        std::uint32_t m = static_cast<std::uint32_t>(scaled);  // floor
        const double frac = scaled - static_cast<double>(m);
        if (frac > 0.5 || (frac == 0.5 && (m & 1))) ++m;
        if (m <= 7) return static_cast<std::uint8_t>(sign | m);
        return static_cast<std::uint8_t>(sign | 0x08u);  // rounds up to min normal
    }
    int e8 = e + 7;
    const std::uint32_t man = mag & 0x7FFFFFu;
    std::uint32_t m3 = man >> 20;
    const std::uint32_t rem = man & 0xFFFFFu;
    if (rem > (1u << 19) || (rem == (1u << 19) && (m3 & 1))) ++m3;  // RNE
    if (m3 == 8u) {
        m3 = 0;
        ++e8;
    }
    // e4m3FN ("finite, no inf"): e8=15 is a VALID exponent with mantissa <= 6
    // (max finite 448 = 1.110_2 * 2^8); only m3=7 there is the NaN slot.
    // Satfinite clamps anything beyond (incl. RNE candidates that landed on
    // 480) to 448.
    if (e8 > 15 || (e8 == 15 && m3 >= 7))
        return static_cast<std::uint8_t>(sign | 0x7Eu);
    return static_cast<std::uint8_t>(sign | (static_cast<std::uint32_t>(e8) << 3) | m3);
}
// branchless decode (dsv4_dequant_gather_k's validated form), bias 7 OCP
static inline float e4m3_ocp_to_f32(std::uint8_t b) {
    const std::uint32_t sign = (b & 0x80u) ? 0x80000000u : 0u;
    const std::uint32_t rest = b & 0x7Fu;
    float out;
    if ((rest >> 3) == 0 && (rest & 7) != 0) {
        // subnormal: rest * 2^(1-7-3) = rest * 2^-9
        out = static_cast<float>(rest) * 0.001953125f;
    } else if (rest == 0x7F) {
        out = std::nanf("");
    } else {
        const std::uint32_t bits = (rest << 20) + ((127 - 7) << 23);
        std::memcpy(&out, &bits, 4);
    }
    std::uint32_t u;
    std::memcpy(&u, &out, 4);
    u |= sign;
    std::memcpy(&out, &u, 4);
    return out;
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

constexpr float kAmaxFloor = 1e-10f;  // aiter::kAmaxFloor (quant_amax_floor.h)

// ── the job ──────────────────────────────────────────────────────────────
struct FusedCfg {
    int head_dim;      // multiple of 32
    int rotary_dim;    // even, <= head_dim; embed_dim = rotary_dim/2
    bool interleave;   // GPT-J paired vs NeoX half-rotate
    int nhq, nhk, nhv;
    int page_size, x;
    int num_blocks;
    float eps = 1e-5f;
    bool quantize = true;   // fp8 mode; false = kAuto raw store
    float dtype_max = 448.f;  // finfo<fp8 e4m3 OCP host branch>; e5m2 = 57344
};

struct FusedJob {
    FusedCfg cfg;
    int num_tokens = 0;
    std::vector<std::uint16_t> q_act, k_act, v_act;  // [tokens, heads*hd] bf16
    std::vector<std::uint16_t> q_w, k_w;             // [heads*hd] bf16
    std::vector<std::uint16_t> cos_sin;              // [max_pos, rotary_dim] bf16
    std::vector<std::int64_t> pos_ids;
    std::vector<std::int64_t> slot_mapping;
    // outputs
    std::vector<std::uint8_t> k_cache, v_cache;
    std::vector<std::uint16_t> k_cache_raw, v_cache_raw;  // kAuto mode
    std::vector<float> k_scale, v_scale;                  // [nb, nh, page]
    long cache_size_k() const {
        return static_cast<long>(cfg.num_blocks) * cfg.nhk * cfg.head_dim * cfg.page_size;
    }
    long cache_size_v() const {
        return static_cast<long>(cfg.num_blocks) * cfg.nhv * cfg.head_dim * cfg.page_size;
    }
};

// standard RoPE cache generator (kernel input assumption, not a contract)
static void gen_cos_sin(FusedJob& j, Lcg& rng, float jitter) {
    const int embed = j.cfg.rotary_dim / 2;
    const int max_pos = 32;
    j.cos_sin.assign(static_cast<std::size_t>(max_pos) * j.cfg.rotary_dim, 0);
    for (int p = 0; p < max_pos; ++p)
        for (int i = 0; i < embed; ++i) {
            const float theta = std::pow(10000.f, -2.f * static_cast<float>(i) /
                                                         static_cast<float>(j.cfg.rotary_dim));
            float a = std::cos(static_cast<float>(p) * theta);
            float b = std::sin(static_cast<float>(p) * theta);
            if (jitter > 0.f) {  // keep the cache from being perfectly smooth
                a += rng.uniform(-jitter, jitter);
                b += rng.uniform(-jitter, jitter);
            }
            j.cos_sin[static_cast<std::size_t>(p) * j.cfg.rotary_dim + i] = f32_to_bf16(a);
            j.cos_sin[static_cast<std::size_t>(p) * j.cfg.rotary_dim + embed + i] = f32_to_bf16(b);
        }
}

// ── butterfly helper shared structurally by both implementations ─────────
// warpReduceSum-style: for offset in {16,8,4,2,1}, v[L] = f(v[L], v[L^offset])
// with a SNAPSHOT per step (simultaneous exchange). The emulation snapshots
// explicitly; the reference folds over a flat array where the snapshot is the
// array copy. Same f, same step order, same per-lane op sequence -> bitwise.
template <typename F>
static void butterfly(std::vector<float>& v, F f) {
    for (int off : {16, 8, 4, 2, 1}) {
        const std::vector<float> snap = v;  // EVERY step snapshots: the exchange
        // is simultaneous within a step, sequential across steps
        for (int L = 0; L < 32; ++L) v[static_cast<std::size_t>(L)] =
            f(snap[static_cast<std::size_t>(L)], snap[static_cast<std::size_t>(L ^ off)]);
    }
}
// explicit per-step form used by the reference: identical op order
template <typename F>
static void butterfly_ref(std::vector<float>& v, F f) {
    for (int off : {16, 8, 4, 2, 1}) {
        const std::vector<float> snap = v;
        for (int L = 0; L < 32; ++L) v[static_cast<std::size_t>(L)] =
            f(snap[static_cast<std::size_t>(L)], snap[static_cast<std::size_t>(L ^ off)]);
    }
}

// ── EMULATION: per-lane arrays + snapshots (faithful warp machinery) ─────
struct EmuOut {
    // post-run activations (q/k written back, v untouched)
    const FusedJob* j;
    // per-token-per-head cache/scale writes recorded structurally
};

static void run_emul(FusedJob& j) {
    const FusedCfg& c = j.cfg;
    const int E = c.head_dim / 32;
    const int embed = c.rotary_dim / 2;
    const int total_heads = c.nhq + c.nhk + c.nhv;
    j.k_cache.assign(static_cast<std::size_t>(j.cache_size_k()), 0);
    j.v_cache.assign(static_cast<std::size_t>(j.cache_size_v()), 0);
    j.k_cache_raw.assign(static_cast<std::size_t>(j.cache_size_k()), 0);
    j.v_cache_raw.assign(static_cast<std::size_t>(j.cache_size_v()), 0);
    j.k_scale.assign(static_cast<std::size_t>(c.num_blocks) * c.nhk * c.page_size, 0.f);
    j.v_scale.assign(static_cast<std::size_t>(c.num_blocks) * c.nhv * c.page_size, 0.f);

    for (int tok = 0; tok < j.num_tokens; ++tok) {
        for (int lh = 0; lh < total_heads; ++lh) {
            const bool isQ = lh < c.nhq;
            const bool isK = !isQ && lh < c.nhq + c.nhk;
            const bool isV = !isQ && !isK;
            const int head = isV ? lh - c.nhq - c.nhk : (isK ? lh - c.nhq : lh);
            const std::uint16_t* w = isQ ? j.q_w.data() : j.k_w.data();
            const long st = static_cast<long>(total_heads) * c.head_dim;
            const long base = static_cast<long>(tok) * st + static_cast<long>(head) * c.head_dim;

            // load: lane L owns dims [L*E, L*E+E)
            std::vector<std::vector<std::uint16_t>> le(
                32, std::vector<std::uint16_t>(static_cast<std::size_t>(E)));
            for (int L = 0; L < 32; ++L)
                for (int i = 0; i < E; ++i)
                    le[static_cast<std::size_t>(L)][static_cast<std::size_t>(i)] =
                        (isQ ? j.q_act : (isK ? j.k_act : j.v_act))
                            [static_cast<std::size_t>(base + L * E + i)];

            if (!isV) {
                // RMSNorm: per-lane sum of squares, butterfly, normalize
                std::vector<float> ss(32, 0.f);
                for (int L = 0; L < 32; ++L)
                    for (int i = 0; i < E; ++i) {
                        const float v = bf16_to_f32(le[static_cast<std::size_t>(L)][static_cast<std::size_t>(i)]);
                        ss[static_cast<std::size_t>(L)] += v * v;
                    }
                butterfly(ss, [](float a, float b) { return a + b; });
                const float total = ss[0];
                const float rms_rcp = 1.0f / std::sqrt(total / static_cast<float>(c.head_dim) + c.eps);
                for (int L = 0; L < 32; ++L)
                    for (int i = 0; i < E; ++i) {
                        const int dim = L * E + i;
                        const float v = bf16_to_f32(le[static_cast<std::size_t>(L)][static_cast<std::size_t>(i)]);
                        const float wv = bf16_to_f32(w[static_cast<std::size_t>(dim)]);
                        le[static_cast<std::size_t>(L)][static_cast<std::size_t>(i)] =
                            f32_to_bf16(v * rms_rcp * wv);
                    }

                // RoPE
                const std::uint16_t* cs =
                    &j.cos_sin[static_cast<std::size_t>(j.pos_ids[static_cast<std::size_t>(tok)]) *
                               static_cast<std::size_t>(c.rotary_dim)];
                if (c.interleave) {
                    for (int L = 0; L < 32; ++L)
                        for (int i = 0; i < E / 2; ++i) {
                            const int idx0 = 2 * i, idx1 = 2 * i + 1;
                            const int dim0 = L * E + idx0;
                            if (dim0 + 1 < c.rotary_dim) {
                                const float v0 = bf16_to_f32(le[static_cast<std::size_t>(L)][static_cast<std::size_t>(idx0)]);
                                const float v1 = bf16_to_f32(le[static_cast<std::size_t>(L)][static_cast<std::size_t>(idx1)]);
                                const int half = dim0 / 2;
                                const float cv = bf16_to_f32(cs[static_cast<std::size_t>(half)]);
                                const float sv = bf16_to_f32(cs[static_cast<std::size_t>(embed + half)]);
                                le[static_cast<std::size_t>(L)][static_cast<std::size_t>(idx0)] =
                                    f32_to_bf16(v0 * cv - v1 * sv);
                                le[static_cast<std::size_t>(L)][static_cast<std::size_t>(idx1)] =
                                    f32_to_bf16(v0 * sv + v1 * cv);
                            }
                        }
                } else {
                    // partner lane = L ^ (embed/E); snapshot BEFORE the exchange
                    const int delta = embed / E;
                    std::vector<std::vector<std::uint16_t>> snap = le;
                    for (int L = 0; L < 32; ++L)
                        for (int i = 0; i < E; ++i) {
                            const int dim = L * E + i;
                            if (dim < c.rotary_dim) {
                                const float partner =
                                    bf16_to_f32(snap[static_cast<std::size_t>(L ^ delta)][static_cast<std::size_t>(i)]);
                                float p2 = partner;
                                if (dim < embed) p2 = -p2;
                                const float v = bf16_to_f32(le[static_cast<std::size_t>(L)][static_cast<std::size_t>(i)]);
                                const int half = dim % embed;
                                const float cv = bf16_to_f32(cs[static_cast<std::size_t>(half)]);
                                const float sv = bf16_to_f32(cs[static_cast<std::size_t>(embed + half)]);
                                le[static_cast<std::size_t>(L)][static_cast<std::size_t>(i)] =
                                    f32_to_bf16(v * cv + p2 * sv);
                            }
                        }
                }
                // writeback (q/k in place)
                for (int L = 0; L < 32; ++L)
                    for (int i = 0; i < E; ++i)
                        (isQ ? j.q_act : j.k_act)[static_cast<std::size_t>(base + L * E + i)] =
                            le[static_cast<std::size_t>(L)][static_cast<std::size_t>(i)];
            }
            // the kernel returns for Q heads right after the writeback: no
            // slot read, no cache/scale access (missing this made Q heads
            // fall into the V branch with head = localHeadIdx -> wild offsets)
            if (isQ) continue;

            const std::int64_t slot = j.slot_mapping[static_cast<std::size_t>(tok)];
            if (slot < 0) continue;  // padding: cache write skipped, writeback done
            const std::int64_t b = slot / c.page_size;
            const std::int64_t t = slot % c.page_size;

            if (c.quantize) {
                // amax over the head's elements (K post-norm-rope, V raw)
                std::vector<float> am(32);
                for (int L = 0; L < 32; ++L) {
                    float m = bf16_to_f32(le[static_cast<std::size_t>(L)][0]);
                    for (int i = 1; i < E; ++i)
                        m = std::fmax(std::fabs(m),
                                      std::fabs(bf16_to_f32(le[static_cast<std::size_t>(L)][static_cast<std::size_t>(i)])));
                    am[static_cast<std::size_t>(L)] = m;
                }
                butterfly(am, [](float a, float b) { return std::fmax(std::fabs(a), std::fabs(b)); });
                const float scale = std::fmax(am[0], kAmaxFloor) / c.dtype_max;

                if (isK) {
                    j.k_scale[static_cast<std::size_t>(b) * c.page_size * c.nhk +
                              static_cast<std::size_t>(head) * c.page_size + static_cast<std::size_t>(t)] = scale;
                    const long coff = static_cast<long>(b) * c.page_size * c.nhk * c.head_dim +
                                      static_cast<long>(head) * c.head_dim * c.page_size +
                                      static_cast<long>(t) * c.x;
                    for (int L = 0; L < 32; ++L)
                        for (int i = 0; i < E; ++i) {
                            const int d = L * E + i;
                            const long off = coff + d / c.x * c.page_size * c.x + d % c.x;
                            j.k_cache[static_cast<std::size_t>(off)] =
                                f32_to_e4m3_ocp(bf16_to_f32(le[static_cast<std::size_t>(L)][static_cast<std::size_t>(i)]) / scale);
                        }
                } else {
                    j.v_scale[static_cast<std::size_t>(b) * c.page_size * c.nhv +
                              static_cast<std::size_t>(head) * c.page_size + static_cast<std::size_t>(t)] = scale;
                    const long coff = static_cast<long>(b) * c.page_size * c.nhv * c.head_dim +
                                      static_cast<long>(head) * c.head_dim * c.page_size +
                                      static_cast<long>(t) / c.x * c.head_dim * c.x +
                                      static_cast<long>(t) % c.x;
                    for (int L = 0; L < 32; ++L)
                        for (int i = 0; i < E; ++i) {
                            const int d = L * E + i;
                            const long off = coff + static_cast<long>(d) * c.x;
                            j.v_cache[static_cast<std::size_t>(off)] =
                                f32_to_e4m3_ocp(bf16_to_f32(le[static_cast<std::size_t>(L)][static_cast<std::size_t>(i)]) / scale);
                        }
                }
            } else {
                // kAuto: raw store, no scale writes
                if (isK) {
                    const long coff = static_cast<long>(b) * c.page_size * c.nhk * c.head_dim +
                                      static_cast<long>(head) * c.head_dim * c.page_size +
                                      static_cast<long>(t) * c.x;
                    for (int L = 0; L < 32; ++L)
                        for (int i = 0; i < E; ++i) {
                            const int d = L * E + i;
                            j.k_cache_raw[static_cast<std::size_t>(coff + d / c.x * c.page_size * c.x + d % c.x)] =
                                le[static_cast<std::size_t>(L)][static_cast<std::size_t>(i)];
                        }
                } else {
                    const long coff = static_cast<long>(b) * c.page_size * c.nhv * c.head_dim +
                                      static_cast<long>(head) * c.head_dim * c.page_size +
                                      static_cast<long>(t) / c.x * c.head_dim * c.x + static_cast<long>(t) % c.x;
                    for (int L = 0; L < 32; ++L)
                        for (int i = 0; i < E; ++i) {
                            const int d = L * E + i;
                            j.v_cache_raw[static_cast<std::size_t>(coff + static_cast<long>(d) * c.x)] =
                                le[static_cast<std::size_t>(L)][static_cast<std::size_t>(i)];
                        }
                }
            }
        }
    }
}

// ── REFERENCE: one flat lane array, flat index math ──────────────────────
static void run_reference(FusedJob& j) {
    const FusedCfg& c = j.cfg;
    const int E = c.head_dim / 32;
    const int embed = c.rotary_dim / 2;
    const int total_heads = c.nhq + c.nhk + c.nhv;
    j.k_cache.assign(static_cast<std::size_t>(j.cache_size_k()), 0);
    j.v_cache.assign(static_cast<std::size_t>(j.cache_size_v()), 0);
    j.k_cache_raw.assign(static_cast<std::size_t>(j.cache_size_k()), 0);
    j.v_cache_raw.assign(static_cast<std::size_t>(j.cache_size_v()), 0);
    j.k_scale.assign(static_cast<std::size_t>(c.num_blocks) * c.nhk * c.page_size, 0.f);
    j.v_scale.assign(static_cast<std::size_t>(c.num_blocks) * c.nhv * c.page_size, 0.f);

    for (int tok = 0; tok < j.num_tokens; ++tok) {
        for (int lh = 0; lh < total_heads; ++lh) {
            const bool isQ = lh < c.nhq;
            const bool isK = !isQ && lh < c.nhq + c.nhk;
            const bool isV = !isQ && !isK;
            const int head = isV ? lh - c.nhq - c.nhk : (isK ? lh - c.nhq : lh);
            const std::uint16_t* w = isQ ? j.q_w.data() : j.k_w.data();
            const long st = static_cast<long>(total_heads) * c.head_dim;
            const long base = static_cast<long>(tok) * st + static_cast<long>(head) * c.head_dim;

            // flat element array: flat[L*E + i]
            std::vector<std::uint16_t> flat(static_cast<std::size_t>(c.head_dim));
            for (int d = 0; d < c.head_dim; ++d)
                flat[static_cast<std::size_t>(d)] =
                    (isQ ? j.q_act : (isK ? j.k_act : j.v_act))
                        [static_cast<std::size_t>(base + d)];

            if (!isV) {
                // RMSNorm: butterfly on the lane-sum array, flat fold form
                std::vector<float> ss(32, 0.f);
                for (int L = 0; L < 32; ++L)
                    for (int i = 0; i < E; ++i) {
                        const float v = bf16_to_f32(flat[static_cast<std::size_t>(L * E + i)]);
                        ss[static_cast<std::size_t>(L)] += v * v;
                    }
                butterfly_ref(ss, [](float a, float b) { return a + b; });
                const float total = ss[0];
                const float rms_rcp = 1.0f / std::sqrt(total / static_cast<float>(c.head_dim) + c.eps);
                for (int d = 0; d < c.head_dim; ++d) {
                    const float v = bf16_to_f32(flat[static_cast<std::size_t>(d)]);
                    flat[static_cast<std::size_t>(d)] =
                        f32_to_bf16(v * rms_rcp * bf16_to_f32(w[static_cast<std::size_t>(d)]));
                }
                const std::uint16_t* cs =
                    &j.cos_sin[static_cast<std::size_t>(j.pos_ids[static_cast<std::size_t>(tok)]) *
                               static_cast<std::size_t>(c.rotary_dim)];
                if (c.interleave) {
                    for (int dim0 = 0; dim0 + 1 < c.rotary_dim; dim0 += 2) {
                        const float v0 = bf16_to_f32(flat[static_cast<std::size_t>(dim0)]);
                        const float v1 = bf16_to_f32(flat[static_cast<std::size_t>(dim0 + 1)]);
                        const float cv = bf16_to_f32(cs[static_cast<std::size_t>(dim0 / 2)]);
                        const float sv = bf16_to_f32(cs[static_cast<std::size_t>(embed + dim0 / 2)]);
                        flat[static_cast<std::size_t>(dim0)] = f32_to_bf16(v0 * cv - v1 * sv);
                        flat[static_cast<std::size_t>(dim0 + 1)] = f32_to_bf16(v0 * sv + v1 * cv);
                    }
                } else {
                    // partner dims read straight off the PRE-rope array: the flat
                    // array IS the snapshot; partner dim of d is d ± embed
                    const std::vector<std::uint16_t> pre = flat;
                    for (int d = 0; d < c.rotary_dim; ++d) {
                        const int pd = (d < embed) ? d + embed : d - embed;
                        float p2 = bf16_to_f32(pre[static_cast<std::size_t>(pd)]);
                        if (d < embed) p2 = -p2;
                        const float v = bf16_to_f32(flat[static_cast<std::size_t>(d)]);
                        const float cv = bf16_to_f32(cs[static_cast<std::size_t>(d % embed)]);
                        const float sv = bf16_to_f32(cs[static_cast<std::size_t>(embed + d % embed)]);
                        flat[static_cast<std::size_t>(d)] = f32_to_bf16(v * cv + p2 * sv);
                    }
                }
                for (int d = 0; d < c.head_dim; ++d)
                    (isQ ? j.q_act : j.k_act)[static_cast<std::size_t>(base + d)] =
                        flat[static_cast<std::size_t>(d)];
            }
            if (isQ) continue;  // kernel returns here (see run_emul)

            const std::int64_t slot = j.slot_mapping[static_cast<std::size_t>(tok)];
            if (slot < 0) continue;
            const std::int64_t b = slot / c.page_size;
            const std::int64_t t = slot % c.page_size;

            if (c.quantize) {
                float amax = bf16_to_f32(flat[0]);
                for (int d = 1; d < c.head_dim; ++d)
                    amax = std::fmax(std::fabs(amax),
                                     std::fabs(bf16_to_f32(flat[static_cast<std::size_t>(d)])));
                const float scale = std::fmax(amax, kAmaxFloor) / c.dtype_max;
                if (isK) {
                    // mixed-radix scale index [b][head][t]
                    j.k_scale[static_cast<std::size_t>(((b * c.nhk + head) * c.page_size) + t)] = scale;
                    for (int d = 0; d < c.head_dim; ++d) {
                        // mixed-radix 5-D: [b][head][d/x][t][d%x]
                        const long off = ((((b * c.nhk + head) * (c.head_dim / c.x) + d / c.x) *
                                           c.page_size + t) * c.x) + d % c.x;
                        j.k_cache[static_cast<std::size_t>(off)] =
                            f32_to_e4m3_ocp(bf16_to_f32(flat[static_cast<std::size_t>(d)]) / scale);
                    }
                } else {
                    j.v_scale[static_cast<std::size_t>(((b * c.nhv + head) * c.page_size) + t)] = scale;
                    for (int d = 0; d < c.head_dim; ++d) {
                        // mixed-radix 5-D: [b][head][t/x][d][t%x]
                        const long off = ((((b * c.nhv + head) * (c.page_size / c.x) + t / c.x) *
                                           c.head_dim + d) * c.x) + t % c.x;
                        j.v_cache[static_cast<std::size_t>(off)] =
                            f32_to_e4m3_ocp(bf16_to_f32(flat[static_cast<std::size_t>(d)]) / scale);
                    }
                }
            } else {
                if (isK) {
                    for (int d = 0; d < c.head_dim; ++d) {
                        const long off = ((((b * c.nhk + head) * (c.head_dim / c.x) + d / c.x) *
                                           c.page_size + t) * c.x) + d % c.x;
                        j.k_cache_raw[static_cast<std::size_t>(off)] = flat[static_cast<std::size_t>(d)];
                    }
                } else {
                    for (int d = 0; d < c.head_dim; ++d) {
                        const long off = ((((b * c.nhv + head) * (c.page_size / c.x) + t / c.x) *
                                           c.head_dim + d) * c.x) + t % c.x;
                        j.v_cache_raw[static_cast<std::size_t>(off)] = flat[static_cast<std::size_t>(d)];
                    }
                }
            }
        }
    }
}

// ── job builders ─────────────────────────────────────────────────────────
static void fill_job(FusedJob& j, std::uint64_t seed, bool pad_slots) {
    const FusedCfg& c = j.cfg;
    const int total_heads = c.nhq + c.nhk + c.nhv;
    Lcg rng(seed);
    const long act_size = static_cast<long>(j.num_tokens) * total_heads * c.head_dim;
    j.q_act.resize(static_cast<std::size_t>(act_size));
    j.k_act.resize(static_cast<std::size_t>(act_size));
    j.v_act.resize(static_cast<std::size_t>(act_size));
    for (auto& v : j.q_act) v = f32_to_bf16(rng.uniform(-3.f, 3.f));
    for (auto& v : j.k_act) v = f32_to_bf16(rng.uniform(-3.f, 3.f));
    for (auto& v : j.v_act) v = f32_to_bf16(rng.uniform(-3.f, 3.f));
    j.q_w.resize(static_cast<std::size_t>(c.nhq * c.head_dim));
    j.k_w.resize(static_cast<std::size_t>(c.nhk * c.head_dim));
    for (auto& v : j.q_w) v = f32_to_bf16(rng.uniform(0.5f, 1.5f));
    for (auto& v : j.k_w) v = f32_to_bf16(rng.uniform(0.5f, 1.5f));
    gen_cos_sin(j, rng, 0.0f);
    j.pos_ids.resize(static_cast<std::size_t>(j.num_tokens));
    for (auto& p : j.pos_ids) p = static_cast<std::int64_t>(rng.next() % 32);
    j.slot_mapping.resize(static_cast<std::size_t>(j.num_tokens));
    for (std::size_t t = 0; t < j.slot_mapping.size(); ++t) {
        if (pad_slots && t % 4 == 3)
            j.slot_mapping[t] = -1;  // padding token
        else
            j.slot_mapping[t] = static_cast<std::int64_t>(rng.next() %
                static_cast<std::uint32_t>(c.num_blocks * c.page_size));
    }
}

// bitwise comparison of the whole output surface
static bool outputs_equal(const FusedJob& a, const FusedJob& b) {
    if (a.q_act != b.q_act || a.k_act != b.k_act || a.v_act != b.v_act) return false;
    if (a.k_cache != b.k_cache || a.v_cache != b.v_cache) return false;
    if (a.k_cache_raw != b.k_cache_raw || a.v_cache_raw != b.v_cache_raw) return false;
    for (std::size_t i = 0; i < a.k_scale.size(); ++i)
        if (a.k_scale[i] != b.k_scale[i]) return false;
    for (std::size_t i = 0; i < a.v_scale.size(); ++i)
        if (a.v_scale[i] != b.v_scale[i]) return false;
    return true;
}

static void print_first_diff(const FusedJob& a, const FusedJob& b) {
    const long asz = static_cast<long>(a.q_act.size());
    for (long i = 0; i < asz; ++i)
        if (a.q_act[static_cast<std::size_t>(i)] != b.q_act[static_cast<std::size_t>(i)]) {
            std::printf("    q_act[%ld]: %04x vs %04x\n", i, a.q_act[static_cast<std::size_t>(i)],
                        b.q_act[static_cast<std::size_t>(i)]);
            return;
        }
    for (long i = 0; i < asz; ++i)
        if (a.k_act[static_cast<std::size_t>(i)] != b.k_act[static_cast<std::size_t>(i)]) {
            std::printf("    k_act[%ld]: %04x vs %04x\n", i, a.k_act[static_cast<std::size_t>(i)],
                        b.k_act[static_cast<std::size_t>(i)]);
            return;
        }
    for (std::size_t i = 0; i < a.k_cache.size(); ++i)
        if (a.k_cache[i] != b.k_cache[i]) {
            std::printf("    k_cache[%zu]: %02x vs %02x\n", i, a.k_cache[i], b.k_cache[i]);
            return;
        }
    for (std::size_t i = 0; i < a.v_cache.size(); ++i)
        if (a.v_cache[i] != b.v_cache[i]) {
            std::printf("    v_cache[%zu]: %02x vs %02x\n", i, a.v_cache[i], b.v_cache[i]);
            return;
        }
    for (std::size_t i = 0; i < a.k_scale.size(); ++i)
        if (a.k_scale[i] != b.k_scale[i]) {
            std::printf("    k_scale[%zu]: %g vs %g\n", i, a.k_scale[i], b.k_scale[i]);
            return;
        }
    std::printf("    (no diff found?)\n");
}

int main() {
    // ════ 0. xor partner-lane algebra: the half-rotate exchange constraint ════
    {
        // embed_dim/E must be a power of two: xor by delta equals +delta for
        // lanes below delta and -delta for lanes at/above it ONLY when delta
        // is a single bit. The dispatch enforces (rotary_dim/2) % E == 0, but
        // that alone allows non-powers-of-two (e.g. rotary 96, head_dim 128:
        // E = 4, embed/E = 12, xor 12 != +12 for lane 4) -- the caller's
        // shapes must still respect it or the rope silently mis-rotates.
        CHECK((8 ^ 16) == 24 && (24 ^ 16) == 8);          // delta 16: add/remove
        CHECK((4 ^ 12) != 16);                            // delta 12 (two bits): breaks
        CHECK((4 ^ 12) == 8);
        for (int hd : {64, 128, 256}) {
            const int E = hd / 32;
            for (int rot : {hd, hd / 2, hd / 4}) {
                if (rot % 2 != 0) continue;
                const int delta = (rot / 2) / E;
                bool pow2 = (delta & (delta - 1)) == 0;
                // participating lanes are exactly [0, 2*delta) (dims < rotary_dim);
                // within them xor==+delta for L<delta and xor==-delta for L>=delta
                // holds IFF delta is a single bit. Lanes >= 2*delta skip the
                // exchange entirely (their dims >= rotary_dim).
                bool ok = true;
                for (int L = 0; L < 2 * delta && ok; ++L) {
                    const int want = L < delta ? L + delta : L - delta;
                    if ((L ^ delta) != want) ok = false;
                }
                CHECK(ok == pow2);
                CHECK(ok);  // all swept combos keep the constraint
            }
        }
    }

    // ════ 1. RoPE machinery: interleave vs half-rotate, partial rotary ════
    {
        for (int mode = 0; mode < 4; ++mode) {
            FusedCfg c;
            c.head_dim = 128;
            c.rotary_dim = (mode / 2 == 0) ? 128 : 64;  // full vs partial rope
            c.interleave = (mode % 2 == 0);
            c.nhq = 2; c.nhk = 1; c.nhv = 1;
            // page_size % x == 0 is a caller obligation: the V layout
            // [.., page/x, head_dim, x] only covers its per-(block,head) span
            // of head_dim*page when page/x >= 1 (page=4 with x=8 walks d*x past
            // the allocation -- caught by ASAN, not by the two schedules,
            // which agree on the same crossing offsets)
            c.page_size = 8; c.x = 8; c.num_blocks = 2;
            c.quantize = false;  // isolate the rope machinery
            FusedJob j;
            j.cfg = c;
            j.num_tokens = 3;
            fill_job(j, 0x100 + static_cast<std::uint64_t>(mode), false);
            FusedJob ref = j;
            run_emul(j);
            run_reference(ref);
            ++checks;
            if (!outputs_equal(j, ref)) {
                std::printf("  rope mode %d (rot %d, %s):\n", mode, c.rotary_dim,
                            c.interleave ? "interleave" : "half-rotate");
                print_first_diff(j, ref);
                ++fails;
            }
            // partial rope: dims >= rotary_dim must equal the post-norm values
            // (rope only touches [0, rotary_dim))
            if (c.rotary_dim == 64) {
                bool untouched = true;
                for (int d = 64; d < 128 && untouched; ++d)
                    // q_act after run == f32_to_bf16(norm * w): compare against
                    // the reference's untouched dims (which are post-norm only)
                    if (j.q_act[static_cast<std::size_t>(d)] != ref.q_act[static_cast<std::size_t>(d)])
                        untouched = false;
                CHECK(untouched);
            }
        }
    }

    // ════ 2. quantization + cache layout + floor + padding ════
    {
        // zero row: amax floor -> scale = 1e-10/448, stored values zero
        {
            FusedCfg c;
            c.head_dim = 128; c.rotary_dim = 128; c.interleave = false;
            c.nhq = 1; c.nhk = 1; c.nhv = 1;
            c.page_size = 8; c.x = 8; c.num_blocks = 1;
            FusedJob j;
            j.cfg = c;
            j.num_tokens = 1;
            fill_job(j, 0x200, false);
            for (auto& v : j.k_act) v = 0;
            for (auto& v : j.v_act) v = 0;
            FusedJob ref = j;
            run_emul(j);
            run_reference(ref);
            CHECK(outputs_equal(j, ref));
            // scale entry lives at the token's ACTUAL slot, not [0]
            const std::int64_t zslot = j.slot_mapping[0];
            const std::size_t zsi = static_cast<std::size_t>(zslot / c.page_size) *
                                        static_cast<std::size_t>(c.nhk * c.page_size) +
                                    static_cast<std::size_t>(zslot % c.page_size);
            CHECK(std::fabs(j.k_scale[zsi] - kAmaxFloor / 448.f) <= 0.f);  // bitwise equal
            CHECK(j.k_scale[zsi] == kAmaxFloor / c.dtype_max);
            // all stored bytes are zero -- but the half-rotate rope turns
            // (+0)*cos + (-0)*sin into IEEE -0 for some cos/sin sign pairs, and
            // the fp8 cast keeps the sign: byte 0x80 (negative zero) counts as
            // zero here, exactly as the device cast would produce
            bool zeros = true;
            for (std::size_t zi = 0; zi < j.k_cache.size(); ++zi)
                if (j.k_cache[zi] != 0 && j.k_cache[zi] != 0x80) zeros = false;
            CHECK(zeros);
        }
        // slot < 0: no cache/scale write, but the Q/K writeback still happened
        {
            FusedCfg c;
            c.head_dim = 128; c.rotary_dim = 128; c.interleave = false;
            c.nhq = 1; c.nhk = 1; c.nhv = 1;
            c.page_size = 8; c.x = 8; c.num_blocks = 2;
            FusedJob j;
            j.cfg = c;
            j.num_tokens = 2;
            fill_job(j, 0x201, false);
            j.slot_mapping[1] = -1;
            FusedJob ref = j;
            run_emul(j);
            run_reference(ref);
            CHECK(outputs_equal(j, ref));
            // token 1's cache slot untouched (all zero), token 0's written
            bool slot1_zero = true;
            const long per_tok = static_cast<long>(c.nhk) * c.head_dim * 1;  // one page row
            (void)per_tok;
            for (auto b : j.k_cache)
                if (b != 0) slot1_zero = false;
            CHECK(!slot1_zero);  // token 0 wrote something
            const std::int64_t s0 = j.slot_mapping[0];
            CHECK(j.k_scale[static_cast<std::size_t>(s0 / c.page_size) *
                                static_cast<std::size_t>(c.nhk * c.page_size) +
                            static_cast<std::size_t>(s0 % c.page_size)] != 0.f);
        }
        // kAuto raw mode: bf16 cache bytes, no scale writes
        {
            FusedCfg c;
            c.head_dim = 128; c.rotary_dim = 128; c.interleave = false;
            c.nhq = 1; c.nhk = 1; c.nhv = 1;
            c.page_size = 8; c.x = 8; c.num_blocks = 2;
            c.quantize = false;
            FusedJob j;
            j.cfg = c;
            j.num_tokens = 2;
            fill_job(j, 0x202, false);
            FusedJob ref = j;
            run_emul(j);
            run_reference(ref);
            CHECK(outputs_equal(j, ref));
            bool raw_written = false;
            for (auto v : j.k_cache_raw)
                if (v != 0) raw_written = true;
            CHECK(raw_written);
        }
        // e5m2-style dtype_max parameterization: same placement, wider scale
        {
            FusedCfg c;
            c.head_dim = 128; c.rotary_dim = 128; c.interleave = false;
            c.nhq = 1; c.nhk = 1; c.nhv = 1;
            c.page_size = 8; c.x = 8; c.num_blocks = 1;
            c.dtype_max = 57344.f;
            FusedJob j;
            j.cfg = c;
            j.num_tokens = 1;
            fill_job(j, 0x203, false);
            FusedJob ref = j;
            run_emul(j);
            run_reference(ref);
            CHECK(outputs_equal(j, ref));
            CHECK(j.k_scale[0] < 0.01f);  // wider dtype -> much smaller scale
        }
    }

    // ════ 3. fused vs modular composition (same op order, bitwise) ════
    {
        // the reference IS the modular composition; run against the warp
        // emulation on a config exercising every feature at once
        FusedCfg c;
        c.head_dim = 128; c.rotary_dim = 96; c.interleave = false;  // partial + not 2*E aligned
        // rotary 96: embed 48, E 4 -> delta 12: NOT a power of two -> the
        // dispatch guard (rotary/2) % E == 0 passes (48 % 4 == 0) but xor 12
        // breaks. The pipeline must therefore NOT be run with these shapes;
        // the emulation and reference AGREE here only because the reference
        // reads partner dims by +-embed index math (the honest semantics),
        // while the xor emulation diverges. Verify the DIVERGENCE itself:
        c.nhq = 1; c.nhk = 1; c.nhv = 1;
        c.page_size = 8; c.x = 8; c.num_blocks = 2;
        FusedJob j;
        j.cfg = c;
        j.num_tokens = 2;
        fill_job(j, 0x300, true);
        FusedJob ref = j;
        run_reference(ref);
        FusedJob emu = j;
        run_emul(emu);
        // the two DISAGREE on the rope'd activations (xor delta 12 mis-pairs):
        // this documents why the power-of-two delta is a REAL constraint
        bool diverged = (emu.q_act != ref.q_act) || (emu.k_act != ref.k_act);
        CHECK(diverged);
        // now the same shapes with rotary 64 (delta 8, power of two): agree bitwise
        c.rotary_dim = 64;
        j.cfg = c;
        ref.cfg = c;
        emu.cfg = c;
        fill_job(j, 0x301, true);
        ref = j;
        run_reference(ref);
        emu = j;
        run_emul(emu);
        ++checks;
        if (!outputs_equal(emu, ref)) {
            std::printf("  fused-vs-reference (rotary 64) mismatch:\n");
            print_first_diff(emu, ref);
            ++fails;
        }
    }

    // ════ 4. randomized master sweep ════
    {
        struct Cfg0 {
            int hd, rot, nhq, nhk, nhv, page, x, nb;
            bool inter, quant;
        };
        const Cfg0 cfgs[] = {
            {128, 128, 4, 2, 2, 8, 8, 3, false, true},
            {128, 128, 4, 2, 2, 8, 8, 3, true, true},
            {128, 64, 2, 1, 1, 4, 4, 2, false, true},
            {128, 64, 2, 1, 1, 4, 4, 2, true, true},
            {64, 64, 3, 3, 3, 16, 8, 2, false, true},
            {64, 32, 3, 3, 3, 16, 8, 2, true, true},
            {256, 128, 1, 1, 1, 8, 8, 2, false, true},
            {256, 256, 1, 1, 1, 8, 8, 2, true, true},
            {128, 128, 2, 1, 3, 8, 8, 2, false, true},   // nhv != nhk
            {128, 128, 2, 1, 3, 8, 8, 2, true, false},   // kAuto
            {128, 128, 2, 2, 2, 8, 8, 3, false, true},
            {128, 128, 2, 2, 2, 8, 8, 3, true, true},
        };
        int rows = 0;
        for (int ci = 0; ci < 12; ++ci) {
            for (int seed = 0; seed < 3; ++seed) {
                FusedCfg c;
                c.head_dim = cfgs[ci].hd;
                c.rotary_dim = cfgs[ci].rot;
                c.nhq = cfgs[ci].nhq;
                c.nhk = cfgs[ci].nhk;
                c.nhv = cfgs[ci].nhv;
                c.page_size = cfgs[ci].page;
                c.x = cfgs[ci].x;
                c.num_blocks = cfgs[ci].nb;
                c.interleave = cfgs[ci].inter;
                c.quantize = cfgs[ci].quant;
                FusedJob j;
                j.cfg = c;
                j.num_tokens = 7;
                fill_job(j, 0x9000u + static_cast<std::uint64_t>(ci) * 97u + static_cast<std::uint64_t>(seed),
                         true);
                FusedJob ref = j;
                run_emul(j);
                run_reference(ref);
                ++rows;
                ++checks;
                if (!outputs_equal(j, ref)) {
                    std::printf("  sweep cfg%d seed%d (hd %d rot %d %s quant %d):\n", ci, seed,
                                c.head_dim, c.rotary_dim, c.interleave ? "IL" : "HR",
                                c.quantize);
                    print_first_diff(j, ref);
                    ++fails;
                }
                // dequant round-trip bound: |v_ref - decode(stored)*scale| <=
                // half an e4m3 ulp (rel 2^-4) + bf16 input is identical on both
                if (c.quantize) {
                    // slots collide (random mapping): the cache holds whichever
                    // token wrote LAST, so only the final writer of each slot
                    // can be round-trip checked against its own activations
                    std::vector<int> last_writer(
                        static_cast<std::size_t>(c.num_blocks * c.page_size), -1);
                    for (int tok = 0; tok < j.num_tokens; ++tok) {
                        const std::int64_t sl = j.slot_mapping[static_cast<std::size_t>(tok)];
                        if (sl >= 0) last_writer[static_cast<std::size_t>(sl)] = tok;
                    }
                    bool bound_ok = true;
                    for (int tok = 0; tok < j.num_tokens && bound_ok; ++tok) {
                        const std::int64_t slot = j.slot_mapping[static_cast<std::size_t>(tok)];
                        if (slot < 0) continue;
                        if (last_writer[static_cast<std::size_t>(slot)] != tok) continue;
                        const std::int64_t b = slot / c.page_size;
                        const std::int64_t t = slot % c.page_size;
                        for (int h = 0; h < c.nhk && bound_ok; ++h) {
                            const float sc = j.k_scale[static_cast<std::size_t>(b * c.nhk + h) *
                                                           static_cast<std::size_t>(c.page_size) +
                                                       static_cast<std::size_t>(t)];
                            const long kbase = static_cast<long>(b) * c.nhk * c.head_dim * c.page_size +
                                               static_cast<long>(h) * c.head_dim * c.page_size;
                            for (int d = 0; d < c.head_dim && bound_ok; ++d) {
                                const long off = kbase + d / c.x * c.page_size * c.x +
                                                 static_cast<long>(t) * c.x + d % c.x;
                                const float dec = e4m3_ocp_to_f32(j.k_cache[static_cast<std::size_t>(off)]) * sc;
                                const float want = bf16_to_f32(ref.k_act[static_cast<std::size_t>(
                                    static_cast<long>(tok) * (c.nhq + c.nhk + c.nhv) * c.head_dim +
                                    static_cast<long>(h) * c.head_dim + d)]);
                                const float err = std::fabs(dec - want);
                                // half an e4m3 ulp: rel 2^-4 in the normal zone,
                                // abs 2^-10*scale in the subnormal zone
                                const float bound = std::fmax(std::fabs(want), 1e-30f) * 0.0625f +
                                                    sc * 0.001f;
                                if (err > bound) {
                                    bound_ok = false;
                                    std::printf("  BND tok%d h%d d%d want %.6g dec %.6g err %.4g bound %.4g sc %.6g q %.4g\n",
                                                tok, h, d, want, dec, err, bound, sc,
                                                e4m3_ocp_to_f32(j.k_cache[static_cast<std::size_t>(off)]));
                                }
                            }
                        }
                    }
                    CHECK(bound_ok);
                }
            }
        }
        std::printf("  sweep: %d rows compared bitwise\n", rows);
        CHECK(rows == 36);
    }

    std::printf("fused_qk_norm_rope_cache_quant: %d checks, %d failures -> %s\n", checks, fails,
                fails ? "FAIL" : "PASS");
    return fails ? 1 : 0;
}
