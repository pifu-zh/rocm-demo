// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2026, Advanced Micro Devices, Inc. All rights reserved.
//
// Soft fp8/fp4 codecs for gfx1030 (no packed-fp8 conversion hardware):
// pure bit manipulation over f32, semantically pinned to CUDA's
// cvt.rn.satfinite.e4m3x2.f32 / cvt.rn.e5m2x2.f32 / __nv_fp4x2_e2m1
// contracts — a 1:1 ROCm C++ translation of cuda-oxide
// crates/cuda-device/src/fp8.rs @ adapt-rocm (validated there by 450,852
// on-card checks). All encodes RNE; decodes exact; lane 0 in the LOW
// byte/nibble of packed forms.
//
// Formats:
//   E4M3FN  1-4-3, bias 7, no Inf; 0x7F/0xFF = NaN; max finite 448.
//   E5M2    1-5-2, bias 15, IEEE Inf/NaN.
//   E2M1    1-2-1, bias 1, values 0/.5/1/1.5/2/3/4/6; satfinite to 6.
#ifndef ROCM_DEMO_DEMOS_EMULATION_SOFT_FP8_SOFT_FP8_HPP
#define ROCM_DEMO_DEMOS_EMULATION_SOFT_FP8_SOFT_FP8_HPP

#include <cstdint>

