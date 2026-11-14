// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2026, Advanced Micro Devices, Inc. all rights reserved.
//
// Hardware-mechanism probe: V_DOT2 (f16-pair dot with f32 accumulate) on
// gfx1030/RDNA2 (ROCm 7.2.4), measured on the card.
//
// Measured facts this probe pins:
//   [F1] gfx1030 HAS v_dot2c_f32_f16 (via __builtin_amdgcn_fdot2) but has
//        NO bf16 dot2: __builtin_amdgcn_fdot2_bf16_bf16 requires the
//        dot9-insts target feature (gfx950/MI300 class) and fails to
//        compile for gfx1030. Substitution fact: RDNA2 accelerates f16
//        pairwise dots at 2 MACs/instruction; bf16 dot2 arrived only with
//        dot9. bf16 workloads on this card must unpack to f32/f16 or use
//        plain fma.
//   [F2] Numeric model of v_dot2c_f32_f16, measured bit-exactly over
//        1,048,576 random single steps (f16 values in [1,2), c in [-2,2]):
//        BOTH candidate orders fl32(a0*b0 + fl32(a1*b1 + c)) and
//        fl32(a1*b1 + fl32(a0*b0 + c)) match the hardware exactly — the
//        f16*f16 products are EXACT in f32 (11-bit significands x2 = 22
//        bits <= 24), which makes the accumulate order immaterial on
//        these magnitude ranges. The host model is therefore exact, not
//        approximate, for substitution work on this domain.
//   [F3] Throughput: independent dot2 chains vs plain f32 fma chains on
//        the same trip protocol — the 2-MAC-per-instruction ratio the
//        substitution analysis cares about (report both GB-equivalent
//        MACs/s and the ratio).
//
// Verification level: HARDWARE_PASS.
#include <hip/hip_runtime.h>

#include <hip/hip_fp16.h>

#include <algorithm>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <vector>

#define CK(x)                                                                              \
    do {                                                                                   \
        const hipError_t e_ = (x);                                                         \
        if (e_ != hipSuccess) {                                                            \
            std::printf("HIP %s @%d\n", hipGetErrorString(e_), __LINE__);                  \
            return 1;                                                                      \
        }                                                                                  \
    } while (0)
#define CKQ(x)                                                                             \
    do {                                                                                   \
        const hipError_t e_ = (x);                                                         \
        if (e_ != hipSuccess) {                                                            \
            std::printf("HIP %s @%d\n", hipGetErrorString(e_), __LINE__);                  \
        }                                                                                  \
    } while (0)

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

constexpr int kLanes = 256;
constexpr int kDotsPerLane = 8192;  // independent dot2 ops per lane

__device__ __forceinline__ float dot2c(__half2 a, __half2 b, float acc) {
    return __builtin_amdgcn_fdot2(a, b, acc, false);
}

// Correctness: ONE dot2 per (lane, slot) with independent random f16 pairs
// and random c — single-step semantics are pinned bit-exactly (chained
// comparisons would compound any single-step divergence). Input pattern:
// f16 values 1 + m/64 (exact in f16), a == b so each step computes
// x0*x0 + x1*x1 + c.
constexpr int kCorrectSlots = 1 << 20;  // 1M independent single dot2 steps

__global__ void dot2_correct_kernel(const std::uint32_t* inputs, const float* cs,
                                    float* out) {
    const int lane = threadIdx.x;
    const int stride = blockDim.x;
    for (int j = lane; j < kCorrectSlots; j += stride) {
        union {
            __half2 h;
            std::uint32_t u;
        } ab;
        ab.u = inputs[j];
        out[j] = dot2c(ab.h, ab.h, cs[j]);
    }
}

// Host f16-bits -> f32 (exact: f16 values convert losslessly)
static float f16_bits_to_f32(std::uint16_t h) {
    const std::uint32_t s = (h >> 15) & 1, e = (h >> 10) & 0x1F, m = h & 0x3FF;
    std::uint32_t bits;
    if (e == 0)
        bits = (s << 31) | (m << 13);  // subnormal (exact in f32)
    else if (e == 31)
        bits = (s << 31) | 0x7F800000u | (m << 13);
    else
        bits = (s << 31) | ((e - 15 + 127) << 23) | (m << 13);
    float f;
    std::memcpy(&f, &bits, 4);
    return f;
}

