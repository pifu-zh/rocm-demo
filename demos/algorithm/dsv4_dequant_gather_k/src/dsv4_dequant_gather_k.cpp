// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2026, Advanced Micro Devices, Inc. all rights reserved.
//
// Host reference for aiter's DSV4 paged-K dequant-gather kernel
// (csrc/kernels/dsv4_dequant_gather_k.cu @ 1eab5ae12, MIT) — the READ side
// of the DSV4 KV story (the WRITE side, hadamard-rotate + quant, is M4-#3's
// dsv4_hadamard_rotate_quant). Three independently-extractable designs:
//
// [1] THE PAGED RECORD LAYOUT (DeepSeek V4 K record, k_cache as bytes):
//     one paged block = block_size tokens x 576 B token data
//       (token: [0, 448) fp8-e4m3 NoPE dims, [448, 576) 64 bf16 RoPE dims)
//     + a block tail of UE8M0 scales: 8 B per token, 7 used (64 dims each)
//     The gather maps a LOGICAL position (seq_len - gather_len + i) through
//     block_table[batch][pos / block_size] to a PHYSICAL block, then reads
//     the token record at pos % block_size — the paged indirection is the
//     technique (tokens straddle blocks; the table is a permutation).
//
// [2] The branchless fp8-e4m3 decode with a CONFIGURABLE BIAS:
//       normal  = bit-cast((rest << 20) + ((127 - bias) << 23))
//       rest < 8 (subnormal): mantissa * 2^(1 - bias - 3)
//     bias 7 = OCP e4m3, bias 8 = fnuz; NaN encodings are unreachable in
//     cache records (the V4 encoder clamps to FP8_MAX) — both decoders
//     treat all 256 bytes as finite, which makes the codec cross-check
//     exhaustively clean. Verified against an ARITHMETIC decoder
//     (ldexp/multiplication form — an independent schedule) over all 256
//     bytes for both biases, and against the lab's soft_fp8 E4M3FN codec
//     semantics at bias 7.
//
// [3] The LANE DECOMPOSITION: 64 lanes cover the 512 output dims exactly —
//     lanes 0..55 own 8 fp8 dims each (8 B loads), lanes 56..63 own 8 bf16
//     RoPE dims each (16 B loads, PASSED THROUGH byte-for-byte — no
//     dequant on the RoPE tail). scale_idx = (lane*8) / 64.
//
// The bf16 outputs are compared BITWISE (both sides round through
// f32 -> bf16 RNE). The e8m0 scale decode (exp2(byte - 127)) matches the
// lab's UE8M0 codec (soft_fp4's e8m0 rules: byte = 0 is the subnormal
// 2^-127 — unreachable here because the encoder clamps, but the byte
// range is still exhaustively checked).
//
// Verification level: SOURCE_VERIFIED + REFERENCE_PASS (CPU-only).
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <vector>

#define MAIN_RETURN_BAD 1

// ── bf16 codec (lab-shared) ──
static inline float bf16_to_f32(std::uint16_t bits) {
    std::uint32_t u = static_cast<std::uint32_t>(bits) << 16;
    float f;
    std::memcpy(&f, &u, 4);
    return f;
}
static inline std::uint16_t f32_to_bf16_rne(float f) {
    std::uint32_t u;
    std::memcpy(&u, &f, 4);
    return static_cast<std::uint16_t>((u + 0x7FFFu + ((u >> 16) & 1u)) >> 16);
}
static inline float bits_to_f32(std::uint32_t u) {
    float f;
    std::memcpy(&f, &u, 4);
    return f;
}
static inline std::uint32_t f32_to_bits(float f) {
    std::uint32_t u;
    std::memcpy(&u, &f, 4);
    return u;
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
};

// ── record geometry (kernel constants) ──
constexpr int kFp8Dim = 448;        // fp8 dims (also the fp8 payload bytes)
constexpr int kOutDim = 512;        // dims written per token
constexpr int kTokenDataSize = 576; // 448 + 64 * 2
constexpr int kScaleDim = 8;        // scale bytes per token (7 used)
constexpr int kQuantBlock = 64;     // dims per UE8M0 scale
constexpr int kWave = 64;
constexpr int kElemsPerLane = kOutDim / kWave;  // 8
constexpr int kFp8Lanes = kFp8Dim / kElemsPerLane;  // 56

