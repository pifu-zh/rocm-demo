// SPDX-License-Identifier: Apache-2.0
// Unit tests for the E4M3FN codec port (256/256 round trip + boundary and
// tie cases). Upstream: cuda-oxide `crates/cuda-device/src/fp8.rs`.

#include <cmath>
#include <cstdint>
#include <limits>

#include "aiter_ref/fp8.hpp"
#include "test_util.hpp"

void test_roundtrip_all_256_bytes() {
    for (int b = 0; b <= 255; ++b) {
        const float v = aiter_ref::e4m3_to_f32(static_cast<std::uint8_t>(b));
        CHECK_EQ(aiter_ref::f32_to_e4m3_rne_satfinite(v), static_cast<std::uint8_t>(b));
    }
}

void test_boundary_spot_checks() {
    CHECK_NEAR(aiter_ref::e4m3_to_f32(0x7E), 448.0f, 0.0);   // max finite
    CHECK_NEAR(aiter_ref::e4m3_to_f32(0x08), 0x1p-6f, 0.0);  // min normal
    CHECK_NEAR(aiter_ref::e4m3_to_f32(0x01), 0x1p-9f, 0.0);  // min denormal
    CHECK(std::isnan(aiter_ref::e4m3_to_f32(0x7F)));
    CHECK(std::isnan(aiter_ref::e4m3_to_f32(0xFF)));
    CHECK_EQ(aiter_ref::f32_to_e4m3_rne_satfinite(1e30f), 0x7E);   // saturate +
    CHECK_EQ(aiter_ref::f32_to_e4m3_rne_satfinite(-1e30f), 0xFE);  // saturate -
    CHECK_EQ(aiter_ref::f32_to_e4m3_rne_satfinite(464.0f), 0x7E);  // midpoint ties to even (448)
    CHECK_EQ(aiter_ref::f32_to_e4m3_rne_satfinite(480.0f), 0x7E);
    CHECK_EQ(aiter_ref::f32_to_e4m3_rne_satfinite(std::numeric_limits<float>::infinity()),
             0x7F);  // no Inf -> NaN byte
    CHECK_EQ(aiter_ref::f32_to_e4m3_rne_satfinite(-std::numeric_limits<float>::infinity()),
             0xFF);
    CHECK_EQ(aiter_ref::f32_to_e4m3_rne_satfinite(std::numeric_limits<float>::quiet_NaN()),
             0x7F);
    // Denormal grid ties: 2^-10 is exactly half of 2^-9 -> ties to even (0);
    // 1.5 * 2^-9 is halfway between bytes 1 and 2 -> ties to even (2).
    CHECK_EQ(aiter_ref::f32_to_e4m3_rne_satfinite(0x1p-10f), 0x00);
    CHECK_EQ(aiter_ref::f32_to_e4m3_rne_satfinite(1.5f * 0x1p-9f), 0x02);
    CHECK_EQ(aiter_ref::f32_to_e4m3_rne_satfinite(0x1p-9f), 0x01);
}

int main() {
    RUN_TEST(test_roundtrip_all_256_bytes);
    RUN_TEST(test_boundary_spot_checks);
    return finish();
}
