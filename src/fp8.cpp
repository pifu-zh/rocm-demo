// SPDX-License-Identifier: Apache-2.0
// See aiter_ref/fp8.hpp for provenance and semantics.

#include "aiter_ref/fp8.hpp"

#include <bit>

namespace aiter_ref {
namespace {

// Round-to-nearest-even shift right. shift == 0 returns the value;
// shift > 31 returns zero.
std::uint32_t rne_shift(std::uint32_t v, std::uint32_t shift) {
    if (shift == 0) return v;
    if (shift > 31) return 0;
    const std::uint32_t q = v >> shift;
    const std::uint32_t rem = v & ((1u << shift) - 1);
    const std::uint32_t half = 1u << (shift - 1);
    if (rem > half || (rem == half && (q & 1) == 1)) return q + 1;
    return q;
}

}  // namespace

float e4m3_to_f32(std::uint8_t bits) {
    const std::uint32_t s = (bits >> 7) & 1;
    const std::uint32_t e = (bits >> 3) & 0xF;
    const std::uint32_t m = bits & 0x7;
    std::uint32_t bits32;
    if (e == 0) {
        // Denormal: m * 2^-9, decoded arithmetically (the linear m << 20
        // form would wrongly enable the implicit leading one).
        const float mag =
            static_cast<float>(m) * std::bit_cast<float>(118u << 23);  // * 2^-9, exact
        bits32 = std::bit_cast<std::uint32_t>(mag) | (s << 31);
    } else if (e == 0xF && m == 0x7) {
        // NaN: E4M3FN reserves 1111.111; no infinities exist.
        bits32 = (s << 31) | 0x7FC00000u;
    } else {
        // Normal: 2^(e-7) * (1 + m/8) -> f32 exponent field (e-7)+127 = e+120.
        bits32 = (s << 31) | ((e + 120) << 23) | (m << 20);
    }
    return std::bit_cast<float>(bits32);
}

std::uint8_t f32_to_e4m3_rne_satfinite(float x) {
    const std::uint32_t bits = std::bit_cast<std::uint32_t>(x);
    const std::uint8_t s = static_cast<std::uint8_t>((bits >> 31) & 1);
    const std::int32_t e32 = static_cast<std::int32_t>((bits >> 23) & 0xFF);
    const std::uint32_t m32 = bits & 0x7FFFFFu;
    if (e32 == 0xFF) {
        // NaN and Inf both map to the E4M3FN NaN byte (no Inf exists).
        return static_cast<std::uint8_t>((s << 7) | 0x7F);
    }
    if (e32 == 0) {
        // f32 denormals are below 2^-126, far under half-of-min-denormal
        // (2^-10): they all round to zero.
        return static_cast<std::uint8_t>(s << 7);
    }
    const std::int32_t e = e32 - 127 + 7;        // E4M3-biased exponent
    const std::uint32_t mant = m32 | 0x800000u;  // implicit leading one

    if (e < 1) {
        // Denormal target: the value in units of the denormal step 2^-9 is
        // mant >> (21 - e), RNE. An RNE overflow to 8 means the value rounds
        // up to the min normal (2^-6 = byte 0x08).
        const std::uint32_t m3 = rne_shift(mant, static_cast<std::uint32_t>(21 - e));
        if (m3 <= 7) return static_cast<std::uint8_t>((s << 7) | m3);
        return static_cast<std::uint8_t>((s << 7) | 0x08);
    }

    // Normal target: round the 24-bit significand to 3 fraction bits.
    const std::uint32_t v = rne_shift(mant, 20);  // in [8, 16]; 16 = mantissa overflow
    std::int32_t e3;
    std::int32_t m3;
    if (v == 16) {
        e3 = e + 1;
        m3 = 0;
    } else {
        e3 = e;
        m3 = static_cast<std::int32_t>(v - 8);
    }
    if (e3 > 15 || (e3 == 15 && m3 == 7)) {
        // Overflow past the max finite (448): the NaN zone (1111.111) is
        // next, so .satfinite clamps to 448.
        return static_cast<std::uint8_t>((s << 7) | 0x7E);
    }
    return static_cast<std::uint8_t>((s << 7) | (static_cast<std::uint32_t>(e3) << 3) |
                                     static_cast<std::uint32_t>(m3));
}

}  // namespace aiter_ref
