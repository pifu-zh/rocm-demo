// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2026, Advanced Micro Devices, Inc. All rights reserved.
//
// Port of the Hadamard-rotate + group-quantize chain from ROCm/aiter
// (csrc/kernels/dsv4_rotate_quant.cu @ 1eab5ae12 — whole-row rotate form;
// csrc/include/quant.h hadamard_rotate — per-group-32 form; MIT), plus an
// E2M1 (OCP MX FP4) codec. See LICENSES/MIT.txt.
//
// Designs pinned here:
// - Normalized Sylvester Hadamard rotation y = H_dim·x/sqrt(dim) computed as
//   the XOR butterfly: stage h = 1, 2, ..., dim/2 combines (j, j+h) into
//   (x0+x1, x0-x1). The device splits stages into intra-thread (vector
//   registers) and inter-thread (DPP/permute lane XORs) halves; the host
//   runs one unified butterfly — identical math, same stage order.
// - Two rotate scopes upstream: whole-row (dsv4: dim 128/256/512/1024,
//   rotate_dim_rsqrt constants) and per-32-group (quant.h hadamard_rotate,
//   1/sqrt(32)). Both pinned; the rotation is orthogonal, so it spreads
//   outliers without changing the row's energy (the reason it helps
//   quantization: tested below).
// - fp4 group chain: per 32-group, absMax = max(6·2^-126, max|y|) (the
//   fp4_max·denorm-min floor), e8m0 scale = ceil_pow2(absMax/6) as a bias-127
//   exponent byte (NaN/inf input -> 0xFF), quantized = e2m1(y * (1/scale)).
// - fp8 group chain: per 32-group, absMax = max(1e-10, max|y|)
//   (kAmaxFloor), scale = absMax/448 stored as the dequant scale,
//   quantized = e4m3(y * (1/scale)) — mirrors dynamic_per_group_scaled_quant.
// - Packed fp4 byte: element 2i in the LOW nibble, 2i+1 in the HIGH nibble
//   (pk-fp4 hardware convention). RNE with saturation.
//
// E2M1 codec domain (OCP MX): values 0, 0.5, 1, 1.5, 2, 3, 4, 6 per sign;
// no NaN/inf codes. Tie behavior pinned: exact midpoints 1.25/1.75/2.5/3.5/5
// round to the even mantissa (1, 2, 2, 4, 4); the two degenerate power-of-
// two-boundary ties 0.25 and 0.75 round AWAY from zero — [inferred: gfx1030
// has no fp4 hardware and the upstream cast runs on gfx950 instructions, so
// these two corners could not be probed; everything else is nearest-value].
// NaN saturates to +6.
#ifndef ROCM_DEMO_AITER_REF_HADAMARD_QUANT_HPP
#define ROCM_DEMO_AITER_REF_HADAMARD_QUANT_HPP

#include <cstddef>
#include <cstdint>
#include <vector>

namespace aiter_ref {

// Whole-row normalized Hadamard; x.size() must be 128/256/512/1024.
std::vector<float> hadamard_rotate_row(const std::vector<float>& x);

// Per-32-group normalized Hadamard; x.size() must be a multiple of 32.
std::vector<float> hadamard_rotate_groups32(const std::vector<float>& x);

// E2M1 (OCP MX FP4) codec, 16 codes, sign in bit 3.
float e2m1_to_f32(std::uint8_t code);
std::uint8_t f32_to_e2m1_rne_satfinite(float x);

struct Fp4GroupQuant {
    // Packed nibbles, [rows, dim/2]: low nibble = even element.
    std::vector<std::uint8_t> packed;
    // e8m0 exponent bytes, [rows, dim/32]; dequant scale = 2^(byte - 127).
    std::vector<std::uint8_t> e8m0_scales;
};

// Per-32-group fp4 (E2M1 + e8m0) quantization of x ([rows, dim], dim a
// multiple of 32), with optional whole-row Hadamard rotation first
// (dim 128/256/512/1024 only, mirroring rotate_dim_rsqrt).
Fp4GroupQuant fp4_group_quant(const std::vector<float>& x, std::size_t rows, std::size_t dim,
                              bool hadamard_rotate);

struct Fp8GroupQuant {
    std::vector<std::uint8_t> packed;  // E4M3FN bytes, [rows, dim]
    std::vector<float> scales;         // dequant scales, [rows, dim/32]
};

// Per-32-group fp8 (E4M3FN) quantization with optional whole-row Hadamard
// rotation first. Extends the repo's group_quant line with the rotate step.
Fp8GroupQuant fp8_group_quant(const std::vector<float>& x, std::size_t rows, std::size_t dim,
                              bool hadamard_rotate);

}  // namespace aiter_ref

#endif  // ROCM_DEMO_AITER_REF_HADAMARD_QUANT_HPP
