// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
//
// Ported from cuda-oxide crates/cuda-device/src/fp8.rs (Apache-2.0), where
// the codec was exhaustively validated on-card (all 256 decode patterns
// plus 404,872 packed vectors). C++ host port for the aiter reference tests.
//
// Software E4M3FN <-> float codec (subset):
// OCP E4M3FN (1-4-3, bias 7, no infinities; 0x7F/0xFF = NaN; max finite
// 448). Encodes round-to-nearest-even, overflow saturates (.satfinite);
// decodes are exact (every E4M3FN value is representable in float).
#ifndef ROCM_DEMO_AITER_REF_FP8_HPP
#define ROCM_DEMO_AITER_REF_FP8_HPP

#include <cstdint>

namespace aiter_ref {

// Decodes one E4M3FN byte (CUDA __nv_fp8_e4m3 layout) to float, exactly.
float e4m3_to_f32(std::uint8_t bits);

// Encodes a float to one E4M3FN byte: RNE, overflow saturates to the max
// finite (448) per .satfinite; NaN and Inf both map to the NaN byte.
std::uint8_t f32_to_e4m3_rne_satfinite(float x);

}  // namespace aiter_ref

#endif  // ROCM_DEMO_AITER_REF_FP8_HPP
