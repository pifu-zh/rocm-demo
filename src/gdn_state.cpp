// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2026, Advanced Micro Devices, Inc. All rights reserved.
// Host reference for the chunked gated delta rule fwd_h recurrence; see the
// header for the pinned semantics and scope.
#include "aiter_ref/gdn_state.hpp"

#include <algorithm>
#include <cassert>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <vector>

namespace aiter_ref {

std::uint16_t f32_to_bf16_rne(float f) {
    std::uint32_t x;
    std::memcpy(&x, &f, 4);
    const std::uint32_t lsb = (x >> 16) & 1;
    const std::uint32_t rounded = (x + 0x7fffu + lsb) >> 16;
    return static_cast<std::uint16_t>(rounded);
}

float bf16_to_f32(std::uint16_t bits) {
    const std::uint32_t x = static_cast<std::uint32_t>(bits) << 16;
    float f;
    std::memcpy(&f, &x, 4);
    return f;
}

namespace {

inline float gated_exp(float x, bool use_exp2) {
    return use_exp2 ? exp2f(x * 1.4426950408889634f) : expf(x);
}

}  // namespace

GdnOutputs gdn_fwd_h(const GdnInputs& in, std::size_t num_chunks, bool save_new_value) {
    assert(in.k.size() == in.w.size());
    assert(in.u.size() == in.k.size() / kGdnK * kGdnV);
    assert(in.g.size() * kGdnK == in.k.size());
    const std::size_t T = in.k.size() / kGdnK;
    assert(num_chunks > 0 && T > 0 && T <= num_chunks * kGdnBT);

    std::vector<float> H(kGdnK * kGdnV, 0.0f);
    if (in.initial_state.size() == kGdnK * kGdnV) {
        H = in.initial_state;
    }

    GdnOutputs out;
    out.snapshots.reserve(num_chunks);
    out.final_state.assign(kGdnK * kGdnV, 0.0f);
    if (save_new_value) out.v_new.assign(T * kGdnV, 0);

    std::vector<float> corr(kGdnBT * kGdnV);              // [BT, V]
    std::vector<std::uint16_t> gated(kGdnBT * kGdnV);     // [BT, V] bf16

    for (std::size_t c = 0; c < num_chunks; ++c) {
        const std::size_t t0 = c * kGdnBT;
        const std::size_t bt = std::min(kGdnBT, T - t0);
        assert(bt > 0);

        // 1. Snapshot: state entering the chunk, bf16-rounded (the kernel
        // stores and re-reads the snapshot in bf16).
        std::vector<float> snap(kGdnK * kGdnV);
        for (std::size_t i = 0; i < kGdnK * kGdnV; ++i) {
            snap[i] = bf16_to_f32(f32_to_bf16_rne(H[i]));
        }
        out.snapshots.push_back(std::move(snap));
        const std::vector<float>& Hb = out.snapshots.back();

        // 2. corr[r, v] = sum_k W[t0+r, k] * Hb[k, v], f32 accumulation.
        for (std::size_t r = 0; r < bt; ++r) {
            const std::uint16_t* w_row = in.w.data() + (t0 + r) * kGdnK;
            for (std::size_t v = 0; v < kGdnV; ++v) {
                float acc = 0.0f;
                for (std::size_t k = 0; k < kGdnK; ++k) {
                    acc += bf16_to_f32(w_row[k]) * Hb[k * kGdnV + v];
                }
                corr[r * kGdnV + v] = acc;
            }
        }

        // 3. gated[r, v] = bf16((U[t0+r, v] - corr[r, v]) * gscale[r]).
        const float g_last = in.g[t0 + bt - 1];
        for (std::size_t r = 0; r < bt; ++r) {
            const float gscale = gated_exp(g_last - in.g[t0 + r], in.use_exp2);
            const std::uint16_t* u_row = in.u.data() + (t0 + r) * kGdnV;
            for (std::size_t v = 0; v < kGdnV; ++v) {
                const float value = bf16_to_f32(u_row[v]) - corr[r * kGdnV + v];
                if (save_new_value) {
                    out.v_new[(t0 + r) * kGdnV + v] = f32_to_bf16_rne(value);
                }
                gated[r * kGdnV + v] = f32_to_bf16_rne(value * gscale);
            }
        }

        // 4a. Chunk decay applies to H BEFORE the delta adds (the kernel
        // decays h_reg, then accumulates the matmul result).
        const float decay = gated_exp(g_last, in.use_exp2);
        for (std::size_t i = 0; i < kGdnK * kGdnV; ++i) H[i] *= decay;

        // 4b. H[k, v] += sum_r K[t0+r, k] * gated[r, v]. The kernel batches
        // the whole chunk into one matmul; this port adds token rows in
        // order (f32 addition order differs, bounded in the tests).
        for (std::size_t r = 0; r < bt; ++r) {
            const std::uint16_t* k_row = in.k.data() + (t0 + r) * kGdnK;
            const std::uint16_t* g_row = gated.data() + r * kGdnV;
            for (std::size_t k = 0; k < kGdnK; ++k) {
                const float kv = bf16_to_f32(k_row[k]);
                float* hrow = H.data() + k * kGdnV;
                for (std::size_t v = 0; v < kGdnV; ++v) {
                    hrow[v] += kv * bf16_to_f32(g_row[v]);
                }
            }
        }
    }

    out.final_state = H;
    return out;
}

}  // namespace aiter_ref
