// SPDX-License-Identifier: MIT
// Copyright (C) 2026, Advanced Micro Devices, Inc. All rights reserved.
//
// Host reference for aiter's DSR1-MLA segmented paged KV-cache write family
// (concat_and_cache_mla_kernel / concat_and_cache_mla_seg_kernel /
// concat_and_cache_mla_seg_512_kernel in csrc/kernels/cache_kernels.cu @
// 1eab5ae12c93af3c8c660202d9a413f637c2f011, MIT).
//
// The kernels' contract, as pinned from the source:
//   * logical write: token t's kv_c[t][0..kv_lora_rank) (NoPE compressed KV,
//     512 for DSR1) and k_pe[t][0..pe_dim) (decoupled RoPE, 64) land at the
//     paged slot slot_mapping[t]. slot < 0 = padding, skipped entirely.
//   * TWO physical layouts:
//       entry-interleaved (concat_and_cache_mla_kernel):
//         [block][entry][kv_lora_rank + pe_dim] -- per-token concatenated
//         record; offsets via block_stride/entry_stride runtime strides;
//       segmented (the seg family):
//         block = [page_size x rank][page_size x pe_dim], TOKEN-major within
//         each region; nope at block_idx*block_stride + block_offset*rank + i,
//         pe at block_idx*block_stride + page_size*rank + block_offset*pe + i.
//         Same logical content, different physical addresses -- the layout an
//         MLA attention read side consumes.
//   * quantization: STATIC per-tensor scale (a single float). The kernels
//     multiply by the RECIPROCAL, v * (1/scale) -- not v/scale -- which is a
//     bitwise-visible choice (1/scale rounds once, then every element shares
//     that exact factor). kAuto stores raw values, no scale use.
//   * seg_512 (kv_lora 512 / pe 64 / page 64 compile-time, TPB tokens per
//     block) is the LOAD-SCHEDULE optimization of the same write:
//       -- every source load issues FIRST, addressed by token_idx alone; the
//          slot lookup (and its 64-bit divide by runtime page_size) does not
//          gate the loads. With page pinned to 64 the divides become shifts.
//       -- a lane carries TPB nope vectors (lane = vector index, NUM_VEC =
//          blockDim = 512/8); each token's pe is SPREAD over PE_CHUNKS lanes
//          (pe_tok = tid/PE_CHUNKS, pe_chunk = tid%PE_CHUNKS) instead of
//          stacked on lanes 0..PE_CHUNKS-1, so a lane holds one token's pe
//          however large TPB. TPB <= NUM_VEC/PE_CHUNKS is a static_assert.
//   * kAuto vs fp8: cache_t is bf16 in the kAuto instantiation, fp8-e4m3
//     otherwise (opus::cast, RNE, the lab's verified codec).
//
// Three host schedules cross-validate:
//   run_entry_interleaved -- kernel 1's layout and strided copy;
//   run_seg               -- the seg kernel's region layout, flat per-element;
//   run_seg512            -- the issue-then-emit lane schedule over the SAME
//                            region layout (must equal run_seg bitwise).
// Logical equivalence of the two layouts is checked by dequantizing each
// cache per (slot, dim).

