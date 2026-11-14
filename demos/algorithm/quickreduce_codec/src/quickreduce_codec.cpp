// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2026, Advanced Micro Devices, Inc. All rights reserved.
//
// Host reference for aiter QuickReduce communication-compression codecs
// (csrc/include/quick_all_reduce.cuh CodecQ4/CodecQ3/CodecQ6 +
// csrc/include/quick_all_reduce_base.h @ 1eab5ae12, MIT). Covers three
// independently-extractable designs:
//
// [1] Block-scaled symmetric int quantization with a SIGN-FLIPPED scale.
//     Per quantization group (8 threads x 8 bf16 lanes = 64 values, two
//     independent scales for the even/odd lane positions via the packed
//     f16x2 halves):
//       decoding_scale = bf16(absmax) * (-1/2^b)        (b = 4/3/6 bits)
//       encoding_scale = rcp(decoding_scale + 1e-7)
//       w              = clip(v * encoding_scale, [-2^b, 2^b - 1])
//       q              = rint(w) + 2^b                   (unsigned [0, 2^(b+1)-1])
//     The flip is the design point: the absmax element maps to exactly the
//     WIDE code point (-2^b, never clipped) while the opposite sign clips
//     at 2^b - 1 — the guaranteed-occurring extreme gets the extra level.
//     The 1e-7 epsilon (kScaleEpsilon) makes all-zero blocks safe
//     (scale=0 -> rcp(eps) -> w=0 -> q=0 -> decode 0*0 = 0, no NaN).
//     On-device rcp is the fast h2rcp; this reference uses exact 1/x
//     (documented substitution — the error bound tolerates ~1 ulp).
//
// [2] Bit-level pack layouts per codec, verified as EXACT integer-domain
//     round trips:
//     - Q4: 8 values -> one uint32 (4-bit fields); recv unpacks through the
//       fp16 mantissa trick ((q & 0xF) | 0x6400 = f16(1024+q), then
//       += -1032 -> q-8) for the half path; bf16 path uses explicit int
//       converts then adds kRangeMin.
//     - Q3: 3-bit unsigned split into low-2 bits (uint16, 2 bits/value) +
//       high-1 bit (uint8, 1 bit/value).
//     - Q6: low 4 bits per value -> uint32; high 2 bits per value -> uint16
//       at (i*2); recv reassembles q6 = q4 | (q2 << 4) and (half path)
//       builds the f16x2 mantissa trick with 1024/-1056.
//
// [3] Tile geometry: per-rank tile strides and region offsets (Q4: payload
//     1024B + scale 128B @ 1024 = 1152B; Q3: q2 512B + q1 256B @ 512 + scale
//     @ 768 = 896B; Q6: q4 1024B + q2 512B @ 1024 + scale @ 1536 = 1664B),
//     with scale written only by the group leader at index thread/8 —
//     verified by round-tripping a full 256-thread tile through byte
//     buffers using the real offsets.
//
// Scope exclusion (NOT extracted, NOT verified here): the IPC/multi-GPU
// communicator machinery around the codecs (buffer registration, flag
// sync two-shot protocol, PullQ4 layout) — this demo is the codec layer
// only, host-verifiable. The PullQ4 path rejects the legacy routes in
// upstream; no claim is made about it here.
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
static inline std::uint16_t f32_to_bf16(float f) { return bf16_round(f); }

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

// ══════════════════════════════════════════════════════════════════════
// Codec parameters (bf16 variants; constants cross-checked from the
// upstream packed hex — see the table in README.md)
// ══════════════════════════════════════════════════════════════════════
struct CodecParams {
    int bits;              // b: 4 / 3 / 6
    float scale_factor;    // -1/2^b (bf16 constant, applied via bf16 mul)
    float scale_epsilon;   // 1e-7 as bf16 (0x33D7 ≈ 1.0007e-7)
    float range_min;       // -2^b
    float range_max;       // +2^b - 1
    int range_bias;        // +2^b (int16 domain)
    int tile_stride;       // kRankTileStride bytes
    int q1_offset;         // kRankTileQ1Offset (Q3) or 0
    int q2_offset;         // kRankTileQ2Offset (Q6) or 0
    int scale_offset;      // kRankTileScaleOffset
    const char* name;
};

