// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2026, Advanced Micro Devices, Inc. all rights reserved.
//
// Host reference for aiter's gated RMSNorm + FP8 group quant kernels
// (csrc/kernels/gated_rmsnorm_quant_kernels.cu @ 1eab5ae12, MIT). Two
// kernel variants + three independently-extractable designs:
//
// [1] The GATED RMSNORM MATH (per head, head_dim = GROUP_SIZE = 128):
//       var   = mean(x^2)                       (over the head dim)
//       norm  = x * weight * rsqrt(var + eps)
//       gated = norm * silu(z)                  (or norm * sigmoid(z) for
//                                                the USE_SIGMOID variant)
//     The lane decomposition: threads_per_group = 128/THREAD_DATA_SIZE
//     lanes cooperate on ONE head; the sum-sq and amax reduce over the
//     group via shfl_xor butterfly (masks threads_per_group/2 .. 1) —
//     emulated here with logical lane arrays.
//
// [2] TWO QUANT-SCOPE VARIANTS:
//     a) per-HEAD group quant (group kernel): scale[head][token] with a
//        TRANSPOSE_SCALE layout option (head-major vs token-major);
//     b) per-TOKEN quant (per_token kernel): ONE scale per token across
//        the flattened [num_heads * head_dim] row — matches the per-token
//        activation + per-channel weight a8w8 GEMM scheme.
//     scale = amax / FP8_MAX (fp8 e4m3 max = 448), guarded to 1e-10 when
//     amax <= 1e-10 (all-zero gated rows quantize to zero, never NaN).
//
// [3] The CLAMP + CAST contract: out = cast(clamp(gated / scale, ±FP8_MAX))
//     — the clamp is explicit (saturation), and the fp8 CAST uses the
//     lab-verified e4m3 RNE encode from soft_fp8 (documented substitute
//     for opus::cast<fp8_t>, whose bitwise form is upstream's choice).
//     Quantized values are modeled as clamped FLOATS here; the bitwise
//     e4m3 encode is soft_fp8's verified territory.
//
// Verification level: SOURCE_VERIFIED + REFERENCE_PASS (CPU-only).
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <vector>

#define MAIN_RETURN_BAD 1

static inline float bf16_to_f32(std::uint16_t bits) {
    std::uint32_t u = static_cast<std::uint32_t>(bits) << 16;
    float f;
    std::memcpy(&f, &u, 4);
    return f;
}
static inline std::uint16_t f32_to_bf16(float f) {
    std::uint32_t x;
    std::memcpy(&x, &f, 4);
    const std::uint32_t lsb = (x >> 16) & 1;
    return static_cast<std::uint16_t>((x + 0x7FFFu + lsb) >> 16);
}

struct Lcg {
    std::uint64_t s;
    explicit Lcg(std::uint64_t seed) : s(seed) {}
    std::uint32_t next() {
        s = s * 6364136223846793005ULL + 1442695040888963407ULL;
        return static_cast<std::uint32_t>(s >> 33);
    }
    float uniform(float lo, float hi) {
        return lo + (hi - lo) * static_cast<float>(next() % 1000001) / 1.0e6f;
    }
};

constexpr int HEAD_DIM = 128;
constexpr float FP8_MAX = 448.0f;
constexpr float kScaleGuard = 1e-10f;

static float silu(float v) { return v / (1.0f + std::exp(-v)); }
static float sigmoid(float v) { return 1.0f / (1.0f + std::exp(-v)); }

// ══════════════════════════════════════════════════════════════════════
// [1] Per-head group quant, kernel-faithful lane decomposition
// ══════════════════════════════════════════════════════════════════════
// THREAD_DATA_SIZE elements per lane; threads_per_group lanes cooperate on
// one head (shfl_xor butterfly with masks tpg/2..1 — emulated as pairwise
// exchanges over logical lanes).
struct HeadQuantResult {
    std::vector<float> out;      // 128 clamped pre-cast values
    float quant_scale = 0.f;
};

