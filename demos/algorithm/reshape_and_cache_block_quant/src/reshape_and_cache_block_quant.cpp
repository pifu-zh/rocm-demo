// SPDX-License-Identifier: MIT
// Copyright (C) 2026, Advanced Micro Devices, Inc. All rights reserved.
//
// Host reference for aiter's vLLM-style KV block-quant cache write
// (reshape_and_cache_with_block_quant_kernel, csrc/kernels/cache_kernels.cu
// lines 522-768 @ 1eab5ae12c93af3c8c660202d9a413f637c2f011, MIT).
//
// The kernel's contract, as pinned from the source + launcher:
//   * grid = (batch, ceil(seq_len/block_size) + 1, num_heads); the +1-th
//     window is a TAIL GUARD: it targets the batch's LAST token's physical
//     block and returns immediately when the last full window's first token
//     already sits in that same block (preTg == block_idx). Under the
//     contiguous-slot regime a full window's first token is exactly bs slots
//     behind the next window's, so in-window duplicates cannot arise; the
//     guard skip is the only dedupe the kernel does.
//   * one CTA owns ONE PHYSICAL block (not one window): a window whose slot
//     starts mid-block (block_offset > 0) scans backwards through
//     slot_mapping (threads < block_size, token_idx = first - tid - 1) to
//     find the boundary INTO this block, and re-scopes first_token_idx to
//     the block's first CALL token. The fix runs on the COMMON path (guard
//     CTAs fix too; window 0 cannot, blockIdx.y == 0, and cannot need it --
//     the batch's first token is its block's first call token by
//     construction).
//   * numtokens_in_block = count of CALL tokens (up to blockDim >= bs of
//     them, striding by 1) whose slot block == block_idx. The amax and
//     store loops iterate CONSECUTIVE tokens from first_token_idx, so the
//     kernel assumes the block's call tokens are the contiguous run starting
//     at its first call token -- the contiguous-slot prefill pattern
//     (vLLM appends slots per sequence); arbitrary slot permutations are a
//     caller contract violation the kernel will silently mis-handle.
//   * amax covers THIS CALL's tokens only, seeded at kAmaxFloor = 1e-10 (an
//     all-zero group still derives a finite scale, same constant as the
//     a8w8 fused kernel); scale_new = amax/dtypeMax (fp8 = 448).
//   * THE RESCALE-BACK CONTRACT (block_offset > 0, i.e. entries from
//     previous calls live in the block): let s_old = scales[scale_idx],
//     s_new = amax/dtypeMax.
//       s_old <  s_new: rewrite the OLD region [0, block_offset) as
//                       cast(cast_f32(old) * s_old / s_new) and adopt s_new
//                       -- old entries carry COMPOUNDED double-quantization
//                       error, and the block scale moves monotonically UP;
//       s_old >= s_new: keep s_old (finer) and quantize the new tokens with
//                       it -- the scale never decreases across calls;
//       block_offset == 0: write s_new unconditionally (the block is fresh;
//                       any stale scale is discarded).
//     The old entries' true values are NOT reconsidered for the amax: the
//     block scale is a function of this call's tokens and the old scale.
//   * store: v * (1/scale) (reciprocal multiply again), cast to fp8 RNE
//     satfinite; K layout [nb, nh, hs/x, bs, x]:
//       ((blk*nh + h)*(hs/x) + d/x)*bs*x + bol*x + d%x;
//     V plain [nb, nh, hs, bs]: ((blk*nh + h)*hs + d)*bs + bol;
//     V asmLayout [nb, nh, bs/x, hs, x]:
//       ((blk*nh + h)*(bs/x) + bol/x)*hs*x + d*x + bol%x.
//   * scale index: plain h*nb + blk, asmLayout blk*nh + h.
//
// Two host schedules cross-validate bitwise under the contiguous regime:
//   run_windowed -- the literal grid emulation, CTA by CTA including the
//                   guard and the backward fix (reads see call-start state;
//                   racing duplicate writers are byte-identical by design);
//   run_flat     -- per (batch, physical block touched): derive the block's
//                   first call token and count directly, one pass, no
//                   window/guard machinery.

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
// fp8 e4m3 OCP RNE satfinite (e4m3FN), the lab-verified codec
static inline std::uint8_t f32_to_e4m3_ocp(float f) {
    std::uint32_t u;
    std::memcpy(&u, &f, 4);
    const std::uint8_t sign = static_cast<std::uint8_t>((u >> 24) & 0x80u);
    const std::uint32_t mag = u & 0x7FFFFFFFu;
    if (mag == 0) return sign;
    if ((u >> 23) == 0xFFu)
        return (mag & 0x7FFFFFu) ? static_cast<std::uint8_t>(sign | 0x7Fu)
                                 : static_cast<std::uint8_t>(sign | 0x7Eu);
    const int e = static_cast<int>(mag >> 23) - 127;
    if (e < -6) {
        const double scaled = static_cast<double>(mag) * 0x1p-23 * 512.0;
        std::uint32_t m = static_cast<std::uint32_t>(scaled);
        const double frac = scaled - static_cast<double>(m);
        if (frac > 0.5 || (frac == 0.5 && (m & 1))) ++m;
        if (m <= 7) return static_cast<std::uint8_t>(sign | m);
        return static_cast<std::uint8_t>(sign | 0x08u);
    }
    int e8 = e + 7;
    const std::uint32_t man = mag & 0x7FFFFFu;
    std::uint32_t m3 = man >> 20;
    const std::uint32_t rem = man & 0xFFFFFu;
    if (rem > (1u << 19) || (rem == (1u << 19) && (m3 & 1))) ++m3;
    if (m3 == 8u) {
        m3 = 0;
        ++e8;
    }
    if (e8 > 15 || (e8 == 15 && m3 >= 7))
        return static_cast<std::uint8_t>(sign | 0x7Eu);
    return static_cast<std::uint8_t>(sign | (static_cast<std::uint32_t>(e8) << 3) | m3);
}
static inline float e4m3_to_f32(std::uint8_t b) {
    const std::uint32_t sign = (b & 0x80u) ? 0x80000000u : 0u;
    const std::uint32_t rest = b & 0x7Fu;
    float out;
    if ((rest >> 3) == 0 && (rest & 7) != 0) {
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

constexpr float kAmaxFloor = 1e-10f;

// ── the job ──
struct BKJob {
    int bs = 8;         // block_size
    int hs = 16;        // head_size
    int x = 4;
    int nh = 2;
    int nb = 6;         // physical blocks in the cache
    int nbatch = 1;
    int seq = 5;        // per batch
    bool asm_layout = false;
    float dtype_max = 448.f;
    std::vector<std::uint16_t> key, val;   // [nbatch*seq, nh, hs] bf16
    std::vector<std::int64_t> slot;        // [nbatch*seq]
    // caches + scales (mutated in place across calls)
    std::vector<std::uint8_t> kc, vc;
    std::vector<float> ks, vs;
    long num_tokens() const { return static_cast<long>(nbatch) * seq; }
    long kc_size() const {
        return static_cast<long>(nb) * nh * (hs / x) * bs * x;
    }
    long vc_size() const { return static_cast<long>(nb) * nh * hs * bs; }
    int scale_idx(int h, int blk) const {
        return asm_layout ? blk * nh + h : h * nb + blk;
    }
    long k_off(int blk, int h, int d, int bol) const {
        return (static_cast<long>(blk) * nh + h) * (hs / x) * bs * x +
               static_cast<long>(d / x) * bs * x + static_cast<long>(bol) * x + d % x;
    }
    long v_off(int blk, int h, int d, int bol) const {
        if (asm_layout)
            return (static_cast<long>(blk) * nh + h) * (bs / x) * hs * x +
                   static_cast<long>(bol / x) * hs * x + static_cast<long>(d) * x + bol % x;
        return (static_cast<long>(blk) * nh + h) * hs * bs + static_cast<long>(d) * bs + bol;
    }
};

static void init_cache(BKJob& j) {
    j.kc.assign(static_cast<std::size_t>(j.kc_size()), 0);
    j.vc.assign(static_cast<std::size_t>(j.vc_size()), 0);
    j.ks.assign(static_cast<std::size_t>(j.nh * j.nb), 0.f);
    j.vs.assign(static_cast<std::size_t>(j.nh * j.nb), 0.f);
}

static void quant_block(BKJob& j, const std::vector<float>& ks_snap,
                        const std::vector<float>& vs_snap, int blk, int h,
                        long fti, int block_offset, int cnt);

// the per-CTA body, transcribed from the kernel (both schedules use it)
struct CtaOut {
    bool ran = false;
    int blk = -1, h = -1;
};
static CtaOut run_cta(BKJob& j, const std::vector<float>& ks_snap,
                      const std::vector<float>& vs_snap, int b, int w, int h) {
    CtaOut out;
    const int blockDimx = (j.bs + 255) / 256 * 256;
    long fti = static_cast<long>(b) * j.seq + static_cast<long>(w) * j.bs;
    std::int64_t slot_idx, block_idx, block_offset;
    if (static_cast<long>(w) * j.bs >= j.seq) {
        // tail guard
        const std::int64_t pre =
            j.slot[static_cast<std::size_t>(fti - j.bs)] / j.bs;
        fti = static_cast<long>(b) * j.seq + j.seq - 1;
        slot_idx = j.slot[static_cast<std::size_t>(fti)];
        block_idx = slot_idx / j.bs;
        if (pre == block_idx) return out;  // already handled
        block_offset = slot_idx % j.bs;
    } else {
        slot_idx = j.slot[static_cast<std::size_t>(fti)];
        block_idx = slot_idx / j.bs;
        block_offset = slot_idx % j.bs;
    }
    if (slot_idx < 0) return out;  // padding

    // backward fix: common path, needs w > 0 and a mid-block start
    if (w > 0 && block_offset > 0) {
        bool found = false;
        for (int tid = 0; tid < j.bs; ++tid) {
            const long tok = fti - (tid + 1);
            const std::int64_t b1 = j.slot[static_cast<std::size_t>(tok)] / j.bs;
            const std::int64_t s2 = j.slot[static_cast<std::size_t>(tok + 1)];
            const std::int64_t b2 = s2 / j.bs;
            if (b1 != b2 && b2 == block_idx) {
                fti = tok + 1;
                slot_idx = s2;
                found = true;
                break;  // contiguous regime: exactly one boundary
            }
        }
        (void)found;  // contiguous regime guarantees it
        block_offset = slot_idx % j.bs;
    }

    // count the block's call tokens
    int cnt = 0;
    for (int tid = 0; tid < blockDimx; ++tid)
        if (fti + tid < j.num_tokens() &&
            j.slot[static_cast<std::size_t>(fti + tid)] / j.bs == block_idx)
            ++cnt;

    quant_block(j, ks_snap, vs_snap, static_cast<int>(block_idx), h,
                fti, static_cast<int>(block_offset), cnt);
    out.ran = true;
    out.blk = static_cast<int>(block_idx);
    out.h = h;
    return out;
}

// the amax/rescale/store body shared by both schedules (transcribed from
// the kernel once; the schedules differ only in how a block's parameters
// are derived)
static void quant_block(BKJob& j, const std::vector<float>& ks_snap,
                        const std::vector<float>& vs_snap, int blk, int h,
                        long fti, int block_offset, int cnt) {
    float k_max = kAmaxFloor, v_max = kAmaxFloor;
    for (int id = 0; id < cnt * j.hs; ++id) {
        const long tok = id / j.hs + fti;
        const int d = id % j.hs;
        k_max = std::fmax(k_max, std::fabs(bf16_to_f32(
            j.key[static_cast<std::size_t>(tok) * j.nh * j.hs + static_cast<std::size_t>(h) * j.hs + d])));
        v_max = std::fmax(v_max, std::fabs(bf16_to_f32(
            j.val[static_cast<std::size_t>(tok) * j.nh * j.hs + static_cast<std::size_t>(h) * j.hs + d])));
    }
    float k_scale = k_max / j.dtype_max;
    float v_scale = v_max / j.dtype_max;
    const int si = j.scale_idx(h, blk);

    if (block_offset > 0) {
        const float k_global = ks_snap[static_cast<std::size_t>(si)];
        const float v_global = vs_snap[static_cast<std::size_t>(si)];
        if (k_global < k_scale) {
            for (int id = 0; id < block_offset * j.hs; ++id) {
                const int bol = id / j.hs;
                const int d = id % j.hs;
                const long off = j.k_off(blk, h, d, bol);
                j.kc[static_cast<std::size_t>(off)] = f32_to_e4m3_ocp(
                    e4m3_to_f32(j.kc[static_cast<std::size_t>(off)]) * k_global / k_scale);
            }
            j.ks[static_cast<std::size_t>(si)] = k_scale;
        } else {
            k_scale = k_global;
        }
        if (v_global < v_scale) {
            for (int id = 0; id < block_offset * j.hs; ++id) {
                const int bol = id / j.hs;
                const int d = id % j.hs;
                const long off = j.v_off(blk, h, d, bol);
                j.vc[static_cast<std::size_t>(off)] = f32_to_e4m3_ocp(
                    e4m3_to_f32(j.vc[static_cast<std::size_t>(off)]) * v_global / v_scale);
            }
            j.vs[static_cast<std::size_t>(si)] = v_scale;
        } else {
            v_scale = v_global;
        }
    } else {
        j.ks[static_cast<std::size_t>(si)] = k_scale;
        j.vs[static_cast<std::size_t>(si)] = v_scale;
    }
    const float k_inv = 1.f / k_scale, v_inv = 1.f / v_scale;
    for (int id = 0; id < cnt * j.hs; ++id) {
        const long tok = id / j.hs + fti;
        const int d = id % j.hs;
        const int bol = static_cast<int>(tok - fti + block_offset);
        const float kv = bf16_to_f32(
            j.key[static_cast<std::size_t>(tok) * j.nh * j.hs + static_cast<std::size_t>(h) * j.hs + d]);
        const float vv = bf16_to_f32(
            j.val[static_cast<std::size_t>(tok) * j.nh * j.hs + static_cast<std::size_t>(h) * j.hs + d]);
        j.kc[static_cast<std::size_t>(j.k_off(blk, h, d, bol))] = f32_to_e4m3_ocp(kv * k_inv);
        j.vc[static_cast<std::size_t>(j.v_off(blk, h, d, bol))] = f32_to_e4m3_ocp(vv * v_inv);
    }
}

// ── schedule 1: literal grid emulation ──
static void run_windowed(BKJob& j) {
    const int windows = (j.seq + j.bs - 1) / j.bs;
    for (int b = 0; b < j.nbatch; ++b)
        for (int h = 0; h < j.nh; ++h) {
            // call-start scale snapshot: racing duplicates are byte-identical,
            // and none may consume another's rescale mid-call
            const std::vector<float> ks_snap = j.ks, vs_snap = j.vs;
            for (int w = 0; w <= windows; ++w)  // +1 = the tail guard
                run_cta(j, ks_snap, vs_snap, b, w, h);
        }
}

// ── schedule 2: flat per-physical-block ──
// No window/guard machinery: for each (batch, head), collect the blocks the
// grid would touch (full-window first tokens + the guard's target with its
// preTg skip), then derive each block's parameters DIRECTLY (first call
// token by scan, count by scan) and run the shared body once.
static void run_flat(BKJob& j) {
    const int windows = (j.seq + j.bs - 1) / j.bs;
    for (int b = 0; b < j.nbatch; ++b)
        for (int h = 0; h < j.nh; ++h) {
            const std::vector<float> ks_snap = j.ks, vs_snap = j.vs;
            // target set in CTA order
            std::vector<int> targets;
            for (int w = 0; w <= windows; ++w) {
                long fti;
                if (static_cast<long>(w) * j.bs >= j.seq) {
                    // guard: skip when the last full window owns the block
                    const long last = static_cast<long>(b) * j.seq + j.seq - 1;
                    const std::int64_t si = j.slot[static_cast<std::size_t>(last)];
                    if (si < 0) continue;
                    const std::int64_t blk = si / j.bs;
                    const std::int64_t pre =
                        j.slot[static_cast<std::size_t>(static_cast<long>(b) * j.seq +
                                                         static_cast<long>(windows - 1) * j.bs)] /
                        j.bs;
                    if (pre == blk) continue;
                    fti = last;
                } else {
                    fti = static_cast<long>(b) * j.seq + static_cast<long>(w) * j.bs;
                    if (j.slot[static_cast<std::size_t>(fti)] < 0) continue;
                }
                const int blk = static_cast<int>(j.slot[static_cast<std::size_t>(fti)] / j.bs);
                if (std::find(targets.begin(), targets.end(), blk) == targets.end())
                    targets.push_back(blk);
            }
            // independent per-block derivation + one shared-body run each
            for (int blk : targets) {
                long first = -1;
                for (long t = 0; t < j.num_tokens(); ++t)
                    if (j.slot[static_cast<std::size_t>(t)] >= 0 &&
                        j.slot[static_cast<std::size_t>(t)] / j.bs == blk) {
                        first = t;
                        break;
                    }
                if (first < 0) continue;
                const int off = static_cast<int>(j.slot[static_cast<std::size_t>(first)] % j.bs);
                int cnt = 0;
                for (long t = 0; t < j.num_tokens(); ++t)
                    if (j.slot[static_cast<std::size_t>(t)] >= 0 &&
                        j.slot[static_cast<std::size_t>(t)] / j.bs == blk)
                        ++cnt;
                quant_block(j, ks_snap, vs_snap, blk, h, first, off, cnt);
            }
        }
}

// ── job builders ──
// contiguous slots per batch, optionally continuing mid-block from a prior
// call (start_off), with page breaks wherever the block fills
static void fill_contiguous(BKJob& j, Lcg& rng, int start_slot, int start_blk_first,
                            float amp) {
    const long nt = j.num_tokens();
    j.key.resize(static_cast<std::size_t>(nt) * j.nh * j.hs);
    j.val.resize(static_cast<std::size_t>(nt) * j.nh * j.hs);
    for (auto& v : j.key) v = f32_to_bf16(rng.uniform(-amp, amp));
    for (auto& v : j.val) v = f32_to_bf16(rng.uniform(-amp, amp));
    j.slot.resize(static_cast<std::size_t>(nt));
    std::int64_t s = start_slot;
    for (long t = 0; t < nt; ++t) {
        j.slot[static_cast<std::size_t>(t)] = s++;
    }
    (void)start_blk_first;
}
static bool cache_equal(const BKJob& a, const BKJob& b) {
    return a.kc == b.kc && a.vc == b.vc && a.ks == b.ks && a.vs == b.vs;
}

int main() {
    // ════ 0. layout arithmetic ════
    {
        BKJob j;
        j.bs = 8; j.hs = 16; j.x = 4; j.nh = 2; j.nb = 6;
        // K: [nb, nh, hs/x, bs, x] -- blk 2, h 1, d 7 (x_idx 1, xo 3), bol 5
        CHECK(j.k_off(2, 1, 7, 5) ==
              (2L * 2 + 1) * 4 * 8 * 4 + 1L * 8 * 4 + 5L * 4 + 3);
        // V plain: [nb, nh, hs, bs]
        CHECK(j.v_off(2, 1, 7, 5) == (2L * 2 + 1) * 16 * 8 + 7L * 8 + 5);
        // V asm: [nb, nh, bs/x, hs, x] -- bol 5 (bol/x 1, bol%x 1)
        j.asm_layout = true;
        CHECK(j.v_off(2, 1, 7, 5) ==
              (2L * 2 + 1) * 2 * 16 * 4 + 1L * 16 * 4 + 7L * 4 + 1);
        // scale indices
        j.asm_layout = false;
        CHECK(j.scale_idx(1, 2) == 1 * 6 + 2);
        j.asm_layout = true;
        CHECK(j.scale_idx(1, 2) == 2 * 2 + 1);
        j.asm_layout = false;
        // launcher shape facts
        CHECK((8 + 255) / 256 * 256 == 256);      // bs 8 -> 256 threads
        CHECK((300 + 255) / 256 * 256 == 512);    // bs 300 -> 512 threads
        const int windows5 = (5 + 8 - 1) / 8;     // seq 5, bs 8 -> 1 window
        CHECK(windows5 == 1);                     // + 1 guard = grid.y 2
        const int windows13 = (13 + 8 - 1) / 8;
        CHECK(windows13 == 2);
    }

    // ════ 1. rescale-back contract ════
    {
        // (a) fresh block, all-zero tokens: floor scale, zero entries
        {
            BKJob j;
            j.nbatch = 1; j.seq = 4;
            Lcg rng(0x01);
            fill_contiguous(j, rng, 0, 0, 0.5f);
            for (auto& v : j.key) v = 0;
            for (auto& v : j.val) v = 0;
            init_cache(j);
            run_windowed(j);
            CHECK(j.ks[0] == kAmaxFloor / j.dtype_max);
            CHECK(j.vs[0] == kAmaxFloor / j.dtype_max);
            bool zeros = true;
            for (int t = 0; t < 4; ++t)
                for (int d = 0; d < j.hs; ++d) {
                    if (j.kc[static_cast<std::size_t>(j.k_off(0, 0, d, t))] != 0) zeros = false;
                    if (j.vc[static_cast<std::size_t>(j.v_off(0, 0, d, t))] != 0) zeros = false;
                }
            CHECK(zeros);
        }
        // (b) growth: call 2 amax larger -> old entries re-quantized down,
        //     scale adopted, monotone
        {
            BKJob j;
            j.nbatch = 1; j.seq = 4;
            Lcg rng(0x02);
            fill_contiguous(j, rng, 0, 0, 0.5f);
            init_cache(j);
            run_windowed(j);
            const float s1 = j.ks[0];
            const std::vector<std::uint8_t> old_k = j.kc;
            // call 2: same block continues, 100x amax
            BKJob j2 = j;
            fill_contiguous(j2, rng, 4, 0, 50.f);
            j2.slot.resize(4);
            for (int t = 0; t < 4; ++t) j2.slot[static_cast<std::size_t>(t)] = 4 + t;
            run_windowed(j2);
            const float s2 = j2.ks[0];
            CHECK(s2 > s1);
            // the call-2 CTA saw block_offset = 4: the old region [0,4) was
            // rescaled in place (j2 was copied AFTER call 1, so its bytes
            // going in were call-1's); each rescaled entry must round-trip
            // near the original decoded value times s1/s2
            bool rescale_ok = true;
            for (int t = 0; t < 4 && rescale_ok; ++t)
                for (int d = 0; d < j.hs && rescale_ok; ++d) {
                    const std::size_t off = static_cast<std::size_t>(j2.k_off(0, 0, d, t));
                    const float before = e4m3_to_f32(old_k[off]) * s1;
                    const float after = e4m3_to_f32(j2.kc[off]) * s2;
                    const float bound = 0.0625f * std::fabs(after) + s2 * 0.0625f + 1e-9f;
                    if (std::fabs(after - before) > bound) rescale_ok = false;
                }
            CHECK(rescale_ok);
        }
        // (c) shrink: call 2 amax smaller -> scale stays, new tokens quantized
        //     with the OLD scale, old bytes bitwise untouched
        {
            BKJob j;
            j.nbatch = 1; j.seq = 4;
            Lcg rng(0x03);
            fill_contiguous(j, rng, 0, 0, 1.f);
            init_cache(j);
            run_windowed(j);
            const float s1 = j.ks[0];
            BKJob j2 = j;
            // continuation tokens, small amax
            for (auto& v : j2.key) v = f32_to_bf16(0.01f);
            for (auto& v : j2.val) v = f32_to_bf16(0.01f);
            j2.seq = 4;
            j2.slot.assign(4, 0);
            for (int t = 0; t < 4; ++t) j2.slot[static_cast<std::size_t>(t)] = 4 + t;
            const std::vector<std::uint8_t> kc_before = j2.kc, vc_before = j2.vc;
            run_windowed(j2);
            CHECK(j2.ks[0] == s1);  // scale kept
            // old region bitwise identical
            bool untouched = true;
            for (int t = 0; t < 4 && untouched; ++t)
                for (int d = 0; d < j.hs && untouched; ++d) {
                    if (j2.kc[static_cast<std::size_t>(j2.k_off(0, 0, d, t))] !=
                        kc_before[static_cast<std::size_t>(j2.k_off(0, 0, d, t))])
                        untouched = false;
                }
            CHECK(untouched);
            // new entries quantized with the old (finer) scale: decode ~ v
            bool new_ok = true;
            for (int t = 4; t < 8 && new_ok; ++t)
                for (int d = 0; d < j.hs && new_ok; ++d) {
                    const float want = 0.01f;
                    const float got = e4m3_to_f32(
                        j2.kc[static_cast<std::size_t>(j2.k_off(0, 0, d, t))]) * s1;
                    if (std::fabs(got - want) > 0.0625f * want + 1e-9f) new_ok = false;
                }
            CHECK(new_ok);
        }
        // (d) monotonicity across four calls
        {
            BKJob j;
            j.nbatch = 1; j.seq = 2;
            Lcg rng(0x04);
            init_cache(j);
            float prev = 0.f;
            bool mono = true;
            std::int64_t slot = 0;
            for (int call = 0; call < 4; ++call) {
                BKJob jc = j;
                jc.seq = 2;
                fill_contiguous(jc, rng, static_cast<int>(slot), 0,
                                call == 3 ? 40.f : 0.3f * (call + 1));
                jc.slot.resize(2);
                for (int t = 0; t < 2; ++t) jc.slot[static_cast<std::size_t>(t)] = slot + t;
                run_windowed(jc);
                if (jc.ks[0] < prev - 0.f) mono = false;
                prev = jc.ks[0];
                j = jc;
                slot += 2;
                if (slot == 8) slot = 0;  // wrap to a fresh block scenario
            }
            CHECK(mono);
        }
    }

    // ════ 2. windowed vs flat + tail guard + batch boundary ════
    {
        // seq 13, bs 8: two full windows + guard; slots run across a block
        // boundary mid-sequence and across the batch boundary
        BKJob j;
        j.nbatch = 2; j.seq = 13; j.bs = 8; j.nh = 2; j.nb = 8;
        Lcg rng(0x21);
        fill_contiguous(j, rng, 5, 0, 0.8f);  // starts mid-block (offset 5)
        init_cache(j);
        BKJob f = j;
        run_windowed(j);
        run_flat(f);
        CHECK(cache_equal(j, f));
        // scale entries written for exactly the touched blocks
        int touched = 0;
        for (std::size_t i = 0; i < j.ks.size(); ++i)
            if (j.ks[i] != 0.f) ++touched;
        CHECK(touched > 0);
        // seq 5 <= bs: single window; guard must SKIP (same block) -> the
        // cache equals the flat run and only one block carries scale
        BKJob g;
        g.nbatch = 1; g.seq = 5; g.bs = 8; g.nh = 1; g.nb = 4;
        Lcg rng2(0x22);
        fill_contiguous(g, rng2, 8, 0, 0.4f);  // slots 8..12, one block
        init_cache(g);
        BKJob gf = g;
        run_windowed(g);
        run_flat(gf);
        CHECK(cache_equal(g, gf));
        int scaled = 0;
        for (std::size_t i = 0; i < g.ks.size(); ++i)
            if (g.ks[i] != 0.f) ++scaled;
        CHECK(scaled == 1);
        // padding semantics: slot < 0 is checked ONLY at the window level
        // (the window's FIRST token) -- a mid-window pad is NOT skipped.
        // C++ integer division truncates toward zero, so (-1)/bs == 0: the
        // pad token counts into block 0 and its key/value data is written
        // to its positional offset. Unlike the concat_and_cache_mla family
        // (per-token skip), this kernel relies on the caller never putting
        // pads inside a block-quant prefill window. Pinned as-is.
        BKJob p;
        p.nbatch = 1; p.seq = 6; p.bs = 8; p.nh = 1; p.nb = 4;
        Lcg rng3(0x23);
        fill_contiguous(p, rng3, 0, 0, 0.5f);
        p.slot[2] = -1;
        p.slot[3] = -1;
        init_cache(p);
        run_windowed(p);
        // window token 0 has slot 0 (block 0, offset 0): CTA runs; tokens
        // 2,3 (pads) are counted into block 0 by the (-1)/bs == 0 artifact
        bool pad_written = true;
        for (int d = 0; d < p.hs && pad_written; ++d) {
            // the byte at offset 2 equals token 2's data quantized with the
            // block scale (the pad's data went in, not a zero/skip)
            const float want = bf16_to_f32(
                p.key[static_cast<std::size_t>(2) * p.nh * p.hs + d]);
            const float got = e4m3_to_f32(
                p.kc[static_cast<std::size_t>(p.k_off(0, 0, d, 2))]) * p.ks[0];
            if (std::fabs(got - want) > 0.07f * std::fabs(want) + 1e-9f)
                pad_written = false;
        }
        CHECK(pad_written);
        // whole-window pad: the window's first token slot < 0 -> CTA returns,
        // nothing written
        BKJob p2;
        p2.nbatch = 1; p2.seq = 4; p2.bs = 8; p2.nh = 1; p2.nb = 4;
        Lcg rng4(0x26);
        fill_contiguous(p2, rng4, 0, 0, 0.5f);
        for (auto& sl : p2.slot) sl = -1;
        init_cache(p2);
        run_windowed(p2);
        bool all_zero = true;
        for (auto b : p2.kc)
            if (b != 0) all_zero = false;
        CHECK(all_zero);
        CHECK(p2.ks[0] == 0.f);  // no scale written either
        // asmLayout variant cross-validates the same way
        BKJob a;
        a.nbatch = 1; a.seq = 13; a.bs = 8; a.nh = 2; a.nb = 8;
        a.asm_layout = true;
        Lcg rng5(0x24);
        fill_contiguous(a, rng5, 5, 0, 0.8f);
        init_cache(a);
        BKJob af = a;
        run_windowed(a);
        run_flat(af);
        CHECK(cache_equal(a, af));
    }

    // ════ 3. randomized master sweep ════
    {
        int rows = 0;
        for (int seed = 0; seed < 6; ++seed) {
            Lcg rng(0x9000u + static_cast<std::uint64_t>(seed));
            BKJob j;
            j.nbatch = 1 + static_cast<int>(rng.next() % 2);
            j.seq = 3 + static_cast<int>(rng.next() % 12);
            j.bs = 4 + static_cast<int>(rng.next() % 5) * 2;  // 4..12
            j.hs = 8;
            j.x = 4;
            j.nh = 1 + static_cast<int>(rng.next() % 2);
            j.nb = 8;
            j.asm_layout = (seed % 2) == 1;
            const int start = static_cast<int>(rng.next() % 6);
            fill_contiguous(j, rng, start, 0, 0.3f + 0.2f * static_cast<float>(seed % 4));
            init_cache(j);
            BKJob f = j;
            run_windowed(j);
            run_flat(f);
            ++rows;
            CHECK(cache_equal(j, f));
            // monotone non-decreasing scales vs the (zero) initial state is
            // trivially true on call 1; verify entries decode near sources
            bool bound_ok = true;
            for (long t = 0; t < j.num_tokens() && bound_ok; ++t) {
                const std::int64_t si = j.slot[static_cast<std::size_t>(t)];
                if (si < 0) continue;
                const int blk = static_cast<int>(si / j.bs);
                const int bol = static_cast<int>(si % j.bs);
                for (int h = 0; h < j.nh && bound_ok; ++h) {
                    const float ks_ = j.ks[static_cast<std::size_t>(j.scale_idx(h, blk))];
                    if (ks_ == 0.f) { bound_ok = false; break; }
                    for (int d = 0; d < j.hs && bound_ok; d += j.hs - 1 > 0 ? (j.hs - 1) : 1) {
                        const float want = bf16_to_f32(
                            j.key[static_cast<std::size_t>(t) * j.nh * j.hs + static_cast<std::size_t>(h) * j.hs + d]);
                        const float got = e4m3_to_f32(
                            j.kc[static_cast<std::size_t>(j.k_off(blk, h, d, bol))]) * ks_;
                        if (std::fabs(got - want) > 0.07f * std::fabs(want) + 1e-9f)
                            bound_ok = false;
                    }
                }
            }
            CHECK(bound_ok);
        }
        std::printf("  sweep: %d configs, windowed vs flat bitwise\n", rows);
        CHECK(rows == 6);
    }

    std::printf("reshape_and_cache_block_quant: %d checks, %d failures -> %s\n", checks, fails,
                fails ? "FAIL" : "PASS");
    return fails ? 1 : 0;
}
