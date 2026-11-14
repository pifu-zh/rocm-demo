// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2026, Advanced Micro Devices, Inc. all rights reserved.
//
// Cross-verification: THREE independent E2M1 encoders over one input
// lattice. Translations, in port order:
//
// [T1] aiter FlyDSL emit_f32_to_e2m1 (aiter/ops/flydsl/kernels/
//      quant_utils.py @ 1eab5ae12, MIT) — the bit-trick RNE with a
//      2^22-bias denormal path and the +0xC11FFFFF+mant_odd normal path.
//      NaN/Inf policy: saturate to sign|7 (bit pattern falls through the
//      masks to the saturation value).
//
// [T2] cuda-oxide f32_to_e2m1_rne_satfinite (cuda-oxide/cuda-oxide/crates/
//      cuda-device/src/fp8.rs, Apache-2.0) — rne_shift based, two-stage
//      (sub-1.0 candidate counts in 0.5 units; normal target rounds the
//      24-bit significand to 1 fraction bit, mantissa overflow bumps the
//      exponent, past-6.0 saturates). NaN/Inf policy: satfinite sign|7.
//
// [T3] lab e2m1_encode_rne (src/mxfp4_moe_aux.cpp, this demo) — nearest-
//      code loop with absolute distance and ties-to-even. NaN/Inf policy:
//      NaN -> POSITIVE 0x7 (sign dropped — the lab's documented choice;
//      the two upstream translations keep the sign bit for NaN: signed
//      satfinite), Inf -> sign|7.
//
// Expected agreements (the thing this test pins):
// - All FINITE inputs (±0, f16 lattice, f32 sweeps around every rounding
//   boundary): all three encoders produce the SAME nibble — the RNE
//   semantics of E2M1 are pinned three ways.
// - NaN: T1 == T2 == sign|7; T3 diverges by documented policy (positive
//   0x7). The test reports this as the ONLY expected divergence class.
//
// Input lattice: all 2^16 f16 bit patterns (the quantization input domain
// for f16/bf16 activations, exact in f32) + targeted f32 sweeps around
// every E2M1 rounding boundary (midpoints ± 512 ulps) + f32 denormals +
// ±Inf/NaN patterns + randomized f32 in [-8, 8].
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstring>

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

// [T3] lab encoder — identical to src/mxfp4_moe_aux.cpp (kept in sync)
static std::uint8_t lab_e2m1_encode_rne(float x) {
    if (std::isnan(x)) return 0x7;  // lab policy: sign dropped for NaN
    if (std::fabs(x) >= 6.0f) return std::signbit(x) ? 0xF : 0x7;
    const int neg = std::signbit(x);
    const double mag = std::fabs(static_cast<double>(x));
    std::uint8_t best = 0;
    double best_d = 1e300;
    static const double vals[8] = {0.0, 0.5, 1.0, 1.5, 2.0, 3.0, 4.0, 6.0};
    for (int c = 0; c < 8; ++c) {
        const double d = std::fabs(mag - vals[c]);
        if (d < best_d || (d == best_d && ((best & 1) != 0))) {
            best_d = d;
            best = static_cast<std::uint8_t>(c);
        }
    }
    return neg ? static_cast<std::uint8_t>(best | 0x8) : best;
}

// [T1] aiter FlyDSL translation (uint32 arithmetic mirrors the IR)
static std::uint8_t aiter_e2m1(float x) {
    const std::uint32_t qx = f32_to_bits(x);
    const std::uint32_t s = qx & 0x80000000u;
    const std::uint32_t qx_abs = qx & 0x7FFFFFFFu;
    const bool denormal_mask = qx_abs < 0x3F800000u;
    const bool normal_mask = (qx_abs < 0x40C00000u) && (qx_abs >= 0x3F800000u);
    const std::uint32_t denorm_f32 =
        f32_to_bits(bits_to_f32(qx_abs) + bits_to_f32(0x4A800000u));
    const std::uint32_t denormal_x = denorm_f32 - 0x4A800000u;
    const std::uint32_t mant_odd = (qx_abs >> 22) & 1u;
    const std::uint32_t normal_x = (qx_abs + 0xC11FFFFFu + mant_odd) >> 22;
    std::uint32_t e2m1 = normal_mask ? normal_x : 7u;
    e2m1 = denormal_mask ? denormal_x : e2m1;
    return static_cast<std::uint8_t>((s >> 28) | e2m1);
}

// [T2] cuda-oxide translation
static std::uint32_t rne_shift(std::uint32_t v, std::uint32_t shift) {
    if (shift == 0) return v;
    if (shift > 31) return 0;
    const std::uint32_t q = v >> shift;
    const std::uint32_t rem = v & ((1u << shift) - 1);
    const std::uint32_t half = 1u << (shift - 1);
    if (rem > half || (rem == half && (q & 1) == 1)) return q + 1;
    return q;
}
static std::uint8_t oxide_e2m1(float x) {
    const std::uint32_t bits = f32_to_bits(x);
    const std::uint8_t s = static_cast<std::uint8_t>((bits >> 31) & 1);
    const std::int32_t e32 = static_cast<std::int32_t>((bits >> 23) & 0xFF);
    const std::uint32_t m32 = bits & 0x7FFFFFu;
    if (e32 == 0xFF || e32 == 0) {
        // NaN/Inf -> satfinite sign|7; f32 denormals -> ±0
        return static_cast<std::uint8_t>(e32 == 0 ? (s << 3) : ((s << 3) | 0b0111));
    }
    const std::int32_t e = e32 - 127 + 1;
    const std::uint32_t mant = m32 | 0x800000u;
    if (e < 1) {
        const std::uint8_t m2 = static_cast<std::uint8_t>(rne_shift(mant, static_cast<std::uint32_t>(23 - e)));
        if (m2 == 0) return static_cast<std::uint8_t>(s << 3);
        if (m2 == 1) return static_cast<std::uint8_t>((s << 3) | 0b0001);
        return static_cast<std::uint8_t>((s << 3) | 0b0010);
    }
    const std::uint32_t v = rne_shift(mant, 22);
    std::int32_t e2;
    std::int32_t m2;
    if (v == 4) {
        e2 = e + 1;
        m2 = 0;
    } else {
        e2 = e;
        m2 = static_cast<std::int32_t>(v - 2);
    }
    if (e2 > 3 || (e2 == 3 && m2 == 1)) {
        return static_cast<std::uint8_t>((s << 3) | 0b0111);
    }
    return static_cast<std::uint8_t>((s << 3) | (((e2 & 3) << 1) | (m2 & 1)));
}

