// SPDX-License-Identifier: Apache-2.0
// Copyright (C) 2024-2026, The vLLM team. Copyright (C) AMD.
//
// Algorithm port of vllm::moe_align_block_size_kernel from ROCm/aiter
// (csrc/kernels/moe_align_block_size_kernels.cu @ 1eab5ae12, Apache-2.0),
// reduced to a deterministic single-threaded host reference.
//
// The CUDA kernel is one block of num_experts threads over four
// barrier-separated passes. Only pass 4 (token scatter) is order-sensitive:
// on the device each expert's slots are claimed via atomicAdd cursors, so
// token order within one expert's segment is nondeterministic. This port
// keeps the passes and outputs identical but scatters in ascending token
// order; on-card ports must therefore be compared per-segment as multisets,
// never element-wise.
//
// Outputs (same contract as the kernel arguments):
// - sorted_token_ids: length padded_len(), prefilled by the caller with the
//   sentinel topk_ids.size(); unwritten padding keeps it.
// - expert_ids / token_nums: one entry per allocated block.
// - total_tokens_post_pad: sum_e ceil(count_e / block_size) * block_size.
#ifndef ROCM_DEMO_AITER_REF_MOE_ALIGN_HPP
#define ROCM_DEMO_AITER_REF_MOE_ALIGN_HPP

#include <cstddef>
#include <cstdint>

namespace aiter_ref {

// Host-side buffer bound: each expert wastes at most block_size - 1 slots.
std::size_t padded_len(std::size_t numel, std::size_t num_experts, std::size_t block_size);

// Block-aligned expert scheduling. topk_ids values must lie in
// [0, num_experts); sorted_token_ids must be prefilled with the sentinel
// over at least padded_len() entries; expert_ids/token_nums need at least
// numel + num_experts entries.
void moe_align_block_size(const std::int32_t* topk_ids, std::size_t numel,
                          std::int32_t num_experts, std::int32_t block_size,
                          std::int32_t* sorted_token_ids, std::int32_t* expert_ids,
                          std::int32_t* token_nums, std::int32_t* total_tokens_post_pad);

}  // namespace aiter_ref

#endif  // ROCM_DEMO_AITER_REF_MOE_ALIGN_HPP
