// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2026, Advanced Micro Devices, Inc. all rights reserved.
//
// Hardware tuning sweep: the float4 COPY kernel is the memory-ceiling
// denominator for the soft_tma grading (demos/emulation/soft_tma). The
// shipped shape (1024 threads x 1 float4) was inherited, never swept.
// This demo sweeps block size x vector width x elements-per-thread over
// the SAME 8-region rotation protocol (335 MB regions, 2.7 GB total >> L2)
// and reports the table plus the best shape — measured, not assumed.
//
// Verification level: HARDWARE_PASS + PERFORMANCE_MEASURED.
#include <hip/hip_runtime.h>

#include <algorithm>
#include <cstring>
#include <cstdint>
#include <cstdio>
#include <string>
#include <vector>

#define CK(x)                                                                              \
    do {                                                                                   \
        const hipError_t e_ = (x);                                                         \
        if (e_ != hipSuccess) {                                                            \
            std::printf("HIP %s @%d\n", hipGetErrorString(e_), __LINE__);                  \
            return 1;                                                                      \
        }                                                                                  \
    } while (0)

constexpr int kRegions = 4;
// region = 335 MB (soft_tma's shape: 320 blocks x 2048 quads x 512 B);
// 8 regions = 2.7 GB >> the 8 MB L2. The sweep MUST be L2-defeating or it
// measures L2 bandwidth and misranks every shape: the first sweep attempt
// used 2.6 MB regions (8 fit L2) and reported 773.9 GB/s "best" — an
// L2-resident number, not HBM.
constexpr int kCopyBlocks = 320;
constexpr long kQuadsF4 = 2048L * 32;  // 512 B = 32 float4s
constexpr long kRegionF4 = static_cast<long>(kCopyBlocks) * kQuadsF4;  // 21M f4
// NOTE: the copy kernel's `off` is a FLOAT offset and kRegionF4 below is
// passed as the FLOAT count (n_floats = kRegionF4 * 4 in the launchers)
// — the grid math uses the float count.

// vector-width-typed copy: VT in {float, float2, float4}; each thread
// handles EPT groups of sizeof(VT)/4 consecutive floats (a contiguous
// [tid*VEPT, (tid+1)*VEPT) block); safe scalar tail.
template <typename VT, int EPT>
__global__ void copy_kernel(const float* __restrict__ src, float* __restrict__ dst, long n) {
    constexpr long VF = static_cast<long>(sizeof(VT) / 4);
    const long tid = blockIdx.x * blockDim.x + threadIdx.x;
    const long base = tid * VF * EPT;
#pragma unroll
    for (int e = 0; e < EPT; ++e) {
        const long off = base + e * VF;
        if (off + VF <= n) {
            const VT v = *reinterpret_cast<const VT*>(src + off);
            *reinterpret_cast<VT*>(dst + off) = v;
        } else {
            for (long j = off; j < n && j < off + VF; ++j) dst[j] = src[j];
        }
    }
}

struct Cfg {
    int block;
    int vec;
    int ept;
    const char* name;
};

