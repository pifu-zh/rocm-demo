// SPDX-License-Identifier: MIT
// Copyright (C) 2025-2026, Advanced Micro Devices, Inc. All rights reserved.
// Host reference for aiter's forward rotary-embedding family; see the
// header for the pinned semantics and scope exclusions.
#include "aiter_ref/rope.hpp"

#include <cassert>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <vector>

namespace aiter_ref {

namespace {

// One angle lookup, mirroring load_cos_sin_cached / load_cos_sin_uncached:
// for pair p (relative to the rotate region), NEOX reads p and (non-reuse)
// p + half_r; GPT-J reads 2p and 2p+1 (non-reuse) or p (reuse).
struct Angles {
    float cos0, sin0, cos1, sin1;
};

template <typename Src>  // Src(p) -> (cos, sin)
Angles load_angles(Src&& src, std::size_t p, std::size_t half_r, RotateStyle style,
                   bool reuse) {
    if (style == RotateStyle::NeoX) {
        const auto a = src(p);
        if (reuse) return {a.first, a.second, a.first, a.second};
        const auto b = src(p + half_r);
        return {a.first, a.second, b.first, b.second};
    }
    if (reuse) {
        const auto a = src(p);
        return {a.first, a.second, a.first, a.second};
    }
    const auto a = src(2 * p);
    const auto b = src(2 * p + 1);
    return {a.first, a.second, b.first, b.second};
}

// One (input, output) channel: rotate region + verbatim nope slice. Mirrors
// load_payload / store_payload / elementwise_copy (non-inplace kernels).
template <typename Src>  // Src(p) -> (cos, sin)
void rope_one_channel(const float* in, float* out, std::size_t heads, std::size_t dim,
                      std::size_t size_r, bool nope_first, RotateStyle style, bool reuse,
                      Src&& angle_row) {
    const std::size_t half_r = size_r / 2;
    const std::size_t did_start = nope_first ? dim - size_r : 0;
    const std::size_t nope_start = nope_first ? 0 : size_r;
    const std::size_t nope_end = nope_first ? dim - size_r : dim;
    for (std::size_t h = 0; h < heads; ++h) {
        const float* in_h = in + h * dim;
        float* out_h = out + h * dim;
        for (std::size_t p = 0; p < half_r; ++p) {
            std::size_t lane0, lane1;
            if (style == RotateStyle::NeoX) {
                lane0 = did_start + p;
                lane1 = lane0 + half_r;
            } else {
                lane0 = did_start + 2 * p;
                lane1 = lane0 + 1;
            }
            const Angles a = load_angles(angle_row, p, half_r, style, reuse);
            const float x0 = in_h[lane0];
            const float x1 = in_h[lane1];
            out_h[lane0] = x0 * a.cos0 - x1 * a.sin0;
            out_h[lane1] = x1 * a.cos1 + x0 * a.sin1;
        }
        for (std::size_t d = nope_start; d < nope_end; ++d) out_h[d] = in_h[d];
    }
}

std::size_t rotate_width(std::size_t dim, std::size_t size_f, bool reuse) {
    const std::size_t size_r = reuse ? 2 * size_f : size_f;
    assert(size_r >= 2 && size_r % 2 == 0 && size_r <= dim);
    return size_r;
}

}  // namespace

Rope2cOut rope_cached_positions_2c_fwd(const std::vector<float>& in_x,
                                       const std::vector<float>& in_y, std::size_t heads_x,
                                       std::size_t heads_y, std::size_t dim, std::size_t size_f,
                                       const std::vector<float>& cos_table,
                                       const std::vector<float>& sin_table,
                                       const std::vector<std::int32_t>& positions,
                                       RotateStyle style, bool reuse_freqs_front_part,
                                       bool nope_first) {
    assert(dim > 0 && heads_x > 0 && heads_y > 0 && size_f > 0);
    const std::size_t rows = positions.size();
    assert(rows > 0);
    assert(in_x.size() == rows * heads_x * dim);
    assert(in_y.size() == rows * heads_y * dim);
    assert(cos_table.size() == sin_table.size());
    assert(cos_table.size() % size_f == 0);
    const std::size_t max_pos = cos_table.size() / size_f;
    const std::size_t size_r = rotate_width(dim, size_f, reuse_freqs_front_part);

    Rope2cOut out;
    out.out_x.resize(rows * heads_x * dim);
    out.out_y.resize(rows * heads_y * dim);
    for (std::size_t r = 0; r < rows; ++r) {
        const std::size_t pos = static_cast<std::size_t>(positions[r]);
        assert(pos < max_pos);
        const float* cos_row = cos_table.data() + pos * size_f;
        const float* sin_row = sin_table.data() + pos * size_f;
        auto src = [&](std::size_t p) {
            assert(p < size_f);
            return std::make_pair(cos_row[p], sin_row[p]);
        };
        rope_one_channel(in_x.data() + r * heads_x * dim, out.out_x.data() + r * heads_x * dim,
                         heads_x, dim, size_r, nope_first, style, reuse_freqs_front_part, src);
        rope_one_channel(in_y.data() + r * heads_y * dim, out.out_y.data() + r * heads_y * dim,
                         heads_y, dim, size_r, nope_first, style, reuse_freqs_front_part, src);
    }
    return out;
}

std::vector<float> rope_cached_positions_1c_fwd(const std::vector<float>& in_x,
                                                std::size_t heads_x, std::size_t dim,
                                                std::size_t size_f,
                                                const std::vector<float>& cos_table,
                                                const std::vector<float>& sin_table,
                                                const std::vector<std::int32_t>& positions,
                                                RotateStyle style, bool reuse_freqs_front_part,
                                                bool nope_first) {
    const auto both = rope_cached_positions_2c_fwd(
        in_x, in_x, heads_x, heads_x, dim, size_f, cos_table, sin_table, positions, style,
        reuse_freqs_front_part, nope_first);
    return both.out_x;
}

Rope2cOut rope_uncached_2c_fwd(const std::vector<float>& in_x, const std::vector<float>& in_y,
                               std::size_t heads_x, std::size_t heads_y, std::size_t dim,
                               std::size_t size_f, const std::vector<float>& freqs,
                               RotateStyle style, bool reuse_freqs_front_part, bool nope_first) {
    assert(dim > 0 && heads_x > 0 && heads_y > 0 && size_f > 0);
    const std::size_t rows = in_x.size() / (heads_x * dim);
    assert(in_x.size() == rows * heads_x * dim);
    assert(in_y.size() == rows * heads_y * dim);
    assert(freqs.size() == rows * size_f);
    const std::size_t size_r = rotate_width(dim, size_f, reuse_freqs_front_part);

    Rope2cOut out;
    out.out_x.resize(rows * heads_x * dim);
    out.out_y.resize(rows * heads_y * dim);
    for (std::size_t r = 0; r < rows; ++r) {
        const float* f_row = freqs.data() + r * size_f;
        // Uncached: sincosf on the fly (float precision, like the device).
        auto src = [&](std::size_t p) {
            assert(p < size_f);
            return std::make_pair(std::cos(f_row[p]), std::sin(f_row[p]));
        };
        rope_one_channel(in_x.data() + r * heads_x * dim, out.out_x.data() + r * heads_x * dim,
                         heads_x, dim, size_r, nope_first, style, reuse_freqs_front_part, src);
        rope_one_channel(in_y.data() + r * heads_y * dim, out.out_y.data() + r * heads_y * dim,
                         heads_y, dim, size_r, nope_first, style, reuse_freqs_front_part, src);
    }
    return out;
}

}  // namespace aiter_ref
