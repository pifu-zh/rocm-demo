// SPDX-License-Identifier: Apache-2.0
// Unit tests for the per-token-group quantization port: golden amax/scale
// cases, the amax floor, error bounds on random groups, and fp8
// quantization verified against a brute-force 256-way nearest-value
// reference (upstream: aiter `csrc/kernels/quant_kernels.cu`).

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstdlib>
#include <limits>
#include <vector>

#include "aiter_ref/fp8.hpp"
#include "aiter_ref/group_quant.hpp"
#include "aiter_ref/rng.hpp"
#include "test_util.hpp"

void test_i8_amax_element_maps_to_127() {
    const std::vector<float> x = {0.5f, -2.0f, 1.25f, -0.125f};
    const auto [q, scale] = aiter_ref::quant_group_i8(x);
    CHECK_NEAR(scale, 2.0f / 127.0f, std::numeric_limits<float>::epsilon());
    CHECK_EQ(q[1], -127);  // the amax element
    // dequantization error within half a step (RTNE + reciprocal slack)
    for (std::size_t i = 0; i < x.size(); ++i) {
        const float err = std::fabs(x[i] - static_cast<float>(q[i]) * scale);
        CHECK(err <= 0.501f * scale);
    }
}

void test_i8_zero_group_uses_amax_floor() {
    const auto [q, scale] = aiter_ref::quant_group_i8(std::vector<float>(8, 0.0f));
    CHECK(scale == aiter_ref::kAmaxFloor / aiter_ref::kI8Qmax);
    for (std::int8_t v : q) CHECK_EQ(v, 0);
}

void test_i8_tiny_group_floors_amax() {
    // amax = 1e-12 < floor 1e-10: scale comes from the floor.
    const auto [q, scale] = aiter_ref::quant_group_i8({1e-12f, -5e-13f});
    CHECK(scale == aiter_ref::kAmaxFloor / aiter_ref::kI8Qmax);
    // y = 1e-12 * 127/1e-10 = 1.27 -> RNE 1; y = -0.635 -> RNE -1.
    CHECK_EQ(q[0], 1);
    CHECK_EQ(q[1], -1);
}

void test_i8_random_groups_error_bound_and_range() {
    aiter_ref::Rng rng(0x0A17);
    for (int iter = 0; iter < 500; ++iter) {
        const std::size_t n = 1 + rng.below(128);
        std::vector<float> g(n);
        for (float& v : g) v = rng.f32_sym() * 100.0f;
        const auto [q, scale] = aiter_ref::quant_group_i8(g);
        std::int8_t max_abs = 0;
        for (std::size_t i = 0; i < n; ++i) {
            CHECK(std::abs(static_cast<int>(q[i])) <= 127);
            max_abs = std::max(max_abs, static_cast<std::int8_t>(std::abs(static_cast<int>(q[i]))));
            const float err = std::fabs(g[i] - static_cast<float>(q[i]) * scale);
            CHECK(err <= 0.501f * scale);
        }
        // The amax element lands on +-127 exactly (rounding slack aside).
        CHECK(max_abs >= 126);
    }
}

void test_i8_group_independence() {
    const auto [q1, s1] = aiter_ref::quant_group_i8({1.0f, 2.0f, 3.0f});
    const auto [q2, s2] = aiter_ref::quant_group_i8({100.0f, -200.0f});
    CHECK_NEAR(s1, 3.0f / 127.0f, 1e-6f);
    CHECK_NEAR(s2, 200.0f / 127.0f, 1e-5f);
    CHECK(s1 != s2);
    static_cast<void>(q1);
    static_cast<void>(q2);
}

void test_fp8_zero_group_and_amax_floor() {
    const auto [q, scale] = aiter_ref::quant_group_fp8(std::vector<float>(4, 0.0f));
    CHECK(scale == aiter_ref::kAmaxFloor / aiter_ref::kF8E4M3Qmax);
    for (std::uint8_t b : q) CHECK_EQ(b, 0);
}