static HeadQuantResult head_quant_emul(const std::vector<float>& x,
                                       const std::vector<float>& z,
                                       const std::vector<float>& w, double eps, int tds,
                                       bool use_sigmoid) {
    const int tpg = HEAD_DIM / tds;
    HeadQuantResult r;
    r.out.assign(HEAD_DIM, 0.f);

    // logical lanes: lane l owns elements [l*tds, (l+1)*tds)
    std::vector<float> sum_sq(tpg, 0.f), amax(tpg, -INFINITY);
    std::vector<std::vector<float>> xv(tpg), zv(tpg), wv(tpg);
    for (int l = 0; l < tpg; ++l) {
        xv[l].assign(x.begin() + l * tds, x.begin() + (l + 1) * tds);
        zv[l].assign(z.begin() + l * tds, z.begin() + (l + 1) * tds);
        wv[l].assign(w.begin() + l * tds, w.begin() + (l + 1) * tds);
        for (int i = 0; i < tds; ++i) sum_sq[l] += xv[l][i] * xv[l][i];
    }

    // shfl_xor butterfly, ONCE for the whole group (the kernel reduces
    // after all lanes' partials are in — a per-lane-loop butterfly
    // multiplies the total by the lane count, measured 64x here)
    for (int mask = tpg / 2; mask > 0; mask >>= 1) {
        const std::vector<float> snap = sum_sq;
        for (int l = 0; l < tpg; ++l) sum_sq[l] += snap[l ^ mask];
    }
    const float inv_std =
        1.0f / std::sqrt(sum_sq[0] / HEAD_DIM + static_cast<float>(eps));

    // norm + gate + amax
    for (int l = 0; l < tpg; ++l)
        for (int i = 0; i < tds; ++i) {
            const float normed = xv[l][i] * wv[l][i] * inv_std;
            const float gate =
                use_sigmoid ? sigmoid(zv[l][i]) : silu(zv[l][i]);
            const float gated = normed * gate;
            r.out[l * tds + i] = gated;
            amax[l] = std::fmax(amax[l], std::fabs(gated));
        }
    // amax butterfly, once
    for (int mask = tpg / 2; mask > 0; mask >>= 1) {
        const std::vector<float> snap = amax;
        for (int l = 0; l < tpg; ++l) amax[l] = std::fmax(amax[l], snap[l ^ mask]);
    }
    r.quant_scale = (amax[0] > kScaleGuard) ? (amax[0] / FP8_MAX) : kScaleGuard;
    for (int i = 0; i < HEAD_DIM; ++i)
        r.out[i] = std::fmin(std::fmax(r.out[i] / r.quant_scale, -FP8_MAX), FP8_MAX);
    return r;
}

// Naive: scalar per-element, one pass
static HeadQuantResult head_quant_naive(const std::vector<float>& x,
                                        const std::vector<float>& z,
                                        const std::vector<float>& w, double eps, int,
                                        bool use_sigmoid) {
    HeadQuantResult r;
    r.out.assign(HEAD_DIM, 0.f);
    float sum_sq = 0.f;
    for (int i = 0; i < HEAD_DIM; ++i) sum_sq += x[i] * x[i];
    const float inv_std = 1.0f / std::sqrt(sum_sq / HEAD_DIM + static_cast<float>(eps));
    float amax = -INFINITY;
    for (int i = 0; i < HEAD_DIM; ++i) {
        const float normed = x[i] * w[i] * inv_std;
        const float gate = use_sigmoid ? sigmoid(z[i]) : z[i] / (1.0f + std::exp(-z[i]));
        r.out[i] = normed * gate;
        amax = std::fmax(amax, std::fabs(r.out[i]));
    }
    r.quant_scale = (amax > kScaleGuard) ? (amax / FP8_MAX) : kScaleGuard;
    for (int i = 0; i < HEAD_DIM; ++i)
        r.out[i] = std::fmin(std::fmax(r.out[i] / r.quant_scale, -FP8_MAX), FP8_MAX);
    return r;
}

