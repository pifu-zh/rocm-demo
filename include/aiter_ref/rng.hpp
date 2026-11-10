// SPDX-License-Identifier: Apache-2.0
// Deterministic xorshift64* RNG for the property tests (no dependency on an
// external random library).
#ifndef ROCM_DEMO_AITER_REF_RNG_HPP
#define ROCM_DEMO_AITER_REF_RNG_HPP

#include <cstdint>

namespace aiter_ref {

class Rng {
public:
    explicit Rng(std::uint64_t seed) : state_(seed | 1) {}

    std::uint64_t next_u64() {
        std::uint64_t x = state_;
        x ^= x >> 12;
        x ^= x << 25;
        x ^= x >> 27;
        state_ = x;
        return x * 0x2545F4914F6CDD1Dull;
    }

    // Uniform integer in [0, n); n must be nonzero.
    std::uint64_t below(std::uint64_t n) { return next_u64() % n; }

    // Uniform float in [0, 1) with 24 random mantissa bits.
    float f32_unit() { return static_cast<float>(next_u64() >> 40) / 16777216.0f; }

    // Uniform float in [-1, 1).
    float f32_sym() { return f32_unit() * 2.0f - 1.0f; }

private:
    std::uint64_t state_;
};

}  // namespace aiter_ref

#endif  // ROCM_DEMO_AITER_REF_RNG_HPP
