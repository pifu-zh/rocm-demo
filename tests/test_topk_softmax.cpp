// SPDX-License-Identifier: Apache-2.0
// Unit tests for the MoE routing front-end port: softmax against an f64
// reference, extreme-logit stability, selection/tie-break/renorm/sentinel
// semantics, the pinned expert-parallel exclusion quirk, and randomized
// end-to-end rows (upstream: aiter `csrc/kernels/topk_softmax_kernels.cu`).

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <limits>
#include <vector>

#include "aiter_ref/rng.hpp"
#include "aiter_ref/topk_softmax.hpp"
#include "test_util.hpp"

namespace {

std::vector<double> softmax_f64(const std::vector<float>& x) {
    double m = -std::numeric_limits<double>::infinity();
    for (float v : x) m = std::max(m, static_cast<double>(v));
    std::vector<double> e(x.size());
    double z = 0.0;
    for (std::size_t i = 0; i < x.size(); ++i) {
        e[i] = std::exp(static_cast<double>(x[i]) - m);
        z += e[i];
    }
    for (double& v : e) v /= z;
    return e;
}

}  // namespace

void test_softmax_matches_f64_reference() {
    aiter_ref::Rng rng(0x50F7);
    for (int iter = 0; iter < 200; ++iter) {
        const std::size_t n = 1 + rng.below(256);
        std::vector<float> row(n);
        for (float& v : row) v = rng.f32_sym() * 20.0f;
        const std::vector<float> got = aiter_ref::moe_softmax(row);
        const std::vector<double> want = softmax_f64(row);
        for (std::size_t i = 0; i < n; ++i) {
            CHECK_NEAR(got[i], static_cast<float>(want[i]), 1e-5);
        }
        float sum = 0.0f;
        for (float g : got) sum += g;
        CHECK_NEAR(sum, 1.0, 1e-6);
    }
}

void test_softmax_stable_at_extreme_logits() {
    const std::vector<float> out = aiter_ref::moe_softmax({1e30f, -1e30f, 0.0f});
    CHECK(std::fabs(out[0] - 1.0f) < 1e-7f);
    CHECK(out[1] == 0.0f);
    for (float v : out) CHECK(std::isfinite(v));
}

void test_topk_selects_descending_with_exclusion() {
    const aiter_ref::TopK r = aiter_ref::moe_topk({0.1f, 0.4f, 0.2f, 0.3f}, 3, false, 0, 4);
    const std::vector<std::int32_t> want_ids = {1, 3, 2};
    const std::vector<float> want_values = {0.4f, 0.3f, 0.2f};
    CHECK_VEC_EQ(r.expert_ids, want_ids);
    CHECK_VEC_EQ(r.values, want_values);
}

void test_topk_tie_breaks_to_lower_expert() {
    const aiter_ref::TopK r = aiter_ref::moe_topk({0.3f, 0.3f, 0.3f, 0.1f}, 2, false, 0, 4);
    const std::vector<std::int32_t> want_ids = {0, 1};  // exact ties: lowest index first
    const std::vector<float> want_values = {0.3f, 0.3f};
    CHECK_VEC_EQ(r.expert_ids, want_ids);
    CHECK_VEC_EQ(r.values, want_values);
}

void test_topk_renorm_sums_to_one() {
    const aiter_ref::TopK r = aiter_ref::moe_topk({0.5f, 0.25f, 0.125f, 0.125f}, 2, true, 0, 4);
    float sum = 0.0f;
    for (float v : r.values) sum += v;
    CHECK_NEAR(sum, 1.0, 1e-6);
    const std::vector<std::int32_t> want_ids = {0, 1};
    CHECK_VEC_EQ(r.expert_ids, want_ids);
    // Raw path keeps probabilities untouched.
    const aiter_ref::TopK raw = aiter_ref::moe_topk({0.5f, 0.25f, 0.125f, 0.125f}, 2, false, 0, 4);
    const std::vector<float> want_raw = {0.5f, 0.25f};
    CHECK_VEC_EQ(raw.values, want_raw);
}

void test_topk_renorm_skipped_when_sum_zero() {
    // All-zero probabilities: the kernel skips the renorm division.
    const aiter_ref::TopK r = aiter_ref::moe_topk({0.0f, 0.0f, 0.0f}, 2, true, 0, 3);
    const std::vector<float> want_values = {0.0f, 0.0f};
    const std::vector<std::int32_t> want_ids = {0, 1};  // ties -> ascending
    CHECK_VEC_EQ(r.values, want_values);
    CHECK_VEC_EQ(r.expert_ids, want_ids);
}

