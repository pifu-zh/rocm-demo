// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2025, Advanced Micro Devices, Inc. All rights reserved.
// See aiter_ref/group_quant.hpp for provenance and semantics.

#include "aiter_ref/group_quant.hpp"

#include <algorithm>
#include <cmath>
#include <utility>

#include "aiter_ref/fp8.hpp"

namespace aiter_ref {
namespace {

struct GroupScale {
    float scale;  // stored dequant scale: amax / qmax
    float inv;    // reciprocal used for quantization (one rounding each)
};

GroupScale group_scale(const std::vector<float>& x, float qmax) {
    float amax = kAmaxFloor;
    for (float v : x) amax = std::max(amax, std::fabs(v));
    GroupScale s;
    s.scale = amax / qmax;
    s.inv = 1.0f / s.scale;
    return s;
}

}  // namespace

std::pair<std::vector<std::int8_t>, float> quant_group_i8(const std::vector<float>& x) {
    const GroupScale s = group_scale(x, kI8Qmax);
    std::vector<std::int8_t> q(x.size());
    for (std::size_t i = 0; i < x.size(); ++i) {
        // Default rounding mode FE_TONEAREST: round-to-nearest, ties to even
        // (do NOT replace with std::round, which is ties-away-from-zero).
        float r = std::nearbyint(x[i] * s.inv);
        r = std::clamp(r, -kI8Qmax, kI8Qmax);
        q[i] = static_cast<std::int8_t>(r);
    }
    return {std::move(q), s.scale};
}

std::pair<std::vector<std::uint8_t>, float> quant_group_fp8(const std::vector<float>& x) {
    const GroupScale s = group_scale(x, kF8E4M3Qmax);
    std::vector<std::uint8_t> q(x.size());
    for (std::size_t i = 0; i < x.size(); ++i) {
        q[i] = f32_to_e4m3_rne_satfinite(x[i] * s.inv);
    }
    return {std::move(q), s.scale};
}

}  // namespace aiter_ref