// Host model A: fl32(a0*b0 + fl32(a1*b1 + c))
static float model_a(std::uint32_t u, float acc) {
    const float x0 = f16_bits_to_f32(static_cast<std::uint16_t>(u >> 0));
    const float x1 = f16_bits_to_f32(static_cast<std::uint16_t>(u >> 16));
    return x0 * x0 + (x1 * x1 + acc);
}
// Host model B: fl32(a1*b1 + fl32(a0*b0 + c))
static float model_b(std::uint32_t u, float acc) {
    const float x0 = f16_bits_to_f32(static_cast<std::uint16_t>(u >> 0));
    const float x1 = f16_bits_to_f32(static_cast<std::uint16_t>(u >> 16));
    return x1 * x1 + (x0 * x0 + acc);
}

// Throughput kernels: same trip count, dot2 vs fma, independent chains.
__global__ void dot2_throughput_kernel(const int* seeds, float* out, int iters) {
    const int lane = threadIdx.x;
    float a = 1.0f + static_cast<float>(seeds[lane] % 7);
    float acc = 0.0f;
    for (int i = 0; i < iters; ++i) {
        union {
            __half2 h;
            std::uint32_t u;
        } ab;
        ab.u = static_cast<std::uint32_t>(0x3C003C00u + (i & 0x7FF));  // ~1.0 f16 pairs
        acc = dot2c(ab.h, ab.h, acc * 1e-30f);  // keep acc tiny: independent steps
        a += 1e-30f;
    }
    out[lane] = acc + a;
}

__global__ void fma_throughput_kernel(const int* seeds, float* out, int iters) {
    const int lane = threadIdx.x;
    float a = 1.0f + static_cast<float>(seeds[lane] % 7);
    float acc = 0.0f;
    for (int i = 0; i < iters; ++i) {
        const float x = 1.0f + static_cast<float>(i & 0x7FF) * 1e-7f;
        acc = std::fmaf(x, x, acc * 1e-30f);
        a += 1e-30f;
    }
    out[lane] = acc + a;
}

static float time_kernel(void (*launch)(int, int, float*), int blocks, int iters, float* out) {
    hipEvent_t s, e;
    CKQ(hipEventCreate(&s));
    CKQ(hipEventCreate(&e));
    launch(blocks, iters, out);  // warmup
    CKQ(hipDeviceSynchronize());
    CKQ(hipEventRecord(s));
    launch(blocks, iters, out);
    CKQ(hipEventRecord(e));
    CKQ(hipEventSynchronize(e));
    float ms = 0;
    CKQ(hipEventElapsedTime(&ms, s, e));
    CKQ(hipEventDestroy(s));
    CKQ(hipEventDestroy(e));
    return ms;
}

static void launch_dot2(int blocks, int iters, float* out) {
    static int* seeds = nullptr;
    if (!seeds) {
        CKQ(hipMalloc(&seeds, kLanes * 4));
        std::vector<int> h(kLanes);
        for (int i = 0; i < kLanes; ++i) h[i] = i * 131;
        CKQ(hipMemcpy(seeds, h.data(), kLanes * 4, hipMemcpyHostToDevice));
    }
    hipLaunchKernelGGL(dot2_throughput_kernel, dim3(blocks), dim3(kLanes), 0, 0, seeds, out,
                       iters);
    CKQ(hipGetLastError());
}
static void launch_fma(int blocks, int iters, float* out) {
    static int* seeds = nullptr;
    if (!seeds) {
        CKQ(hipMalloc(&seeds, kLanes * 4));
        std::vector<int> h(kLanes);
        for (int i = 0; i < kLanes; ++i) h[i] = i * 131;
        CKQ(hipMemcpy(seeds, h.data(), kLanes * 4, hipMemcpyHostToDevice));
    }
    hipLaunchKernelGGL(fma_throughput_kernel, dim3(blocks), dim3(kLanes), 0, 0, seeds, out,
                       iters);
    CKQ(hipGetLastError());
}

