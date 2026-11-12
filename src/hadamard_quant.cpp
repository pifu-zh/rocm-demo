// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2026, Advanced Micro Devices, Inc. All rights reserved.
// Host reference for aiter's Hadamard-rotate + group-quantize chain; see the
// header for pinned semantics and the codec tie domain.
#include "aiter_ref/hadamard_quant.hpp"

#include <algorithm>
#include <cassert>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <vector>

#include "aiter_ref/fp8.hpp"

namespace aiter_ref {

namespace {

// rotate_dim_rsqrt constants (dsv4_rotate_quant.cu) — exact float literals.
float dim_rsqrt(std::size_t dim) {
    switch (dim) {
        case 32: return 0.17677669529663687f;  // 1/sqrt(32) (quant.h group path)
        case 128: return 0.08838834764831845f;
        case 256: return 0.0625f;
        case 512: return 0.04419417382415922f;
        case 1024: return 0.03125f;
        default: assert(false && "unsupported rotation dimension");
    }
    return 0.0f;
}

// Unified XOR butterfly: stage h pairs (j, j+h) -> (x0+x1, x0-x1). The
// device's intra/inter-thread split is pure data placement; the math and
// stage order match this single loop.
void hadamard_inplace(float* v, std::size_t dim, float rsqrt) {
    for (std::size_t h = 1; h < dim; h <<= 1) {
        for (std::size_t g = 0; g < dim; g += 2 * h) {
            for (std::size_t o = 0; o < h; ++o) {
                const float x0 = v[g + o];
                const float x1 = v[g + o + h];
                v[g + o] = x0 + x1;
                v[g + o + h] = x0 - x1;
            }
        }
    }
    for (std::size_t i = 0; i < dim; ++i) v[i] *= rsqrt;
}

// ceil to the next power of two as an e8m0 exponent byte (upstream
// ceil_pow2): exponent + 1 when the mantissa is nonzero; 0xFF for NaN/inf.
std::uint8_t ceil_pow2_e8m0(float tmp) {
    const std::uint32_t u32 = [](float f) {
        std::uint32_t bits;
        static_assert(sizeof(bits) == sizeof(f));
        __builtin_memcpy(&bits, &f, sizeof(bits));
        return bits;
    }(tmp);
    std::uint32_t exponent = (u32 >> 23) & 0xFF;
    if (exponent == 0xFF) return 0xFF;
    if (u32 & 0x7FFFFF) exponent += 1;
    return static_cast<std::uint8_t>(exponent);
}

float e8m0_to_f32(std::uint8_t byte) {
    const std::uint32_t bits = static_cast<std::uint32_t>(byte) << 23;
    float f;
    __builtin_memcpy(&f, &bits, sizeof(f));
    return f;
}

constexpr float kFp4Max = 6.0f;

// Per-32-group quantization core over a rotated (or raw) row.
template <typename Store>
void quant_groups(const float* row, std::size_t dim, float amax_floor, float qmax_inv_scale,
                  bool fp4, Store&& store) {
    constexpr std::size_t kGroup = 32;
    assert(dim % kGroup == 0);
    for (std::size_t g = 0; g < dim; g += kGroup) {
        float abs_max = amax_floor;
        for (std::size_t i = 0; i < kGroup; ++i) {
            abs_max = std::fmax(abs_max, std::fabs(row[g + i]));
        }
        if (fp4) {
            // e8m0 power-of-two scale from ceil(absMax/6).
            const std::uint8_t byte = ceil_pow2_e8m0(abs_max * (1.0f / kFp4Max));
            const float scale = e8m0_to_f32(byte);
            const float inv = 1.0f / scale;
            for (std::size_t i = 0; i < kGroup; ++i) {
                store(g, i, f32_to_e2m1_rne_satfinite(row[g + i] * inv), byte);
            }
        } else {
            // Mirror upstream: inverted max in double, product narrowed.
            const float scale = static_cast<float>(static_cast<double>(abs_max) *
                                                   (1.0 / 448.0));  // dequant scale
            (void)qmax_inv_scale;
            const float inv = 1.0f / scale;
            for (std::size_t i = 0; i < kGroup; ++i) {
                store(g, i, f32_to_e4m3_rne_satfinite(row[g + i] * inv), scale);
            }
        }
    }
}

}  // namespace

std::vector<float> hadamard_rotate_row(const std::vector<float>& x) {
    const std::size_t dim = x.size();
    assert(dim == 128 || dim == 256 || dim == 512 || dim == 1024);
    std::vector<float> y = x;
    hadamard_inplace(y.data(), dim, dim_rsqrt(dim));
    return y;
}

std::vector<float> hadamard_rotate_groups32(const std::vector<float>& x) {
    assert(x.size() % 32 == 0);
    std::vector<float> y = x;
    for (std::size_t g = 0; g < y.size(); g += 32) {
        hadamard_inplace(y.data() + g, 32, dim_rsqrt(32));
    }
    return y;
}

float e2m1_to_f32(std::uint8_t code) {
    static const float kValues[8] = {0.0f, 0.5f, 1.0f, 1.5f, 2.0f, 3.0f, 4.0f, 6.0f};
    const float mag = kValues[code & 0x7];
    return (code & 0x8) ? -mag : mag;
}

std::uint8_t f32_to_e2m1_rne_satfinite(float x) {
    if (std::isnan(x)) return 0x7;  // +6 (documented; no NaN code exists)
    float mag = std::fabs(x);
    // Saturate before rounding like .satfinite: anything above the 4/6
    // midpoint region clamps to max.
    if (mag >= 6.0f) return std::signbit(x) ? 0xF : 0x7;
    // Nearest of the 8 magnitudes with the pinned tie rule.
    static const float kValues[8] = {0.0f, 0.5f, 1.0f, 1.5f, 2.0f, 3.0f, 4.0f, 6.0f};
    int best = 0;
    float best_dist = std::fabs(mag - kValues[0]);
    for (int c = 1; c < 8; ++c) {
        const float dist = std::fabs(mag - kValues[c]);
        if (dist < best_dist) {
            best_dist = dist;
            best = c;
        } else if (dist == best_dist) {
            // Exact midpoint: even mantissa wins where defined; the
            // degenerate power-of-two ties (0.25, 0.75) go away from zero.
            const bool degenerate = (c == 1 || c == 2);  // 0.25 / 0.75 midpoints
            if (degenerate) {
                best = c;  // larger magnitude
            } else if ((c & 1) == 0) {
                best = c;  // even mantissa
            }
            // else keep the current (even) candidate.
        }
    }
    const std::uint8_t code = static_cast<std::uint8_t>(best);
    return std::signbit(x) ? static_cast<std::uint8_t>(code | 0x8) : code;
}

Fp4GroupQuant fp4_group_quant(const std::vector<float>& x, std::size_t rows, std::size_t dim,
                              bool hadamard_rotate) {
    assert(rows > 0 && dim % 32 == 0 && x.size() >= rows * dim);
    if (hadamard_rotate) {
        assert(dim == 128 || dim == 256 || dim == 512 || dim == 1024);
    }
    Fp4GroupQuant out;
    out.packed.assign(rows * (dim / 2), 0);
    out.e8m0_scales.assign(rows * (dim / 32), 0);
    std::vector<float> row(dim);
    for (std::size_t r = 0; r < rows; ++r) {
        std::copy(x.begin() + static_cast<long>(r * dim),
                  x.begin() + static_cast<long>((r + 1) * dim), row.begin());
        if (hadamard_rotate) hadamard_inplace(row.data(), dim, dim_rsqrt(dim));
        quant_groups(
            row.data(), dim, kFp4Max * 1.1754944e-38f, 0.0f, true,
            [&](std::size_t g, std::size_t i, std::uint8_t q, std::uint8_t byte) {
                if (i % 2 == 0) {
                    out.packed[r * (dim / 2) + (g + i) / 2] = q;  // low nibble
                } else {
                    out.packed[r * (dim / 2) + (g + i) / 2] =
                        static_cast<std::uint8_t>(out.packed[r * (dim / 2) + (g + i) / 2] |
                                                  static_cast<std::uint8_t>(q << 4));
                }
                if (i == 0) out.e8m0_scales[r * (dim / 32) + g / 32] = byte;
            });
    }
    return out;
}

Fp8GroupQuant fp8_group_quant(const std::vector<float>& x, std::size_t rows, std::size_t dim,
                              bool hadamard_rotate) {
    assert(rows > 0 && dim % 32 == 0 && x.size() >= rows * dim);
    if (hadamard_rotate) {
        assert(dim == 128 || dim == 256 || dim == 512 || dim == 1024);
    }
    Fp8GroupQuant out;
    out.packed.assign(rows * dim, 0);
    out.scales.assign(rows * (dim / 32), 0.0f);
    std::vector<float> row(dim);
    for (std::size_t r = 0; r < rows; ++r) {
        std::copy(x.begin() + static_cast<long>(r * dim),
                  x.begin() + static_cast<long>((r + 1) * dim), row.begin());
        if (hadamard_rotate) hadamard_inplace(row.data(), dim, dim_rsqrt(dim));
        quant_groups(
            row.data(), dim, 1e-10f, 1.0f / 448.0f, false,
            [&](std::size_t g, std::size_t i, std::uint8_t q, float scale) {
                out.packed[r * dim + g + i] = q;
                if (i == 0) out.scales[r * (dim / 32) + g / 32] = scale;
            });
    }
    return out;
}

}  // namespace aiter_ref
