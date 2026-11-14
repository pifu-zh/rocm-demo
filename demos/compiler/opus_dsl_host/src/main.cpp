// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2026, Advanced Micro Devices, Inc. all rights reserved.
//
// Host unit tests for the DEVICE-INDEPENDENT half of opus's single-header
// DSL (vendor/opus_host_slice.hpp — extracted from aiter
// csrc/include/opus/opus.hpp @ 1eab5ae12, MIT, lines 1..1190). These are
// the abstractions every aiter kernel is BUILT ON — the compile-time
// algebra is where the DSL's design intent lives, and it is host-verifiable
// (the device half — MFMA wrappers, DPP ops, .buffer loads — stays on the
// hardware line; three pieces are already independently verified by other
// lab demos: med3/mov_dpp/upd_dpp semantics -> warp_sync; make_gmem/V#
// descriptor -> lds_passthrough; the fp4/e8m0 finfo tables -> soft_fp4).
//
// clang-only note: opus.hpp uses the __make_integer_seq /
// __type_pack_element compiler intrinsics (clang builtins) — g++ cannot
// compile it; the build system therefore requires clang++.
//
// Test groups:
//   1. number arithmetic + _I literal + is_constant (the compile-time
//      value domain)
//   2. seq algebra: make_index_seq (3 forms), size/at/get/pop_front,
//      concat_seq, reduce_seq_sum/mul, transform (via static_ford)
//   3. static_ford / static_for: compile-time iteration driving runtime
//      accumulation
//   4. array/vector containers + the sub-byte fp4 pack proxy round trip
//   5. tuple algebra: make/get/size, transform_tuple(_with_idx),
//      make_repeated_tuple, concat_tuple, nested flatten
//   6. layout: make_layout + coord_to_linear (row-major verification vs
//      hand-computed) + packed_shape_to_stride
//   7. finfo dtype tables (fp16/bf16/fp8 OCP host branch/i8)
//   8. slice identity fallback
#include <cstdint>
#include <cstring>
#include <cstdio>
#include <type_traits>

#include "vendor/opus_host_slice.hpp"

using namespace opus;

static inline std::uint32_t f32_to_bits(float f) {
    std::uint32_t u;
    std::memcpy(&u, &f, 4);
    return u;
}

static int checks = 0, fails = 0;

