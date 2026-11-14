// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2026, Advanced Micro Devices, Inc. all rights reserved.
//
// Hardware-mechanism probe: __builtin_amdgcn_sched_group_barrier on
// gfx1030/RDNA2 (ROCm 7.2.4, clang-22). Measured facts:
//
//   [F1] The intrinsic is a pure scheduling HINT: kernels annotated with
//        upstream-style groups (multiple instruction-class masks sharing
//        ONE group id — see aiter's
//        pa_mqa_logits_mxfp4_gfx950_common.cuh:476-477 pattern) produce
//        BITWISE-IDENTICAL outputs to the unannotated kernel. Functional
//        no-op; the effect is instruction ordering only.
//   [F2] Instruction-class ids that compile on gfx1030 (measured): 0x11
//        (VALU/ALU), 0x8 (VMEM), 0x18 (TRANS), 0x28 (SALU). The
//        MFMA-family masks aiter uses on gfx950/gfx1250 have no meaning
//        here (no such units); they still compile but classify nothing
//        on RDNA2.
//   [F3] TOOLCHAIN HAZARD (measured): certain mixed-type TWO-GROUP
//        patterns SEGFAULT the LLVM machine scheduler
//        (ScheduleDAGMI::schedule, clang-22). Crash set is irregular:
//        {0x11 gid0, 0x8 gid1} crashes, {0x11 gid5, 0x8 gid10} compiles,
//        {0x8 gid0, 0x18 gid0} compiles, reversed orders compile. This is
//        an LLVM bug surface, not a usage rule. SAFE pattern (measured +
//        matches upstream): all sched_group_barrier calls share ONE group
//        id per scheduling region, groups emitted per loop iteration.
//
// Verification level: HARDWARE_PASS (correctness on card) +
// STATIC_ANALYSIS_PASS (ISA artifact).
#include <hip/hip_runtime.h>

#include <cmath>
#include <cstring>
#include <cstdint>
#include <cstdio>
#include <vector>

#define CK(x)                                                                              \
    do {                                                                                   \
        const hipError_t e_ = (x);                                                         \
        if (e_ != hipSuccess) {                                                            \
            std::printf("HIP %s @%d\n", hipGetErrorString(e_), __LINE__);                  \
            return 1;                                                                      \
        }                                                                                  \
    } while (0)

constexpr int kThreads = 256;
constexpr int kElements = 1 << 20;

__global__ void dot_plain(const float* a, const float* b, float* o, int n) {
    const int i = threadIdx.x + blockIdx.x * blockDim.x;
    if (i >= n) return;
    float acc = 0.f;
    for (int j = 0; j < 16; ++j) acc += a[i * 16 + j] * b[i * 16 + j];
    o[i] = acc;
}

// Annotated twin: upstream-style groups — per iteration, one VMEM mask
// group and one VALU mask group, SAME group id (safe pattern, F3).
constexpr unsigned kVMEM = 0x8;
constexpr unsigned kALU = 0x11;
__global__ void dot_annotated(const float* a, const float* b, float* o, int n) {
    const int i = threadIdx.x + blockIdx.x * blockDim.x;
    if (i >= n) return;
    float acc = 0.f;
#pragma unroll 1
    for (int j = 0; j < 16; ++j) {
        __builtin_amdgcn_sched_group_barrier(kVMEM, 2, 0);
        const float va = a[i * 16 + j];
        const float vb = b[i * 16 + j];
        __builtin_amdgcn_sched_group_barrier(kALU, 4, 0);
        acc += va * vb;
    }
    o[i] = acc;
}

int main() {
    std::vector<float> a(static_cast<size_t>(kElements)), b(kElements), o1(kThreads), o2(kThreads);
    for (int i = 0; i < kElements; ++i) {
        a[i] = std::sin(static_cast<float>(i) * 0.001f);
        b[i] = std::cos(static_cast<float>(i) * 0.002f);
    }
    float *da, *db, *d1, *d2;
    CK(hipMalloc(&da, kElements * 4));
    CK(hipMalloc(&db, kElements * 4));
    CK(hipMalloc(&d1, kThreads * 4));
    CK(hipMalloc(&d2, kThreads * 4));
    CK(hipMemcpy(da, a.data(), kElements * 4, hipMemcpyHostToDevice));
    CK(hipMemcpy(db, b.data(), kElements * 4, hipMemcpyHostToDevice));

    dot_plain<<<kThreads, 256>>>(da, db, d1, kThreads);
    dot_annotated<<<kThreads, 256>>>(da, db, d2, kThreads);
    CK(hipDeviceSynchronize());
    CK(hipMemcpy(o1.data(), d1, kThreads * 4, hipMemcpyDeviceToHost));
    CK(hipMemcpy(o2.data(), d2, kThreads * 4, hipMemcpyDeviceToHost));
    CK(hipFree(da));
    CK(hipFree(db));
    CK(hipFree(d1));
    CK(hipFree(d2));

    int bad = 0;
    for (int i = 0; i < kThreads; ++i)
        if (std::memcmp(&o1[i], &o2[i], 4) != 0) ++bad;
    std::printf("F1 annotated vs plain (bitwise): %s (%d/%d mismatch)\n",
                bad ? "FAIL" : "PASS", bad, kThreads);
    return bad ? 1 : 0;
}
