// SPDX-License-Identifier: Apache-2.0
// Copyright (C) 2024-2026, The vLLM team. Copyright (C) AMD.
//
// Port of vllm::reshape_and_cache_flash_kernel from ROCm/aiter
// (csrc/kernels/cache_kernels.cu @ 1eab5ae12, Apache-2.0), reduced to a
// deterministic single-threaded host reference. fp8 quantized stores reuse
// the repo's E4M3FN codec (aiter_ref fp8, itself validated exhaustively).
//
// Semantics pinned here:
// - key/value: [num_tokens, num_heads, head_size] (row stride = key_stride /
//   value_stride, may exceed heads*head_size); caches: [num_blocks,
//   block_size, num_heads, head_size] with block_stride =
//   block_size*num_heads*head_size.
// - slot_mapping[num_tokens] maps a token to a flat cache slot:
//   block = slot / block_size, offset = slot % block_size, target =
//   block*block_stride + offset*num_heads*head_size + head*head_size + d.
// - slot < 0 (vLLM padding sentinel) skips the token entirely: the cache
//   keeps whatever the caller prefilled.
// - fp8 path (kv dt != auto): cache = cast<E4M3FN>(float(x) * (1/scale))
//   with per-tensor scalar scales (upstream *k_scale pointer semantics,
//   reciprocal computed once per token row).
// - Duplicate slots: on the device two blocks writing one slot is a race;
//   this port is ascending-deterministic (higher token index wins). Like
//   moe_align, on-card comparisons must treat written slots as multisets.
#ifndef ROCM_DEMO_AITER_REF_KV_CACHE_HPP
#define ROCM_DEMO_AITER_REF_KV_CACHE_HPP

#include <cstddef>
#include <cstdint>
#include <vector>

namespace aiter_ref {

struct CacheShape {
    std::size_t num_tokens;
    std::size_t num_heads;
    std::size_t head_size;
    std::size_t block_size;   // slots per block
    std::size_t num_blocks;   // must exceed max(slot)/block_size
    std::size_t key_stride = 0;   // 0 derives to num_heads*head_size
    std::size_t value_stride = 0; // 0 derives to num_heads*head_size
};

// Raw (f32 cache) store. Caches must be prefilled by the caller (padding
// slots keep the prefill); slot_mapping holds one entry per token.
void reshape_and_cache_flash_f32(const std::vector<float>& key, const std::vector<float>& value,
                                 const CacheShape& shape,
                                 const std::vector<std::int64_t>& slot_mapping,
                                 std::vector<float>& key_cache, std::vector<float>& value_cache);

// fp8 E4M3FN cache store: cache = e4m3(float(x) / scale). Scales are
// per-tensor scalars (upstream passes pointers; 0 is rejected upstream
// implicitly via inf — rejected here with an assert).
void reshape_and_cache_flash_fp8(const std::vector<float>& key, const std::vector<float>& value,
                                 const CacheShape& shape,
                                 const std::vector<std::int64_t>& slot_mapping, float k_scale,
                                 float v_scale, std::vector<std::uint8_t>& key_cache,
                                 std::vector<std::uint8_t>& value_cache);

}  // namespace aiter_ref

#endif  // ROCM_DEMO_AITER_REF_KV_CACHE_HPP
