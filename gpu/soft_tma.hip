// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2026, Advanced Micro Devices, Inc. All rights reserved.
//
// Demo host for the hand-written ISA soft-TMA pipeline kernel
// (soft_tma_pipeline.s, assembled separately to soft_tma_pipeline.co).
// Demonstrates the raw-code-object toolchain path: clang-assembled ISA ->
// hipModuleLoadData -> hipModuleLaunchKernel, plus a correctness check
// against the host-computed expectation and an [info] throughput
// comparison against a plain HIP kernel doing the same work.
//
// Data model (one wave32 per workgroup): the wave consumes quads_per_wg
// 512-byte quads; lane L accumulates the four f32 words of its own 16 B
// slice across all its quads; results land at dst + wg*512 + L*16.
//   expected[wg][lane][k] = sum_q src[(wg*quads_per_wg + q)*128 + lane*4 + k]
//
// Build & run (inside the ROCm container):
//   clang -c -x assembler -target amdgcn-amd-amdhsa -mcpu=gfx1030 \
//       soft_tma_pipeline.s -o soft_tma_pipeline.co
//   hipcc -x hip --offload-arch=gfx1030 soft_tma.hip -o soft_tma && ./soft_tma
#include <hip/hip_runtime.h>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <vector>

#define CK(x)                                                                              \
    do {                                                                                   \
        const hipError_t e_ = (x);                                                         \
        if (e_ != hipSuccess) {                                                            \
            std::printf("HIP error %s at %s:%d\n", hipGetErrorString(e_), __FILE__,        \
                        __LINE__);                                                         \
            return 1;                                                                      \
        }                                                                                  \
    } while (0)

// Plain baseline: same work as st_tma1 (read own 16 B slice per quad,
// accumulate) without any of the pipeline machinery.
__global__ void plain_accum(const float* __restrict__ src, float* __restrict__ dst,
                            int quads_per_wg) {
    const int wg = blockIdx.x;
    const int lane = threadIdx.x;
    float v0 = 0, v1 = 0, v2 = 0, v3 = 0;
    const long base = static_cast<long>(wg) * quads_per_wg * 128 + lane * 4;
    for (int q = 0; q < quads_per_wg; ++q) {
        const float* p = src + base + static_cast<long>(q) * 128;
        v0 += p[0];
        v1 += p[1];
        v2 += p[2];
        v3 += p[3];
    }
    float* out = dst + static_cast<long>(wg) * 128 + lane * 4;
    out[0] = v0;
    out[1] = v1;
    out[2] = v2;
    out[3] = v3;
}