namespace aiter_lab {

// Host+device bit reinterpretation (no device-only builtins in the codec).
__host__ __device__ inline float bits_to_f32(std::uint32_t u) {
    float f;
    __builtin_memcpy(&f, &u, 4);
    return f;
}

// ── decoders (exact, arithmetic field reassembly — no LUT) ──

__host__ __device__ inline float e4m3_to_f32(std::uint8_t bits) {
    const std::uint32_t s = (bits >> 7) & 0x1;
    const std::uint32_t e = (bits >> 3) & 0xF;
    const std::uint32_t m = bits & 0x7;
    std::uint32_t u;
    if (e == 0) {
        // Denormals decoded arithmetically: m * 2^-9. The linear (m<<20)
        // form would wrongly enable the implicit leading one.
        const float v = static_cast<float>(m) * bits_to_f32(118u << 23);
        return s ? -v : v;
    }
    if (e == 15 && m == 7) u = (s << 31) | 0x7FC00000u;  // NaN, sign preserved
    else u = (s << 31) | ((e + 120) << 23) | (m << 20);
    return bits_to_f32(u);
}

__host__ __device__ inline float e5m2_to_f32(std::uint8_t bits) {
    const std::uint32_t s = (bits >> 7) & 0x1;
    const std::uint32_t e = (bits >> 2) & 0x1F;
    const std::uint32_t m = bits & 0x3;
    if (e == 31) {
        const std::uint32_t u = m ? 0x7FC00000u : 0x7F800000u;  // NaN / Inf
        return bits_to_f32((s << 31) | u);
    }
    if (e == 0) {
        // Subnormal arithmetic decode (the exponent-field form would enable
        // the implicit leading bit): (m/4) * 2^-14 = m * 2^-16.
        const float v = static_cast<float>(m) * bits_to_f32(111u << 23);
        return s ? -v : v;
    }
    return bits_to_f32((s << 31) | ((e + 112) << 23) | (m << 21));
}

// E2M1 magnitudes, index = (exp<<1)|man.
__host__ __device__ inline float e2m1_to_f32(std::uint8_t code) {
    constexpr float kTable[8] = {0.0f, 0.5f, 1.0f, 1.5f, 2.0f, 3.0f, 4.0f, 6.0f};
    const float v = kTable[code & 0x7];
    return (code & 0x8) ? -v : v;
}

// ── RNE primitive: shift right with round-to-nearest-even ──
__host__ __device__ inline std::uint32_t rne_shift(std::uint32_t v, std::uint32_t shift) {
    if (shift > 31) return 0;
    const std::uint32_t rem = v & ((1u << shift) - 1);
    std::uint32_t q = v >> shift;
    const std::uint32_t half = 1u << (shift - 1);
    if (shift && (rem > half || (rem == half && (q & 1)))) ++q;
    return q;
}

// ── encoders ──

// E4M3FN: NaN and Inf -> (s<<7)|0x7F; f32 denormals -> 0; overflow past 448
// clamps to (s<<7)|0x7E (.satfinite).
__host__ __device__ inline std::uint8_t f32_to_e4m3_rne_satfinite(float f) {
    const std::uint32_t x = __builtin_bit_cast(std::uint32_t, f);
    const std::uint32_t s = (x >> 31) << 7;
    const std::uint32_t exp = (x >> 23) & 0xFF;
    const std::uint32_t man = x & 0x7FFFFF;
    if (exp == 0xFF) return static_cast<std::uint8_t>(s | 0x7F);  // NaN/Inf
    if (exp == 0 && man == 0) return static_cast<std::uint8_t>(s);
    // Reconstruct the significand with the implicit bit; f32 denormals
    // (exp==0, man!=0) round to zero at fp8 denormal scale — treated as the
    // sub-1.0 path below with a 0 exponent contribution (handled by the
    // general path via the unbiased exponent being < -6).
    const int e32 = static_cast<int>(exp) - 127;
    // fp8 normal range: e8 in [1,15] <-> e32 in [-6, 8].
    if (e32 < -6) {
        // Rounds to zero or to the smallest fp8 denormal/normal via RNE on
        // the combined field: value = 1.man * 2^e32; fp8 denormal unit =
        // 2^-9. Combined integer grid: (1<<3 | man_hi) * 2^(e32+6) in units
        // of 2^-9 — do it by rounding the f32 significand to the 0x08 grid.
        const std::uint32_t sig = (1u << 23) | man;  // 24-bit significand
        // value = sig * 2^(e32-23); fp8 denormal = k * 2^-9 -> k = sig >> (23 - 9 - e32)
        const std::uint32_t shift = static_cast<std::uint32_t>(23 - 9 - e32);
        const std::uint32_t k = rne_shift(sig, shift);
        if (k == 0) return static_cast<std::uint8_t>(s);
        // k in [1..7] stays denormal; k == 8 carries to min normal 0x08.
        return static_cast<std::uint8_t>(s | (k & 0x7) + ((k >> 3) << 3));
    }
    const std::uint32_t e8 = static_cast<std::uint32_t>(e32 + 7);
    if (e32 > 8) return static_cast<std::uint8_t>(s | 0x7E);  // satfinite 448
    // Round the 24-bit significand to 3 fraction bits (4-bit field with the
    // implicit bit); mantissa overflow bumps the exponent.
    std::uint32_t m3 = rne_shift(man, 20);
    std::uint32_t e = e8;
    if (m3 == 0x8) {  // mantissa carry: 1.000 -> next exponent
        m3 = 0;
        ++e;
    }
    if (e >= 16) return static_cast<std::uint8_t>(s | 0x7E);  // carry past max
    std::uint8_t byte = static_cast<std::uint8_t>(s | (e << 3) | m3);
    if ((byte & 0x7F) == 0x7F) byte = static_cast<std::uint8_t>(s | 0x7E);  // NaN slot -> satfinite 448
    return byte;
}

// E5M2: IEEE semantics — overflow rounds to Inf, NaN -> (s<<7)|0x7E.
__host__ __device__ inline std::uint8_t f32_to_e5m2_rne(float f) {
    const std::uint32_t x = __builtin_bit_cast(std::uint32_t, f);
    const std::uint32_t s = (x >> 31) << 7;
    const std::uint32_t exp = (x >> 23) & 0xFF;
    const std::uint32_t man = x & 0x7FFFFF;
    if (exp == 0xFF) return static_cast<std::uint8_t>(s | (man ? 0x7E : 0x7C));
    if (exp == 0 && man == 0) return static_cast<std::uint8_t>(s);
    const int e32 = static_cast<int>(exp) - 127;
    if (e32 < -14) {
        // k = value / 2^-16 = sig * 2^(e32 - 7) -> shift = 7 - e32.
        const std::uint32_t sig = (1u << 23) | man;
        const std::uint32_t shift = static_cast<std::uint32_t>(7 - e32);
        const std::uint32_t k = rne_shift(sig, shift);
        if (k == 0) return static_cast<std::uint8_t>(s);
        if (k >= 4) return static_cast<std::uint8_t>(s | (1u << 2));  // carry to min normal
        return static_cast<std::uint8_t>(s | k);
    }
    const std::uint32_t e5 = static_cast<std::uint32_t>(e32 + 15);
    if (e32 > 16) return static_cast<std::uint8_t>(s | 0x7C);  // Inf
    std::uint32_t m2 = rne_shift(man, 21);
    std::uint32_t e = e5;
    if (m2 == 0x4) {
        m2 = 0;
        ++e;
    }
    if (e >= 31) return static_cast<std::uint8_t>(s | 0x7C);  // round to Inf
    return static_cast<std::uint8_t>(s | (e << 2) | m2);
}

// E2M1: NaN/Inf saturate to max finite 0b0111 (6.0); sub-1.0 path RNE in
// 0.5 units with carry to 1.0; overflow past 6.0 clamps.
__host__ __device__ inline std::uint8_t f32_to_e2m1_rne_satfinite(float f) {
    const std::uint32_t x = __builtin_bit_cast(std::uint32_t, f);
    const std::uint32_t s = (x >> 31) << 3;
    const std::uint32_t exp = (x >> 23) & 0xFF;
    const std::uint32_t man = x & 0x7FFFFF;
    if (exp == 0xFF) return static_cast<std::uint8_t>(s | 0x7);  // satfinite
    if (exp == 0 && man == 0) return static_cast<std::uint8_t>(s);
    const int e32 = static_cast<int>(exp) - 127;
    if (e32 < 0) {
        // Sub-1.0 (E2M1 normals start at 1.0): value in 0.5 units,
        // k = value/0.5 = sig * 2^(e32-22) -> shift = 22 - e32.
        const std::uint32_t sig = (1u << 23) | man;
        const std::uint32_t shift = static_cast<std::uint32_t>(22 - e32);
        const std::uint32_t k = rne_shift(sig, shift);
        if (k == 0) return static_cast<std::uint8_t>(s);
        if (k >= 2) return static_cast<std::uint8_t>(s | 0x2);  // carry to 1.0
        return static_cast<std::uint8_t>(s | 0x1);              // 0.5
    }
    // Normals: 2-bit exponent (bias 1), 1 mantissa bit.
    std::uint32_t e2 = static_cast<std::uint32_t>(e32 + 1);
    std::uint32_t m1 = rne_shift(man, 22);
    if (m1 == 0x2) {
        m1 = 0;
        ++e2;
    }
    if (e2 >= 4) return static_cast<std::uint8_t>(s | 0x7);  // satfinite 6
    return static_cast<std::uint8_t>(s | (e2 << 1) | m1);
}

// ── packed forms: lane 0 (x) in the LOW byte/nibble (CUDA __nv_fp8x2 /
// __nv_fp4x2 layout) ──
__host__ __device__ inline void e4m3x2_to_f32x2(std::uint16_t v, float& x, float& y) {
    x = e4m3_to_f32(static_cast<std::uint8_t>(v & 0xFF));
    y = e4m3_to_f32(static_cast<std::uint8_t>(v >> 8));
}
__host__ __device__ inline void e5m2x2_to_f32x2(std::uint16_t v, float& x, float& y) {
    x = e5m2_to_f32(static_cast<std::uint8_t>(v & 0xFF));
    y = e5m2_to_f32(static_cast<std::uint8_t>(v >> 8));
}
__host__ __device__ inline void e2m1x2_to_f32x2(std::uint8_t v, float& x, float& y) {
    x = e2m1_to_f32(v & 0xF);
    y = e2m1_to_f32(v >> 4);
}
__host__ __device__ inline std::uint16_t f32x2_to_e4m3x2_rne_satfinite(float x, float y) {
    return static_cast<std::uint16_t>(f32_to_e4m3_rne_satfinite(x)) |
           static_cast<std::uint16_t>(f32_to_e4m3_rne_satfinite(y) << 8);
}
__host__ __device__ inline std::uint16_t f32x2_to_e5m2x2_rne(float x, float y) {
    return static_cast<std::uint16_t>(f32_to_e5m2_rne(x)) |
           static_cast<std::uint16_t>(f32_to_e5m2_rne(y) << 8);
}
__host__ __device__ inline std::uint8_t f32x2_to_e2m1x2_rne_satfinite(float x, float y) {
    return static_cast<std::uint8_t>(f32_to_e2m1_rne_satfinite(x) |
                                     (f32_to_e2m1_rne_satfinite(y) << 4));
}

}  // namespace aiter_lab

#endif  // ROCM_DEMO_DEMOS_EMULATION_SOFT_FP8_SOFT_FP8_HPP