void test_topk_k_equals_num_experts_takes_all_ascending_on_ties() {
    const aiter_ref::TopK r = aiter_ref::moe_topk({0.0f, 0.0f, 0.0f, 0.0f}, 4, false, 0, 4);
    const std::vector<std::int32_t> want_ids = {0, 1, 2, 3};
    CHECK_VEC_EQ(r.expert_ids, want_ids);
}

void test_topk_out_of_range_expert_reports_sentinel() {
    const std::vector<float> probs = {0.4f, 0.3f, 0.2f, 0.1f};
    // Local window [1, 3): expert 0 is someone else's. With the pinned
    // exclusion quirk (start_expert > 0, see below), expert 0 is never
    // excluded and wins every round — each time reporting the sentinel
    // num_experts (4), not the window size.
    const aiter_ref::TopK r = aiter_ref::moe_topk(probs, 3, false, 1, 3);
    const std::vector<std::int32_t> want_ids = {4, 4, 4};
    const std::vector<float> want_values = {0.4f, 0.4f, 0.4f};
    CHECK_VEC_EQ(r.expert_ids, want_ids);
    CHECK_VEC_EQ(r.values, want_values);
}

// Pins the upstream EP-path behavior documented in the header: with
// start_expert > 0, stored (local) ids never equal the global index
// compared against, so nothing is excluded and the same expert can fill
// every slot.
void test_quirk_exclusion_incomplete_for_expert_parallel() {
    // Expert 1 wins round 0 and is stored as LOCAL id 0; the next round
    // compares stored 0 against global expert 1 — never equal — so expert
    // 1 repeats.
    const aiter_ref::TopK r2 = aiter_ref::moe_topk({0.1f, 0.4f, 0.3f, 0.2f}, 2, false, 1, 4);
    const std::vector<std::int32_t> want_ids = {0, 0};  // expert 1 twice
    const std::vector<float> want_values = {0.4f, 0.4f};
    CHECK_VEC_EQ(r2.expert_ids, want_ids);
    CHECK_VEC_EQ(r2.values, want_values);
}

void test_composed_topk_softmax_matches_manual() {
    const std::vector<float> logits = {1.0f, 2.0f, 3.0f, -1.0f};
    const aiter_ref::TopK composed = aiter_ref::topk_softmax(logits, 2, true, 0, 4);
    const std::vector<float> probs = aiter_ref::moe_softmax(logits);
    const aiter_ref::TopK manual = aiter_ref::moe_topk(probs, 2, true, 0, 4);
    CHECK_VEC_EQ(composed.values, manual.values);
    CHECK_VEC_EQ(composed.expert_ids, manual.expert_ids);
}

void test_pipeline_random_rows_end_to_end() {
    aiter_ref::Rng rng(0x7091);
    for (int iter = 0; iter < 100; ++iter) {
        const std::size_t e = 2 + rng.below(30);
        const std::size_t k = 1 + rng.below(e);
        std::vector<float> logits(e);
        for (float& v : logits) v = rng.f32_sym() * 10.0f;
        const aiter_ref::TopK r = aiter_ref::topk_softmax(logits, k, true, 0, e);
        // Strictly non-increasing values.
        for (std::size_t i = 1; i < r.values.size(); ++i) CHECK(r.values[i - 1] >= r.values[i]);
        // Distinct in-range experts.
        std::vector<std::int32_t> sorted_ids = r.expert_ids;
        std::sort(sorted_ids.begin(), sorted_ids.end());
        for (std::size_t i = 0; i < sorted_ids.size(); ++i) {
            CHECK(sorted_ids[i] >= 0 && static_cast<std::size_t>(sorted_ids[i]) < e);
            if (i > 0) CHECK(sorted_ids[i - 1] != sorted_ids[i]);
        }
        // Weights sum to 1.
        float sum = 0.0f;
        for (float v : r.values) sum += v;
        CHECK_NEAR(sum, 1.0, 1e-5);
    }
}

int main() {
    RUN_TEST(test_softmax_matches_f64_reference);
    RUN_TEST(test_softmax_stable_at_extreme_logits);
    RUN_TEST(test_topk_selects_descending_with_exclusion);
    RUN_TEST(test_topk_tie_breaks_to_lower_expert);
    RUN_TEST(test_topk_renorm_sums_to_one);
    RUN_TEST(test_topk_renorm_skipped_when_sum_zero);
    RUN_TEST(test_topk_k_equals_num_experts_takes_all_ascending_on_ties);
    RUN_TEST(test_topk_out_of_range_expert_reports_sentinel);
    RUN_TEST(test_quirk_exclusion_incomplete_for_expert_parallel);
    RUN_TEST(test_composed_topk_softmax_matches_manual);
    RUN_TEST(test_pipeline_random_rows_end_to_end);
    return finish();
}