int main(int argc, char** argv) {
    const char* co_path = argc > 1 ? argv[1] : "soft_tma_pipeline.co";
    // ── load the raw ISA code object ──
    FILE* f = fopen(co_path, "rb");
    if (!f) {
        std::printf("cannot open %s\n", co_path);
        return 1;
    }
    fseek(f, 0, SEEK_END);
    const long size = ftell(f);
    fseek(f, 0, SEEK_SET);
    std::vector<char> image(size);
    if (fread(image.data(), 1, size, f) != static_cast<size_t>(size)) return 1;
    fclose(f);

    hipModule_t mod;
    CK(hipModuleLoadData(&mod, image.data()));
    hipFunction_t fn;
    CK(hipModuleGetFunction(&fn, mod, "st_tma1"));

    // ── data: 1024 workgroups x 512 quads = 256 MiB read ──
    constexpr int kWgs = 1024, kQuadsPerWg = 512;  // quads per wg: multiple of 4
    constexpr int kLaneWords = 4;
    const long src_words = static_cast<long>(kWgs) * kQuadsPerWg * 128;
    const long dst_words = static_cast<long>(kWgs) * 32 * kLaneWords;
    std::vector<float> hsrc(src_words), hdst(dst_words, 0.0f);
    unsigned seed = 0xC0FFEEu;
    for (auto& v : hsrc) {
        seed = seed * 1664525u + 1013904223u;
        v = static_cast<float>(static_cast<int>(seed >> 8) % 2001 - 1000) / 64.0f;
    }

    float *dsrc, *ddst;
    CK(hipMalloc(&dsrc, src_words * 4));
    CK(hipMalloc(&ddst, dst_words * 4));
    CK(hipMemcpy(dsrc, hsrc.data(), src_words * 4, hipMemcpyHostToDevice));
    CK(hipMemset(ddst, 0, dst_words * 4));

    int quads = kQuadsPerWg;
    void* args[] = {&dsrc, &ddst, &quads};
    const unsigned wg32 = 32;

    // Correctness run.
    CK(hipModuleLaunchKernel(fn, kWgs, 1, 1, wg32, 1, 1, 0, nullptr, args, nullptr));
    CK(hipDeviceSynchronize());
    CK(hipMemcpy(hdst.data(), ddst, dst_words * 4, hipMemcpyDeviceToHost));

    int bad = 0;
    double max_abs = 0.0;
    for (int wg = 0; wg < kWgs && bad == 0; ++wg) {
        for (int lane = 0; lane < 32; ++lane) {
            for (int k = 0; k < kLaneWords; ++k) {
                const long idx = (static_cast<long>(wg) * 32 + lane) * kLaneWords + k;
                // Per-lane accumulation over 512 quads in f32: compare with a
                // float-order host reference (same order, cheap and exact).
                float e = 0.0f;
                const long base =
                    static_cast<long>(wg) * kQuadsPerWg * 128 + lane * 4 + k;
                for (int q = 0; q < kQuadsPerWg; ++q)
                    e += hsrc[base + static_cast<long>(q) * 128];
                const double diff = fabs(static_cast<double>(hdst[idx]) - e);
                max_abs = fmax(max_abs, diff);
                if (diff > 1e-3 * fabs(e) + 1e-4) {
                    std::printf("mismatch wg=%d lane=%d k=%d got=%f want=%f\n", wg, lane, k,
                                hdst[idx], e);
                    ++bad;
                    break;
                }
            }
            if (bad) break;
        }
        if (bad) break;
    }
    std::printf("soft_tma correctness: %s (max_abs=%.3g over %d lanes)\n",
                bad == 0 ? "PASS" : "FAIL", max_abs, kWgs * 32);

    if (bad == 0) {
        // Throughput [info]: st_tma1 vs the plain kernel, event-timed, best
        // of 5 launches over the same buffers. Bytes counted as read+write.
        hipEvent_t t0, t1;
        CK(hipEventCreate(&t0));
        CK(hipEventCreate(&t1));
        const double gb = (src_words + dst_words) * 4.0 / 1e9;
        float best_isa = 1e30f, best_plain = 1e30f;
        for (int rep = 0; rep < 5; ++rep) {
            CK(hipEventRecord(t0));
            CK(hipModuleLaunchKernel(fn, kWgs, 1, 1, wg32, 1, 1, 0, nullptr, args, nullptr));
            CK(hipEventRecord(t1));
            CK(hipEventSynchronize(t1));
            float ms;
            CK(hipEventElapsedTime(&ms, t0, t1));
            best_isa = fminf(best_isa, ms);
        }
        void* pargs[] = {&dsrc, &ddst, &quads};
        for (int rep = 0; rep < 5; ++rep) {
            CK(hipEventRecord(t0));
            hipLaunchKernelGGL(plain_accum, dim3(kWgs), dim3(32), 0, 0,
                               reinterpret_cast<const float*>(dsrc), ddst, quads);
            CK(hipEventRecord(t1));
            CK(hipEventSynchronize(t1));
            float ms;
            CK(hipEventElapsedTime(&ms, t0, t1));
            best_plain = fminf(best_plain, ms);
        }
        std::printf(
            "[info] throughput best-of-5 over %.1f MB: isa=%.1f GB/s plain=%.1f GB/s\n",
            gb * 1000.0, gb / (best_isa * 1e-3f), gb / (best_plain * 1e-3f));
    }

    CK(hipFree(dsrc));
    CK(hipFree(ddst));
    CK(hipModuleUnload(mod));
    return bad == 0 ? 0 : 1;
}