static const CodecParams kQ4 = {4, -0.125f, bf16_to_f32(0x33D7), -8.0f, 7.0f, 8, 1152, 0, 0,
                                1024, "Q4"};
static const CodecParams kQ3 = {3, -0.25f, bf16_to_f32(0x33D7), -4.0f, 3.0f, 4, 896, 512, 0,
                                768, "Q3"};
static const CodecParams kQ6 = {6, -1.0f / 32.0f, bf16_to_f32(0x33D7), -32.0f, 31.0f, 32, 1664,
                                0, 1024, 1536, "Q6"};

constexpr int kGroupSize = 8;   // kThreadGroupSize: threads per quant group
constexpr int kBlockSize = 256; // threads per block tile
constexpr int kLanesPerAtom = 8;

// One quantization group: kGroupSize threads, each with kLanesPerAtom bf16
// values. Even/odd lane positions carry independent scales (packed f16x2
// halves of decoding_scale).
struct Group {
    float values[kGroupSize][kLanesPerAtom];
};

struct GroupEncoded {
    // per thread: unsigned quantized values [0, 2^(b+1)-1] in int16 domain
    int q[kGroupSize][kLanesPerAtom];
    // per half: stored bf16 decoding scales (even lanes / odd lanes)
    std::uint16_t scale_even, scale_odd;
};

// group_abs_max emulation: packed max/min across the 8 threads per half,
// then abs-max per half. On device this is a shfl_down chain (masks 1,2,4)
// whose leader value equals this fold; only the leader's result is
// broadcast, so the fold below is the faithful semantic.
static void group_abs_max(const Group& g, float& absmax_even, float& absmax_odd) {
    absmax_even = 0.0f;
    absmax_odd = 0.0f;
    for (int t = 0; t < kGroupSize; ++t) {
        for (int i = 0; i < kLanesPerAtom; i += 2) {
            absmax_even = std::fmax(absmax_even, std::fabs(g.values[t][i]));
            absmax_odd = std::fmax(absmax_odd, std::fabs(g.values[t][i + 1]));
        }
    }
}

// bf16 packed-op semantics: scalar op + bf16 rounding (device packed_mul/
// packed_add round to T at each step).
static GroupEncoded encode_group(const Group& g, const CodecParams& p) {
    GroupEncoded e;
    float amax_e, amax_o;
    group_abs_max(g, amax_e, amax_o);
    // decoding_scale = bf16(absmax) * scale_factor  (packed bf16 mul rounds)
    const std::uint16_t amax_e_bf = f32_to_bf16(amax_e);
    const std::uint16_t amax_o_bf = f32_to_bf16(amax_o);
    e.scale_even = bf16_round(bf16_to_f32(amax_e_bf) * p.scale_factor);
    e.scale_odd = bf16_round(bf16_to_f32(amax_o_bf) * p.scale_factor);
    // encoding_scale = rcp(decoding_scale + eps) — device uses h2rcp
    // (approximate); host reference uses exact reciprocal (documented).
    const float enc_e =
        1.0f / (bf16_to_f32(e.scale_even) + p.scale_epsilon);
    const float enc_o = 1.0f / (bf16_to_f32(e.scale_odd) + p.scale_epsilon);

    for (int t = 0; t < kGroupSize; ++t)
        for (int i = 0; i < kLanesPerAtom; ++i) {
            const bool even = (i % 2) == 0;
            const float enc = even ? enc_e : enc_o;
            float w = bf16_to_f32(f32_to_bf16(g.values[t][i] * enc));  // packed_mul<T>
            w = std::fmax(w, p.range_min);                             // packed_max
            w = std::fmin(w, p.range_max);                             // packed_min
            e.q[t][i] = static_cast<std::int16_t>(std::rint(w)) + p.range_bias;
        }
    return e;
}

// Direct scalar decode path (ground truth for the bit-layout path).
static void decode_group(const GroupEncoded& e, const CodecParams& p, float out[kGroupSize][kLanesPerAtom]) {
    const float s_even = bf16_to_f32(e.scale_even);
    const float s_odd = bf16_to_f32(e.scale_odd);
    for (int t = 0; t < kGroupSize; ++t)
        for (int i = 0; i < kLanesPerAtom; ++i) {
            const int signed_q = e.q[t][i] - p.range_bias;  // [-2^b, 2^b-1]
            out[t][i] = static_cast<float>(signed_q) * ((i % 2 == 0) ? s_even : s_odd);
        }
}

