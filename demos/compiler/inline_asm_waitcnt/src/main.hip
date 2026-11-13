// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2026, Advanced Micro Devices, Inc. All rights reserved.
//
// Compiler-feature demo: s_waitcnt vmcnt(N) partial drain via inline asm in
// HIP C++. Correctness requires the partial drain to be real: BATCH loads
// stay in flight while the OLDER BATCH is guaranteed landed. If the asm were
// dropped (or replaced by a full drain), the test below would still pass
// (full drains are a superset) — so the INSPECTION script (scripts/
// inspect.sh) is the second half of the evidence: it greps the IR and final
// ISA for the s_waitcnt vmcnt instruction and asserts its presence.
//
// The kernel mirrors demos/emulation/soft_tma's pipeline at B=4 with an
// exact shape (quads % 4 == 0) so correctness is bitwise.
#include <hip/hip_runtime.h>

#include <cstdio>
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

constexpr int BATCH = 4;

__global__ void __launch_bounds__(32) partial_drain_probe(const float4* __restrict__ src,
                                                          float4* __restrict__ out,
                                                          int quads_per_block) {
    __shared__ float4 lds[2 * BATCH * 32];
    const int lane = threadIdx.x & 31;
    const long quad_base = static_cast<long>(blockIdx.x) * quads_per_block;
    float4 acc = {0.f, 0.f, 0.f, 0.f};

    float4 gA[BATCH], gB[BATCH];
    int issued = 0, nA = 0, phase = 0;

    for (; nA < BATCH && issued < quads_per_block; ++nA, ++issued) {
        gA[nA] = src[(quad_base + issued) * 32 + lane];
    }

    auto consume = [&](float4* slot_base) {
        asm volatile("s_waitcnt lgkmcnt(0)" ::: "memory");
        for (int b = 0; b < BATCH; ++b) {
            const float4 v = slot_base[b * 32 + lane];
            acc.x += v.x;
            acc.y += v.y;
            acc.z += v.z;
            acc.w += v.w;
        }
    };

    while (true) {
        const bool full = (quads_per_block - issued) >= BATCH;
        if (full) {
            for (int b = 0; b < BATCH; ++b, ++issued) {
                gB[b] = src[(quad_base + issued) * 32 + lane];
            }
            // THE load-bearing instruction under study (compile-time immediate).
            asm volatile("s_waitcnt vmcnt(%0)" :: "n"(BATCH));
        } else {
            asm volatile("s_waitcnt vmcnt(0)" ::: "memory");
        }
        float4* slot = lds + phase * BATCH * 32;
        for (int b = 0; b < nA; ++b) slot[b * 32 + lane] = gA[b];
        consume(slot);
        phase ^= 1;
        for (int b = 0; b < BATCH; ++b) gA[b] = gB[b];
        nA = full ? BATCH : 0;
        if (!full) break;
    }

    out[static_cast<long>(blockIdx.x) * 32 + lane] = acc;
}

int main() {
    const int blocks = 64, qpb = 128;  // exact shape: 128 % 4 == 0
    std::vector<float4> src(static_cast<long>(blocks) * qpb * 32);
    for (long i = 0; i < static_cast<long>(src.size()); ++i) {
        const float v = static_cast<float>(i % 1000);
        src[i] = {v, v, v, v};
    }
    std::vector<float4> out(static_cast<long>(blocks) * 32, float4{0, 0, 0, 0});
    float4 *d, *o;
    CK(hipMalloc(&d, src.size() * 16));
    CK(hipMalloc(&o, out.size() * 16));
    CK(hipMemcpy(d, src.data(), src.size() * 16, hipMemcpyHostToDevice));
    hipLaunchKernelGGL(partial_drain_probe, blocks, 32, 0, 0, d, o, qpb);
    CK(hipDeviceSynchronize());
    CK(hipMemcpy(out.data(), o, out.size() * 16, hipMemcpyDeviceToHost));

    int bad = 0;
    for (int b = 0; b < blocks && !bad; ++b)
        for (int l = 0; l < 32 && !bad; ++l) {
            // each float4 component accumulates the same (i%1000) sequence —
            // f32 exact for these magnitudes -> bitwise comparison valid.
            float ex = 0;
            for (int q = 0; q < qpb; ++q) {
                const long base = (static_cast<long>(b) * qpb + q) * 32 + l;
                ex += static_cast<float>(base % 1000);
            }
            const float ey = ex, ez = ex, ew = ex;
            const float4 got = out[static_cast<long>(b) * 32 + l];
            if (got.x != ex || got.y != ey || got.z != ez || got.w != ew) {
                std::printf("mismatch b=%d l=%d got=(%g,%g,%g,%g) want=(%g,%g,%g,%g)\n", b, l,
                            got.x, got.y, got.z, got.w, ex, ey, ez, ew);
                bad = 1;
            }
        }
    std::printf("partial-drain probe: %s\n", bad ? "FAIL" : "PASS");
    return bad;
}
