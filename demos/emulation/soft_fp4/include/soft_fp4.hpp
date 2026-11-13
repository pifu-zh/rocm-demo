// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2026, Advanced Micro Devices, Inc. All rights reserved.
//
// Soft fp4 (MXFP4: E2M1 data + UE8M0 scales) for gfx1030 — no fp4 hardware.
// The E2M1 codec comes from demos/emulation/soft_fp8 (include path set by
// scripts; dependency recorded in DEPENDENCY_GRAPH.md). This header adds:
//   - UE8M0 scale codec (byte = power-of-two exponent, bias 127; 0xFF = NaN;
//     encode uses aiter's ceil/RoundUp contract from quant_amax_floor.h so
//     the scale never under-covers the group amax), and
//   - the MXFP4 group-scale dot product with SF (scale folding): per-K-group
//     scales multiply OUTSIDE the group's inner f32 FFMA sum, so the hot loop
//     is pure decoded-nibble math — the structure aiter/DeepGEMM use to keep
//     quantized GEMMs accurate without hardware dequant.
#ifndef ROCM_DEMO_DEMOS_EMULATION_SOFT_FP4_SOFT_FP4_HPP
#define ROCM_DEMO_DEMOS_EMULATION_SOFT_FP4_SOFT_FP4_HPP

#include "soft_fp8.hpp"  // e2m1_to_f32 / f32_to_e2m1_rne_satfinite / e2m1x2 (lab-shared codec)

#include <hip/hip_runtime.h>
#include <cstdint>

namespace aiter_lab {

// ── UE8M0: unsigned 8-bit exponent, value = 2^(byte-127), 0xFF = NaN ──
__host__ __device__ inline float e8m0_to_f32(std::uint8_t byte) {
    if (byte == 0xFF) return __builtin_nanf("");
    if (byte == 0) return bits_to_f32(0x00400000u);  // 2^-127: f32 subnormal (field assembly would flush to 0)
    // 2^(b-127) via exponent-field assembly (exact for b >= 1).
    return bits_to_f32(static_cast<std::uint32_t>(byte) << 23);
}

// aiter ceil/RoundUp contract (quant_amax_floor.h lineage): scale = smallest
// power of two >= x; NaN/Inf -> 0xFF; x <= 0 -> min normal byte 0x00
// (2^-127) — mirrors ceil_pow2_e8m0 in core/hadamard_quant.
__host__ __device__ inline std::uint8_t f32_to_e8m0_ceil(float x) {
    const std::uint32_t bits = __builtin_bit_cast(std::uint32_t, x);
    const std::uint32_t exp = (bits >> 23) & 0xFF;
    const std::uint32_t man = bits & 0x7FFFFF;
    if (exp == 0xFF) return 0xFF;  // NaN/Inf
    if (exp == 0) {
        // f32 subnormal input: value = man * 2^-149. Ceil to the power-of-two
        // scale byte (the generic mantissa-nonzero ++e rule misclassifies
        // subnormals: 2^-127 is a power of two but has man != 0).
        if (man == 0) return 0x00;  // zero: aiter ceil_pow2 behavior
        const unsigned k = 31 - __builtin_clz(man);
        const int b = static_cast<int>((man & (man - 1)) == 0 ? k : k + 1) - 22;
        return static_cast<std::uint8_t>(b < 0 ? 0 : b);
    }
    std::uint32_t e = exp;
    if (man) ++e;  // mantissa nonzero -> ceil to next power of two
    return static_cast<std::uint8_t>(e);
}

// ── packed nibble access (lane 0 = low nibble, lab-wide convention) ──
__host__ __device__ inline std::uint8_t fp4_nibble(const std::uint8_t* packed, int i) {
    const std::uint8_t byte = packed[i / 2];
    return (i % 2 == 0) ? (byte & 0xF) : static_cast<std::uint8_t>(byte >> 4);
}

// ── MXFP4 group-scale dot: one thread per output element ──
// C[m,n] = sum_g SFA[m,g]*SB[g,n] * ( sum_{k in group g} decA[m,k]*decB[k,n] )
// A packed [M, K/2] nibbles; B packed [K, N/2] nibbles (fp4 along K for A,
// along N for B); scales e8m0: SFA [M, K/32], SB [K/32, N].
constexpr int MXFP4_GROUP = 32;

__global__ void mxfp4_dot_kernel(const std::uint8_t* __restrict__ a_packed,
                                 const std::uint8_t* __restrict__ b_packed,
                                 const std::uint8_t* __restrict__ sfa,
                                 const std::uint8_t* __restrict__ sfb,
                                 float* __restrict__ c, int m, int n, int k) {
    const int col = blockIdx.x * blockDim.x + threadIdx.x;
    const int row = blockIdx.y;
    if (col >= n) return;
    const int groups = k / MXFP4_GROUP;
    float acc = 0.0f;
    for (int g = 0; g < groups; ++g) {
        float inner = 0.0f;
        const int base = g * MXFP4_GROUP;
#pragma unroll 8
        for (int i = 0; i < MXFP4_GROUP; ++i) {
            const int kk = base + i;
            const float va = e2m1_to_f32(fp4_nibble(a_packed + static_cast<long>(row) * (k / 2), kk));
            const float vb = e2m1_to_f32(fp4_nibble(b_packed + static_cast<long>(kk) * (n / 2), col));
            inner = fmaf(va, vb, inner);
        }
        // Scale folding: one multiply per group, outside the inner sum.
        const float sf = e8m0_to_f32(sfa[static_cast<long>(row) * groups + g]);
        const float sb = e8m0_to_f32(sfb[g * n + col]);
        acc = fmaf(inner, sf * sb, acc);
    }
    c[static_cast<long>(row) * n + col] = acc;
}

// Conversion-stream kernel: decode a packed fp4 buffer to f32 (4.5 B/elt).
__global__ void decode_e2m1x2_stream(const std::uint8_t* __restrict__ in, float* __restrict__ out,
                                     int pairs) {
    const int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < pairs) aiter_lab::e2m1x2_to_f32x2(in[i], out[2 * i], out[2 * i + 1]);
}

// Quantize-stream kernel: f32 -> packed fp4 pairs (2 B/elt read, 1 B/elt write... per
// pair: 8 B in + 1 B out).
__global__ void quantize_e2m1x2_stream(const float* __restrict__ in, std::uint8_t* __restrict__ out,
                                       int pairs) {
    const int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < pairs) out[i] = aiter_lab::f32x2_to_e2m1x2_rne_satfinite(in[2 * i], in[2 * i + 1]);
}

// Host launcher for the dot kernel.
inline hipError_t launch_mxfp4_dot(const std::uint8_t* a, const std::uint8_t* b,
                                   const std::uint8_t* sfa, const std::uint8_t* sfb, float* c,
                                   int m, int n, int k, hipStream_t stream = nullptr) {
    const dim3 grid((n + 63) / 64, m);
    mxfp4_dot_kernel<<<grid, 64, 0, stream>>>(a, b, sfa, sfb, c, m, n, k);
    return hipGetLastError();
}

}  // namespace aiter_lab

#endif  // ROCM_DEMO_DEMOS_EMULATION_SOFT_FP4_SOFT_FP4_HPP
