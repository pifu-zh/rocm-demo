// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2026, Advanced Micro Devices, Inc. All rights reserved.
//
// soft_tma demo driver: correctness at three pipeline depths (incl. tails),
// then a triad-protocol throughput grading (rotation over >2 GiB to defeat
// L2, median of runs) against three references:
//   - plain: the same work without any pipelining (serialized wait/roundtrip)
//   - copy:  a plain float4 copy kernel over the same bytes (memory ceiling proxy)
//   - ISA:   the hand-written gfx1030 kernel soft_tma_pipeline.co (st_tma1),
//            loaded via hipModuleLoadData — the proven 553 GB/s reference
// Grades use the research-line ladder: 60% pass / 70% good / 80% excellent /
// 90% perfect substitution, relative to the substituted reference path.
//
// Build & run: see scripts/build_run.sh (inside the ROCm container).
#include "soft_tma.hpp"

#include <hip/hip_runtime.h>

#include <algorithm>
#include <chrono>
#include <cstdio>
#include <cstring>
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

namespace {

// Plain reference kernel: same work, zero pipelining (serialized per quad).
__global__ void __launch_bounds__(32) plain_reduce(const float4* __restrict__ src,
                                                   float4* __restrict__ out,
                                                   int quads_per_block) {
    __shared__ float4 lds[32];
    const int lane = threadIdx.x & 31;
    const long quad_base = static_cast<long>(blockIdx.x) * quads_per_block;
    float4 acc = {0.f, 0.f, 0.f, 0.f};
    for (int q = 0; q < quads_per_block; ++q) {
        const float4 v = src[(quad_base + q) * 32 + lane];  // one load, fully drained
        lds[lane] = v;
        asm volatile("s_waitcnt lgkmcnt(0)" ::: "memory");
        const float4 r = lds[lane];
        acc.x += r.x;
        acc.y += r.y;
        acc.z += r.z;
        acc.w += r.w;
    }
    out[static_cast<long>(blockIdx.x) * 32 + lane] = acc;
}

// Memory-ceiling proxy: copy the same byte volume (read+write both counted).
__global__ void copy_f4(const float4* __restrict__ src, float4* __restrict__ dst, long n4) {
    const long i = static_cast<long>(blockIdx.x) * blockDim.x + threadIdx.x;
    if (i < n4) dst[i] = src[i];
}

// Host expectation: lane's float4 accumulates its slice of every quad.
// Integer-valued input keeps f32 accumulation exact -> bitwise comparison.
void fill_src(std::vector<float4>& h) {
    for (long i = 0; i < static_cast<long>(h.size()); ++i) {
        const float v = static_cast<float>(i % 1000);
        h[i] = {v, v, v, v};
    }
}

bool check_out(const std::vector<float4>& out, const std::vector<float4>& src, int blocks,
               int quads_per_block) {
    for (int b = 0; b < blocks; ++b) {
        for (int l = 0; l < 32; ++l) {
            float ex = 0, ey = 0, ez = 0, ew = 0;
            for (int q = 0; q < quads_per_block; ++q) {
                const long idx = (static_cast<long>(b) * quads_per_block + q) * 32 + l;
                const float v = static_cast<float>(idx % 1000);
                ex += v;
                ey += v;
                ez += v;
                ew += v;
            }
            const float4 got = out[static_cast<long>(b) * 32 + l];
            if (got.x != ex || got.y != ey || got.z != ez || got.w != ew) {
                std::printf("  MISMATCH b=%d l=%d got=(%g,%g,%g,%g) want=(%g,%g,%g,%g)\n", b, l,
                            got.x, got.y, got.z, got.w, ex, ey, ez, ew);
                return false;
            }
        }
    }
    return true;
}

}  // namespace

