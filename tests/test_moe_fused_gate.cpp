// SPDX-License-Identifier: Apache-2.0
// Tests for the moe_fused_gate host reference. Selection is verified against
// an independent sort-based reference (different algorithm, same pinned
// semantics), plus hand-derived cases and the pad-row/shared-expert quirks.
#include "aiter_ref/moe_fused_gate.hpp"
#include "aiter_ref/rng.hpp"
#include "test_util.hpp"

#include <algorithm>
#include <cfloat>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <numeric>
#include <vector>

namespace {

using aiter_ref::FusedGateParams;

float sigmoid_f32(float x) {
    return std::isnan(x) ? 0.0f : 1.0f / (1.0f + std::exp(-x));
}

// Independent reference: same math, selection by sorting instead of the
// iterative tracker/argmax-fold. NaN bias would break std::sort, so bias is
// kept NaN-free in every test (NaN logits are fine: they score 0).
aiter_ref::FusedGate ref_gate(const std::vector<float>& logits, const std::vector<float>& bias,
                              const FusedGateParams& p) {
    const std::size_t ne = bias.size();
    const std::size_t groups = p.num_expert_group;
    const std::size_t vpt = ne / groups;
    const std::size_t topk_excl = p.topk - p.num_fused_shared_experts;
    const std::size_t stride = p.out_stride != 0 ? p.out_stride : p.topk;
    const std::size_t rows = logits.size() / ne;
    aiter_ref::FusedGate out;
    out.weights.assign(rows * stride, 0.0f);
    out.expert_ids.assign(rows * stride, -1);
    std::vector<float> sig(ne), sel(ne);
    for (std::size_t row = 0; row < rows; ++row) {
        const bool pad = p.num_valid_rows && row >= static_cast<std::size_t>(*p.num_valid_rows);
        for (std::size_t e = 0; e < ne; ++e) {
            sig[e] = sigmoid_f32(logits[row * ne + e]);
            sel[e] = sig[e] + bias[e];
        }
        std::vector<float> gs(groups);
        for (std::size_t g = 0; g < groups; ++g) {
            std::vector<float> v(sel.begin() + static_cast<long>(g * vpt),
                                 sel.begin() + static_cast<long>((g + 1) * vpt));
            std::sort(v.begin(), v.end(), [](float a, float b) { return a > b; });
            gs[g] = v[0] + (vpt >= 2 ? v[1] : -FLT_MAX);
        }
        std::vector<std::size_t> order(groups);
        std::iota(order.begin(), order.end(), 0);
        // ArgMin semantics: lower score first, ties to the lower group.
        std::sort(order.begin(), order.end(), [&](std::size_t a, std::size_t b) {
            if (gs[a] != gs[b]) return gs[a] < gs[b];
            return a < b;
        });
        std::vector<char> excluded(groups, 0);
        for (std::size_t k = 0; k < groups - p.topk_group; ++k) excluded[order[k]] = 1;
        std::vector<std::size_t> eligible;
        for (std::size_t e = 0; e < ne; ++e)
            if (!excluded[e / vpt]) eligible.push_back(e);
        // ArgMax semantics: higher value first, ties to the lower expert.
        std::sort(eligible.begin(), eligible.end(), [&](std::size_t a, std::size_t b) {
            if (sel[a] != sel[b]) return sel[a] > sel[b];
            return a < b;
        });
        float sum = 0.0f;
        for (std::size_t k = 0; k < topk_excl; ++k) sum += sig[eligible[k]];
        for (std::size_t k = 0; k < topk_excl; ++k) {
            out.expert_ids[row * stride + k] = pad ? -1 : static_cast<std::int32_t>(eligible[k]);
            out.weights[row * stride + k] = pad ? 0.0f : sig[eligible[k]] / sum;
        }
        if (p.num_fused_shared_experts > 0) {
            std::size_t slot = topk_excl;
            std::size_t off = row % p.num_fused_shared_experts;
            for (std::size_t i = 0; i < p.num_fused_shared_experts; ++i) {
                out.expert_ids[row * stride + slot] = static_cast<std::int32_t>(ne + off);
                out.weights[row * stride + slot] =
                    static_cast<float>(1.0 / p.routed_scaling_factor);
                ++slot;
                ++off;
            }
        }
    }
    return out;
}

void compare_with_ref(const std::vector<float>& logits, const std::vector<float>& bias,
                      const FusedGateParams& p) {
    const auto got = aiter_ref::moe_fused_gate(logits, bias, p);
    const auto want = ref_gate(logits, bias, p);
    CHECK_VEC_EQ(got.expert_ids, want.expert_ids);
    CHECK_EQ(got.weights.size(), want.weights.size());
    for (std::size_t i = 0; i < want.weights.size(); ++i) {
        const bool both_nan = std::isnan(got.weights[i]) && std::isnan(want.weights[i]);
        if (both_nan) {
            CHECK(true);
        } else {
            CHECK_NEAR(got.weights[i], want.weights[i], 1e-6f);
        }
    }
}

std::vector<float> grid_logits(aiter_ref::Rng& rng, std::size_t n) {
    std::vector<float> v(n);
    for (std::size_t i = 0; i < n; ++i) {
        // Two-decimal grid keeps near-ties off the float-vs-sort boundary.
        v[i] = std::floor(rng.f32_sym() * 100.0f) / 100.0f;
    }
    return v;
}

void hand_case_group_selection() {
    // 8 experts, 2 groups of 4, bias 0. Group 1 logits dominate -> group 0
    // excluded; expected routed ids {7, 6} in that order. Logits stay in the
    // non-saturating sigmoid range: f32 saturation (e.g. sigmoid(20) == 1.0f)
    // would turn the top into an exact tie, broken toward the lower id.
    std::vector<float> logits = {0.1f, 0.2f, 0.3f, 0.4f, 2.0f, 2.5f, 3.0f, 3.5f};
    std::vector<float> bias(8, 0.0f);
    FusedGateParams p;
    p.num_expert_group = 2;
    p.topk_group = 1;
    p.topk = 2;
    const auto out = aiter_ref::moe_fused_gate(logits, bias, p);
    CHECK_EQ(out.expert_ids[0], 7);
    CHECK_EQ(out.expert_ids[1], 6);
    const float s7 = sigmoid_f32(3.5f), s6 = sigmoid_f32(3.0f);
    CHECK_NEAR(out.weights[0], s7 / (s7 + s6), 1e-6f);
    CHECK_NEAR(out.weights[1], s6 / (s7 + s6), 1e-6f);
}

void ties_go_to_lower_expert_and_group() {
    // All-equal scores: the ArgMin exclusion removes the LOW group first and
    // the ArgMax selection walks experts 4, 5, 6 with equal 1/3 weights.
    std::vector<float> logits(8, 0.0f);
    std::vector<float> bias(8, 0.0f);
    FusedGateParams p;
    p.num_expert_group = 2;
    p.topk_group = 1;
    p.topk = 3;
    const auto out = aiter_ref::moe_fused_gate(logits, bias, p);
    CHECK_EQ(out.expert_ids[0], 4);
    CHECK_EQ(out.expert_ids[1], 5);
    CHECK_EQ(out.expert_ids[2], 6);
    CHECK_NEAR(out.weights[0], 1.0f / 3.0f, 1e-6f);
    CHECK_NEAR(out.weights[2], 1.0f / 3.0f, 1e-6f);
}

void vpt1_group_score_degenerates() {
    // VPT == 1: the second tracker stays -FLT_MAX, so every group score is
    // -FLT_MAX and both phases fall through to lowest-key ties.
    std::vector<float> logits = {0, 0, 0, 0};
    std::vector<float> bias(4, 0.0f);
    FusedGateParams p;
    p.num_expert_group = 4;
    p.topk_group = 2;
    p.topk = 2;
    const auto out = aiter_ref::moe_fused_gate(logits, bias, p);
    // Groups 0 and 1 excluded (lowest keys); experts 2 and 3 selected.
    CHECK_EQ(out.expert_ids[0], 2);
    CHECK_EQ(out.expert_ids[1], 3);
    compare_with_ref(logits, bias, p);
}

void nan_logit_scores_zero() {
    // NaN logits become score-0 experts: still selectable through bias.
    std::vector<float> logits = {std::nanf(""), std::nanf(""), 5.0f, 5.0f};
    std::vector<float> bias = {100.0f, 0.0f, 0.0f, 0.0f};
    FusedGateParams p;
    p.num_expert_group = 2;
    p.topk_group = 2;
    p.topk = 2;
    const auto out = aiter_ref::moe_fused_gate(logits, bias, p);
    // sel: e0 = 0+100, e1 = 0, e2 = s(5), e3 = s(5). Top-2 = {0, 2}.
    CHECK_EQ(out.expert_ids[0], 0);
    CHECK_EQ(out.expert_ids[1], 2);
    CHECK(std::isfinite(out.weights[0]) && std::isfinite(out.weights[1]));
}

void shared_experts_round_robin() {
    std::vector<float> logits(4 * 8, 0.0f);
    std::vector<float> bias(8, 0.0f);
    FusedGateParams p;
    p.num_expert_group = 2;
    p.topk_group = 1;
    p.topk = 4;
    p.num_fused_shared_experts = 2;
    p.routed_scaling_factor = 2.5;
    const auto out = aiter_ref::moe_fused_gate(logits, bias, p);
    for (int row = 0; row < 4; ++row) {
        const int base = row * 4;
        // Two routed slots (rows are all-equal -> experts 4, 5), then the
        // shared pair num_experts + (row % 2) + i with weight 1/2.5.
        CHECK_EQ(out.expert_ids[base + 2], 8 + (row % 2));
        CHECK_EQ(out.expert_ids[base + 3], 8 + (row % 2) + 1);
        CHECK_NEAR(out.weights[base + 2], 0.4f, 1e-6f);
        CHECK_NEAR(out.weights[base + 3], 0.4f, 1e-6f);
        CHECK_NEAR(out.weights[base + 0] + out.weights[base + 1], 1.0f, 1e-5f);
    }
}

void pad_rows_zero_and_minus_one_but_shared_written() {
    // Pinned upstream behavior: pad rows get -1/0.0 on the routed slots but
    // the shared-expert slots are still fully written (no pad guard there).
    std::vector<float> logits(3 * 8, 1.0f);
    std::vector<float> bias(8, 0.5f);
    std::int32_t valid = 1;
    FusedGateParams p;
    p.num_expert_group = 2;
    p.topk_group = 1;
    p.topk = 3;
    p.num_fused_shared_experts = 1;
    p.routed_scaling_factor = 4.0;
    p.num_valid_rows = &valid;
    const auto out = aiter_ref::moe_fused_gate(logits, bias, p);
    // Row 0: normal.
    CHECK(out.expert_ids[0] >= 0 && out.expert_ids[0] < 8);
    CHECK(std::isfinite(out.weights[0]));
    CHECK_EQ(out.expert_ids[2], 8);  // shared slot, row 0 % 1 = 0
    CHECK_NEAR(out.weights[2], 0.25f, 1e-6f);
    // Rows 1-2: routed -1/0.0, shared slot still num_experts + 0 at 0.25.
    for (int row = 1; row < 3; ++row) {
        CHECK_EQ(out.expert_ids[row * 3 + 0], -1);
        CHECK_EQ(out.expert_ids[row * 3 + 1], -1);
        CHECK_EQ(out.weights[row * 3 + 0], 0.0f);
        CHECK_EQ(out.weights[row * 3 + 1], 0.0f);
        CHECK_EQ(out.expert_ids[row * 3 + 2], 8);
        CHECK_NEAR(out.weights[row * 3 + 2], 0.25f, 1e-6f);
    }
}

void out_stride_padding_stays_prefilled() {
    std::vector<float> logits(2 * 8, 0.5f);
    std::vector<float> bias(8, 0.0f);
    FusedGateParams p;
    p.num_expert_group = 2;
    p.topk_group = 1;
    p.topk = 2;
    p.out_stride = 5;
    const auto out = aiter_ref::moe_fused_gate(logits, bias, p);
    CHECK_EQ(out.expert_ids.size(), 2 * 5);
    for (int row = 0; row < 2; ++row) {
        CHECK_EQ(out.expert_ids[row * 5 + 2], -1);
        CHECK_EQ(out.expert_ids[row * 5 + 3], -1);
        CHECK_EQ(out.weights[row * 5 + 4], 0.0f);
    }
}

void zero_sum_mirrors_unguarded_division() {
    // All-NaN logits -> every sigmoid score 0 -> sum 0 -> 0/0. The port
    // mirrors upstream's missing guard instead of inventing one.
    std::vector<float> logits(8, std::nanf(""));
    std::vector<float> bias(8, 0.0f);
    FusedGateParams p;
    p.num_expert_group = 2;
    p.topk_group = 1;
    p.topk = 2;
    const auto out = aiter_ref::moe_fused_gate(logits, bias, p);
    CHECK(std::isnan(out.weights[0]));
    CHECK(std::isnan(out.weights[1]));
}

void deepseek_v3_config_matches_reference() {
    aiter_ref::Rng rng(0xA17E57);
    const std::size_t ne = 256;
    for (int trial = 0; trial < 20; ++trial) {
        std::vector<float> logits = grid_logits(rng, 8 * ne);
        std::vector<float> bias = grid_logits(rng, ne);
        FusedGateParams p;
        p.num_expert_group = 8;
        p.topk_group = 4;
        p.topk = 8;
        compare_with_ref(logits, bias, p);
    }
}

void random_configs_match_reference() {
    aiter_ref::Rng rng(0x50F7);
    const struct C {
        std::size_t ne, groups, topk_group, topk, nfs;
        double rsf;
    } cases[] = {
        {256, 8, 4, 8, 2, 2.5}, {128, 4, 2, 8, 1, 1.0}, {96, 8, 3, 6, 0, 1.0},
        {64, 2, 1, 4, 0, 1.0},  {16, 16, 8, 4, 0, 1.0}, {32, 8, 8, 6, 0, 1.0},
    };
    for (const auto& c : cases) {
        for (int trial = 0; trial < 8; ++trial) {
            std::vector<float> logits = grid_logits(rng, 3 * c.ne);
            std::vector<float> bias = grid_logits(rng, c.ne);
            FusedGateParams p;
            p.num_expert_group = c.groups;
            p.topk_group = c.topk_group;
            p.topk = c.topk;
            p.num_fused_shared_experts = c.nfs;
            p.routed_scaling_factor = c.rsf;
            compare_with_ref(logits, bias, p);
        }
    }
}

}  // namespace

int main() {
    RUN_TEST(hand_case_group_selection);
    RUN_TEST(ties_go_to_lower_expert_and_group);
    RUN_TEST(vpt1_group_score_degenerates);
    RUN_TEST(nan_logit_scores_zero);
    RUN_TEST(shared_experts_round_robin);
    RUN_TEST(pad_rows_zero_and_minus_one_but_shared_written);
    RUN_TEST(out_stride_padding_stays_prefilled);
    RUN_TEST(zero_sum_mirrors_unguarded_division);
    RUN_TEST(deepseek_v3_config_matches_reference);
    RUN_TEST(random_configs_match_reference);
    return finish();
}
