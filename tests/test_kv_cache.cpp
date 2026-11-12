// SPDX-License-Identifier: Apache-2.0
// Tests for the reshape_and_cache_flash host reference: scatter layout,
// padding skip, duplicate-slot determinism, strided inputs, fp8 quantized
// path, and a read-back round trip.
#include "aiter_ref/kv_cache.hpp"
#include "aiter_ref/fp8.hpp"
#include "test_util.hpp"

#include <cstddef>
#include <cstdint>
#include <vector>

namespace {

aiter_ref::CacheShape make_shape(std::size_t tokens, std::size_t heads, std::size_t head_size,
                                 std::size_t block_size, std::size_t blocks) {
    aiter_ref::CacheShape s;
    s.num_tokens = tokens;
    s.num_heads = heads;
    s.head_size = head_size;
    s.block_size = block_size;
    s.num_blocks = blocks;
    return s;
}

std::size_t cache_index(std::size_t slot, const aiter_ref::CacheShape& s, std::size_t head,
                        std::size_t d) {
    const std::size_t n = s.num_heads * s.head_size;
    return (slot / s.block_size) * (s.block_size * n) + (slot % s.block_size) * n +
           head * s.head_size + d;
}

void scatter_layout_and_readback() {
    const std::size_t heads = 2, hd = 3, bs = 4, blocks = 3;
    auto s = make_shape(5, heads, hd, bs, blocks);
    std::vector<float> key(5 * heads * hd), value(5 * heads * hd);
    for (std::size_t i = 0; i < key.size(); ++i) key[i] = static_cast<float>(i);
    for (std::size_t i = 0; i < value.size(); ++i) value[i] = -static_cast<float>(i);
    // Slots span three blocks with a gap (block 1 offset 3 unused).
    const std::vector<std::int64_t> slots = {0, 3, 4, 9, 11};
    const float k_prefill = -7.0f, v_prefill = 7.0f;
    std::vector<float> kc(blocks * bs * heads * hd, k_prefill);
    std::vector<float> vc(blocks * bs * heads * hd, v_prefill);
    aiter_ref::reshape_and_cache_flash_f32(key, value, s, slots, kc, vc);
    // Every written slot holds the token's row; layout per (head, d).
    for (std::size_t t = 0; t < 5; ++t) {
        for (std::size_t h = 0; h < heads; ++h) {
            for (std::size_t d = 0; d < hd; ++d) {
                const std::size_t idx = cache_index(slots[t], s, h, d);
                CHECK_EQ(kc[idx], key[t * heads * hd + h * hd + d]);
                CHECK_EQ(vc[idx], value[t * heads * hd + h * hd + d]);
            }
        }
    }
    // The untouched slot (block 1, offset 3 -> flat 7) keeps the prefill.
    CHECK_EQ(kc[cache_index(7, s, 0, 0)], k_prefill);
    CHECK_EQ(vc[cache_index(7, s, 2 % heads, 0)], v_prefill);
}

void padding_slots_are_skipped() {
    auto s = make_shape(3, 1, 2, 2, 2);
    std::vector<float> key(3 * 2, 1.0f), value(3 * 2, 2.0f);
    const std::vector<std::int64_t> slots = {0, -1, 3};  // token 1 padded
    std::vector<float> kc(2 * 2 * 2, -100.0f), vc(2 * 2 * 2, -100.0f);
    aiter_ref::reshape_and_cache_flash_f32(key, value, s, slots, kc, vc);
    CHECK_EQ(kc[cache_index(0, s, 0, 0)], 1.0f);
    CHECK_EQ(kc[cache_index(3, s, 0, 1)], 1.0f);
    // Slot 2 (block 1 offset 0) was never targeted.
    CHECK_EQ(kc[cache_index(2, s, 0, 0)], -100.0f);
}

void duplicate_slot_last_token_wins() {
    auto s = make_shape(2, 1, 1, 2, 1);
    std::vector<float> key = {5.0f, 9.0f}, value = {50.0f, 90.0f};
    const std::vector<std::int64_t> slots = {1, 1};  // both tokens -> slot 1
    std::vector<float> kc(2, 0.0f), vc(2, 0.0f);
    aiter_ref::reshape_and_cache_flash_f32(key, value, s, slots, kc, vc);
    // Device race; the port is ascending-deterministic (last token wins).
    CHECK_EQ(kc[1], 9.0f);
    CHECK_EQ(vc[1], 90.0f);
}

void strided_input_rows() {
    // key_stride > heads*head_size: rows padded beyond the cached window.
    auto s = make_shape(2, 1, 2, 2, 1);
    s.key_stride = 4;
    s.value_stride = 4;
    std::vector<float> key = {1, 2, 99, 99, 3, 4, 99, 99};
    std::vector<float> value = {10, 20, 99, 99, 30, 40, 99, 99};
    const std::vector<std::int64_t> slots = {0, 1};
    std::vector<float> kc(4, 0.0f), vc(4, 0.0f);
    aiter_ref::reshape_and_cache_flash_f32(key, value, s, slots, kc, vc);
    CHECK_EQ(kc[cache_index(0, s, 0, 0)], 1.0f);
    CHECK_EQ(kc[cache_index(0, s, 0, 1)], 2.0f);
    CHECK_EQ(kc[cache_index(1, s, 0, 0)], 3.0f);
    CHECK_EQ(vc[cache_index(1, s, 0, 1)], 40.0f);
}

void fp8_path_divides_by_scale() {
    auto s = make_shape(2, 1, 2, 2, 1);
    std::vector<float> key = {3.0f, -5.0f, 0.25f, 448.0f};
    std::vector<float> value = {1.5f, -0.03125f, 6.0f, 100.0f};
    const std::vector<std::int64_t> slots = {0, 1};
    std::vector<std::uint8_t> kc(4), vc(4);
    // cache = e4m3(x / scale): scale 2 -> 3 -> 1.5, -5 -> -2.5, ...
    aiter_ref::reshape_and_cache_flash_fp8(key, value, s, slots, 2.0f, 2.0f, kc, vc);
    CHECK_NEAR(aiter_ref::e4m3_to_f32(kc[cache_index(0, s, 0, 0)]), 1.5f, 1e-6f);
    CHECK_NEAR(aiter_ref::e4m3_to_f32(kc[cache_index(0, s, 0, 1)]), -2.5f, 1e-6f);
    CHECK_NEAR(aiter_ref::e4m3_to_f32(kc[cache_index(1, s, 0, 0)]), 0.125f, 1e-6f);
    // 448/2 = 224: representable exactly in E4M3FN.
    CHECK_NEAR(aiter_ref::e4m3_to_f32(kc[cache_index(1, s, 0, 1)]), 224.0f, 1e-4f);
    CHECK_NEAR(aiter_ref::e4m3_to_f32(vc[cache_index(0, s, 0, 0)]), 0.75f, 1e-6f);
    CHECK_NEAR(aiter_ref::e4m3_to_f32(vc[cache_index(0, s, 0, 1)]), -0.015625f, 1e-9f);
    // Padding token with the quantized path too.
    const std::vector<std::int64_t> slots_pad = {-1, 1};
    std::vector<std::uint8_t> kc2(4, 0xAB), vc2(4, 0xAB);
    aiter_ref::reshape_and_cache_flash_fp8(key, value, s, slots_pad, 2.0f, 2.0f, kc2, vc2);
    CHECK_EQ(kc2[cache_index(0, s, 0, 0)], 0xAB);
    CHECK_EQ(kc2[cache_index(1, s, 0, 1)], kc[cache_index(1, s, 0, 1)]);
}

}  // namespace

int main() {
    RUN_TEST(scatter_layout_and_readback);
    RUN_TEST(padding_slots_are_skipped);
    RUN_TEST(duplicate_slot_last_token_wins);
    RUN_TEST(strided_input_rows);
    RUN_TEST(fp8_path_divides_by_scale);
    return finish();
}