// Independent reference: the quantized byte must be a representable E4M3
// value minimizing |y - value|, with exact ties going to the byte with even
// value (same-binade even mantissa and cross-binade even-min-denormal both
// reduce to an even byte value).
std::uint8_t brute_force_best_byte(float y) {
    std::uint8_t best = 0;
    float best_d = std::numeric_limits<float>::infinity();
    for (int b = 0; b <= 255; ++b) {
        const float d = std::fabs(y - aiter_ref::e4m3_to_f32(static_cast<std::uint8_t>(b)));
        // Strictly better wins; on a tie, switch only if the incumbent is odd
        // and the candidate even. (The +0/-0 tie is both-even: keep the
        // first, so +0 stays +0.)
        if (d < best_d || (d == best_d && best % 2 == 1 && b % 2 == 0)) {
            best = static_cast<std::uint8_t>(b);
            best_d = d;
        }
    }
    // The only cross-sign tie is +0 (0x00) vs -0 (0x80) — including the
    // half-step underflow case y = ±2^-10 where 0 co-wins the argmin. RNE
    // conversion is sign-preserving, so match y's sign bit.
    if (best_d == std::fabs(y)) return std::signbit(y) ? 0x80 : 0x00;
    return best;
}

void test_fp8_matches_brute_force_rne() {
    aiter_ref::Rng rng(0xBEEF);
    std::vector<float> ys;
    for (int i = 0; i < 2000; ++i) ys.push_back(rng.f32_sym() * 448.0f);
    // Grid-adjacent and boundary values.
    const std::vector<float> extra = {0.0f,        448.0f,      -448.0f,     464.0f,
                                      480.0f,      416.0f,      432.0f,      0x1p-9f,
                                      0x1p-10f,    1.5f * 0x1p-9f, 0x1p-6f, 0.75f * 0x1p-6f,
                                      224.0f,      240.0f,      1e-30f,      -1e-30f};
    ys.insert(ys.end(), extra.begin(), extra.end());
    for (float y : ys) {
        CHECK_EQ(aiter_ref::f32_to_e4m3_rne_satfinite(y), brute_force_best_byte(y));
    }
}

void test_fp8_group_error_bound_vs_amax() {
    aiter_ref::Rng rng(0xF8F8);
    for (int iter = 0; iter < 500; ++iter) {
        const std::size_t n = 1 + rng.below(128);
        std::vector<float> g(n);
        for (float& v : g) v = rng.f32_sym() * 50.0f;
        float amax = 0.0f;
        for (float v : g) amax = std::max(amax, std::fabs(v));
        const auto [q, scale] = aiter_ref::quant_group_fp8(g);
        for (std::size_t i = 0; i < n; ++i) {
            const float dq = aiter_ref::e4m3_to_f32(q[i]);
            // Worst e4m3 step is 32 at the top of the range -> half-step 16
            // -> 16/448 ~ 0.0357 of amax, plus reciprocal slack.
            const float err = std::fabs(g[i] - dq * scale);
            CHECK(err <= 0.04f * std::max(amax, 1e-10f));
        }
    }
}

void test_fp8_degenerate_group_stays_finite() {
    const auto [q, scale] = aiter_ref::quant_group_fp8({0.0f, 1e-30f});
    CHECK(std::isfinite(scale) && scale > 0.0f);
    CHECK_EQ(q[0], 0);
    // 1e-30 * 448/1e-10 = 4.48e-18: far below the denormal grid -> 0.
    CHECK_EQ(q[1], 0);
}

int main() {
    RUN_TEST(test_i8_amax_element_maps_to_127);
    RUN_TEST(test_i8_zero_group_uses_amax_floor);
    RUN_TEST(test_i8_tiny_group_floors_amax);
    RUN_TEST(test_i8_random_groups_error_bound_and_range);
    RUN_TEST(test_i8_group_independence);
    RUN_TEST(test_fp8_zero_group_and_amax_floor);
    RUN_TEST(test_fp8_matches_brute_force_rne);
    RUN_TEST(test_fp8_group_error_bound_vs_amax);
    RUN_TEST(test_fp8_degenerate_group_stays_finite);
    return finish();
}