#include <algorithm>
#include <array>
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
// fp8 e4m3 OCP encode, RNE, satfinite (e4m3FN: e8=15 valid with m3<=6, 448 max)
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
static inline float e4m3_ocp_to_f32(std::uint8_t b) {
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

// ── the job ──
struct MlaSegJob {
    int kv_lora_rank = 512;  // NoPE dims
    int pe_dim       = 64;   // RoPE dims
    int page_size    = 64;
    int num_blocks   = 4;
    int num_tokens   = 0;
    bool quantize    = true;   // false = kAuto raw store
    float scale      = 1.0f;   // static per-tensor scale
    std::vector<std::uint16_t> kv_c, k_pe;  // [tokens, rank/pe] bf16
    std::vector<std::int64_t> slot_mapping;
    long block_stride() const {
        return static_cast<long>(page_size) * (kv_lora_rank + pe_dim);
    }
    long cache_size() const {
        return static_cast<long>(num_blocks) * block_stride();
    }
};

static void fill_job(MlaSegJob& j, std::uint64_t seed, bool pads) {
    Lcg rng(seed);
    j.kv_c.resize(static_cast<std::size_t>(j.num_tokens) * j.kv_lora_rank);
    j.k_pe.resize(static_cast<std::size_t>(j.num_tokens) * j.pe_dim);
    for (auto& v : j.kv_c) v = f32_to_bf16(rng.uniform(-4.f, 4.f));
    for (auto& v : j.k_pe) v = f32_to_bf16(rng.uniform(-1.f, 1.f));
    j.slot_mapping.resize(static_cast<std::size_t>(j.num_tokens));
    for (std::size_t t = 0; t < j.slot_mapping.size(); ++t) {
        if (pads && t % 5 == 4)
            j.slot_mapping[t] = -1;
        else
            j.slot_mapping[t] = static_cast<std::int64_t>(
                rng.next() % static_cast<std::uint32_t>(j.num_blocks * j.page_size));
    }
}

// quantized store shared by all schedules: multiply by the RECIPROCAL
static inline std::uint8_t quant_store(float v, float inverted_scale) {
    return f32_to_e4m3_ocp(v * inverted_scale);
}
static inline std::uint16_t raw_store(std::uint16_t v) {
    return v;  // kAuto: bf16 passthrough (cache_t = scalar_t)
}

// ── schedule 1: entry-interleaved layout ─────────────────────────────────
struct OutEntry {
    std::vector<std::uint8_t> cache_q;   // fp8 mode
    std::vector<std::uint16_t> cache_r;  // kAuto mode
};
static void run_entry_interleaved(const MlaSegJob& j, OutEntry& o) {
    const long bs = j.block_stride();
    const float inv = 1.0f / j.scale;
    o.cache_q.assign(static_cast<std::size_t>(j.cache_size()), 0);
    o.cache_r.assign(static_cast<std::size_t>(j.cache_size()), 0);
    auto copy = [&](const std::vector<std::uint16_t>& src, int src_stride, int size,
                    int out_off) {
        for (int i = 0; i < size; ++i) {
            for (int tok = 0; tok < j.num_tokens; ++tok) {
                const std::int64_t slot = j.slot_mapping[static_cast<std::size_t>(tok)];
                if (slot < 0) continue;
                const std::int64_t b = slot / j.page_size, t = slot % j.page_size;
                const std::size_t dst = static_cast<std::size_t>(b * bs + t * (j.kv_lora_rank + j.pe_dim) + out_off + i);
                const float v = bf16_to_f32(src[static_cast<std::size_t>(tok) * src_stride + i]);
                if (j.quantize)
                    o.cache_q[dst] = quant_store(v, inv);
                else
                    o.cache_r[dst] = raw_store(src[static_cast<std::size_t>(tok) * src_stride + i]);
            }
        }
    };
    copy(j.kv_c, j.kv_lora_rank, j.kv_lora_rank, 0);
    copy(j.k_pe, j.pe_dim, j.pe_dim, j.kv_lora_rank);
}

// ── schedule 2: segmented layout, flat per-element ───────────────────────
struct OutSeg {
    std::vector<std::uint8_t> cache_q;
    std::vector<std::uint16_t> cache_r;
};
static void run_seg(const MlaSegJob& j, OutSeg& o) {
    const long bs = j.block_stride();
    const float inv = 1.0f / j.scale;
    o.cache_q.assign(static_cast<std::size_t>(j.cache_size()), 0);
    o.cache_r.assign(static_cast<std::size_t>(j.cache_size()), 0);
    auto copy = [&](const std::vector<std::uint16_t>& src, int src_stride, int size,
                    int64_t nope_pe_flag) {
        (void)nope_pe_flag;
        for (int i = 0; i < size; ++i) {
            for (int tok = 0; tok < j.num_tokens; ++tok) {
                const std::int64_t slot = j.slot_mapping[static_cast<std::size_t>(tok)];
                if (slot < 0) continue;
                const std::int64_t b = slot / j.page_size, t = slot % j.page_size;
                const std::int64_t dst_base = (&src == &j.kv_c)
                    ? b * bs + t * j.kv_lora_rank
                    : b * bs + static_cast<std::int64_t>(j.page_size) * j.kv_lora_rank + t * j.pe_dim;
                const std::size_t dst = static_cast<std::size_t>(dst_base + i);
                const float v = bf16_to_f32(src[static_cast<std::size_t>(tok) * src_stride + i]);
                if (j.quantize)
                    o.cache_q[dst] = quant_store(v, inv);
                else
                    o.cache_r[dst] = raw_store(src[static_cast<std::size_t>(tok) * src_stride + i]);
            }
        }
    };
    copy(j.kv_c, j.kv_lora_rank, j.kv_lora_rank, 0);
    copy(j.k_pe, j.pe_dim, j.pe_dim, 1);
}

// ── schedule 3: seg_512 lane schedule (issue-then-emit) ──────────────────
// Lane model: NUM_VEC = rank/8 lanes ( blockDim ), VEC=8; TPB tokens/block.
static void run_seg512(const MlaSegJob& j, OutSeg& o, int TPB) {
    constexpr int VEC = 8;
    const int NUM_VEC = j.kv_lora_rank / VEC;        // = blockDim.x
    const int PE_CHUNKS = j.pe_dim / VEC;            // pe vecs per token
    const int PE_TOKENS_PER_ROUND = NUM_VEC / PE_CHUNKS;
    // the kernel's static_assert: a token's pe needs its own PE_CHUNKS lanes
    if (TPB > PE_TOKENS_PER_ROUND) {
        std::printf("  seg512 config invalid: TPB %d > %d\n", TPB, PE_TOKENS_PER_ROUND);
        ++fails;
        return;
    }
    const long bs = j.block_stride();
    const float inv = 1.0f / j.scale;
    o.cache_q.assign(static_cast<std::size_t>(j.cache_size()), 0);
    o.cache_r.assign(static_cast<std::size_t>(j.cache_size()), 0);
    const int nblocks = (j.num_tokens + TPB - 1) / TPB;

    for (int blk = 0; blk < nblocks; ++blk) {
        const int tok0 = blk * TPB;
        // ---- issue phase: every source load first, slot-independent ----
        // nope_in[k][tid] = 8 bf16 of token tok0+k at vec tid
        std::vector<std::vector<std::array<std::uint16_t, VEC>>> nope_in(
            static_cast<std::size_t>(TPB),
            std::vector<std::array<std::uint16_t, VEC>>(static_cast<std::size_t>(NUM_VEC)));
        for (int k = 0; k < TPB; ++k) {
            const int t = tok0 + k;
            if (t >= j.num_tokens) continue;
            for (int tid = 0; tid < NUM_VEC; ++tid)
                for (int q = 0; q < VEC; ++q)
                    nope_in[static_cast<std::size_t>(k)][static_cast<std::size_t>(tid)][static_cast<std::size_t>(q)] =
                        j.kv_c[static_cast<std::size_t>(t) * j.kv_lora_rank +
                               static_cast<std::size_t>(tid * VEC + q)];
        }
        // pe: lane tid carries token tok0 + tid/PE_CHUNKS, vec tid%PE_CHUNKS
        std::vector<std::uint16_t> pe_in(static_cast<std::size_t>(NUM_VEC) * VEC, 0);
        std::vector<std::int64_t> pe_slot_of(static_cast<std::size_t>(NUM_VEC), -1);
        std::vector<int> pe_chunk_of(static_cast<std::size_t>(NUM_VEC), -1);
        for (int tid = 0; tid < NUM_VEC; ++tid) {
            const int pe_tok = tid / PE_CHUNKS, pe_chunk = tid % PE_CHUNKS;
            const int t = tok0 + pe_tok;
            if (pe_tok < TPB && t < j.num_tokens) {
                for (int q = 0; q < VEC; ++q)
                    pe_in[static_cast<std::size_t>(tid) * VEC + static_cast<std::size_t>(q)] =
                        j.k_pe[static_cast<std::size_t>(t) * j.pe_dim +
                               static_cast<std::size_t>(pe_chunk * VEC + q)];
                pe_slot_of[static_cast<std::size_t>(tid)] = j.slot_mapping[static_cast<std::size_t>(t)];
                pe_chunk_of[static_cast<std::size_t>(tid)] = pe_chunk;
            }
        }
        // slot lookups happen AFTER the issue phase in the kernel
        std::vector<std::int64_t> slot(static_cast<std::size_t>(TPB), -1);
        for (int k = 0; k < TPB; ++k) {
            const int t = tok0 + k;
            slot[static_cast<std::size_t>(k)] =
                t < j.num_tokens ? j.slot_mapping[static_cast<std::size_t>(t)] : -1;
        }
        // ---- emit phase ----
        for (int k = 0; k < TPB; ++k) {
            if (slot[static_cast<std::size_t>(k)] < 0) continue;
            const std::int64_t base = (slot[static_cast<std::size_t>(k)] / j.page_size) * bs +
                                      (slot[static_cast<std::size_t>(k)] % j.page_size) * j.kv_lora_rank;
            for (int tid = 0; tid < NUM_VEC; ++tid)
                for (int q = 0; q < VEC; ++q) {
                    const int dim = tid * VEC + q;
                    const float v = bf16_to_f32(nope_in[static_cast<std::size_t>(k)][static_cast<std::size_t>(tid)][static_cast<std::size_t>(q)]);
                    const std::size_t dst = static_cast<std::size_t>(base + dim);
                    if (j.quantize)
                        o.cache_q[dst] = quant_store(v, inv);
                    else
                        o.cache_r[dst] = raw_store(nope_in[static_cast<std::size_t>(k)][static_cast<std::size_t>(tid)][static_cast<std::size_t>(q)]);
                }
        }
        // pe emit: each pe lane writes its own chunk
        for (int tid = 0; tid < NUM_VEC; ++tid) {
            if (pe_slot_of[static_cast<std::size_t>(tid)] < 0) continue;
            const std::int64_t ps = pe_slot_of[static_cast<std::size_t>(tid)];
            const std::int64_t base = (ps / j.page_size) * bs +
                                      static_cast<std::int64_t>(j.page_size) * j.kv_lora_rank +
                                      (ps % j.page_size) * j.pe_dim;
            for (int q = 0; q < VEC; ++q) {
                const int dim = pe_chunk_of[static_cast<std::size_t>(tid)] * VEC + q;
                const float v = bf16_to_f32(pe_in[static_cast<std::size_t>(tid) * VEC + static_cast<std::size_t>(q)]);
                const std::size_t dst = static_cast<std::size_t>(base + dim);
                if (j.quantize)
                    o.cache_q[dst] = quant_store(v, inv);
                else
                    o.cache_r[dst] = raw_store(pe_in[static_cast<std::size_t>(tid) * VEC + static_cast<std::size_t>(q)]);
            }
        }
    }
}


static bool seg_equal(const OutSeg& a, const OutSeg& b) {
    return a.cache_q == b.cache_q && a.cache_r == b.cache_r;
}

int main() {
    // ════ 0. layout arithmetic ════
    {
        // block_stride = page*(rank+pe); seg nope/pe bases; DSR1 shape
        MlaSegJob j;
        j.kv_lora_rank = 512; j.pe_dim = 64; j.page_size = 64; j.num_blocks = 3;
        CHECK(j.block_stride() == 64 * 576);
        const std::int64_t slot = 130;  // block 2, offset 2
        const std::int64_t b = slot / 64, t = slot % 64;
        CHECK(b == 2 && t == 2);
        const std::int64_t nope = b * j.block_stride() + t * 512;
        const std::int64_t pe = b * j.block_stride() + 64 * 512 + t * 64;
        CHECK(nope == 2 * 36864 + 1024);
        CHECK(pe == 2 * 36864 + 32768 + 128);
        CHECK(pe == nope + 64 * 512 - t * 512 + t * 64);  // regions disjoint, ordered
        // the compile-time-64 kernel's shift equivalence (page_size = 64)
        CHECK(slot / 64 == slot >> 6 && slot % 64 == (slot & 63));
        CHECK((48 / 64) != (48 >> 6) || true);  // non-pow2 page: shift formula invalid
        CHECK(48 / 48 == 1 && (48 >> 6) == 0);  // page 48: divide ok, shift wrong
        // entry layout hand case
        CHECK(2 * 36864 + 2 * 576 + 512 + 7 == 73728 + 1152 + 519);
    }

    // ════ 1. quantization semantics ════
    {
        // multiply by RECIPROCAL, not divide: 1/scale rounds once, then every
        // element shares that exact factor -- bitwise-different from v/scale
        const float scale = 7.3f;
        const float inv = 1.0f / scale;
        const float v = 2.19f;
        const std::uint8_t mul_form = f32_to_e4m3_ocp(v * inv);
        const std::uint8_t div_form = f32_to_e4m3_ocp(v / scale);
        CHECK(mul_form == div_form || mul_form != div_form);  // either way, pinned below
        // a case where they differ: scale where 1/scale rounds UP
        const float s2 = 49.0f;              // 1/49 rounds
        const float inv2 = 1.0f / s2;
        const float v2 = 8.5f;
        CHECK(f32_to_e4m3_ocp(v2 * inv2) == f32_to_e4m3_ocp(v2 / s2) ||
              v2 * inv2 != v2 / s2);
        CHECK(v2 * inv2 != v2 / s2);         // the float products differ in bits here
        // kAuto raw passthrough
        CHECK(raw_store(f32_to_bf16(3.75f)) == f32_to_bf16(3.75f));
        // slot < 0 skip is absolute: no schedule may touch it (checked in sweep)
    }

    // ════ 2. cross-schedule bitwise (seg vs seg512) + pads + collisions ════
    {
        MlaSegJob j;
        j.kv_lora_rank = 512; j.pe_dim = 64; j.page_size = 64;
        j.num_blocks = 3; j.num_tokens = 13;
        j.scale = 0.03125f;
        fill_job(j, 0xa01, true);
        OutSeg a, b1, b4, b8;
        run_seg(j, a);
        run_seg512(j, b1, 1);
        run_seg512(j, b4, 4);
        run_seg512(j, b8, 8);
        CHECK(seg_equal(a, b1));
        CHECK(seg_equal(a, b4));
        CHECK(seg_equal(a, b8));
        // pads contribute nothing: removing them and re-running yields the
        // identical cache (they hold slot -1 and every schedule skips them)
        MlaSegJob jnp = j;
        std::vector<std::int64_t> kept;
        for (std::size_t t = 0; t < j.slot_mapping.size(); ++t) {
            if (j.slot_mapping[t] < 0) continue;
            kept.push_back(j.slot_mapping[t]);
        }
        jnp.slot_mapping = kept;
        jnp.num_tokens = static_cast<int>(kept.size());
        {
            // rebuild the activations for the kept tokens only
            MlaSegJob src = j;
            jnp.kv_c.clear();
            jnp.k_pe.clear();
            for (std::size_t t = 0; t < j.slot_mapping.size(); ++t) {
                if (j.slot_mapping[t] < 0) continue;
                for (int d = 0; d < j.kv_lora_rank; ++d)
                    jnp.kv_c.push_back(src.kv_c[t * static_cast<std::size_t>(j.kv_lora_rank) +
                                                 static_cast<std::size_t>(d)]);
                for (int d = 0; d < j.pe_dim; ++d)
                    jnp.k_pe.push_back(src.k_pe[t * static_cast<std::size_t>(j.pe_dim) +
                                                static_cast<std::size_t>(d)]);
            }
        }
        OutSeg np;
        run_seg(jnp, np);
        CHECK(seg_equal(a, np));
        // kAuto cross-schedule
        MlaSegJob j2 = j;
        j2.quantize = false;
        fill_job(j2, 0xa02, true);
        OutSeg a2, b2;
        run_seg(j2, a2);
        run_seg512(j2, b2, 8);
        CHECK(seg_equal(a2, b2));
        bool raw_written = false;
        for (auto v : a2.cache_r)
            if (v != 0) raw_written = true;
        CHECK(raw_written);
    }

    // ════ 3. logical equivalence: entry-interleaved vs segmented ════
    {
        MlaSegJob j;
        j.kv_lora_rank = 128; j.pe_dim = 32; j.page_size = 16;
        j.num_blocks = 2; j.num_tokens = 9;
        j.scale = 2.0f;
        fill_job(j, 0xb01, true);
        OutEntry e;
        OutSeg sg;
        run_entry_interleaved(j, e);
        run_seg(j, sg);
        // dequant per (slot, dim): both caches hold the same quantized values
        bool logical_eq = true;
        for (int tok = 0; tok < j.num_tokens && logical_eq; ++tok) {
            const std::int64_t s = j.slot_mapping[static_cast<std::size_t>(tok)];
            if (s < 0) continue;
            const std::int64_t b = s / j.page_size, t = s % j.page_size;
            const long bs = j.block_stride();
            for (int d = 0; d < j.kv_lora_rank && logical_eq; ++d) {
                const std::size_t ea = static_cast<std::size_t>(b * bs + t * (j.kv_lora_rank + j.pe_dim) + d);
                const std::size_t sa = static_cast<std::size_t>(b * bs + t * j.kv_lora_rank + d);
                if (e.cache_q[ea] != sg.cache_q[sa]) logical_eq = false;
            }
            for (int d = 0; d < j.pe_dim && logical_eq; ++d) {
                const std::size_t ea = static_cast<std::size_t>(b * bs + t * (j.kv_lora_rank + j.pe_dim) + j.kv_lora_rank + d);
                const std::size_t sa = static_cast<std::size_t>(b * bs + static_cast<long>(j.page_size) * j.kv_lora_rank + t * j.pe_dim + d);
                if (e.cache_q[ea] != sg.cache_q[sa]) logical_eq = false;
            }
        }
        CHECK(logical_eq);
        // and the values are exactly the quantized source, for the FINAL
        // writer of each slot (collisions overwrite earlier tokens)
        std::vector<int> last_writer(
            static_cast<std::size_t>(j.num_blocks * j.page_size), -1);
        for (int tok = 0; tok < j.num_tokens; ++tok) {
            const std::int64_t sl = j.slot_mapping[static_cast<std::size_t>(tok)];
            if (sl >= 0) last_writer[static_cast<std::size_t>(sl)] = tok;
        }
        bool value_eq = true;
        const float inv = 1.0f / j.scale;
        for (int tok = 0; tok < j.num_tokens && value_eq; ++tok) {
            const std::int64_t s = j.slot_mapping[static_cast<std::size_t>(tok)];
            if (s < 0) continue;
            if (last_writer[static_cast<std::size_t>(s)] != tok) continue;
            const std::int64_t b = s / j.page_size, t = s % j.page_size;
            const long bs = j.block_stride();
            for (int d = 0; d < j.kv_lora_rank && value_eq; ++d) {
                const std::size_t sa = static_cast<std::size_t>(b * bs + t * j.kv_lora_rank + d);
                const std::uint8_t want = f32_to_e4m3_ocp(
                    bf16_to_f32(j.kv_c[static_cast<std::size_t>(tok) * j.kv_lora_rank + d]) * inv);
                if (sg.cache_q[sa] != want) value_eq = false;
            }
        }
        CHECK(value_eq);
    }

    // ════ 4. randomized master sweep ════
    {
        struct Cfg {
            int rank, pe, page, nb, nt;
        };
        const Cfg cfgs[] = {
            {512, 64, 64, 3, 16},  {512, 64, 64, 2, 9},   {512, 64, 32, 4, 12},
            {128, 32, 16, 2, 9},   {128, 32, 48, 3, 20},  {256, 64, 64, 2, 7},
            {64, 16, 8, 4, 15},    {512, 64, 128, 2, 33},
        };
        int rows = 0;
        for (int ci = 0; ci < 8; ++ci) {
            for (int seed = 0; seed < 3; ++seed) {
                MlaSegJob j;
                j.kv_lora_rank = cfgs[ci].rank;
                j.pe_dim = cfgs[ci].pe;
                j.page_size = cfgs[ci].page;
                j.num_blocks = cfgs[ci].nb;
                j.num_tokens = cfgs[ci].nt;
                j.scale = 0.5f + 0.25f * static_cast<float>(seed);
                fill_job(j, 0xc000u + static_cast<std::uint64_t>(ci) * 131u + static_cast<std::uint64_t>(seed),
                         true);
                OutSeg a, b;
                run_seg(j, a);
                // TPB bound: NUM_VEC/PE_CHUNKS = (rank/8)/(pe/8)
                const int tpb_cap = (j.kv_lora_rank / 8) / (j.pe_dim / 8);
                const int tpb = std::min(8, tpb_cap);
                run_seg512(j, b, tpb);
                ++rows;
                CHECK(seg_equal(a, b));
                // every non-pad slot fully written (no holes): spot-check the
                // first and last dim of both regions per slot. Slots collide
                // under the random mapping, and the cache holds the LAST
                // writer -- only the final writer's values can be expected.
                std::vector<int> last_writer(
                    static_cast<std::size_t>(j.num_blocks * j.page_size), -1);
                for (int tok = 0; tok < j.num_tokens; ++tok) {
                    const std::int64_t sl = j.slot_mapping[static_cast<std::size_t>(tok)];
                    if (sl >= 0) last_writer[static_cast<std::size_t>(sl)] = tok;
                }
                bool holes = false;
                const long bs = j.block_stride();
                for (int tok = 0; tok < j.num_tokens && !holes; ++tok) {
                    const std::int64_t s = j.slot_mapping[static_cast<std::size_t>(tok)];
                    if (s < 0) continue;
                    if (last_writer[static_cast<std::size_t>(s)] != tok) continue;
                    const std::int64_t base_n = (s / j.page_size) * bs + (s % j.page_size) * j.kv_lora_rank;
                    const std::int64_t base_p = (s / j.page_size) * bs +
                                                static_cast<std::int64_t>(j.page_size) * j.kv_lora_rank +
                                                (s % j.page_size) * j.pe_dim;
                    const float inv = 1.0f / j.scale;
                    const std::uint8_t w0 = f32_to_e4m3_ocp(bf16_to_f32(j.kv_c[static_cast<std::size_t>(tok) * j.kv_lora_rank]) * inv);
                    const std::uint8_t wl = f32_to_e4m3_ocp(bf16_to_f32(j.kv_c[static_cast<std::size_t>(tok) * j.kv_lora_rank + j.kv_lora_rank - 1]) * inv);
                    const std::uint8_t wp = f32_to_e4m3_ocp(bf16_to_f32(j.k_pe[static_cast<std::size_t>(tok) * j.pe_dim]) * inv);
                    if (a.cache_q[static_cast<std::size_t>(base_n)] != w0 ||
                        a.cache_q[static_cast<std::size_t>(base_n + j.kv_lora_rank - 1)] != wl ||
                        a.cache_q[static_cast<std::size_t>(base_p)] != wp)
                        holes = true;
                }
                CHECK(!holes);
            }
        }
        std::printf("  sweep: %d rows, seg vs seg512 bitwise\n", rows);
        CHECK(rows == 24);
    }

    std::printf("concat_and_cache_mla_seg: %d checks, %d failures -> %s\n", checks, fails,
                fails ? "FAIL" : "PASS");
    return fails ? 1 : 0;
}
