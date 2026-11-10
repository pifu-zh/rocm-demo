// SPDX-License-Identifier: Apache-2.0
// Golden cases, an exhaustive small-shape sweep against an independent
// recomputation, and randomized property tests for the moe_align port
// (upstream: aiter `csrc/kernels/moe_align_block_size_kernels.cu`).

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <vector>

#include "aiter_ref/moe_align.hpp"
#include "aiter_ref/rng.hpp"
#include "test_util.hpp"

namespace {

struct AlignResult {
    std::vector<std::int32_t> sorted;
    std::vector<std::int32_t> expert_ids;
    std::vector<std::int32_t> token_nums;
    std::int32_t total = -1;
};

AlignResult run(const std::vector<std::int32_t>& ids, int num_experts, int block_size) {
    const std::size_t numel = ids.size();
    AlignResult r;
    r.sorted.assign(aiter_ref::padded_len(numel, static_cast<std::size_t>(num_experts),
                                          static_cast<std::size_t>(block_size)),
                    static_cast<std::int32_t>(numel));
    const std::size_t meta_len = numel + static_cast<std::size_t>(num_experts);
    r.expert_ids.assign(meta_len, -1);
    r.token_nums.assign(meta_len, -1);
    aiter_ref::moe_align_block_size(ids.data(), numel, num_experts, block_size,
                                    r.sorted.data(), r.expert_ids.data(), r.token_nums.data(),
                                    &r.total);
    return r;
}

std::vector<std::int32_t> slice(const std::vector<std::int32_t>& v, std::size_t begin,
                                std::size_t end) {
    return {v.begin() + static_cast<std::ptrdiff_t>(begin),
            v.begin() + static_cast<std::ptrdiff_t>(end)};
}

void check_once(const std::vector<std::int32_t>& ids, int num_experts, int block_size) {
    const std::size_t numel = ids.size();
    const AlignResult r = run(ids, num_experts, block_size);

    std::vector<std::size_t> counts(static_cast<std::size_t>(num_experts), 0);
    for (std::int32_t id : ids) counts[static_cast<std::size_t>(id)] += 1;
    std::vector<std::size_t> blocks(static_cast<std::size_t>(num_experts), 0);
    std::size_t expected_total = 0;
    for (int e = 0; e < num_experts; ++e) {
        blocks[static_cast<std::size_t>(e)] =
            (counts[static_cast<std::size_t>(e)] + static_cast<std::size_t>(block_size) - 1) /
            static_cast<std::size_t>(block_size);
        expected_total += blocks[static_cast<std::size_t>(e)] * static_cast<std::size_t>(block_size);
    }
    CHECK_EQ(r.total, static_cast<std::int32_t>(expected_total));
    CHECK(r.sorted.size() >= expected_total);

    const std::int32_t sentinel = static_cast<std::int32_t>(numel);
    std::size_t pos = 0;
    for (int e = 0; e < num_experts; ++e) {
        const std::size_t seg =
            static_cast<std::size_t>(block_size) * blocks[static_cast<std::size_t>(e)];
        const std::vector<std::int32_t> segv = slice(r.sorted, pos, pos + seg);
        for (std::size_t j = 0; j < seg; ++j) {
            if (j < counts[static_cast<std::size_t>(e)]) {
                CHECK(segv[j] != sentinel);
            } else {
                CHECK_EQ(segv[j], sentinel);
            }
        }
        std::vector<std::int32_t> owned;
        for (std::size_t i = 0; i < numel; ++i) {
            if (ids[i] == e) owned.push_back(static_cast<std::int32_t>(i));
        }
        std::sort(owned.begin(), owned.end());
        CHECK_VEC_EQ(slice(segv, 0, counts[static_cast<std::size_t>(e)]), owned);

        for (std::size_t bi = 0; bi < blocks[static_cast<std::size_t>(e)]; ++bi) {
            const std::size_t meta = pos / static_cast<std::size_t>(block_size) + bi;
            CHECK_EQ(r.expert_ids[meta], e);
            CHECK_EQ(r.token_nums[meta],
                     static_cast<std::int32_t>(counts[static_cast<std::size_t>(e)] -
                                                bi * static_cast<std::size_t>(block_size)));
        }
        pos += seg;
    }
    CHECK_EQ(pos, expected_total);
    for (std::size_t i = expected_total; i < r.sorted.size(); ++i) {
        CHECK_EQ(r.sorted[i], sentinel);
    }
}

}  // namespace

