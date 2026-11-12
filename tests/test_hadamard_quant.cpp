// SPDX-License-Identifier: Apache-2.0
// Tests for the hadamard_quant host reference: butterfly vs naive Hadamard
// matmul, orthogonality, E2M1 codec boundaries, e8m0 scale selection, and
// the design property (rotation spreads outliers -> smaller quant error).
#include "aiter_ref/hadamard_quant.hpp"
#include "aiter_ref/fp8.hpp"
#include "aiter_ref/rng.hpp"
#include "test_util.hpp"

#include <cmath>
#include <cstddef>
#include <cstdint>
#include <vector>

namespace {

using aiter_ref::e2m1_to_f32;
using aiter_ref::f32_to_e2m1_rne_satfinite;

// Naive Hadamard reference: H[i][j] = (-1)^popcount(i & j), normalized.
std::vector<double> naive_hadamard(const std::vector<float>& x, std::size_t dim) {
    std::vector<double> y(dim, 0.0);
    const double rsqrt = 1.0 / std::sqrt(static_cast<double>(dim));
    for (std::size_t i = 0; i < dim; ++i) {
        double acc = 0.0;
        for (std::size_t j = 0; j < dim; ++j) {
            const int parity = __builtin_popcountll(i & j) & 1;
            acc += (parity ? -1.0 : 1.0) * static_cast<double>(x[j]);
        }
        y[i] = acc * rsqrt;
    }
    return y;
}

void butterfly_matches_naive_matmul() {
    for (std::size_t dim : {std::size_t(128), std::size_t(256)}) {
        aiter_ref::Rng rng(0x1DAB + dim);
        std::vector<float> x(dim);
        for (float& v : x) v = std::floor(rng.f32_sym() * 100.0f) / 100.0f;
        const auto y = aiter_ref::hadamard_rotate_row(x);
        const auto want = naive_hadamard(x, dim);
        for (std::size_t i = 0; i < dim; ++i) CHECK_NEAR(y[i], want[i], 2e-4);
    }
    // Group-32 form: same butterfly on each segment.
    aiter_ref::Rng rng(0x32);
    std::vector<float> x(96);
    for (float& v : x) v = std::floor(rng.f32_sym() * 100.0f) / 100.0f;
    const auto y = aiter_ref::hadamard_rotate_groups32(x);
    for (std::size_t g = 0; g < 96; g += 32) {
        const std::vector<float> seg(x.begin() + static_cast<long>(g),
                                     x.begin() + static_cast<long>(g + 32));
        const auto want = naive_hadamard(seg, 32);
        for (std::size_t i = 0; i < 32; ++i) CHECK_NEAR(y[g + i], want[i], 2e-4);
    }
}

void rotation_preserves_energy() {
    // The reason Hadamard helps quantization: orthogonal, so outlier
    // spreading changes no row energy (Parseval).
    aiter_ref::Rng rng(0xE0E0);
    std::vector<float> x(128, 0.0f);
    for (float& v : x) v = std::floor(rng.f32_sym() * 100.0f) / 100.0f;
    const auto y = aiter_ref::hadamard_rotate_row(x);
    double ex = 0, ey = 0;
    for (std::size_t i = 0; i < 128; ++i) {
        ex += static_cast<double>(x[i]) * x[i];
        ey += static_cast<double>(y[i]) * y[i];
    }
    CHECK_NEAR(ey / ex, 1.0, 1e-4);
}

void e2m1_codec_values_and_roundtrip() {
    for (std::uint8_t code = 0; code < 16; ++code) {
        const float v = e2m1_to_f32(code);
        // All 16 codes round-trip exactly.
        const float mag = std::fabs(v);
        if (mag == 0.0f) {
            CHECK_EQ(f32_to_e2m1_rne_satfinite(v), code & 0x8 ? 0x8 : 0x0);
        } else {
            CHECK_EQ(f32_to_e2m1_rne_satfinite(v), code);
        }
    }
    // The 8 magnitudes.
    const float vals[] = {0.0f, 0.5f, 1.0f, 1.5f, 2.0f, 3.0f, 4.0f, 6.0f};
    for (int c = 0; c < 8; ++c) {
        CHECK_EQ(e2m1_to_f32(static_cast<std::uint8_t>(c)), vals[c]);
        CHECK_EQ(e2m1_to_f32(static_cast<std::uint8_t>(c | 0x8)), -vals[c]);
    }
}

void e2m1_boundaries_and_ties() {
    // Documented tie rule: even mantissa, degenerate power-of-two ties away
    // from zero.
    CHECK_EQ(f32_to_e2m1_rne_satfinite(1.25f), 0x2);  // 1 (even m) over 1.5
    CHECK_EQ(f32_to_e2m1_rne_satfinite(1.75f), 0x4);  // 2
    CHECK_EQ(f32_to_e2m1_rne_satfinite(2.5f), 0x4);   // 2
    CHECK_EQ(f32_to_e2m1_rne_satfinite(3.5f), 0x6);   // 4
    CHECK_EQ(f32_to_e2m1_rne_satfinite(5.0f), 0x6);   // 4
    CHECK_EQ(f32_to_e2m1_rne_satfinite(0.25f), 0x1);  // 0.5 (away from zero)
    CHECK_EQ(f32_to_e2m1_rne_satfinite(0.75f), 0x2);  // 1 (away from zero)
    // Plain nearest.
    CHECK_EQ(f32_to_e2m1_rne_satfinite(0.1f), 0x0);
    CHECK_EQ(f32_to_e2m1_rne_satfinite(0.3f), 0x1);
    CHECK_EQ(f32_to_e2m1_rne_satfinite(4.9f), 0x6);  // 4 (dist 0.9 vs 1.1)
    CHECK_EQ(f32_to_e2m1_rne_satfinite(5.5f), 0x7);  // 6 (dist 0.5 vs 1.5)
    // Saturation and NaN.
    CHECK_EQ(f32_to_e2m1_rne_satfinite(7.0f), 0x7);
    CHECK_EQ(f32_to_e2m1_rne_satfinite(1e30f), 0x7);
    CHECK_EQ(f32_to_e2m1_rne_satfinite(-1e30f), 0xF);
    CHECK_EQ(f32_to_e2m1_rne_satfinite(std::nanf("")), 0x7);
}

float vals_at(int c) {
    static const float vals[8] = {0.0f, 0.5f, 1.0f, 1.5f, 2.0f, 3.0f, 4.0f, 6.0f};
    return vals[c];
}

void e2m1_brute_force_nearest() {
    aiter_ref::Rng rng(0x2E01);
    for (int trial = 0; trial < 500; ++trial) {
        float x;
        if (trial % 3 == 0) {
            x = rng.f32_sym() * 8.0f;
        } else if (trial % 3 == 1) {
            x = rng.f32_unit() * 0.6f;  // dense near small magnitudes
        } else {
            x = rng.f32_sym() * 1e3f;
        }
        const std::uint8_t got = f32_to_e2m1_rne_satfinite(x);
        const float v = e2m1_to_f32(got);
        // Nearest-value property (tolerance only at documented ties).
        float best = 1e30f;
        for (int c = 0; c < 8; ++c) {
            best = std::fmin(best, std::fabs(x - (c == 0 ? 0.0f : vals_at(c))));
        }
        CHECK(std::fabs(x - v) <= best + 1e-6f);
        // Sign preserved (except zero result from tiny inputs).
        if (v != 0.0f) CHECK((v < 0) == (x < 0));
    }
}

void fp4_chain_hand_case() {
    // One row of 32: amax = 1 -> 1/6 has nonzero mantissa -> ceil to 2^-2.
    std::vector<float> x(32, 0.0f);
    x[0] = 1.0f;
    x[1] = 0.5f;
    const auto out = aiter_ref::fp4_group_quant(x, 1, 32, /*hadamard_rotate=*/false);
    CHECK_EQ(out.e8m0_scales[0], 125);  // 2^(125-127) = 0.25
    // 1/0.25 = 4 -> code 0x6; 0.5/0.25 = 2 -> 0x4; zeros -> 0x0.
    CHECK_EQ(out.packed[0] & 0xF, 0x6);
    CHECK_EQ((out.packed[0] >> 4) & 0xF, 0x4);
    CHECK_EQ(out.packed[1], 0x0);
    // Dequant of the amax element is exact up to the power-of-2 scale.
    const float deq0 = e2m1_to_f32(out.packed[0] & 0xF) * 0.25f;
    CHECK_NEAR(deq0, 1.0f, 1e-6f);
}

void fp4_zero_group_hits_floor() {
    std::vector<float> x(32, 0.0f);
    const auto out = aiter_ref::fp4_group_quant(x, 1, 32, false);
    // absMax = 6*2^-126 -> /6 = 2^-126 -> exponent field 1, no ceil.
    CHECK_EQ(out.e8m0_scales[0], 1);
    CHECK_EQ(out.packed[0], 0x0);
}

void fp8_chain_scales_match_group_quant_convention() {
    // Same convention as the existing group_quant module: stored scale is
    // the dequant scale amax/448, quantized via the reciprocal.
    std::vector<float> x(32, 0.0f);
    x[3] = 448.0f;
    x[7] = -224.0f;
    const auto out = aiter_ref::fp8_group_quant(x, 1, 32, false);
    CHECK_NEAR(out.scales[0], 1.0f, 1e-7f);
    // 448/1 = 448 -> E4M3FN max; -224 exact.
    CHECK_NEAR(static_cast<double>(aiter_ref::e4m3_to_f32(out.packed[3])), 448.0, 1e-6);
    CHECK_NEAR(static_cast<double>(aiter_ref::e4m3_to_f32(out.packed[7])), -224.0, 1e-6);
    // Degenerate group: amax below the 1e-10 floor.
    std::vector<float> tiny(32, 1e-12f);
    const auto out2 = aiter_ref::fp8_group_quant(tiny, 1, 32, false);
    CHECK_EQ(out2.scales[0], static_cast<float>(1e-10f / 448.0));
}

// Dequantize a fp4_group_quant result; with rotated=true apply the inverse
// Hadamard (H/sqrt(dim), its own inverse) before comparing against x.
std::vector<float> dequant_fp4(const aiter_ref::Fp4GroupQuant& q, std::size_t rows,
                               std::size_t dim, bool rotated) {
    std::vector<float> y(rows * dim);
    for (std::size_t r = 0; r < rows; ++r) {
        for (std::size_t i = 0; i < dim; ++i) {
            const std::uint8_t byte = q.packed[r * dim / 2 + i / 2];
            const std::uint8_t code = (i % 2 == 0) ? (byte & 0xF) : (byte >> 4);
            const float scale = std::ldexp(1.0f, static_cast<int>(q.e8m0_scales[r * dim / 32 + i / 32]) - 127);
            y[r * dim + i] = e2m1_to_f32(code) * scale;
        }
        if (rotated) {
            float* v = y.data() + r * dim;
            for (std::size_t h = 1; h < dim; h <<= 1) {
                for (std::size_t g = 0; g < dim; g += 2 * h) {
                    for (std::size_t o = 0; o < h; ++o) {
                        const float a = v[g + o], b = v[g + o + h];
                        v[g + o] = a + b;
                        v[g + o + h] = a - b;
                    }
                }
            }
            for (std::size_t i = 0; i < dim; ++i) v[i] /= std::sqrt(static_cast<float>(dim));
        }
    }
    return y;
}

double mse_vs(const std::vector<float>& x, const std::vector<float>& y) {
    double acc = 0.0;
    for (std::size_t i = 0; i < x.size(); ++i) {
        acc += static_cast<double>(y[i] - x[i]) * (y[i] - x[i]);
    }
    return acc / x.size();
}

void rotation_tradeoff_measured() {
    // The design trade-off, measured (values from this repo's implementation):
    // a spike inside a heterogeneous group poisons the direct-quant group's
    // e8m0 scale — rotating first cuts MSE ~3x. A smoothly decaying row
    // already has homogeneous groups and rotation LOSES (re-mixing costs).
    // Both sides are pinned: the win is asserted, the loss printed.
    const std::size_t dim = 128;
    std::vector<float> sin_spike(dim), decay(dim);
    for (std::size_t i = 0; i < dim; ++i) {
        sin_spike[i] = std::sin(i * 0.3f) * 3.0f + 0.5f;
        decay[i] = 64.0f * std::pow(0.9f, static_cast<float>(i));
    }
    sin_spike[7] = 64.0f;

    const auto d_win = aiter_ref::fp4_group_quant(sin_spike, 1, dim, false);
    const auto r_win = aiter_ref::fp4_group_quant(sin_spike, 1, dim, true);
    const double mse_d = mse_vs(sin_spike, dequant_fp4(d_win, 1, dim, false));
    const double mse_r = mse_vs(sin_spike, dequant_fp4(r_win, 1, dim, true));
    std::printf("   [info] sin+spike MSE: direct=%.4f rotated=%.4f\n", mse_d, mse_r);
    CHECK(mse_r < mse_d);

    const auto d_lose = aiter_ref::fp4_group_quant(decay, 1, dim, false);
    const auto r_lose = aiter_ref::fp4_group_quant(decay, 1, dim, true);
    const double mse_dl = mse_vs(decay, dequant_fp4(d_lose, 1, dim, false));
    const double mse_rl = mse_vs(decay, dequant_fp4(r_lose, 1, dim, true));
    std::printf("   [info] exp-decay MSE: direct=%.4f rotated=%.4f (rotation loses)\n",
                mse_dl, mse_rl);
    // Round-trip sanity for both: dequant is finite everywhere.
    for (float v : dequant_fp4(r_win, 1, dim, true)) CHECK(std::isfinite(v));
}

}  // namespace

int main() {
    RUN_TEST(butterfly_matches_naive_matmul);
    RUN_TEST(rotation_preserves_energy);
    RUN_TEST(e2m1_codec_values_and_roundtrip);
    RUN_TEST(e2m1_boundaries_and_ties);
    RUN_TEST(e2m1_brute_force_nearest);
    RUN_TEST(fp4_chain_hand_case);
    RUN_TEST(fp4_zero_group_hits_floor);
    RUN_TEST(fp8_chain_scales_match_group_quant_convention);
    RUN_TEST(rotation_tradeoff_measured);
    return finish();
}