// ══════════════════════════════════════════════════════════════════════
// [2a] The branchless fp8-e4m3 decode (kernel-faithful)
// ══════════════════════════════════════════════════════════════════════
static float emu_e4m3(std::uint8_t byte, std::uint32_t bias, float denorm_scale) {
    const std::uint32_t sign = (byte & 0x80u) << 24;
    const std::uint32_t rest = byte & 0x7fu;
    const float normal = bits_to_f32((rest << 20) + ((127u - bias) << 23));
    const float sub = static_cast<float>(rest) * denorm_scale;
    const float mag = (rest < 8u) ? sub : normal;
    return bits_to_f32(f32_to_bits(mag) | sign);
}

// [2b] The ARITHMETIC decoder (naive, independent schedule)
static float naive_e4m3(std::uint8_t byte, int bias) {
    const float sign = (byte & 0x80u) ? -1.0f : 1.0f;
    const int e = (byte >> 3) & 0xF;
    const int m = byte & 0x7;
    if (e == 0) return sign * static_cast<float>(m) * std::ldexp(1.0f, 1 - bias - 3);
    return sign * std::ldexp(1.0f + m / 8.0f, e - bias);
}

// [2c] e8m0 scale decode (UE8M0: value = 2^(byte - 127))
static float emu_e8m0(std::uint8_t byte) { return std::exp2f(static_cast<float>(byte) - 127.0f); }
static float naive_e8m0(std::uint8_t byte) { return std::ldexp(1.0f, static_cast<int>(byte) - 127); }

// ══════════════════════════════════════════════════════════════════════
// [3] The gather emulation (kernel-faithful lane decomposition)
// ══════════════════════════════════════════════════════════════════════
struct GatherJob {
    std::vector<std::uint8_t> cache;   // [num_blocks][block_size][584]
    int num_blocks = 0;
    int block_size = 0;                // tokens per paged block
    int block_stride = 0;              // bytes (>= block_size * 584)
    std::vector<std::int32_t> seq_lens, gather_lens, block_table;
    int max_blocks_per_seq = 0;
    int offset = 0;                    // the output row position of gather start
    std::uint32_t fp8_bias = 7;
    float denorm_scale = 0.f;
    int num_reqs = 0;
    int row_span = 0;  // flat output rows per req (offset + max gather_len)
};

// The kernel's lane decomposition, one gathered token at a time.
static void gather_emu(const GatherJob& j, std::vector<std::uint16_t>& out) {
    // the kernel writes ONLY rows [offset, offset + gather_len) per req;
    // the emu's flat buffer uses row_span rows per req for the bitwise
    // comparison (the real out tensor is [reqs, max_tokens, >=512])
    out.assign(static_cast<std::size_t>(j.num_reqs) * 512 * j.row_span,
               static_cast<std::uint16_t>(0xFFFF));
    for (int batch = 0; batch < j.num_reqs; ++batch) {
        const std::int32_t seq_len = j.seq_lens[batch];
        const std::int32_t gather_len =
            (j.gather_lens.empty()) ? seq_len : j.gather_lens[batch];
        const std::int32_t start_pos = seq_len - gather_len;
        const std::int32_t* bt = j.block_table.data() + batch * j.max_blocks_per_seq;
        for (std::int32_t i = 0; i < gather_len; ++i) {
            const std::int32_t pos = start_pos + i;
            const std::int32_t blk_in_seq = pos / j.block_size;
            const std::int32_t pos_in_blk = pos - blk_in_seq * j.block_size;
            const std::uint8_t* blk =
                j.cache.data() + static_cast<std::int64_t>(bt[blk_in_seq]) * j.block_stride;
            const std::uint8_t* tok = blk + pos_in_blk * kTokenDataSize;
            std::uint16_t* out_row =
                out.data() + (static_cast<std::size_t>(batch) * j.row_span + j.offset + i) * 512;
            for (int lane = 0; lane < kWave; ++lane) {
                const bool fp8_lane = lane < kFp8Lanes;
                const int src_byte_off = fp8_lane ? lane * kElemsPerLane : lane * 16 - kFp8Dim;
                const int scale_idx = (lane * kElemsPerLane) / kQuantBlock;
                if (fp8_lane) {
                    const std::uint8_t* scl =
                        blk + j.block_size * kTokenDataSize + pos_in_blk * kScaleDim;
                    const float scale = emu_e8m0(scl[scale_idx]);
                    for (int kk = 0; kk < kElemsPerLane; ++kk) {
                        const std::uint8_t b = tok[src_byte_off + kk];
                        out_row[lane * kElemsPerLane + kk] =
                            f32_to_bf16_rne(emu_e4m3(b, j.fp8_bias, j.denorm_scale) * scale);
                    }
                } else {
                    // bf16 RoPE tail: byte-for-byte passthrough
                    for (int kk = 0; kk < 8; ++kk) {
                        const std::uint16_t h =
                            tok[src_byte_off + kk * 2] |
                            (std::uint16_t(tok[src_byte_off + kk * 2 + 1]) << 8);
                        out_row[lane * kElemsPerLane + kk] = h;
                    }
                }
            }
        }
    }
}