struct Lcg {
    std::uint64_t s;
    explicit Lcg(std::uint64_t seed) : s(seed) {}
    std::uint32_t next() {
        s = s * 6364136223846793005ULL + 1442695040888963407ULL;
        return static_cast<std::uint32_t>(s >> 33);
    }
};

int main() {
    long finite_checked = 0, finite_agree = 0;
    long nan_checked = 0, nan_agree_12 = 0, nan_agree_13 = 0;
    long divergences = 0;

    const auto check = [&](float x) {
        const std::uint8_t t1 = aiter_e2m1(x);
        const std::uint8_t t2 = oxide_e2m1(x);
        const std::uint8_t t3 = lab_e2m1_encode_rne(x);
        if (std::isnan(x)) {
            ++nan_checked;
            nan_agree_12 += (t1 == t2);
            nan_agree_13 += (t1 == t3);
            if (!(t1 == t2 && t2 == t3) && divergences < 8) {
                std::printf("  nan divergence x=%a (%08x): aiter %x oxide %x lab %x\n", x,
                            f32_to_bits(x), t1, t2, t3);
                ++divergences;
            }
            return;
        }
        ++finite_checked;
        const bool all = (t1 == t2) && (t2 == t3);
        finite_agree += all;
        if (!all && divergences < 8) {
            std::printf("  FINITE divergence x=%a (%08x): aiter %x oxide %x lab %x\n", x,
                        f32_to_bits(x), t1, t2, t3);
            ++divergences;
        }
    };

    // 1. exhaustive f16 lattice (all bit patterns, mapped through f32)
    for (std::uint32_t h = 0; h < 0x10000; ++h) {
        std::uint32_t bits;
        if ((h & 0x7C00) == 0) {
            bits = (h & 0x8000) << 16 | (h & 0x3FF) << 13;  // zero/subnormal
        } else if ((h & 0x7C00) == 0x7C00) {
            bits = (h & 0x8000) << 16 | 0x7F800000u | (h & 0x3FF) << 13;  // inf/nan
        } else {
            const std::uint32_t e = ((h >> 10) & 0x1F) - 15 + 127;
            bits = (h & 0x8000) << 16 | (e << 23) | (h & 0x3FF) << 13;
        }
        check(bits_to_f32(bits));
    }

    // 2. targeted f32 sweeps around every E2M1 rounding boundary
    static const float boundaries[] = {0.25f, 0.75f, 1.25f, 1.75f, 2.5f,
                                       3.5f,  5.0f,  6.0f};
    for (float b : boundaries) {
        const std::uint32_t bb = f32_to_bits(b);
        for (std::int32_t d = -512; d <= 512; ++d) {
            const std::uint32_t bits = static_cast<std::uint32_t>(
                static_cast<std::int64_t>(bb) + d);
            check(bits_to_f32(bits));
        }
        // the exact midpoint and its negation
        check(b);
        check(-b);
        check(-b - std::fabs(b));
    }

    // 3. f32 denormals + zero signs
    check(0.0f);
    check(-0.0f);
    for (std::uint32_t d = 1; d < 64; ++d) check(bits_to_f32(d));
    for (std::uint32_t d = 1; d < 64; ++d) check(bits_to_f32(0x80000000u | d));

    // 4. Inf/NaN patterns (both signs, quiet and signaling payloads)
    check(bits_to_f32(0x7F800000u));
    check(bits_to_f32(0xFF800000u));
    for (std::uint32_t p = 1; p < 8; ++p) check(bits_to_f32(0x7F800001u | (p << 25)));
    for (std::uint32_t p = 1; p < 8; ++p) check(bits_to_f32(0xFF800001u | (p << 25)));

    // 5. randomized f32 in [-8, 8]
    {
        Lcg rng(0xe2f1);
        for (int i = 0; i < 200000; ++i) {
            const float x = -8.0f + 16.0f * static_cast<float>(rng.next() % 1000001) / 1.0e6f;
            check(x);
        }
    }

    std::printf("crosscheck: finite %ld/%ld three-way agree; NaN %ld checked "
                "(T1==T2 %ld, T1==T3 %ld — lab NaN policy = positive 0x7)\n",
                finite_agree, finite_checked, nan_checked, nan_agree_12, nan_agree_13);
    const bool ok = (finite_agree == finite_checked) &&
                    (nan_agree_12 == nan_checked);  // aiter/oxide agree on NaN policy
    std::printf("e2m1_crosscheck: %s\n", ok ? "PASS" : "FAIL");
    return ok ? 0 : 1;
}