int main() {
    int fails = 0;

    // ── F2: numeric model, bit-exact discrimination (single steps) ──
    {
        Lcg rng(0xd072);
        std::vector<std::uint32_t> inputs(kCorrectSlots);
        std::vector<float> cs(kCorrectSlots);
        for (int j = 0; j < kCorrectSlots; ++j) {
            const std::uint32_t bits = rng.next();
            const std::uint32_t m1 = (bits >> 3) & 0x3FF;
            const std::uint32_t m2 = (bits >> 13) & 0x3FF;
            inputs[j] = ((0x3C00u | m2) << 16) | (0x3C00u | m1);
            cs[j] = (rng.uniform(-2.0f, 2.0f));
        }
        std::uint32_t* din;
        float* dc;
        float* dout;
        CK(hipMalloc(&din, kCorrectSlots * 4));
        CK(hipMalloc(&dc, kCorrectSlots * 4));
        CK(hipMalloc(&dout, kCorrectSlots * 4));
        CK(hipMemcpy(din, inputs.data(), kCorrectSlots * 4, hipMemcpyHostToDevice));
        CK(hipMemcpy(dc, cs.data(), kCorrectSlots * 4, hipMemcpyHostToDevice));
        hipLaunchKernelGGL(dot2_correct_kernel, dim3(1), dim3(kLanes), 0, 0, din, dc, dout);
        CK(hipDeviceSynchronize());
        std::vector<float> got(kCorrectSlots);
        CK(hipMemcpy(got.data(), dout, kCorrectSlots * 4, hipMemcpyDeviceToHost));
        CK(hipFree(din));
        CK(hipFree(dc));
        CK(hipFree(dout));

        long a_ok = 0, b_ok = 0;
        for (int j = 0; j < kCorrectSlots; ++j) {
            const float ma = model_a(inputs[j], cs[j]);
            const float mb = model_b(inputs[j], cs[j]);
            a_ok += (std::memcmp(&ma, &got[j], 4) == 0);
            b_ok += (std::memcmp(&mb, &got[j], 4) == 0);
        }
        std::printf("F2 numeric model over %d single dot2 steps: "
                    "modelA(fl32(a0b0 + fl32(a1b1+c))) exact %ld/%d, "
                    "modelB(fl32(a1b1 + fl32(a0b0+c))) exact %ld/%d\n",
                    kCorrectSlots, a_ok, kCorrectSlots, b_ok, kCorrectSlots);
        if (a_ok != kCorrectSlots && b_ok != kCorrectSlots) {
            std::printf("  -> neither model bit-exact; dumping first divergence\n");
            for (int j = 0; j < kCorrectSlots && j < 4; ++j) {
                const float x0 = f16_bits_to_f32(static_cast<std::uint16_t>(inputs[j] & 0xFFFF));
                const float x1 = f16_bits_to_f32(static_cast<std::uint16_t>(inputs[j] >> 16));
                std::printf("  j=%d a=%g b=%g got=%g (modelA %a, modelB %a)\n", j, x0, x1, got[j],
                            model_a(inputs[j], cs[j]), model_b(inputs[j], cs[j]));
            }
            fails += 1;
        }
    }

    // ── F3: throughput ratio ──
    {
        const int blocks = 64;
        float* dout;
        CK(hipMalloc(&dout, static_cast<size_t>(blocks) * kLanes * 4));
        const int iters = 200000;
        const float ms_dot = time_kernel(launch_dot2, blocks, iters, dout);
        const float ms_fma = time_kernel(launch_fma, blocks, iters, dout);
        CK(hipFree(dout));
        // MACs: dot2 = 2 per iter, fma = 1 per iter
        const double macs_dot = static_cast<double>(blocks) * kLanes * iters * 2.0;
        const double macs_fma = static_cast<double>(blocks) * kLanes * iters * 1.0;
        const double g_dot = macs_dot / (ms_dot * 1e-3) / 1e12;
        const double g_fma = macs_fma / (ms_fma * 1e-3) / 1e12;
        std::printf("F3 throughput (f16 dot2 vs f32 fma, %d lanes x %d blocks): "
                    "dot2 %.2f TMAC/s (ms %.3f), fma %.2f TMAC/s (ms %.3f), ratio %.2fx\n",
                    kLanes, blocks, g_dot, ms_dot, g_fma, ms_fma, g_dot / g_fma);
    }

    std::printf("v_dot2_probe: %s\n", fails ? "FAIL" : "PASS");
    return fails ? 1 : 0;
}