void test_golden_small() {
    // counts [2,1,1], all within one block: no padding inside expert 0.
    const AlignResult r = run({0, 1, 0, 2}, 3, 2);
    const std::vector<std::int32_t> want_sorted = {0, 2, 1, 4, 3, 4, 4};  // sentinel = numel = 4
    const std::vector<std::int32_t> want_expert = {0, 1, 2};
    const std::vector<std::int32_t> want_token = {2, 1, 1};
    CHECK_EQ(r.total, 6);
    CHECK_VEC_EQ(r.sorted, want_sorted);
    CHECK_VEC_EQ(slice(r.expert_ids, 0, 3), want_expert);
    CHECK_VEC_EQ(slice(r.token_nums, 0, 3), want_token);
}

void test_golden_multi_block_token_nums_count_down() {
    // counts [3,1] -> expert 0 gets two blocks (2 used + 1 pad), expert 1 one.
    const AlignResult r = run({0, 0, 0, 1}, 2, 2);
    const std::vector<std::int32_t> want_sorted = {0, 1, 2, 4, 3, 4};
    const std::vector<std::int32_t> want_expert = {0, 0, 1};
    const std::vector<std::int32_t> want_token = {3, 1, 1};  // 3, then 3-2=1 in the pad block
    CHECK_EQ(r.total, 6);
    CHECK_VEC_EQ(r.sorted, want_sorted);
    CHECK_VEC_EQ(slice(r.expert_ids, 0, 3), want_expert);
    CHECK_VEC_EQ(slice(r.token_nums, 0, 3), want_token);
}

void test_golden_empty_expert() {
    // Expert 0 and 2 have no tokens: zero blocks, nothing in metadata.
    const AlignResult r = run({1, 1}, 3, 4);
    const std::vector<std::int32_t> want_expert = {1};
    const std::vector<std::int32_t> want_token = {2};
    const std::vector<std::int32_t> want_sorted = {0, 1};
    CHECK_EQ(r.total, 4);
    CHECK_VEC_EQ(slice(r.expert_ids, 0, 1), want_expert);
    CHECK_VEC_EQ(slice(r.token_nums, 0, 1), want_token);
    CHECK_VEC_EQ(slice(r.sorted, 0, 2), want_sorted);
    for (std::size_t i = 2; i < r.sorted.size(); ++i) CHECK_EQ(r.sorted[i], 2);  // sentinel = 2
}

void test_edge_block_size_one_no_padding() {
    const AlignResult r = run({2, 0, 2}, 3, 1);
    const std::vector<std::int32_t> want_sorted = {1, 0, 2};
    const std::vector<std::int32_t> want_expert = {0, 2, 2};
    const std::vector<std::int32_t> want_token = {1, 2, 1};
    CHECK_EQ(r.total, 3);
    CHECK_VEC_EQ(r.sorted, want_sorted);
    CHECK_VEC_EQ(slice(r.expert_ids, 0, 3), want_expert);
    CHECK_VEC_EQ(slice(r.token_nums, 0, 3), want_token);
}

void test_edge_no_tokens() {
    const AlignResult r = run({}, 4, 8);
    CHECK_EQ(r.total, 0);
    for (std::int32_t s : r.sorted) CHECK_EQ(s, 0);  // sentinel = numel = 0
}

// Exhaustive small-shape sweep against from-scratch recomputation. (Full
// assignment enumeration is exponential in numel — kept to 4^8 = 65k cases
// worst-per-combo; larger shapes go through the randomized property test.)
void test_sweep_all_shapes_small() {
    for (int num_experts = 1; num_experts <= 4; ++num_experts) {
        for (int block_size = 1; block_size <= 5; ++block_size) {
            for (std::size_t numel = 0; numel <= 8; ++numel) {
                std::vector<std::int32_t> ids(numel, 0);
                while (true) {
                    check_once(ids, num_experts, block_size);
                    // odometer increment over all expert-id assignments
                    std::size_t p = 0;
                    while (p < ids.size()) {
                        ids[p] += 1;
                        if (ids[p] < num_experts) break;
                        ids[p] = 0;
                        ++p;
                    }
                    if (p == ids.size()) break;
                }
            }
        }
    }
}

void test_property_random_shapes() {
    aiter_ref::Rng rng(0xA17E57ull);
    for (int case_i = 0; case_i < 300; ++case_i) {
        const int num_experts = 1 + static_cast<int>(rng.below(64));  // up to 64 experts
        const int block_size = 1 << rng.below(6);                     // 1..32
        const std::size_t numel = rng.below(600);
        std::vector<std::int32_t> ids(numel);
        for (std::int32_t& id : ids) id = static_cast<std::int32_t>(rng.below(num_experts));
        check_once(ids, num_experts, block_size);
    }
}

int main() {
    RUN_TEST(test_golden_small);
    RUN_TEST(test_golden_multi_block_token_nums_count_down);
    RUN_TEST(test_golden_empty_expert);
    RUN_TEST(test_edge_block_size_one_no_padding);
    RUN_TEST(test_edge_no_tokens);
    RUN_TEST(test_sweep_all_shapes_small);
    RUN_TEST(test_property_random_shapes);
    return finish();
}