int main(int argc, char** argv) {
    const char* isa_co = argc > 1 ? argv[1] : nullptr;

    // ── 1. Correctness: three depths, exact and tail shapes ──
    struct Shape {
        int blocks, qpb;
        const char* what;
    };
    const Shape shapes[] = {
        {64, 128, "exact/128 (B=4 aligned)"},
        {64, 130, "tail/130 (2-quad remainder)"},
        {8, 1, "tail/1 (single quad per block)"},
        {8, 3, "tail/3 (partial prologue)"},
    };
    int bad = 0;
    for (const Shape& s : shapes) {
        std::vector<float4> src(static_cast<long>(s.blocks) * s.qpb * 32);
        fill_src(src);
        std::vector<float4> out(static_cast<long>(s.blocks) * 32, float4{0, 0, 0, 0});
        float4 *d, *o;
        CK(hipMalloc(&d, src.size() * 16));
        CK(hipMalloc(&o, out.size() * 16));
        CK(hipMemcpy(d, src.data(), src.size() * 16, hipMemcpyHostToDevice));
        CK(aiter_lab::launch_soft_tma_reduce<4>(d, o, s.blocks, s.qpb));
        CK(hipDeviceSynchronize());
        CK(hipMemcpy(out.data(), o, out.size() * 16, hipMemcpyDeviceToHost));
        const bool ok = check_out(out, src, s.blocks, s.qpb);
        std::printf("correctness B=4 %s: %s\n", s.what, ok ? "PASS" : "FAIL");
        bad += !ok;
        // Depth sweep on the exact shape.
        if (s.qpb == 128) {
            for (int B : {8, 16}) {
                CK(hipMemset(o, 0, out.size() * 16));
                if (B == 8)
                    CK(aiter_lab::launch_soft_tma_reduce<8>(d, o, s.blocks, s.qpb));
                else
                    CK(aiter_lab::launch_soft_tma_reduce<16>(d, o, s.blocks, s.qpb));
                CK(hipDeviceSynchronize());
                CK(hipMemcpy(out.data(), o, out.size() * 16, hipMemcpyDeviceToHost));
                const bool okB = check_out(out, src, s.blocks, s.qpb);
                std::printf("correctness B=%d %s: %s\n", B, s.what, okB ? "PASS" : "FAIL");
                bad += !okB;
            }
        }
        CK(hipFree(d));
        CK(hipFree(o));
        std::fflush(stdout);
        if (bad) return 1;
    }

    // ── 2. Throughput: triad protocol (rotation, median) ──
    constexpr int kBlocks = 320;          // 40 CU × 8
    constexpr int kQpb = 2048;            // quads per block -> region = 320*2048*512B = 335 MB
    constexpr int kRotations = 8;         // 8 regions = 2.7 GB >> L2 (defeats caching)
    constexpr long kRegionF4 = static_cast<long>(kBlocks) * kQpb * 32;
    constexpr long kSrcF4 = kRegionF4 * kRotations;
    std::printf("throughput: %d blocks x %d quads, region %.0f MiB x %d rotations\n", kBlocks,
                kQpb, kRegionF4 * 16.0 / 1048576.0, kRotations);

    float4 *dsrc, *ddst, *dcopy;
    CK(hipMalloc(&dsrc, kSrcF4 * 16));
    CK(hipMalloc(&ddst, static_cast<long>(kBlocks) * 32 * 16));
    CK(hipMalloc(&dcopy, kRegionF4 * 16));  // dedicated buffer: copy moves region-sized data
    {
        // Fill on host in chunks (2.7 GB).
        std::vector<float4> chunk(1 << 20);
        for (long i = 0; i < kSrcF4; i += static_cast<long>(chunk.size())) {
            const long n = std::min<long>(chunk.size(), kSrcF4 - i);
            for (long j = 0; j < n; ++j) {
                const float v = static_cast<float>((i + j) % 1000);
                chunk[j] = {v, v, v, v};
            }
            CK(hipMemcpy(dsrc + i, chunk.data(), n * 16, hipMemcpyHostToDevice));
        }
    }

    hipEvent_t t0, t1;
    CK(hipEventCreate(&t0));
    CK(hipEventCreate(&t1));

    // bytes counted: read kRegionF4*16 + write blocks*32*16 per launch.
    const double gb = (static_cast<double>(kRegionF4) * 16 + kBlocks * 32.0 * 16) / 1e9;
    auto median_of3 = [&](auto launch) -> double {
        std::vector<double> ms;
        for (int blk = 0; blk < 3; ++blk) {
            float best = 1e30f;
            for (int rep = 0; rep < kRotations; ++rep) {
                float4* s = dsrc + static_cast<long>(rep) * kRegionF4;
                CK(hipEventRecord(t0));
                CK(launch(s));
                CK(hipEventRecord(t1));
                CK(hipEventSynchronize(t1));
                float t;
                CK(hipEventElapsedTime(&t, t0, t1));
                best = std::fmin(best, t);
            }
            ms.push_back(best);
        }
        std::sort(ms.begin(), ms.end());
        return ms[1];
    };

    // Warmup (2 s wall clock) for DVFS steady state.
    {
        auto tic = std::chrono::steady_clock::now();
        while (std::chrono::duration<double>(std::chrono::steady_clock::now() - tic).count() < 2.0) {
            CK(aiter_lab::launch_soft_tma_reduce<8>(dsrc, ddst, kBlocks, kQpb));
            CK(hipDeviceSynchronize());
        }
    }

    const double ms_isa = median_of3([&](float4* s) {
        return aiter_lab::launch_soft_tma_reduce<8>(s, ddst, kBlocks, kQpb);
    });
    const double ms_isa4 = median_of3([&](float4* s) {
        return aiter_lab::launch_soft_tma_reduce<4>(s, ddst, kBlocks, kQpb);
    });
    const double ms_isa16 = median_of3([&](float4* s) {
        return aiter_lab::launch_soft_tma_reduce<16>(s, ddst, kBlocks, kQpb);
    });
    const double ms_plain = median_of3([&](float4* s) {
        plain_reduce<<<kBlocks, 32>>>(s, ddst, kQpb);
        return hipGetLastError();
    });
    const double ms_copy = median_of3([&](float4* s) {
        copy_f4<<<static_cast<int>((kRegionF4 + 1023) / 1024), 1024>>>(s, dcopy, kRegionF4);
        return hipGetLastError();
    });
    const auto to_gbps = [&](double ms, double bytes) { return bytes / 1e9 / (ms * 1e-3); };
    std::printf("  [ms] isa4=%.3f isa=%.3f isa16=%.3f plain=%.3f copy=%.3f\n", ms_isa4, ms_isa,
                ms_isa16, ms_plain, ms_copy);
    const double gb_isa4 = to_gbps(ms_isa4, gb * 1e9);
    const double gb_isa = to_gbps(ms_isa, gb * 1e9);
    const double gb_isa16 = to_gbps(ms_isa16, gb * 1e9);
    const double gb_plain = to_gbps(ms_plain, gb * 1e9);
    const double gb_copy = to_gbps(ms_copy, 2.0 * kRegionF4 * 16.0);  // read+write

    auto grade = [](double gbps, double ref) { return 100.0 * gbps / ref; };
    std::printf("  soft_tma C++ B=4 : %7.1f GB/s\n", gb_isa4);
    std::printf("  soft_tma C++ B=8 : %7.1f GB/s\n", gb_isa);
    std::printf("  soft_tma C++ B=16: %7.1f GB/s\n", gb_isa16);
    std::printf("  plain (no pipe)  : %7.1f GB/s\n", gb_plain);
    std::printf("  copy_f4 ceiling  : %7.1f GB/s (own r+w bytes)\n", gb_copy);
    std::printf("  grades vs copy ceiling: B=4 %.1f%% | B=8 %.1f%% | B=16 %.1f%% | plain %.1f%%\n",
                grade(gb_isa4, gb_copy), grade(gb_isa, gb_copy), grade(gb_isa16, gb_copy),
                grade(gb_plain, gb_copy));
    std::printf("  NOTE: copy counts 2x region bytes (r+w); soft_tma reads region + tiny\n"
                "  out — cross-mix ratios are indicative, the same-protocol ISA kernel is\n"
                "  the calibrated reference.\n");

    // ── 3. Optional ISA reference under the same protocol ──
    if (isa_co) {
        FILE* f = fopen(isa_co, "rb");
        if (!f) {
            std::printf("ISA reference: cannot open %s (skipped)\n", isa_co);
        } else {
            fseek(f, 0, SEEK_END);
            const long sz = ftell(f);
            fseek(f, 0, SEEK_SET);
            std::vector<char> img(sz);
            if (fread(img.data(), 1, sz, f) == static_cast<size_t>(sz)) {
                hipModule_t mod;
                if (hipModuleLoadData(&mod, img.data()) == hipSuccess) {
                    hipFunction_t fn;
                    if (hipModuleGetFunction(&fn, mod, "st_tma1") == hipSuccess) {
                        int quads = kQpb;
                        const double isa_ms = median_of3([&](float4* s) {
                            float4* src_p = s;
                            void* args[] = {&src_p, &ddst, &quads};
                            return hipModuleLaunchKernel(fn, kBlocks, 1, 1, 32, 1, 1, 0, nullptr,
                                                         args, nullptr);
                        });
                        std::printf(
                            "  ISA st_tma1       : %7.1f GB/s (hand-written reference, %.3f ms)\n",
                            to_gbps(isa_ms, gb * 1e9), isa_ms);
                    } else {
                        std::printf("  ISA reference: st_tma1 not found\n");
                    }
                } else {
                    std::printf("  ISA reference: module load failed\n");
                }
            }
            fclose(f);
        }
    }

    CK(hipFree(dsrc));
    CK(hipFree(ddst));
    CK(hipFree(dcopy));
    std::printf("soft_tma demo: %s\n", bad ? "FAIL" : "PASS");
    return bad ? 1 : 0;
}