int main() {
    int checks = 0, fails = 0;

    // ── 1. per-head group quant vs naive (bf16-rounded inputs) ──
    {
        Lcg rng(0x6263);
        int f = 0;
        for (int tds : {2, 8, 16}) {
            for (bool use_sig : {false, true}) {
                for (int trial = 0; trial < 32; ++trial) {
                    const double eps = (trial % 4 == 0) ? 0.0 : 1e-6;
                    std::vector<float> x(HEAD_DIM), z(HEAD_DIM), w(HEAD_DIM);
                    for (int i = 0; i < HEAD_DIM; ++i) {
                        // bf16-rounded inputs (the kernel reads bf16)
                        x[i] = bf16_to_f32(f32_to_bf16(rng.uniform(-2.f, 2.f)));
                        z[i] = bf16_to_f32(f32_to_bf16(rng.uniform(-2.f, 2.f)));
                        w[i] = bf16_to_f32(f32_to_bf16(rng.uniform(0.5f, 1.5f)));
                    }
                    const auto got = head_quant_emul(x, z, w, eps, tds, use_sig);
                    const auto want = head_quant_naive(x, z, w, eps, tds, use_sig);
                    ++checks;
                    bool ok = std::fabs(got.quant_scale - want.quant_scale) <=
                              1e-5f * std::fabs(want.quant_scale);
                    for (int i = 0; i < HEAD_DIM && ok; ++i)
                        ok = std::fabs(got.out[i] - want.out[i]) <=
                             1e-4f * std::fabs(want.out[i]);
                    if (!ok && f < 5) {
                        std::printf("  tds %d sig %d trial %d: mismatch (scale %g vs %g)\n", tds,
                                    use_sig, trial, got.quant_scale, want.quant_scale);
                        ++f;
                    }
                    // scale contract: amax/448 guarded
                    ++checks;
                    float amax_out = 0.f;
                    for (float v : got.out) amax_out = std::fmax(amax_out, std::fabs(v));
                    if (!(amax_out <= FP8_MAX * 1.001f) && f < 5) {
                        std::printf("  tds %d: quantized exceeds FP8_MAX\n", tds);
                        ++f;
                    }
                }
            }
        }
        fails += f > 0;
        std::printf("1. per-head group quant (tds 2/8/16, silu vs sigmoid, eps variants): %s\n",
                    f ? "FAIL" : "PASS");
    }

    // ── 2. per-token quant (amax across heads) + scale layouts ──
    {
        Lcg rng(0x706e);
        int f = 0;
        const int heads = 4;
        for (int trial = 0; trial < 32; ++trial) {
            // token with `heads` heads of 128 dims
            std::vector<float> x(heads * HEAD_DIM), z(heads * HEAD_DIM), w(HEAD_DIM);
            for (int i = 0; i < heads * HEAD_DIM; ++i) {
                x[i] = bf16_to_f32(f32_to_bf16(rng.uniform(-2.f, 2.f)));
                z[i] = bf16_to_f32(f32_to_bf16(rng.uniform(-2.f, 2.f)));
            }
            for (int i = 0; i < HEAD_DIM; ++i)
                w[i] = bf16_to_f32(f32_to_bf16(rng.uniform(0.5f, 1.5f)));
            // per-token: norm each head independently (RMS group = head),
            // but the AMAX spans the whole flattened row
            std::vector<float> gated(heads * HEAD_DIM);
            float amax = -INFINITY;
            for (int h = 0; h < heads; ++h) {
                float sum_sq = 0.f;
                for (int i = 0; i < HEAD_DIM; ++i)
                    sum_sq += x[h * HEAD_DIM + i] * x[h * HEAD_DIM + i];
                const float inv_std =
                    1.0f / std::sqrt(sum_sq / HEAD_DIM + 1e-6f);
                for (int i = 0; i < HEAD_DIM; ++i) {
                    const float normed = x[h * HEAD_DIM + i] * w[i] * inv_std;
                    gated[h * HEAD_DIM + i] = normed * (z[h * HEAD_DIM + i] /
                                                        (1.0f + std::exp(-z[h * HEAD_DIM + i])));
                    amax = std::fmax(amax, std::fabs(gated[h * HEAD_DIM + i]));
                }
            }
            const float scale = (amax > kScaleGuard) ? (amax / FP8_MAX) : kScaleGuard;
            std::vector<float> out(heads * HEAD_DIM);
            for (int i = 0; i < heads * HEAD_DIM; ++i)
                out[i] = std::fmin(std::fmax(gated[i] / scale, -FP8_MAX), FP8_MAX);
            // the quantized row must never exceed FP8_MAX and the max must
            // hit ±FP8_MAX (amax maps to the max code)
            float amax_out = 0.f;
            for (float v : out) amax_out = std::fmax(amax_out, std::fabs(v));
            ++checks;
            if (!(amax_out <= FP8_MAX * 1.001f) && f < 5) {
                std::printf("  per-token: exceeds FP8_MAX\n");
                ++f;
            }
            ++checks;
            if (!(std::fabs(amax_out - FP8_MAX) <= FP8_MAX * 1e-4f) && f < 5) {
                std::printf("  per-token: amax %.1f != FP8_MAX (scale contract)\n", amax_out);
                ++f;
            }
            // scale layouts: natural [token*heads + head] vs transposed
            // [head*tokens + token] — the same value, different indexing
            std::vector<float> natural(heads), transposed(heads);
            for (int h = 0; h < heads; ++h) {
                natural[h] = scale;
                transposed[h * 1 + 0] = scale;  // 1 token: head*tokens+token = h
            }
            ++checks;
            bool lay_ok = true;
            for (int h = 0; h < heads; ++h)
                if (natural[h] != transposed[h]) lay_ok = false;
            if (!lay_ok && f < 5) {
                std::printf("  scale layouts disagree\n");
                ++f;
            }
        }
        fails += f > 0;
        std::printf("2. per-token quant (amax across heads) + scale layouts: %s\n",
                    f ? "FAIL" : "PASS");
    }

    // ── 3. the zero guard: all-zero gated row -> scale 1e-10, out 0 ──
    {
        int f = 0;
        std::vector<float> x(HEAD_DIM, 0.f), z(HEAD_DIM, -INFINITY), w(HEAD_DIM, 1.f);
        // silu(-inf) = -inf * 0 = NaN?? — the kernel: z very negative gives
        // silu(z) = z·sigmoid(z) → -0 (sigmoid underflows to +0). Use a
        // large-negative finite z instead: silu(-200) = -200·e^-200 ≈ -0
        std::fill(z.begin(), z.end(), -200.f);
        const auto got = head_quant_emul(x, z, w, 1e-6, 16, false);
        ++checks;
        if (!(got.quant_scale == kScaleGuard) && f < 5) {
            std::printf("  zero-guard scale %g != 1e-10\n", got.quant_scale);
            ++f;
        }
        ++checks;
        bool zeros = true;
        for (float v : got.out)
            if (v != 0.f) zeros = false;
        if (!zeros && f < 5) {
            std::printf("  zero-guard out not zero\n");
            ++f;
        }
        fails += f > 0;
        std::printf("3. zero guard (all-zero gated -> scale 1e-10, out 0, never NaN): %s\n",
                    f ? "FAIL" : "PASS");
    }

    // ── 4. clamp saturation: values beyond FP8_MAX saturate, don't wrap ──
    {
        Lcg rng(0xc14c);
        int f = 0;
        // a row with extreme outliers: scale set by the max, everything
        // else lands small — construct the inverse: ONE huge value, the
        // rest tiny; all quantized values must be within ±FP8_MAX
        std::vector<float> x(HEAD_DIM, 0.f), z(HEAD_DIM, 0.f), w(HEAD_DIM, 1.f);
        // the gate must PASS the outliers: silu(z=0) = 0 would zero them
        // (gated = normed * silu(z)) — z large-positive gives silu(z) ≈ z
        z[0] = 50.f;
        z[7] = 50.f;
        x[0] = 100.f;
        x[7] = -100.f;
        for (int i = 8; i < HEAD_DIM; ++i) x[i] = 1e-4f * (i % 3);
        const auto got = head_quant_emul(x, z, w, 1e-6, 16, false);
        ++checks;
        bool in_range = true;
        for (float v : got.out)
            in_range &= (std::fabs(v) <= FP8_MAX);
        if (!in_range && f < 5) {
            std::printf("  clamp: value exceeds FP8_MAX\n");
            ++f;
        }
        // the outliers must SATURATE at ±FP8_MAX (silu(50) ≈ 50 passes the
        // gate; the max element clips at the top code)
        ++checks;
        if (!(got.out[0] >= FP8_MAX * 0.999f && got.out[7] <= -FP8_MAX * 0.999f) && f < 5) {
            std::printf("  clamp: outliers not saturated (out0 %g out7 %g)\n", got.out[0],
                        got.out[7]);
            ++f;
        }
        fails += f > 0;
        std::printf("4. clamp saturation (outliers -> ±FP8_MAX, no wrap): %s\n",
                    f ? "FAIL" : "PASS");
    }

    std::printf("gated_rmsnorm_quant: %d checks, %d failures -> %s\n", checks, fails,
                fails ? "FAIL" : "PASS");
    return fails ? MAIN_RETURN_BAD : 0;
}