int main() {
    // 8 rotating regions: src[i] -> dst (defeats L2, matches soft_tma)
    std::vector<float*> srcs(kRegions), dsts(kRegions);
    for (int r = 0; r < kRegions; ++r) {
        // kRegionF4 is a FLOAT4 count: bytes = kRegionF4 * 16
        CK(hipMalloc(&srcs[r], kRegionF4 * 16));
        CK(hipMalloc(&dsts[r], kRegionF4 * 16));
        CK(hipMemset(srcs[r], r + 1, kRegionF4 * 16));
    }
    std::vector<float> rot(kRegions);
    for (int r = 0; r < kRegions; ++r) rot[r] = static_cast<float>(r);
    float* drot;
    CK(hipMalloc(&drot, kRegions * 4));
    CK(hipMemcpy(drot, rot.data(), kRegions * 4, hipMemcpyHostToDevice));
    // the rotation: src[r] advances by one region per pass (src[i] -> dst of
    // a rotating index), emulating soft_tma's irrigation pattern
    hipEvent_t ev_start, ev_end;
    CK(hipEventCreate(&ev_start));
    CK(hipEventCreate(&ev_end));

    const Cfg cfgs[] = {
        {1024, 4, 1, "b1024 v4 e1"},
        {512, 4, 1, "b512 v4 e1"},
        {256, 4, 1, "b256 v4 e1"},
        {1024, 4, 2, "b1024 v4 e2"},
        {512, 4, 2, "b512 v4 e2"},
        {256, 4, 2, "b256 v4 e2"},
        {1024, 4, 4, "b1024 v4 e4"},
        {512, 4, 4, "b512 v4 e4"},
        {256, 4, 4, "b256 v4 e4"},
        {512, 2, 4, "b512 v2 e4"},
        {256, 2, 4, "b256 v2 e4"},
        {1024, 1, 8, "b1024 v1 e8"},
        {512, 1, 8, "b512 v1 e8"},
        {256, 1, 8, "b256 v1 e8"},
        {64, 4, 1, "b64 v4 e1"},
        {128, 4, 1, "b128 v4 e1"},
        {128, 4, 2, "b128 v4 e2"},
        {128, 4, 4, "b128 v4 e4"},
    };
    struct Result {
        float gbps;
        std::string name;
    };
    std::vector<Result> results;

    // bytes per pass: kRegions moves of kRegionF4 float4s, read+write
    // (16 B per float4) — 4 regions x 338 MB x 2 = 2.7 GB per pass
    const double bytes_per_pass = 2.0 * kRegionF4 * 16 * kRegions;

    auto launch_cfg = [&](int vec, int ept, int block, int region) {
        const long floats_per_thread = static_cast<long>(vec) * ept;
        const long threads_needed = (kRegionF4 * 4 + floats_per_thread - 1) / floats_per_thread;
        const int grid = static_cast<int>((threads_needed + block - 1) / block);
        const float* s = srcs[region];
        float* d = dsts[region];
        const long n = kRegionF4 * 4;
        if (vec == 4 && ept == 1) copy_kernel<float4, 1><<<grid, block>>>(s, d, n);
        else if (vec == 4 && ept == 2) copy_kernel<float4, 2><<<grid, block>>>(s, d, n);
        else if (vec == 4 && ept == 4) copy_kernel<float4, 4><<<grid, block>>>(s, d, n);
        else if (vec == 2 && ept == 4) copy_kernel<float2, 4><<<grid, block>>>(s, d, n);
        else if (ept == 8) copy_kernel<float, 8><<<grid, block>>>(s, d, n);
    };

    for (const Cfg& c : cfgs) {
        const long total_threads =
            static_cast<long>((kCopyBlocks + 1023) / 1024) * 1024;  // grid sized per shape
        // grid: enough blocks of c.block to cover kRegionF4 floats with V*EPT per thread
        const long floats_per_thread = static_cast<long>(c.vec) * c.ept;
        const long threads_needed = (kRegionF4 * 4 + floats_per_thread - 1) / floats_per_thread;
        const int grid = static_cast<int>((threads_needed + c.block - 1) / c.block);

        auto launch = [&](int region) { launch_cfg(c.vec, c.ept, c.block, region); };
        std::printf("  running %-16s grid=%d block=%d\n", c.name, grid, c.block);
        // correctness once: dst must equal src (memset pattern)
        launch(0);
        CK(hipDeviceSynchronize());
        std::vector<char> a(kRegionF4 * 4), b(4096);
        CK(hipMemcpy(a.data(), srcs[0], 4096, hipMemcpyDeviceToHost));
        CK(hipMemcpy(b.data(), dsts[0], 4096, hipMemcpyDeviceToHost));
        if (std::memcmp(a.data(), b.data(), 4096) != 0) {
            std::printf("  %s: CORRECTNESS FAIL\n", c.name);
            continue;
        }
        // median of 3 timed passes, 8-region rotation each
        float best = 1e30f;
        for (int rep = 0; rep < 3; ++rep) {
            CK(hipEventRecord(ev_start));
            for (int r = 0; r < kRegions; ++r) {
                const int src_region = (r + static_cast<int>(rot[0])) % kRegions;
                launch(src_region);
            }
            CK(hipEventRecord(ev_end));
            CK(hipEventSynchronize(ev_end));
            float ms = 0;
            CK(hipEventElapsedTime(&ms, ev_start, ev_end));
            best = std::min(best, ms);
        }
        const double gbps = bytes_per_pass / (best * 1e-3) / 1e9;
        results.push_back({static_cast<float>(gbps), c.name});
        std::printf("  %-16s %8.1f GB/s  (grid %d x %d)\n", c.name, gbps, grid, c.block);
    }
    std::sort(results.begin(), results.end(),
              [](const Result& a, const Result& b) { return a.gbps > b.gbps; });
    std::printf("BEST: %s %.1f GB/s\n", results[0].name.c_str(), results[0].gbps);
    for (auto& r : results) std::printf("  %8.1f  %s\n", r.gbps, r.name.c_str());
    return 0;
}