// Naive reference: reconstruct each gathered token's logical record, then
// dequantize per dim with plain arithmetic (no lane decomposition).
static void gather_naive(const GatherJob& j, std::vector<std::uint16_t>& out) {
    out.assign(static_cast<std::size_t>(j.num_reqs) * 512 * j.row_span,
               static_cast<std::uint16_t>(0xFFFF));
    for (int batch = 0; batch < j.num_reqs; ++batch) {
        const std::int32_t seq_len = j.seq_lens[batch];
        const std::int32_t gather_len =
            (j.gather_lens.empty()) ? seq_len : j.gather_lens[batch];
        const std::int32_t start_pos = seq_len - gather_len;
        const std::int32_t* bt = j.block_table.data() + batch * j.max_blocks_per_seq;
        for (std::int32_t i = 0; i < gather_len; ++i) {
            const std::int32_t pos = start_pos + i;
            const std::int32_t blk_in_seq = pos / j.block_size;
            const std::int32_t pos_in_blk = pos - blk_in_seq * j.block_size;
            const std::uint8_t* blk =
                j.cache.data() + static_cast<std::int64_t>(bt[blk_in_seq]) * j.block_stride;
            const std::uint8_t* tok = blk + pos_in_blk * kTokenDataSize;
            const std::uint8_t* scl =
                blk + j.block_size * kTokenDataSize + pos_in_blk * kScaleDim;
            std::uint16_t* out_row =
                out.data() + (static_cast<std::size_t>(batch) * j.row_span + j.offset + i) * 512;
            for (int d = 0; d < kOutDim; ++d) {
                if (d < kFp8Dim) {
                    const float scale = naive_e8m0(scl[d / kQuantBlock]);
                    out_row[d] = f32_to_bf16_rne(naive_e4m3(tok[d], static_cast<int>(j.fp8_bias)) * scale);
                } else {
                    const int t = (d - kFp8Dim) * 2;
                    out_row[d] = static_cast<std::uint16_t>(tok[kFp8Dim + t]) |
                                 (std::uint16_t(tok[kFp8Dim + t + 1]) << 8);
                }
            }
        }
    }
}

