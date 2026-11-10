// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2025, Advanced Micro Devices, Inc. All rights reserved.
//
// Port of aiter's per-token-group quantization scale semantics
// (csrc/kernels/quant_kernels.cu -> dynamic_per_group_scaled_quant_kernel,
// continuous fp32-scale path; kAmaxFloor from
// csrc/include/quant_amax_floor.h @ 1eab5ae12, MIT). See LICENSES/MIT.txt.
//
// Per group (one row segment of group_size elements):
// 1. amax = max(1e-10, max |x|) — the floor keeps degenerate groups finite.
// 2. scale = amax / qmax — the stored dequant scale (fp32, written once per
//    group by lane 0 upstream).
// 3. Quantized values use the reciprocal: y = x * (1/scale), rounded
//    to-nearest-even, clamped to the representable range. The device
//    software path clamps; fp8 additionally saturates via .satfinite.
//
// Not ported (documented upstream features): the E8M0 (MX) byte scale,
// scale_ub, hadamard32 rotate, shuffle/transpose scale layouts, gfx1250
// tuning. Targets here: i8 (qmax 127) and fp8 E4M3FN (qmax 448).
#ifndef ROCM_DEMO_AITER_REF_GROUP_QUANT_HPP
#define ROCM_DEMO_AITER_REF_GROUP_QUANT_HPP

#include <cstdint>
#include <utility>
#include <vector>

namespace aiter_ref {

// aiter::kAmaxFloor — degenerate-group amax floor.
inline constexpr float kAmaxFloor = 1e-10f;
// qmax for int8 (symmetric).
inline constexpr float kI8Qmax = 127.0f;
// qmax for fp8 E4M3FN (opus::finfo<fp8_t>::max()).
inline constexpr float kF8E4M3Qmax = 448.0f;

// Quantizes one group to symmetric int8. Returns (q, scale) with
// x ~= q[i] * scale.
std::pair<std::vector<std::int8_t>, float> quant_group_i8(const std::vector<float>& x);

// Quantizes one group to fp8 E4M3FN. Returns (q, scale) with
// x ~= e4m3_to_f32(q[i]) * scale.
std::pair<std::vector<std::uint8_t>, float> quant_group_fp8(const std::vector<float>& x);

}  // namespace aiter_ref

#endif  // ROCM_DEMO_AITER_REF_GROUP_QUANT_HPP
