// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2026, Advanced Micro Devices, Inc. All rights reserved.
//
// Port of the sampling family from ROCm/aiter
// (csrc/kernels/sample_kernels.cu @ 1eab5ae12, MIT) plus a bit-exact host
// port of the hiprand/rocrand Philox4x32-10 engine the kernels draw from
// (rocrand_device::philox4x32_10_engine, MIT © AMD / D. E. Shaw Research).
// See LICENSES/MIT.txt.
//
// Designs pinned here:
// - Gumbel/exponential-race sampling: winner = argmax_i p_i / (u_i + eps)
//   with u_i ~ Exp(lambd). The kernel computes it as an online softmax
//   (per-thread running max with rescale) followed by a global rescale by
//   exp(thread_max - global_max) [/ sum]; the thread-local max cancels, so
//   the selection is argmax softmax_i/(u_i+eps) regardless of NeedSum.
// - Decoupled noise ("outer exponential"): the exponential noise is a plain
//   tensor, so the sampling kernel is a deterministic function of
//   (logits, noise) — testable without RNG. `exponential_noise` regenerates
//   that tensor from the same Philox schedule the in-kernel path uses
//   (same engine init, one uniform4 draw per 4-wide slot per thread), so
//   random_sample and random_sample_outer_exponential pick IDENTICAL tokens
//   when fed noise from the same (seed, offset). Verified by a test.
// - Philox stream contract: per row m, thread t (block 1024 lanes, 4-wide
//   vectors) initializes hiprand_init(seed, m*1024+t, offset) and draws one
//   uniform4 per slot base = t*4 + w*4096 < row_len. The Python wrapper
//   advances the shared torch generator offset by
//   philox_counter_offset(numel, rows) per launch.
//
// Pinned quirks:
// - exponential_transform clamps u >= 1 - 2^-24 (incl. exactly 1.0f, which
//   the uniform transform CAN produce) to the log value 2^-24, and returns
//   c * that = -2^-24/lambd — sign-flipped vs the ideal -log(u) ≈ +2^-24.
//   Such a candidate divides by a tiny negative number and can never win
//   the argmax (PyTorch's transform would make it nearly always win).
// - Greedy argmax uses a -INFINITY sentinel (raw logits can reach -FLT_MAX):
//   an all--inf row returns token 0. NaN logits never win; an all-NaN row
//   returns 0. Sampling keeps -FLT_MAX as the internal sentinel (its
//   candidates are >= 0 and the running-max rescale would turn -inf into
//   NaN); NaN candidates never win, all-NaN rows return 0.
// - Cross-thread reductions fold in ascending thread order on the host; the
//   device tree order differs only in final-ulp rounding of the shared
//   max/sum, not in selection (except adversarial NaN-vs-NaN ties).
// - Rows are pinned contiguous (row_stride == row_len); upstream also
//   supports strided rows, orthogonal to the math.
#ifndef ROCM_DEMO_AITER_REF_SAMPLE_HPP
#define ROCM_DEMO_AITER_REF_SAMPLE_HPP

#include <array>
#include <cstddef>
#include <cstdint>
#include <vector>

namespace aiter_ref {

// Bit-exact host port of rocrand_device::philox4x32_10_engine (the engine
// behind hiprand_init / hiprand / hiprand4 / hiprand_uniform4).
class Philox4x32_10 {
public:
    Philox4x32_10(std::uint64_t seed, std::uint64_t subsequence, std::uint64_t offset);

    // Single 32-bit output (hiprand()).
    std::uint32_t next();
    // Four outputs at once (hiprand4()); honours the substate interleave
    // left by prior next() calls.
    std::array<std::uint32_t, 4> next4();
    // hiprand_uniform4(): next4() through the (0,1] uniform transform.
    std::array<float, 4> uniform4();

private:
    void discard_state();
    static std::array<std::uint32_t, 4> ten_rounds(const std::array<std::uint32_t, 4>& counter,
                                                   const std::array<std::uint32_t, 2>& key);
    std::array<std::uint32_t, 4> counter_;
    std::array<std::uint32_t, 4> result_;
    std::array<std::uint32_t, 2> key_;
    unsigned substate_;
};

// rocrand uniform transform of one raw word: 2^-33 + v * 2^-32 in (0,1]
// (the constant is the decimal literal 2.3283064e-10f, not exact 2^-32 —
// pinned as-is, both sides use the same literal).
float philox_uniform(std::uint32_t v);

// aiter exponential_func_impl: Exp(mean=lambd) via -log(u)/lambd with the
// u >= 1-2^-24 clamp (see header comment for the sign-flip quirk).
float exponential_transform(float u, float lambd);

// Python-side stream advance: ((numel-1) / (1024*rows*4) + 1) * 4, the
// per-launch offset increment of the shared torch generator.
std::uint64_t philox_counter_offset(std::uint64_t numel, std::uint64_t num_rows);

// Greedy argmax over raw logits, [rows, row_len]. Ties to the lower index;
// all--inf and all-NaN rows return 0.
std::vector<std::int32_t> greedy_sample(const std::vector<float>& logits, std::size_t num_rows,
                                        std::size_t row_len);

// In-kernel Philox sampling: one uniform4 per slot, exponential transform,
// candidate exp(x*inv_t - max)/u. lambd is the exponential mean (default 1).
std::vector<std::int32_t> random_sample(const std::vector<float>& logits, std::size_t num_rows,
                                        std::size_t row_len,
                                        const std::vector<float>& temperatures, float lambd,
                                        std::uint64_t philox_seed, std::uint64_t philox_offset,
                                        float eps = 1e-10f);

// Noise-decoupled sampling: exponentials is [rows, row_len] of already
// transformed noise; candidate exp(x*inv_t - max)/(noise + eps).
std::vector<std::int32_t> random_sample_outer_exponential(
    const std::vector<float>& logits, std::size_t num_rows, std::size_t row_len,
    const std::vector<float>& exponentials, const std::vector<float>& temperatures,
    float eps = 1e-10f);

// Per-row dispatch: temperature == 0.0f takes the greedy argmax path,
// otherwise the sampling path (both pinned variants).
std::vector<std::int32_t> mixed_sample(const std::vector<float>& logits, std::size_t num_rows,
                                       std::size_t row_len,
                                       const std::vector<float>& temperatures, float lambd,
                                       std::uint64_t philox_seed, std::uint64_t philox_offset,
                                       float eps = 1e-10f);
std::vector<std::int32_t> mixed_sample_outer_exponential(
    const std::vector<float>& logits, std::size_t num_rows, std::size_t row_len,
    const std::vector<float>& exponentials, const std::vector<float>& temperatures,
    float eps = 1e-10f);

// The noise generator behind the outer variant: [rows, row_len] of
// exponential_transform(uniform) + eps from the same Philox schedule the
// in-kernel sampler uses.
std::vector<float> exponential_noise(std::size_t num_rows, std::size_t row_len, float lambd,
                                     std::uint64_t philox_seed, std::uint64_t philox_offset,
                                     float eps = 1e-10f);

}  // namespace aiter_ref

#endif  // ROCM_DEMO_AITER_REF_SAMPLE_HPP
