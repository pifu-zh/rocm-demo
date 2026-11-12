// SPDX-License-Identifier: Apache-2.0
// Copyright (C) 2024-2026, Advanced Micro Devices, Inc. All rights reserved.
// Host reference for aiter::moe_fused_gate_impl, see the header for the
// pinned semantics and domain.
#include "aiter_ref/moe_fused_gate.hpp"

#include <cassert>
#include <cfloat>
#include <cmath>
#include <cstddef>

namespace aiter_ref {

namespace {

constexpr float kClearGroup = FLT_MAX;      // exclusion sentinel (bias_chunk[0])
constexpr float kClearedVal = -FLT_MAX;     // cleared thread's reduce value
constexpr float kNegInfVal  = -FLT_MAX;     // initial max trackers

// Strict-is-better fold for aiter::ArgMax (higher value, ties to lower key).
bool argmax_better(float v, std::int32_t k, float bv, std::int32_t bk) {
    return v > bv || (v == bv && k < bk);
}

// Strict-is-better fold for aiter::ArgMin (lower value, ties to lower key).
bool argmin_better(float v, std::int32_t k, float bv, std::int32_t bk) {
    return v < bv || (v == bv && k < bk);
}

}  // namespace

FusedGate moe_fused_gate(const std::vector<float>& logits, const std::vector<float>& bias,
                         const FusedGateParams& params) {
    const std::size_t num_experts = bias.size();
    assert(num_experts > 0);
    assert(params.num_expert_group >= 1 && logits.size() % num_experts == 0);
    assert(num_experts % params.num_expert_group == 0);
    const std::size_t groups = params.num_expert_group;
    const std::size_t vpt    = num_experts / groups;
    assert(vpt >= 1 && vpt <= 32);
    // The device reduction tree only exists for these widths.
    assert(groups == 1 || groups == 2 || groups == 4 || groups == 8 || groups == 16 ||
           groups == 32);
    assert(params.topk_group >= 1 && params.topk_group <= groups);
    assert(params.topk >= params.num_fused_shared_experts);
    const std::size_t num_rows      = logits.size() / num_experts;
    const std::size_t topk_excl     = params.topk - params.num_fused_shared_experts;
    const std::size_t out_stride    = params.out_stride != 0 ? params.out_stride : params.topk;
    const std::int32_t valid_rows   = params.num_valid_rows ? *params.num_valid_rows : -1;

    FusedGate out;
    out.weights.assign(num_rows * out_stride, 0.0f);
    out.expert_ids.assign(num_rows * out_stride, -1);

    std::vector<float> scores(topk_excl, 0.0f);
    // Selection values (sigmoid + bias) and sigmoid scores, per expert.
    std::vector<float> sel(num_experts);
    std::vector<float> sig(num_experts);

    for (std::size_t row = 0; row < num_rows; ++row) {
        const bool pad = params.num_valid_rows != nullptr &&
                         static_cast<std::int32_t>(row) >= valid_rows;
        const float* row_logits = logits.data() + row * num_experts;

        // Sigmoid (NaN -> 0) + bias.
        for (std::size_t e = 0; e < num_experts; ++e) {
            const float x = row_logits[e];
            const float s = std::isnan(x) ? 0.0f : 1.0f / (1.0f + std::exp(-x));
            sig[e] = s;
            sel[e] = s + bias[e];
        }

        // Per-group score: sum of the group's top-2 selection values
        // (exact upstream tracker loop, both trackers start at -FLT_MAX).
        std::vector<float> group_score(groups, 0.0f);
        for (std::size_t g = 0; g < groups; ++g) {
            float max_val        = kNegInfVal;
            float max_val_second = kNegInfVal;
            for (std::size_t ii = 0; ii < vpt; ++ii) {
                const float val = sel[g * vpt + ii];
                if (val > max_val) {
                    max_val_second = max_val;
                    max_val        = val;
                } else if (val > max_val_second) {
                    max_val_second = val;
                }
            }
            group_score[g] = max_val + max_val_second;
        }

        // Exclude groups: groups - topk_group ArgMin rounds; the loser's
        // element 0 becomes the FLT_MAX sentinel that also silences its
        // local scan in the top-k phase.
        std::vector<char> excluded(groups, 0);
        for (std::size_t k = 0; k < groups - params.topk_group; ++k) {
            std::size_t worst = groups;
            for (std::size_t g = 0; g < groups; ++g) {
                const float v  = excluded[g] ? kClearGroup : group_score[g];
                const auto key = static_cast<std::int32_t>(g * vpt);
                if (worst == groups ||
                    argmin_better(v, key, excluded[worst] ? kClearGroup : group_score[worst],
                                  static_cast<std::int32_t>(worst * vpt))) {
                    worst = g;
                }
            }
            excluded[worst]   = 1;
            group_score[worst] = kClearGroup;
            sel[worst * vpt]   = kClearGroup;
        }

        // Top-k routed slots: per-thread local argmax with the sentinel
        // branch, then ArgMax across groups (ties to the lower expert id).
        float output_sum = 0.0f;
        for (std::size_t k = 0; k < topk_excl; ++k) {
            float best_val    = kClearedVal;
            std::int32_t best_key = -1;
            for (std::size_t g = 0; g < groups; ++g) {
                float local_val = sel[g * vpt];
                std::int32_t local_key;
                if (local_val == kClearGroup) {
                    local_val = kClearedVal;  // cleared thread contributes -FLT_MAX
                    local_key = static_cast<std::int32_t>(g * vpt);
                } else {
                    local_key = static_cast<std::int32_t>(g * vpt);
                    for (std::size_t ii = 1; ii < vpt; ++ii) {
                        const float val = sel[g * vpt + ii];
                        if (val > local_val) {
                            local_val = val;
                            local_key = static_cast<std::int32_t>(g * vpt + ii);
                        }
                    }
                }
                if (g == 0 || argmax_better(local_val, local_key, best_val, best_key)) {
                    best_val = local_val;
                    best_key = local_key;
                }
            }
            assert(best_key >= 0);
            const std::size_t expert = static_cast<std::size_t>(best_key);
            scores[k] = sig[expert];
            sel[expert] = kClearedVal;  // clear the winner element
            out.expert_ids[row * out_stride + k] = pad ? -1 : best_key;
            output_sum += scores[k];
        }

        // Fused shared experts, round-robin by row; no pad guard upstream.
        if (params.num_fused_shared_experts > 0) {
            std::size_t slot = topk_excl;
            std::size_t expert_offset = row % params.num_fused_shared_experts;
            for (std::size_t i = 0; i < params.num_fused_shared_experts; ++i) {
                out.expert_ids[row * out_stride + slot] =
                    static_cast<std::int32_t>(num_experts + expert_offset);
                out.weights[row * out_stride + slot] =
                    static_cast<float>(1.0 / params.routed_scaling_factor);
                ++slot;
                ++expert_offset;
            }
        }

        // Routed weights: renormalized sigmoid scores (0 for pad rows; the
        // zero-sum case is not guarded upstream and is mirrored here).
        for (std::size_t ii = 0; ii < topk_excl; ++ii) {
            out.weights[row * out_stride + ii] = pad ? 0.0f : scores[ii] / output_sum;
        }
    }
    return out;
}

}  // namespace aiter_ref
