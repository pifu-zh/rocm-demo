// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2026, Advanced Micro Devices, Inc. All rights reserved.
//
// Port of the inter-chunk state recurrence of aiter's chunked gated delta
// rule forward (csrc/kernels/chunk_gated_delta_rule_fwd_h.cu @ 1eab5ae12,
// MIT; the FLA-style GDN linear-attention "fwd_h" kernel), reduced from the
// CDNA MFMA-tiled device code to its deterministic host semantics. See
// LICENSES/MIT.txt.
//
// Fixed shape constants of the upstream kernel: K_DIM = V_DIM = 128,
// chunk length BT = 64. Per head, per sequence, state H [K, V] (f32):
//
//   for each chunk c over tokens [t0, t0+bt):
//     1. snapshot[c]      = bf16(H)                    // state ENTERING the chunk
//     2. corr[r, v]       = sum_k bf16(W[t0+r, k]) * bf16(H)[k, v]
//                           // W matmul reads the bf16-rounded snapshot
//     3. g_last           = g[t0+bt-1]                 // last VALID token
//        gscale[r]        = gated_exp(g_last - g[t0+r]) for r < bt, else 0
//        vnew[r, v]       = bf16(U[t0+r, v] - corr[r, v])          // optional output
//        gated[r, v]      = bf16(vnew * gscale[r])
//     4. H[k, v]          = H[k, v] * gated_exp(g_last)            // chunk decay
//        H[k, v]         += sum_r bf16(K[t0+r, k]) * gated[r, v]  // delta update
//
// gated_exp(x) = exp(x), or exp2(x * log2e) with use_exp2 (the two paths
// differ in ulps only). All matmul operands are bf16 (W/K/U are bf16
// tensors; the snapshot is stored and re-read as bf16), accumulation is
// f32. With decay 1 and W == K, U == V the recurrence is the textbook
// delta rule S += k (v - k^T S) per token — the chunked form and a
// sequential per-token loop agree bit-exactly on bf16-exact integer inputs
// (tested).
//
// Scope pinned here: single sequence, contiguous [T, K]/[T, V] layouts,
// scalar per-token g (the per-k-channel gk decay, g_head_major layout,
// varlen cu_seqlens/chunk_offsets, initial_state_indices indirection and
// the bf16-state variants are not ported). H starts from zeros or the
// given initial state; the final state is returned in f32, snapshots as
// bf16-rounded values.
#ifndef ROCM_DEMO_AITER_REF_GDN_STATE_HPP
#define ROCM_DEMO_AITER_REF_GDN_STATE_HPP

#include <cstddef>
#include <cstdint>
#include <vector>

namespace aiter_ref {

constexpr std::size_t kGdnK = 128;
constexpr std::size_t kGdnV = 128;
constexpr std::size_t kGdnBT = 64;

// f32 -> bf16 with round-to-nearest-even (the device conversion), and back.
std::uint16_t f32_to_bf16_rne(float f);
float bf16_to_f32(std::uint16_t bits);

struct GdnInputs {
    // bf16 bit patterns, [T, K] / [T, K] / [T, V], T = num_chunks * BT
    // (a partial tail chunk is allowed: T need not be a multiple of BT).
    std::vector<std::uint16_t> k;
    std::vector<std::uint16_t> w;
    std::vector<std::uint16_t> u;
    std::vector<float> g;             // [T] per-token log decay
    std::vector<float> initial_state; // [K, V] f32, may be empty (zeros)
    bool use_exp2 = false;            // gated_exp via exp2(x*log2e)
};

struct GdnOutputs {
    // One bf16-rounded [K, V] snapshot per chunk (state entering it).
    std::vector<std::vector<float>> snapshots;
    std::vector<float> final_state;  // [K, V] f32
    std::vector<std::uint16_t> v_new;  // bf16 bits [T, V]; empty if not saved
};

GdnOutputs gdn_fwd_h(const GdnInputs& in, std::size_t num_chunks, bool save_new_value);

}  // namespace aiter_ref

#endif  // ROCM_DEMO_AITER_REF_GDN_STATE_HPP
