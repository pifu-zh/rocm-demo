// SPDX-License-Identifier: MIT
// Copyright (C) 2025-2026, Advanced Micro Devices, Inc. All rights reserved.
//
// Port of the forward rotary-embedding family from ROCm/aiter
// (csrc/kernels/rope/rope_common.h @ 1eab5ae12 + general_{1c,2c}_*_fwd
// kernels, MIT), reduced to the scalar semantics over contiguous f32
// tensors. See LICENSES/MIT.txt.
//
// Semantics pinned here (terminology follows the upstream keyword glossary):
// - Pair rotation, per pair p in [0, size_r/2):
//     out[lane0] = x[lane0]*cos0 - x[lane1]*sin0
//     out[lane1] = x[lane1]*cos1 + x[lane0]*sin1
//   With ReuseFreqsFrontPart the second angle equals the first (cos1=cos0,
//   sin1=sin0 — the usual single-angle form, cf. the Python
//   _apply_rotary_emb reference); otherwise each lane takes its own angle.
// - NEOX style: lane0 = p, lane1 = p + size_r/2 (split halves). GPT-J:
//   lane0 = 2p, lane1 = 2p+1 (interleaved). Relative to the rotate region.
// - Rotate region: [0, size_r) (nope_first=false) or [size_d - size_r,
//   size_d) (nope_first=true); the complement ("nope" slice) is copied
//   verbatim to the output. size_r = 2*size_f with reuse, else size_f.
// - Cached: cos/sin are [max_pos, size_f] tables; positions[rows] selects
//   the table row per token (indirect). Uncached: freqs [rows, size_f] is
//   converted with sincosf on the fly (float precision).
// - 1c/2c: one or two independent (input, output) channel pairs (q/k) with
//   their own head counts, sharing positions.
// - Pinned contiguous: x [rows, h, d] row-major (stride_d == 1, like the
//   upstream AITER_CHECK), cos/sin [max_pos, size_f]. All tensors f32:
//   upstream casts every dtype to float for the math. Out-of-place only
//   (in-place kernels alias output onto input — orthogonal here).
//
// Not ported (documented scope): thd/2d layouts, backward (the sin/index
// swap family), indirect-positions/offsets chains, fused QK-norm and
// KV-cache variants, the vectorized/double-buffer lane machinery, bf16/fp16
// dtypes, and the inline/inplace dispatch matrix.
#ifndef ROCM_DEMO_AITER_REF_ROPE_HPP
#define ROCM_DEMO_AITER_REF_ROPE_HPP

#include <cstddef>
#include <cstdint>
#include <vector>

namespace aiter_ref {

enum class RotateStyle {
    NeoX = 0,  // split halves: lane1 = lane0 + size_r/2
    GptJ = 1,  // interleaved: lane1 = lane0 + 1
};

struct Rope2cOut {
    std::vector<float> out_x;  // [rows, h_x, d]
    std::vector<float> out_y;  // [rows, h_y, d]
};

// Cached + positions (indirect) variant, two channels. positions must have
// `rows` entries, each < max_pos (rows of cos/sin). size_f = cos/sin row
// width (size_r/2 with reuse_freqs_front_part, else the rotate width).
Rope2cOut rope_cached_positions_2c_fwd(const std::vector<float>& in_x,
                                       const std::vector<float>& in_y, std::size_t heads_x,
                                       std::size_t heads_y, std::size_t dim, std::size_t size_f,
                                       const std::vector<float>& cos_table,
                                       const std::vector<float>& sin_table,
                                       const std::vector<std::int32_t>& positions,
                                       RotateStyle style, bool reuse_freqs_front_part,
                                       bool nope_first);

// Cached + positions variant, one channel.
std::vector<float> rope_cached_positions_1c_fwd(const std::vector<float>& in_x,
                                                std::size_t heads_x, std::size_t dim,
                                                std::size_t size_f,
                                                const std::vector<float>& cos_table,
                                                const std::vector<float>& sin_table,
                                                const std::vector<std::int32_t>& positions,
                                                RotateStyle style, bool reuse_freqs_front_part,
                                                bool nope_first);

// Uncached variant: freqs is [rows, size_f]; cos/sin computed per pair with
// float sincos. Two channels; positions has no role upstream in this shape.
Rope2cOut rope_uncached_2c_fwd(const std::vector<float>& in_x, const std::vector<float>& in_y,
                               std::size_t heads_x, std::size_t heads_y, std::size_t dim,
                               std::size_t size_f, const std::vector<float>& freqs,
                               RotateStyle style, bool reuse_freqs_front_part, bool nope_first);

}  // namespace aiter_ref

#endif  // ROCM_DEMO_AITER_REF_ROPE_HPP