// ══════════════════════════════════════════════════════════════════════
// [2] Bit pack/unpack per codec (integer domain, exact round trip)
// ══════════════════════════════════════════════════════════════════════

// Q4: 8 x 4-bit fields -> uint32. Field i = value i (lane order), i.e. word
// i of the atom contributes its bias-shifted int16 pair; upstream packs
// q[0..3] with shifts 4*i taking the LOW 4 bits of each int16 lane pair —
// per lane position: value 2i -> field 2i, value 2i+1 -> field 2i+1.
static std::uint32_t q4_pack(const int q[8]) {
    std::uint32_t qw = 0;
    for (int i = 0; i < 8; ++i) qw |= static_cast<std::uint32_t>(q[i] & 0xF) << (4 * i);
    return qw;
}
static void q4_unpack(std::uint32_t qw, int q[8]) {
    for (int i = 0; i < 8; ++i) q[i] = static_cast<int>((qw >> (4 * i)) & 0xF);
}

// Q3: low 2 bits per value -> uint16 (field i*2), high 1 bit -> uint8 (bit i).
static void q3_pack(const int q[8], std::uint16_t& q2w, std::uint8_t& q1w) {
    q2w = 0;
    q1w = 0;
    for (int i = 0; i < 8; ++i) {
        const std::uint32_t v = static_cast<std::uint32_t>(q[i]) & 0x7u;
        q2w |= static_cast<std::uint16_t>((v & 0x3u) << (i * 2));
        q1w |= static_cast<std::uint8_t>(((v >> 2) & 0x1u) << i);
    }
}
static void q3_unpack(std::uint16_t q2w, std::uint8_t q1w, int q[8]) {
    for (int i = 0; i < 8; ++i) {
        const std::uint32_t low2 = (q2w >> (2 * i)) & 0x3u;
        const std::uint32_t high1 = (q1w >> i) & 0x1u;
        q[i] = static_cast<int>(low2 | (high1 << 2));
    }
}

// Q6: low 4 bits per value -> uint32 (field i*4), high 2 bits -> uint16
// (field i*2). Upstream packs via int16 lanes; lane order identical.
static void q6_pack(const int q[8], std::uint32_t& q4w, std::uint16_t& q2w) {
    q4w = 0;
    q2w = 0;
    for (int i = 0; i < 8; ++i) {
        const int v = q[i] & 0x3F;
        q4w |= static_cast<std::uint32_t>(v & 0xF) << (4 * i);
        q2w |= static_cast<std::uint16_t>((v >> 4) << (i * 2));
    }
}
static void q6_unpack(std::uint32_t q4w, std::uint16_t q2w, int q[8]) {
    for (int i = 0; i < 8; ++i) {
        const int lo = static_cast<int>(q4w & 0xF);
        const int hi = static_cast<int>(q2w & 0x3);
        q[i] = lo | (hi << 4);
        q4w >>= 4;
        q2w >>= 2;
    }
}

// Recv-side domain shift: upstream adds kRangeMin as a packed bf16 op; the
// integer identity is signed = unsigned - 2^b.
static float bf16_recv_domain(int unsigned_q, const CodecParams& p) {
    // bf16 path: int -> bf16 (exact for |q| <= 2^(b+1)-1), then bf16 add of
    // kRangeMin — exact for these magnitudes (integers within bf16 exact
    // range and step >= 1).
    return bf16_to_f32(f32_to_bf16(static_cast<float>(unsigned_q))) + p.range_min;
}

// ══════════════════════════════════════════════════════════════════════
// [3] Tile send/recv through real byte layouts (256 threads, 8 groups... 
//     256 threads / 8 = 32 groups; each thread owns one atom = 8 values)
// ══════════════════════════════════════════════════════════════════════
struct Tile {
    // values[thread][lane]
    float values[kBlockSize][kLanesPerAtom];
};

