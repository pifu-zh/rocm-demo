// SPDX-License-Identifier: Apache-2.0
// End-to-end test of the extracted MoE scheduling chain — the exact op
// sequence aiter/vLLM run between gating logits and the fused-MoE GEMMs:
//
//   logits [T, E] --topk_softmax(k, renorm)--> (weights, ids) [T, k]
//                 --moe_align_block_size(E, B)--> sorted_token_ids / metadata
//
// Upstream: aiter `csrc/kernels/topk_softmax_kernels.cu` +
// `csrc/kernels/moe_align_block_size_kernels.cu`.

#include <cmath>
#include <cstddef>
#include <cstdint>
#include <vector>

#include "aiter_ref/moe_align.hpp"
#include "aiter_ref/rng.hpp"
#include "aiter_ref/topk_softmax.hpp"
#include "test_util.hpp"

void test_scheduling_chain_random_shapes() {
    aiter_ref::Rng rng(0xC0FFEE);
    for (int case_i = 0; case_i < 40; ++case_i) {
        const std::size_t tokens = 1 + rng.below(48);
        const std::size_t experts = 2 + rng.below(14);
        const std::size_t k = 1 + rng.below(experts);
        const int block_size = 1 << rng.below(5);  // 1..16

        // 1. Routing: per-row top-k with renormalized weights.
        std::vector<std::int32_t> ids;
        ids.reserve(tokens * k);
        for (std::size_t t = 0; t < tokens; ++t) {
            std::vector<float> logits(experts);
            for (float& v : logits) v = rng.f32_sym() * 8.0f;
            const aiter_ref::TopK r = aiter_ref::topk_softmax(logits, k, true, 0, experts);
            float wsum = 0.0f;
            for (float w : r.values) wsum += w;
            CHECK(std::fabs(wsum - 1.0f) <= 1e-5f);
            CHECK(r.expert_ids.size() == k);
            for (std::int32_t e : r.expert_ids) ids.push_back(e);
        }
        CHECK(ids.size() == tokens * k);

        // 2. Scheduling: block-aligned compaction.
        const std::size_t numel = ids.size();
        std::vector<std::int32_t> sorted(
            aiter_ref::padded_len(numel, experts, static_cast<std::size_t>(block_size)),
            static_cast<std::int32_t>(numel));
        const std::size_t meta_len = numel + experts;
        std::vector<std::int32_t> expert_ids(meta_len, -1);
        std::vector<std::int32_t> token_nums(meta_len, -1);
        std::int32_t total = -1;
        aiter_ref::moe_align_block_size(ids.data(), numel, static_cast<std::int32_t>(experts),
                                        block_size, sorted.data(), expert_ids.data(),
                                        token_nums.data(), &total);

        // 3. Invariants across the chain.
        std::vector<std::size_t> count(experts, 0);
        for (std::int32_t e : ids) count[static_cast<std::size_t>(e)] += 1;
        std::size_t expected_total = 0;
        for (std::size_t e = 0; e < experts; ++e) {
            expected_total += (count[e] + static_cast<std::size_t>(block_size) - 1) /
                              static_cast<std::size_t>(block_size) *
                              static_cast<std::size_t>(block_size);
        }
        CHECK_EQ(total, static_cast<std::int32_t>(expected_total));

        // Every (row, slot) entry index is scattered exactly once, inside
        // its expert's segment; every other slot is sentinel.
        const std::int32_t sentinel = static_cast<std::int32_t>(numel);
        std::vector<std::size_t> seen(numel, 0);
        std::size_t pos = 0;
        for (std::size_t e = 0; e < experts; ++e) {
            const std::size_t seg = (count[e] + static_cast<std::size_t>(block_size) - 1) /
                                    static_cast<std::size_t>(block_size) *
                                    static_cast<std::size_t>(block_size);
            for (std::size_t j = 0; j < seg; ++j) {
                const std::int32_t s = sorted[pos + j];
                if (s != sentinel) {
                    seen[static_cast<std::size_t>(s)] += 1;
                    CHECK_EQ(ids[static_cast<std::size_t>(s)], static_cast<std::int32_t>(e));
                }
            }
            pos += seg;
        }
        CHECK_EQ(pos, expected_total);
        for (std::size_t n : seen) CHECK_EQ(n, 1);  // each entry exactly once
        for (std::size_t i = pos; i < sorted.size(); ++i) CHECK_EQ(sorted[i], sentinel);
    }
}

void test_minimal_chain() {
    const aiter_ref::TopK r = aiter_ref::topk_softmax({0.0f}, 1, true, 0, 1);
    const std::vector<std::int32_t> want_ids = {0};
    const std::vector<float> want_values = {1.0f};  // softmax of a single logit is 1.0
    CHECK_VEC_EQ(r.expert_ids, want_ids);
    CHECK_VEC_EQ(r.values, want_values);

    const std::vector<std::int32_t> ids = r.expert_ids;
    std::vector<std::int32_t> sorted(aiter_ref::padded_len(1, 1, 1), 1);
    std::vector<std::int32_t> expert_ids(2, -1);
    std::vector<std::int32_t> token_nums(2, -1);
    std::int32_t total = -1;
    aiter_ref::moe_align_block_size(ids.data(), 1, 1, 1, sorted.data(), expert_ids.data(),
                                    token_nums.data(), &total);
    CHECK_EQ(total, 1);
    CHECK_EQ(sorted[0], 0);
    CHECK_EQ(expert_ids[0], 0);
    CHECK_EQ(token_nums[0], 1);
}

int main() {
    RUN_TEST(test_scheduling_chain_random_shapes);
    RUN_TEST(test_minimal_chain);
    return finish();
}
