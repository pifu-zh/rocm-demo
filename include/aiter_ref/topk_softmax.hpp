// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2025, Advanced Micro Devices, Inc. All rights reserved.
//
// Port of the MoE routing front-end moeSoftmax + moeTopK from ROCm/aiter
// (csrc/kernels/topk_softmax_kernels.cu @ 1eab5ae12, MIT; the ArgMax
// tie-break comes from csrc/include/hip_reduce.h). See LICENSES/MIT.txt.
//
// Semantics pinned here:
// - Softmax is numerically stable (max-subtract), computed in float.
// - Top-k is iterative argmax: k rounds, each excluding prior winners.
//   Exact ties go to the LOWER expert index.
// - With need_renorm, selected values are divided by their float sum
//   (accumulated in selection order); skipped when the sum is exactly 0.0.
// - Each selected expert is reported as expert - start_expert when it lies
//   in [start_expert, end_expert), else the sentinel num_experts.
//
// Pinned upstream quirk (expert-parallel path of THIS kernel variant):
// later rounds exclude an expert only if its stored id equals the global
// index being compared. Stored ids are local (expert - start_expert) or the
// sentinel, so whenever start_expert > 0 no comparison can match and the
// same expert can be selected repeatedly. Faithful to the source at the
// pinned commit; other variants in the same file were not checked.
#ifndef ROCM_DEMO_AITER_REF_TOPK_SOFTMAX_HPP
#define ROCM_DEMO_AITER_REF_TOPK_SOFTMAX_HPP

#include <cstddef>
#include <cstdint>
#include <vector>

namespace aiter_ref {

// Row-wise stable softmax in float, mirroring moeSoftmax.
std::vector<float> moe_softmax(const std::vector<float>& input);

struct TopK {
    // Selected probabilities (softmax values, optionally renormalized).
    std::vector<float> values;
    // Per-slot stored ids: expert - start_expert, or the sentinel num_experts.
    std::vector<std::int32_t> expert_ids;
};

// Iterative-argmax top-k over softmax probabilities, mirroring moeTopK for
// one active row. k must be in [1, num_experts]; start_expert <= end_expert
// <= num_experts.
TopK moe_topk(const std::vector<float>& probs, std::size_t k, bool need_renorm,
              std::size_t start_expert, std::size_t end_expert);

// Convenience composition: logits -> softmax -> top-k.
TopK topk_softmax(const std::vector<float>& logits, std::size_t k, bool need_renorm,
                  std::size_t start_expert, std::size_t end_expert);

}  // namespace aiter_ref

#endif  // ROCM_DEMO_AITER_REF_TOPK_SOFTMAX_HPP
