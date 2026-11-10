// SPDX-License-Identifier: Apache-2.0
// See aiter_ref/moe_align.hpp for provenance and semantics.

#include "aiter_ref/moe_align.hpp"

#include <cassert>
#include <vector>

namespace aiter_ref {

std::size_t padded_len(std::size_t numel, std::size_t num_experts, std::size_t block_size) {
    return numel + num_experts * (block_size - 1);
}

void moe_align_block_size(const std::int32_t* topk_ids, std::size_t numel,
                          std::int32_t num_experts, std::int32_t block_size,
                          std::int32_t* sorted_token_ids, std::int32_t* expert_ids,
                          std::int32_t* token_nums, std::int32_t* total_tokens_post_pad) {
    assert(block_size >= 1);

    // Pass 1: expert histogram (device: atomicAdd into LDS).
    std::vector<std::int64_t> counts(static_cast<std::size_t>(num_experts), 0);
    for (std::size_t i = 0; i < numel; ++i) {
        assert(topk_ids[i] >= 0 && topk_ids[i] < num_experts);
        counts[static_cast<std::size_t>(topk_ids[i])] += 1;
    }

    // Pass 2: block-index prefix sum + per-expert write cursors. The kernel
    // counts *blocks* in cumsum, not tokens.
    std::vector<std::int64_t> cumsum(static_cast<std::size_t>(num_experts) + 1, 0);
    std::vector<std::int64_t> write_pos(static_cast<std::size_t>(num_experts), 0);
    for (std::int32_t e = 0; e < num_experts; ++e) {
        const std::int64_t blocks =
            (counts[static_cast<std::size_t>(e)] + block_size - 1) / block_size;
        cumsum[static_cast<std::size_t>(e) + 1] = cumsum[static_cast<std::size_t>(e)] + blocks;
        write_pos[static_cast<std::size_t>(e)] =
            cumsum[static_cast<std::size_t>(e)] * static_cast<std::int64_t>(block_size);
    }
    *total_tokens_post_pad = static_cast<std::int32_t>(
        cumsum[static_cast<std::size_t>(num_experts)] * static_cast<std::int64_t>(block_size));

    // Pass 3: per-block expert metadata; token_nums counts down by block_size.
    for (std::int32_t e = 0; e < num_experts; ++e) {
        std::int64_t remaining = counts[static_cast<std::size_t>(e)];
        for (std::int64_t b = cumsum[static_cast<std::size_t>(e)];
             b < cumsum[static_cast<std::size_t>(e) + 1]; ++b) {
            expert_ids[static_cast<std::size_t>(b)] = e;
            token_nums[static_cast<std::size_t>(b)] = static_cast<std::int32_t>(remaining);
            remaining -= block_size;
        }
    }

    // Pass 4: token scatter (device: atomicAdd cursor claim; here ascending).
    for (std::size_t i = 0; i < numel; ++i) {
        const std::int32_t e = topk_ids[i];
        sorted_token_ids[static_cast<std::size_t>(write_pos[static_cast<std::size_t>(e)]++)] =
            static_cast<std::int32_t>(i);
    }
}

}  // namespace aiter_ref
