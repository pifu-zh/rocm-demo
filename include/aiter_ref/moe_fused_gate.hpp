// SPDX-License-Identifier: Apache-2.0
// Copyright (C) 2024-2026, Advanced Micro Devices, Inc. All rights reserved.
// Adapted from sglang sgl-kernel csrc/moe/moe_fused_gate.cu.
//
// Algorithm port of aiter::moe_fused_gate_impl from ROCm/aiter
// (csrc/kernels/moe_fused_gate.cu @ 1eab5ae12, Apache-2.0), reduced to a
// deterministic single-threaded host reference. The ArgMin/ArgMax tie-break
// comes from csrc/include/hip_reduce.h (MIT): both compare by value first
// and break exact ties toward the LOWER key, which makes the device DPP
// reduction tree order-independent — a sequential fold over the groups in
// ascending order is result-identical.
//
// DeepSeek-style grouped biased routing, per row (upstream one thread per
// expert group, THREADS_PER_ROW = num_expert_group, VPT = num_experts /
// num_expert_group experts per thread):
// 1. score = sigmoid(logit), NaN logits score 0; selection value = score +
//    bias (the sigmoid score itself is what ends up in the weights).
// 2. Group score = sum of the group's top-2 bias-added values (fixed top-2,
//    upstream QQ note; with VPT == 1 the second value stays -FLT_MAX so the
//    group score degenerates to top1 + (-FLT_MAX)).
// 3. Group exclusion: num_expert_group - topk_group rounds of ArgMin over
//    group scores (cleared groups hold FLT_MAX); the losing group's
//    bias_chunk[0] is set to FLT_MAX as a sentinel that also disables that
//    thread's local scan in step 4.
// 4. Top-k: topk - num_fused_shared_experts rounds of ArgMax over the
//    per-thread local argmax (cleared threads contribute -FLT_MAX with
//    their first-expert key). The owner records the SIGMOID score, clears
//    the winner element to -FLT_MAX, writes the id (pad rows write -1).
// 5. Fused shared experts fill slots [topk - num_fused_shared_experts,
//    topk) round-robin: id num_experts + (row % n + i), weight
//    1/routed_scaling_factor — written for pad rows too (no pad guard
//    upstream), unlike the routed slots.
// 6. Routed weights = score / sum(scores) (0.0 for pad rows). The sum is
//    NOT guarded against 0 upstream (only an all-NaN row can produce it);
//    the port mirrors that (0/0 -> NaN) rather than inventing a guard.
//
// Domain (mirrors upstream launch checks): num_experts % num_expert_group
// == 0; VPT <= 32; num_expert_group in {1,2,4,8,16,32} (the device reduce
// tree exists only for these); 1 <= topk_group <= num_expert_group. The
// port additionally rejects topk < num_fused_shared_experts (upstream
// would write before the row start; unspecified corrupt behavior).
// Inputs are f32: upstream casts bf16/fp16/fp32 to f32 before the sigmoid,
// so the f32 view is the common tail of all three dtype paths.
#ifndef ROCM_DEMO_AITER_REF_MOE_FUSED_GATE_HPP
#define ROCM_DEMO_AITER_REF_MOE_FUSED_GATE_HPP

#include <cstddef>
#include <cstdint>
#include <vector>

namespace aiter_ref {

struct FusedGateParams {
    // Number of expert groups; num_experts must divide evenly. Power of two.
    std::size_t num_expert_group;
    // Groups kept by the exclusion phase (step 3).
    std::size_t topk_group;
    // Total selected slots per row: routed + num_fused_shared_experts.
    std::size_t topk;
    // Shared experts appended after the routed slots (step 5).
    std::size_t num_fused_shared_experts = 0;
    // Shared-expert weight = 1/routed_scaling_factor (sglang contract).
    double routed_scaling_factor = 1.0;
    // Row stride of both outputs; 0 derives to topk.
    std::size_t out_stride = 0;
    // Optional number of valid rows; rows >= *num_valid_rows are pad rows
    // (routed ids -1, routed weights 0, shared slots still written).
    const std::int32_t* num_valid_rows = nullptr;
};

struct FusedGate {
    // Weights, [num_rows * out_stride]: routed slots renormalized sigmoid
    // scores, shared slots 1/routed_scaling_factor.
    std::vector<float> weights;
    // Ids, [num_rows * out_stride]: routed expert ids (pad rows -1), shared
    // slots num_experts + (row % n + i).
    std::vector<std::int32_t> expert_ids;
};

// Grouped biased MoE routing (moe_fused_gate). logits is row-major
// [num_rows, num_experts] with contiguous rows (upstream input_stride(1)==1
// check); bias is [num_experts]. Both must be non-empty.
FusedGate moe_fused_gate(const std::vector<float>& logits, const std::vector<float>& bias,
                         const FusedGateParams& params);

}  // namespace aiter_ref

#endif  // ROCM_DEMO_AITER_REF_MOE_FUSED_GATE_HPP
