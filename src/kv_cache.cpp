// SPDX-License-Identifier: Apache-2.0
// Copyright (C) 2024-2026, The vLLM team. Copyright (C) AMD.
// Host reference for vllm::reshape_and_cache_flash_kernel; see the header
// for pinned semantics.
#include "aiter_ref/kv_cache.hpp"

#include <cassert>
#include <cmath>
#include <cstddef>
#include <cstdint>

#include "aiter_ref/fp8.hpp"

namespace aiter_ref {

namespace {

std::size_t derived_stride(std::size_t requested, std::size_t heads_h_d) {
    return requested != 0 ? requested : heads_h_d;
}

}  // namespace

void reshape_and_cache_flash_f32(const std::vector<float>& key, const std::vector<float>& value,
                                 const CacheShape& shape,
                                 const std::vector<std::int64_t>& slot_mapping,
                                 std::vector<float>& key_cache, std::vector<float>& value_cache) {
    const std::size_t n = shape.num_heads * shape.head_size;
    const std::size_t key_stride = derived_stride(shape.key_stride, n);
    const std::size_t value_stride = derived_stride(shape.value_stride, n);
    const std::size_t block_stride = shape.block_size * n;
    assert(key.size() >= (shape.num_tokens - 1) * key_stride + n);
    assert(value.size() >= (shape.num_tokens - 1) * value_stride + n);
    assert(slot_mapping.size() >= shape.num_tokens);
    assert(key_cache.size() == shape.num_blocks * block_stride);
    assert(value_cache.size() == shape.num_blocks * block_stride);

    for (std::size_t token = 0; token < shape.num_tokens; ++token) {
        const std::int64_t slot = slot_mapping[token];
        if (slot < 0) continue;  // padding token: cache untouched
        const std::size_t block_idx = static_cast<std::size_t>(slot) / shape.block_size;
        const std::size_t block_offset = static_cast<std::size_t>(slot) % shape.block_size;
        assert(block_idx < shape.num_blocks);
        for (std::size_t i = 0; i < n; ++i) {
            const std::size_t head_idx = i / shape.head_size;
            const std::size_t head_offset = i % shape.head_size;
            const std::size_t tgt =
                block_idx * block_stride + block_offset * n + head_idx * shape.head_size +
                head_offset;
            // Ascending token order: a duplicate slot keeps the LAST writer.
            key_cache[tgt] = key[token * key_stride + i];
            value_cache[tgt] = value[token * value_stride + i];
        }
    }
}

void reshape_and_cache_flash_fp8(const std::vector<float>& key, const std::vector<float>& value,
                                 const CacheShape& shape,
                                 const std::vector<std::int64_t>& slot_mapping, float k_scale,
                                 float v_scale, std::vector<std::uint8_t>& key_cache,
                                 std::vector<std::uint8_t>& value_cache) {
    const std::size_t n = shape.num_heads * shape.head_size;
    const std::size_t key_stride = derived_stride(shape.key_stride, n);
    const std::size_t value_stride = derived_stride(shape.value_stride, n);
    const std::size_t block_stride = shape.block_size * n;
    assert(k_scale != 0.0f && v_scale != 0.0f);
    assert(key.size() >= (shape.num_tokens - 1) * key_stride + n);
    assert(value.size() >= (shape.num_tokens - 1) * value_stride + n);
    assert(slot_mapping.size() >= shape.num_tokens);
    assert(key_cache.size() == shape.num_blocks * block_stride);
    assert(value_cache.size() == shape.num_blocks * block_stride);

    const float inverted_kscale = 1 / k_scale;
    const float inverted_vscale = 1 / v_scale;
    for (std::size_t token = 0; token < shape.num_tokens; ++token) {
        const std::int64_t slot = slot_mapping[token];
        if (slot < 0) continue;
        const std::size_t block_idx = static_cast<std::size_t>(slot) / shape.block_size;
        const std::size_t block_offset = static_cast<std::size_t>(slot) % shape.block_size;
        assert(block_idx < shape.num_blocks);
        for (std::size_t i = 0; i < n; ++i) {
            const std::size_t head_idx = i / shape.head_size;
            const std::size_t head_offset = i % shape.head_size;
            const std::size_t tgt =
                block_idx * block_stride + block_offset * n + head_idx * shape.head_size +
                head_offset;
            key_cache[tgt] = f32_to_e4m3_rne_satfinite(key[token * key_stride + i] *
                                                       inverted_kscale);
            value_cache[tgt] = f32_to_e4m3_rne_satfinite(value[token * value_stride + i] *
                                                         inverted_vscale);
        }
    }
}

}  // namespace aiter_ref