// Send the whole block tile into a byte buffer using the codec's real
// region offsets; recv reconstructs. Encoding is per REAL quantization
// group (8 threads): group_abs_max gathers across them (shfl_down chain on
// device), the group leader stores the packed bf16x2 scale at
// scale_offset + group*4 (low half = even lanes, high half = odd lanes).
static void tile_send(const Tile& in, const CodecParams& p, std::vector<std::uint8_t>& buf) {
    buf.assign(p.tile_stride, 0);
    std::uint32_t scratch4[kBlockSize];
    std::uint16_t scratch2[kBlockSize];
    std::uint8_t scratch1[kBlockSize];
    std::uint32_t scales[kBlockSize / kGroupSize];

    for (int gI = 0; gI < kBlockSize / kGroupSize; ++gI) {
        Group g;
        for (int j = 0; j < kGroupSize; ++j)
            std::memcpy(g.values[j], in.values[gI * kGroupSize + j], sizeof(g.values[j]));
        const GroupEncoded e = encode_group(g, p);
        for (int j = 0; j < kGroupSize; ++j) {
            const int t = gI * kGroupSize + j;
            if (p.name[1] == '4') {
                scratch4[t] = q4_pack(e.q[j]);
            } else if (p.name[1] == '3') {
                q3_pack(e.q[j], scratch2[t], scratch1[t]);
            } else {
                q6_pack(e.q[j], scratch4[t], scratch2[t]);
            }
        }
        scales[gI] =
            static_cast<std::uint32_t>(e.scale_odd) << 16 | static_cast<std::uint32_t>(e.scale_even);
    }

    // lay out regions per codec stride
    for (int t = 0; t < kBlockSize; ++t) {
        if (p.name[1] == '4') {
            std::memcpy(buf.data() + t * 4, &scratch4[t], 4);
        } else if (p.name[1] == '3') {
            std::memcpy(buf.data() + t * 2, &scratch2[t], 2);
            buf[p.q1_offset + t] = scratch1[t];
        } else {
            std::memcpy(buf.data() + t * 4, &scratch4[t], 4);
            std::memcpy(buf.data() + p.q2_offset + t * 2, &scratch2[t], 2);
        }
    }
    for (int gI = 0; gI < kBlockSize / kGroupSize; ++gI)
        std::memcpy(buf.data() + p.scale_offset + gI * 4, &scales[gI], 4);
}

static void tile_recv(const std::vector<std::uint8_t>& buf, const CodecParams& p,
                      float out[kBlockSize][kLanesPerAtom]) {
    for (int t = 0; t < kBlockSize; ++t) {
        const int gI = t / kGroupSize;
        std::uint32_t scale_packed;
        std::memcpy(&scale_packed, buf.data() + p.scale_offset + gI * 4, 4);
        const float s_even = bf16_to_f32(static_cast<std::uint16_t>(scale_packed & 0xFFFF));
        const float s_odd = bf16_to_f32(static_cast<std::uint16_t>(scale_packed >> 16));

        int q[8];
        if (p.name[1] == '4') {
            std::uint32_t qw;
            std::memcpy(&qw, buf.data() + t * 4, 4);
            q4_unpack(qw, q);
        } else if (p.name[1] == '3') {
            std::uint16_t q2w;
            std::uint8_t q1w;
            std::memcpy(&q2w, buf.data() + t * 2, 2);
            q1w = buf[p.q1_offset + t];
            q3_unpack(q2w, q1w, q);
        } else {
            std::uint32_t q4w;
            std::uint16_t q2w;
            std::memcpy(&q4w, buf.data() + t * 4, 4);
            std::memcpy(&q2w, buf.data() + p.q2_offset + t * 2, 2);
            q6_unpack(q4w, q2w, q);
        }
        for (int i = 0; i < 8; ++i) {
            // recv: bf16(q) + kRangeMin -> signed [-2^(b-1), 2^(b-1)-1]; then
            // * the group scale for this lane parity
            const float w = bf16_recv_domain(q[i], p);
            out[t][i] = w * ((i % 2 == 0) ? s_even : s_odd);
        }
    }
}

// ══════════════════════════════════════════════════════════════════════
// Tests
// ══════════════════════════════════════════════════════════════════════
static bool close_enough(float got, float want, float rel_tol, float abs_tol) {
    const float d = std::fabs(got - want);
    return d <= abs_tol || d <= rel_tol * std::fabs(want);
}