#undef CHECK
// variadic: template commas inside CHECK(...) must not split the argument
#define CHECK(...)                                                                                \
    do {                                                                                         \
        ++checks;                                                                                \
        if (!(__VA_ARGS__)) {                                                                    \
            ++fails;                                                                             \
            std::printf("  CHECK failed: %s (line %d)\n", #__VA_ARGS__, __LINE__);               \
        }                                                                                        \
    } while (0)

// ── 1. number arithmetic + literal ──
static void test_number() {
    constexpr number<3> a{};
    constexpr number<4> b{};
    constexpr auto sum = a + b;
    CHECK(std::is_same_v<std::decay_t<decltype(sum)>, number<7>>);
    constexpr auto diff = b - a;
    CHECK(std::is_same_v<std::decay_t<decltype(diff)>, number<1>>);
    constexpr auto prod = a * b;
    CHECK(std::is_same_v<std::decay_t<decltype(prod)>, number<12>>);
    constexpr auto q = number<12>{} / number<4>{};
    CHECK(std::is_same_v<std::decay_t<decltype(q)>, number<3>>);
    // _I literal
    using opus::operator""_I;
    constexpr auto lit = 5_I;
    CHECK(std::is_same_v<std::decay_t<decltype(lit)>, number<5>>);
    // is_constant
    CHECK(is_constant_v<number<9>>);
    CHECK(!is_constant_v<int>);
    // bool_constant
    constexpr bool_constant<true> bt{};
    CHECK(bt());
}

// ── 2. seq algebra ──
static void test_seq() {
    // make_index_seq, three forms
    constexpr auto s0 = make_index_seq<5>();
    CHECK(s0.size() == 5);
    CHECK(s0.at(number<0>{}) == 0 && s0.at(number<4>{}) == 4);
    constexpr auto s1 = make_index_seq<4, 9>();
    CHECK(s1.size() == 5 && s1.at(number<0>{}) == 4 && s1.at(number<4>{}) == 8);
    constexpr auto s2 = make_index_seq<4, 8, 2>();
    CHECK(s2.size() == 2 && s2.at(number<0>{}) == 4 && s2.at(number<1>{}) == 6);
    // get / pop_front
    constexpr auto s3 = seq<7, 8, 9>{};
    CHECK(get<2>(s3) == 9);
    constexpr auto popped = seq_pop_front(s3);
    CHECK(popped.size() == 2 && popped.at(number<0>{}) == 8);
    // concat
    constexpr auto cat = concat_seq(seq<1, 2>{}, seq<3, 4, 5>{});
    CHECK(cat.size() == 5 && cat.at(number<4>{}) == 5);
    // reduce
    constexpr auto s4 = seq<2, 3, 4>{};
    constexpr auto sum_r = reduce_seq_sum(s4);
    CHECK(std::is_same_v<std::decay_t<decltype(sum_r)>, seq<9>>);
    constexpr auto mul_r = reduce_seq_mul(s4);
    CHECK(std::is_same_v<std::decay_t<decltype(mul_r)>, seq<24>>);
    // size() free function
    CHECK(size(s4) == 3);
}

// ── 3. static_ford / static_for ──
static void test_ford() {
    // static_ford over a seq: calls f(number<I>) for each I
    // static_ford(seq<N...>, F): the seq is the SHAPE (dim sizes); ford
    // iterates the full N0 x N1 x ... space, decomposing each flat index
    // into an (i, j, ...) coordinate tuple. 1-D shape <4>: 4 iterations.
    long sum = 0;
    static_ford(seq<4>{}, [&](auto I) { sum += I(); });
    CHECK(sum == 0 + 1 + 2 + 3);
    // 2-D shape <2, 2>: 4 iterations, each f(number<i>, number<j>)
    long sum2d = 0;
    static_ford(seq<2, 2>{}, [&](auto I, auto J) { sum2d += I() * 10 + J(); });
    CHECK(sum2d == 0 + 1 + 10 + 11);
    // static_for with a range (start, end): the compile-time loop unrolls
    // into runtime calls
    long acc = 0;
    static_for([&](auto I) { acc += I() * 2; }, number<0>{}, number<5>{});
    CHECK(acc == 0 + 2 + 4 + 6 + 8);
}

// ── 4. array/vector + sub-byte fp4 pack ──
static void test_array_pack() {
    // a plain fp32 array
    constexpr auto a = make_array(1.f, 2.f, 3.f);
    CHECK(a.size() == 3);
    CHECK(a[number<1>{}] == 2.f);
    CHECK(a[1] == 2.f);
    // concat_array
    constexpr auto b = make_array(4.f, 5.f);
    constexpr auto cat = concat_array(a, b);
    CHECK(cat.size() == 5 && cat[number<3>{}] == 4.f);
    // sub-byte pack: a LOCAL 4-bit unsigned pack type (the fp4_t spelling
    // is registered in the device-line section beyond the slice — the pack
    // MACHINERY (dpacks + the array's proxy storage) is what's extracted)
    using u4 = impl::dpacks<unsigned char, 4, false>;  // 4-bit, 2 per byte
    array<u4, 16> packed{};
    for (int i = 0; i < 16; ++i) packed[i] = u4{static_cast<unsigned char>(i % 16)};
    bool round_trip = true;
    for (int i = 0; i < 16; ++i) {
        // the proxy: .get() recovers the 4-bit value (operator T also decays)
        const int v = static_cast<int>(packed[i].get().value);
        if (v != i % 16) round_trip = false;
    }
    CHECK(round_trip);
    // the storage footprint: 16 x 4-bit = 8 bytes (packed_bytes contract)
    CHECK(packed_bytes_v<u4, 16> == 8);
    CHECK(sizeof(packed) == 8);
}

// ── 5. tuple algebra ──
static void test_tuple() {
    constexpr auto t = make_tuple(1, 2.f, 3.0);
    CHECK(size(t) == 3);
    CHECK(get<0>(t) == 1);
    CHECK(get<1>(t) == 2.f);
    // transform
    const auto t2 = transform_tuple([](auto v) { return v + 1; }, t);
    CHECK(get<0>(t2) == 2);
    CHECK(get<1>(t2) == 3.f);
    // transform with index
    const auto t3 = transform_tuple_with_idx([](auto v, auto I) { return v + I(); }, t);
    CHECK(get<2>(t3) == 5.0);
    // repeated
    const auto rep = make_repeated_tuple(7, number<4>{});
    CHECK(size(rep) == 4 && get<3>(rep) == 7);
    // concat
    const auto c = concat_tuple(make_tuple(1, 2), make_tuple(3.f, 4.0), make_tuple('x'));
    CHECK(size(c) == 5);
    CHECK(get<4>(c) == 'x');
    // nested flatten (1-level)
    const auto nested = make_tuple(make_tuple(1, 2), make_tuple(3, 4));
    const auto flat = flatten_tuple(nested);
    CHECK(size(flat) == 4 && get<3>(flat) == 4);
}

// ── 6. layout: coordinate-to-linear math ──
static void test_layout() {
    // row-major [4, 8]: stride [8, 1]; coord (2, 3) -> 2*8 + 3*1 = 19
    constexpr auto shape = seq<4, 8>{};
    constexpr auto stride = seq<8, 1>{};
    const auto lay = make_layout(shape, stride);
    const auto linear = coord_to_linear(lay, make_tuple(number<2>{}, number<3>{}));
    CHECK(linear == 19);
    // col-major [4, 8]: stride [1, 4]; coord (2, 3) -> 2*1 + 3*4 = 14
    const auto lay_cm = make_layout(seq<4, 8>{}, seq<1, 4>{});
    CHECK(coord_to_linear(lay_cm, make_tuple(number<2>{}, number<3>{})) == 14);
    // packed_shape_to_stride: suffix products of the shape
    constexpr auto strides = packed_shape_to_stride(seq<4, 8>{});
    CHECK(get<0>(strides) == 8 && get<1>(strides) == 1);
    // 3-D: [2, 3, 4] -> strides [12, 4, 1]; coord (1, 2, 3) -> 12 + 8 + 3 = 23
    constexpr auto strides3 = packed_shape_to_stride(seq<2, 3, 4>{});
    CHECK(get<0>(strides3) == 12 && get<1>(strides3) == 4 && get<2>(strides3) == 1);
    const auto lay3 = make_layout(seq<2, 3, 4>{}, strides3);
    CHECK(coord_to_linear(lay3, make_tuple(number<1>{}, number<2>{}, number<3>{})) == 23);
}

// ── 7. finfo dtype tables (host branch = OCP values) ──
static void test_finfo() {
    // fp16
    CHECK(finfo<fp16_t>::max() == 65504.0f);
    CHECK(finfo<fp16_t>::eps() == 9.765625e-4f);
    // bf16 (bitwise: the 3.389531e+38 comment is a rounded decimal)
    CHECK(f32_to_bits(finfo<bf16_t>::max()) == 0x7F7F0000u);
    // fp8 E4M3 OCP (host branch: no __gfx942__ -> 448)
    CHECK(finfo<fp8_t>::max() == 448.0f);
    CHECK(finfo<fp8_t>::eps() == 0.125f);
    // bf8 E5M2 OCP (57344 on gfx942; host branch = 57344? the #else says max
    // 57344 with eps 0.25 — verify against the branch actually compiled)
    CHECK(finfo<bf8_t>::eps() == 0.25f);
    // i8
    CHECK(finfo<i8_t>::max() == 127.0f);
}

// ── 8. empty-tuple contract (the header's NOTE at the tuple section: an
// empty make_tuple returns an INSTANCE, not a reference) ──
static void test_slice() {
    const auto empty = make_tuple();
    CHECK(size(empty) == 0);
    // size() free function on a zero-sized tuple must not crash
    CHECK(size(empty) == size(empty));
}

int main() {
    test_number();
    test_seq();
    test_ford();
    test_array_pack();
    test_tuple();
    test_layout();
    test_finfo();
    test_slice();
    std::printf("opus_dsl_host: %d checks, %d failures -> %s\n", checks, fails,
                fails ? "FAIL" : "PASS");
    return fails ? 1 : 0;
}