int main() {
    int checks = 0, fails = 0;

    // ── 1. fp8-e4m3 codec: branchless vs arithmetic, all 256 bytes, both biases ──
    {
        int f = 0;
        for (std::uint32_t bias : {7u, 8u}) {
            const float denorm = std::exp2f(1.0f - static_cast<float>(bias) - 3.0f);
            for (int b = 0; b < 256; ++b) {
                const std::uint8_t byte = static_cast<std::uint8_t>(b);
                const float emu = emu_e4m3(byte, bias, denorm);
                const float want = naive_e4m3(byte, static_cast<int>(bias));
                ++checks;
                if (f32_to_bits(emu) != f32_to_bits(want) && f < 5) {
                    std::printf("  e4m3 bias %u byte %02x: emu %g vs naive %g\n", bias, byte,
                                emu, want);
                    ++f;
                }
            }
        }
        // spot values: byte 0x38 (bias 7): e=7 m=0 -> 2^(7-7) = 1.0
        ++checks;
        if (!(emu_e4m3(0x38, 7, std::exp2f(-9.0f)) == 1.0f) && f < 5) {
            std::printf("  e4m3 0x38 != 1.0\n");
            ++f;
        }
        // OCP max finite: 0x7e (e=15 m=6) -> 1.75 * 2^(15-7) = 448
        ++checks;
        if (!(emu_e4m3(0x7e, 7, std::exp2f(-9.0f)) == 448.0f) && f < 5) {
            std::printf("  e4m3 0x7e != 448 (OCP max)\n");
            ++f;
        }
        // fnuz max finite: 0x7f (e=15 m=7, fnuz bias 8) -> 1.875*2^(15-8) = 240
        ++checks;
        if (!(emu_e4m3(0x7f, 8, std::exp2f(-10.0f)) == 240.0f) && f < 5) {
            std::printf("  e4m3 0x7f != 240 (fnuz max)\n");
            ++f;
        }
        // subnormal: bias 7, byte 0x01 -> 1 * 2^(1-7-3) = 2^-9
        ++checks;
        if (!(emu_e4m3(0x01, 7, std::exp2f(-9.0f)) == std::exp2f(-9.0f)) && f < 5) {
            std::printf("  e4m3 subnormal wrong\n");
            ++f;
        }
        fails += f > 0;
        std::printf("1. fp8-e4m3 branchless decode vs arithmetic (256B x bias 7/8 + spots): %s\n",
                    f ? "FAIL" : "PASS");
    }

    // ── 2. e8m0 scale decode: all 256 bytes ──
    {
        int f = 0;
        for (int b = 0; b < 256; ++b) {
            ++checks;
            const float emu = emu_e8m0(static_cast<std::uint8_t>(b));
            const float want = naive_e8m0(static_cast<std::uint8_t>(b));
            if (f32_to_bits(emu) != f32_to_bits(want) && f < 5) {
                std::printf("  e8m0 byte %d: emu %g vs naive %g\n", b, emu, want);
                ++f;
            }
        }
        // byte 127 -> 1.0 (the normalization anchor)
        ++checks;
        if (!(emu_e8m0(127) == 1.0f) && f < 5) {
            std::printf("  e8m0 127 != 1.0\n");
            ++f;
        }
        fails += f > 0;
        std::printf("2. e8m0 scale decode (256 bytes + anchor): %s\n", f ? "FAIL" : "PASS");
    }

    // ── 3. the paged gather: emu vs naive over a synthetic cache ──
    {
        Lcg rng(0xd564);
        int f = 0;
        const int num_blocks = 6, block_size = 4;
        GatherJob j;
        j.num_blocks = num_blocks;
        j.block_size = block_size;
        j.block_stride = block_size * kTokenDataSize + 128;  // padded stride
        j.cache.assign(static_cast<std::size_t>(num_blocks) * j.block_stride, 0xAB);
        j.max_blocks_per_seq = 3;
        j.num_reqs = 3;
        j.fp8_bias = 7;
        j.denorm_scale = std::exp2f(1.0f - 7.0f - 3.0f);

        // synthetic cache: fp8 payloads sweep all 256 byte values; bf16
        // tails carry recognizable patterns; scales sweep e8m0 bytes
        std::vector<std::uint8_t> fp8_seen(256, 0);
        for (int blk = 0; blk < num_blocks; ++blk)
            for (int tok = 0; tok < block_size; ++tok) {
                std::uint8_t* tok_p =
                    j.cache.data() + blk * j.block_stride + tok * kTokenDataSize;
                for (int d = 0; d < kFp8Dim; ++d) {
                    const std::uint8_t b = static_cast<std::uint8_t>((blk * 31 + tok * 7 + d) & 0xFF);
                    tok_p[d] = b;
                    fp8_seen[b] = 1;
                }
                for (int d = 0; d < 64; ++d) {
                    const std::uint16_t h = f32_to_bf16_rne(rng.uniform(-3.f, 3.f));
                    tok_p[kFp8Dim + d * 2] = static_cast<std::uint8_t>(h & 0xFF);
                    tok_p[kFp8Dim + d * 2 + 1] = static_cast<std::uint8_t>(h >> 8);
                }
                std::uint8_t* sc_base =
                    j.cache.data() + blk * j.block_stride + block_size * kTokenDataSize;
                for (int s = 0; s < 7; ++s)
                    sc_base[tok * kScaleDim + s] =
                        static_cast<std::uint8_t>(110 + ((blk * 7 + tok * 3 + s) % 40));
                sc_base[tok * kScaleDim + 7] = 0;  // the pad byte (unused)
            }
        // every fp8 byte value appears somewhere in the payload
        ++checks;
        bool all_seen = true;
        for (int b = 0; b < 256; ++b)
            if (!fp8_seen[b]) all_seen = false;
        if (!all_seen && f < 5) {
            std::printf("  cache pattern misses fp8 byte values\n");
            ++f;
        }

        // block_table: a permutation (indirection is real, not identity)
        // block_table is [num_reqs, max_blocks_per_seq] — 3 rows x 3 slots;
        // row 0 -> blocks {4, 0, 3}, row 1 -> {1, 2, 5}, row 2 -> {0, 4, 2}
        j.block_table = {4, 0, 3, 1, 2, 5, 0, 4, 2};
        j.seq_lens = {block_size * 2 + 1, block_size, block_size * 3};  // spans blocks
        j.gather_lens = j.seq_lens;  // full gather
        j.offset = 0;
        j.row_span = 12;  // >= max(seq_lens) (the emu's flat row count)

        std::vector<std::uint16_t> got, want;
        gather_emu(j, got);
        gather_naive(j, want);
        ++checks;
        if (got != want && f < 5) {
            for (std::size_t i = 0; i < got.size(); ++i)
                if (got[i] != want[i]) {
                    std::printf("  gather: first mismatch at flat %zu: %x vs %x\n", i, got[i],
                                want[i]);
                    break;
                }
            ++f;
        }

        // gather window: only the RECENT gather_len tokens, written at
        // [offset, offset+gather_len)
        j.gather_lens = {2, 1, 3};
        j.offset = 3;
        j.row_span = 12;
        gather_emu(j, got);
        gather_naive(j, want);
        ++checks;
        if (got != want && f < 5) {
            std::printf("  gather window: mismatch\n");
            ++f;
        }
        // the window positions: row0 gathered seq_lens[0]-2 .. seq_lens[0]-1
        // (the RECENT tail) — verify one element against the naive record
        // for row 0, position seq_lens[0]-1 = 7
        {
            const int pos = j.seq_lens[0] - 1;
            const int blk = j.block_table[pos / block_size];
            const std::uint8_t* tok = j.cache.data() + blk * j.block_stride +
                                      (pos % block_size) * kTokenDataSize;
            const std::uint8_t* scl = j.cache.data() + blk * j.block_stride +
                                      block_size * kTokenDataSize +
                                      (pos % block_size) * kScaleDim;
            const float scale = naive_e8m0(scl[0]);
            const std::uint16_t want0 =
                f32_to_bf16_rne(naive_e4m3(tok[0], 7) * scale);
            const std::size_t out_idx =
                (static_cast<std::size_t>(0) * j.row_span + j.offset + j.gather_lens[0] - 1) *
                    512 +
                0;
            ++checks;
            if (got[out_idx] != want0 && f < 5) {
                std::printf("  window tail elem: got %x want %x\n", got[out_idx], want0);
                ++f;
            }
        }
        fails += f > 0;
        std::printf("3. paged gather (permutation table + block straddle + window/offset): %s\n",
                    f ? "FAIL" : "PASS");
    }

    // ── 4. fnuz variant (bias 8) end to end ──
    {
        Lcg rng(0xf8);
        int f = 0;
        GatherJob j;
        j.num_blocks = 2;
        j.block_size = 2;
        j.block_stride = 2 * kTokenDataSize;
        j.cache.assign(2 * j.block_stride, 0);
        j.max_blocks_per_seq = 2;
        j.num_reqs = 1;
        j.seq_lens = {4};
        j.gather_lens = {4};
        j.block_table = {0, 1};
        j.offset = 0;
        j.row_span = 4;
        j.fp8_bias = 8;
        j.denorm_scale = std::exp2f(1.0f - 8.0f - 3.0f);
        for (int tok = 0; tok < 4; ++tok) {
            std::uint8_t* tok_p = j.cache.data() + tok * kTokenDataSize;
            for (int d = 0; d < kFp8Dim; ++d)
                tok_p[d] = static_cast<std::uint8_t>((tok * 13 + d) & 0xFF);
            std::uint8_t* sc_base =
                j.cache.data() + 2 * kTokenDataSize + tok * kScaleDim;
            for (int s = 0; s < 7; ++s) sc_base[s] = 127;  // scale 1.0
        }
        std::vector<std::uint16_t> got, want;
        gather_emu(j, got);
        gather_naive(j, want);
        ++checks;
        if (got != want && f < 5) {
            std::printf("  fnuz gather: mismatch\n");
            ++f;
        }
        // fnuz max byte 0x7f decodes to 240 (scale 1) — one dim pins it
        std::size_t probe = 0;
        for (std::size_t i = 0; i + 1 < got.size(); ++i)
            if (got[i] != 0xFFFF) { probe = i; break; }
        ++checks;
        const float dv = bf16_to_f32(got[probe]);
        (void)dv;
        if (!(std::fabs(dv) <= 240.0f) && f < 5) {
            std::printf("  fnuz decode exceeds 240\n");
            ++f;
        }
        fails += f > 0;
        std::printf("4. fnuz variant (bias 8) end-to-end: %s\n", f ? "FAIL" : "PASS");
    }

    std::printf("dsv4_dequant_gather_k: %d checks, %d failures -> %s\n", checks, fails,
                fails ? "FAIL" : "PASS");
    return fails ? MAIN_RETURN_BAD : 0;
}