static int run_codec_tests(const CodecParams& p, int& checks) {
    int fails = 0;

    // ── A. encode/decode round trip with error bound + absmax exactness ──
    {
        Lcg rng(0x600d ^ p.bits);
        int f = 0;
        const float bound_factor = 1.05f;  // bf16 scale rounding + rint slack
        for (int trial = 0; trial < 256; ++trial) {
            Group g;
            float amax = 0;
            int amax_t = 0, amax_i = 0;
            for (int t = 0; t < kGroupSize; ++t)
                for (int i = 0; i < kLanesPerAtom; ++i) {
                    // log-uniform magnitudes exercise denormal..huge range
                    const float mag = std::exp2(rng.uniform(-14.0f, 8.0f));
                    const float sgn = (rng.next() & 1) ? 1.0f : -1.0f;
                    g.values[t][i] = sgn * mag;
                    if (mag > amax) {
                        amax = mag;
                        amax_t = t;
                        amax_i = i;
                    }
                }
            const bool amax_positive = g.values[amax_t][amax_i] > 0.0f;
            const GroupEncoded e = encode_group(g, p);
            float dec[kGroupSize][kLanesPerAtom];
            decode_group(e, p, dec);
            const float s_amax =
                bf16_to_f32((amax_i % 2 == 0) ? e.scale_even : e.scale_odd);
            const float bound = std::fabs(s_amax) * bound_factor;
            for (int t = 0; t < kGroupSize; ++t)
                for (int i = 0; i < kLanesPerAtom; ++i) {
                    // per-element bound: 1.05 LSB in the interior; the clip
                    // ends (either parity's extreme) get 1.3 LSB — the
                    // compounded bf16 rounding of the scale chain (amax ->
                    // bf16, /2^(b-1) -> bf16, each <= 2^-9 rel) can push a
                    // clipped element to ~1.07 LSB (see RESULTS.md).
                    const float s_i =
                        bf16_to_f32((i % 2 == 0) ? e.scale_even : e.scale_odd);
                    const int code = e.q[t][i] - p.range_bias;
                    const int smin = -(1 << (p.bits - 1));
                    const bool at_end = (code == smin) || (code == -smin - 1);
                    const float b_i = std::fabs(s_i) * (at_end ? 1.3f : 1.05f);
                    ++checks;
                    if (!(std::fabs(g.values[t][i] - dec[t][i]) <= b_i) && f < 5) {
                        std::printf("  %s err t%d i%d: |%g - %g| = %g > bound %g\n", p.name, t, i,
                                    g.values[t][i], dec[t][i],
                                    std::fabs(g.values[t][i] - dec[t][i]), b_i);
                        ++f;
                    }
                }
            (void)bound;
            // Sign-flip design point: the encoding scale is negative, so a
            // POSITIVE absmax maps to the protected wide end (signed -2^(b-1),
            // unsigned code 0) without clipping; a negative absmax lands on
            // the +2^(b-1)-1 end and clips by at most 1 LSB (bounded above).
            if (amax_positive) {
                ++checks;
                if (e.q[amax_t][amax_i] != 0 && f < 5) {
                    std::printf("  %s +absmax code %d != wide code 0\n", p.name,
                                e.q[amax_t][amax_i]);
                    ++f;
                }
                ++checks;
                if (!close_enough(dec[amax_t][amax_i], g.values[amax_t][amax_i], 0.01f, 0.0f) &&
                    f < 5) {
                    std::printf("  %s +absmax decode %g vs %g\n", p.name, dec[amax_t][amax_i],
                                g.values[amax_t][amax_i]);
                    ++f;
                }
            } else {
                // negative absmax: clips to the +2^(b-1)-1 end. Error can
                // reach ~1 LSB *plus* the compounded bf16 rounding of the
                // scale chain (amax->bf16, /2^b->bf16: each <= 2^-9 rel,
                // ~1.002^2) — bound at 1.3 LSB (documented in RESULTS.md).
                ++checks;
                if (!(std::fabs(g.values[amax_t][amax_i] - dec[amax_t][amax_i]) <=
                      std::fabs(s_amax) * 1.3f) &&
                    f < 5) {
                    std::printf("  %s -absmax clip err %g > 1.3 LSB\n", p.name,
                                std::fabs(g.values[amax_t][amax_i] - dec[amax_t][amax_i]));
                    ++f;
                }
            }
        }
        fails += f > 0;
        std::printf("A. %s round trip: err <= 1.05 LSB interior / 1.3 LSB clip ends, "
                    "absmax decodes: %s\n",
                    p.name, f ? "FAIL" : "PASS");
    }

    // ── B. all-zero block: no NaN/Inf, decode exactly zero ──
    {
        Group g;
        for (int t = 0; t < kGroupSize; ++t)
            for (int i = 0; i < kLanesPerAtom; ++i) g.values[t][i] = 0.0f;
        const GroupEncoded e = encode_group(g, p);
        float dec[kGroupSize][kLanesPerAtom];
        decode_group(e, p, dec);
        int f = 0;
        for (int t = 0; t < kGroupSize; ++t)
            for (int i = 0; i < kLanesPerAtom; ++i) {
                ++checks;
                if (dec[t][i] != 0.0f && f < 5) {
                    std::printf("  %s zero block decode %g != 0\n", p.name, dec[t][i]);
                    ++f;
                }
            }
        fails += f > 0;
        std::printf("B. %s all-zero block safe (eps guards rcp): %s\n", p.name,
                    f ? "FAIL" : "PASS");
    }

    // ── C. bit-layout exact integer round trip (exhaustive per lane) ──
    {
        int f = 0;
        const int max_code = (1 << (p.bits + 1)) - 1;
        if (p.name[1] == '4') {
            for (int code = 0; code <= max_code; ++code) {
                int q[8];
                for (int i = 0; i < 8; ++i) q[i] = (code >> (i % 4)) & 0xF;
                const std::uint32_t qw = q4_pack(q);
                int back[8];
                q4_unpack(qw, back);
                ++checks;
                if (std::memcmp(q, back, sizeof(q)) != 0 && f < 5) {
                    std::printf("  Q4 layout mismatch code %d\n", code);
                    ++f;
                }
            }
        } else if (p.name[1] == '3') {
            for (int code = 0; code <= max_code; ++code) {
                int q[8];
                for (int i = 0; i < 8; ++i) q[i] = (code >> (i % 3)) & 0x7;
                std::uint16_t q2w;
                std::uint8_t q1w;
                q3_pack(q, q2w, q1w);
                int back[8];
                q3_unpack(q2w, q1w, back);
                ++checks;
                if (std::memcmp(q, back, sizeof(q)) != 0 && f < 5) {
                    std::printf("  Q3 layout mismatch code %d\n", code);
                    ++f;
                }
            }
        } else {
            for (int code = 0; code <= max_code; ++code) {
                int q[8];
                for (int i = 0; i < 8; ++i) q[i] = (code >> (i % 6)) & 0x3F;
                std::uint32_t q4w;
                std::uint16_t q2w;
                q6_pack(q, q4w, q2w);
                int back[8];
                q6_unpack(q4w, q2w, back);
                ++checks;
                if (std::memcmp(q, back, sizeof(q)) != 0 && f < 5) {
                    std::printf("  Q6 layout mismatch code %d\n", code);
                    ++f;
                }
            }
        }
        fails += f > 0;
        std::printf("C. %s bit-layout integer round trip (all %d codes x lane orders): %s\n",
                    p.name, max_code + 1, f ? "FAIL" : "PASS");
    }

    // ── D. tile geometry: full 256-thread send/recv through real offsets ──
    {
        Lcg rng(0x7a11 ^ (p.bits << 8));
        Tile in;
        for (int t = 0; t < kBlockSize; ++t)
            for (int i = 0; i < kLanesPerAtom; ++i)
                in.values[t][i] = rng.uniform(-3.0f, 3.0f);
        std::vector<std::uint8_t> buf;
        tile_send(in, p, buf);
        ++checks;
        if (static_cast<int>(buf.size()) != p.tile_stride) {
            std::printf("  %s tile size %zu != stride %d\n", p.name, buf.size(), p.tile_stride);
            ++fails;
        }
        float out[kBlockSize][kLanesPerAtom];
        tile_recv(buf, p, out);
        int f = 0;
        // The scale is per GROUP (8 threads), so a small thread inside a
        // large-value group quantizes on a coarse grid: the error bound must
        // come from the GROUP's amax, not the thread's. 1.3x covers the clip
        // end + compounded bf16 scale rounding (see RESULTS.md).
        for (int gI = 0; gI < kBlockSize / kGroupSize; ++gI) {
            float amax = 0;
            for (int j = 0; j < kGroupSize; ++j)
                for (int i = 0; i < kLanesPerAtom; ++i)
                    amax = std::fmax(amax, std::fabs(in.values[gI * kGroupSize + j][i]));
            const float bound =
                amax / static_cast<float>(1 << (p.bits - 1)) * 1.3f;
            for (int j = 0; j < kGroupSize; ++j)
                for (int i = 0; i < kLanesPerAtom; ++i) {
                    const int t = gI * kGroupSize + j;
                    ++checks;
                    if (!(std::fabs(in.values[t][i] - out[t][i]) <= bound) && f < 5) {
                        std::printf("  %s tile t%d i%d: %g vs %g\n", p.name, t, i,
                                    in.values[t][i], out[t][i]);
                        ++f;
                    }
                }
        }
        fails += f > 0;
        std::printf("D. %s 256-thread tile send/recv (stride %d B, real offsets): %s\n", p.name,
                    p.tile_stride, f ? "FAIL" : "PASS");
    }
    return fails;
}

