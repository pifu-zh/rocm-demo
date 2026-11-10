// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2025, Advanced Micro Devices, Inc. All rights reserved.
// See aiter_ref/topk_softmax.hpp for provenance and semantics.

#include "aiter_ref/topk_softmax.hpp"

#include <algorithm>
#include <cassert>
#include <cmath>
#include <limits>

namespace aiter_ref {

std::vector<float> moe_softmax(const std::vector<float>& input) {
    float max_elem = -std::numeric_limits<float>::infinity();
    for (float v : input) max_elem = std::max(max_elem, v);

    std::vector<float> out(input.size());
    float z = 0.0f;
    for (std::size_t i = 0; i < input.size(); ++i) {
        out[i] = std::exp(input[i] - max_elem);
        z += out[i];
    }
    const float inv = 1.0f / z;
    for (float& v : out) v *= inv;
    return out;
}

TopK moe_topk(const std::vector<float>& probs, std::size_t k, bool need_renorm,
              std::size_t start_expert, std::size_t end_expert) {
    const std::size_t num_experts = probs.size();
    assert(k >= 1 && k <= num_experts);
    assert(start_expert <= end_expert && end_expert <= num_experts);

    TopK out;
    out.values.reserve(k);
    out.expert_ids.reserve(k);
    // What `indices` holds in the kernel: local ids or the sentinel.
    std::vector<std::int32_t> stored;
    stored.reserve(k);
    float renorm_sum = 0.0f;

    for (std::size_t round = 0; round < k; ++round) {
        // thread_kvp init: value = -1.0 ("OK because inputs are probabilities").
        std::int32_t best_key = -1;
        float best_value = -1.0f;
        for (std::size_t expert = 0; expert < num_experts; ++expert) {
            // Exclusion exactly as the kernel does it: compare the expert's
            // GLOBAL index against each STORED prior id (local or sentinel).
            const std::int32_t gid = static_cast<std::int32_t>(expert);
            if (std::find(stored.begin(), stored.end(), gid) != stored.end()) continue;
            // ArgMax: higher value wins; scanning ascending, strict > keeps
            // the lowest index on exact ties.
            if (probs[expert] > best_value) {
                best_key = gid;
                best_value = probs[expert];
            }
        }
        assert(best_key >= 0);
        const std::size_t best = static_cast<std::size_t>(best_key);
        const bool node_uses_expert = best >= start_expert && best < end_expert;
        stored.push_back(node_uses_expert ? static_cast<std::int32_t>(best - start_expert)
                                          : static_cast<std::int32_t>(num_experts));
        out.values.push_back(best_value);
        out.expert_ids.push_back(stored.back());
        if (need_renorm) renorm_sum += best_value;
    }

    if (need_renorm && renorm_sum != 0.0f) {
        const float inv = 1.0f / renorm_sum;
        for (float& v : out.values) v *= inv;
    }
    return out;
}

TopK topk_softmax(const std::vector<float>& logits, std::size_t k, bool need_renorm,
                  std::size_t start_expert, std::size_t end_expert) {
    return moe_topk(moe_softmax(logits), k, need_renorm, start_expert, end_expert);
}

}  // namespace aiter_ref