int main() {
    int checks = 0, fails = 0;

    // ── 0. constant table cross-check (packed hex -> bf16 scalar) ──
    {
        int f = 0;
        struct Case {
            std::uint16_t bits;
            float want;
            const char* what;
        };
        static const Case cases[] = {
            {0xBE00, -0.125f, "Q4 kScaleFactor (bf16 half of 0xBE00BE00)"},
            {0xC100, -8.0f, "Q4 kRangeMin"},
            {0x40E0, 7.0f, "Q4 kRangeMax"},
            {0xBE80, -0.25f, "Q3 kScaleFactor"},
            {0xC080, -4.0f, "Q3 kRangeMin"},
            {0x4040, 3.0f, "Q3 kRangeMax"},
            {0xBD00, -1.0f / 32.0f, "Q6 kScaleFactor"},
            {0xC200, -32.0f, "Q6 kRangeMin"},
            {0x41F8, 31.0f, "Q6 kRangeMax"},
            {0x33D7, bf16_to_f32(0x33D7), "kScaleEpsilon self-consistency"},
        };
        for (const auto& c : cases) {
            ++checks;
            if (bf16_to_f32(c.bits) != c.want && f < 5) {
                std::printf("  const %s: %g != %g\n", c.what, bf16_to_f32(c.bits), c.want);
                ++f;
            }
        }
        fails += f > 0;
        std::printf("0. packed-hex constant table -> bf16 scalar cross-check: %s\n",
                    f ? "FAIL" : "PASS");
    }

    for (const CodecParams* p : {&kQ4, &kQ3, &kQ6}) {
        std::printf("── %s ──\n", p->name);
        fails += run_codec_tests(*p, checks);
    }

    // ── compression ratios (transmitted bytes per 256-thread atom tile) ──
    {
        const long raw = static_cast<long>(kBlockSize) * kLanesPerAtom * 2;  // bf16
        int f = 0;
        struct Ratio {
            const CodecParams* p;
            double want;
        };
        static const Ratio ratios[] = {{&kQ4, 4096.0 / 1152}, {&kQ3, 4096.0 / 896},
                                       {&kQ6, 4096.0 / 1664}};
        for (const auto& r : ratios) {
            ++checks;
            const double got = static_cast<double>(raw) / r.p->tile_stride;
            if (std::fabs(got - r.want) > 1e-9 && f < 5) {
                std::printf("  %s ratio %g != %g\n", r.p->name, got, r.want);
                ++f;
            }
        }
        fails += f > 0;
        std::printf("6. transmitted-tile compression (4096B raw): Q4 %.3fx Q3 %.3fx Q6 %.3fx: "
                    "%s\n",
                    4096.0 / 1152, 4096.0 / 896, 4096.0 / 1664, f ? "FAIL" : "PASS");
    }

    std::printf("quickreduce_codec: %d checks, %d failures -> %s\n", checks, fails,
                fails ? "FAIL" : "PASS");
    return fails ? MAIN_RETURN_BAD : 0;
}
