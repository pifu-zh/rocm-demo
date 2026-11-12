// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2026, Advanced Micro Devices, Inc. All rights reserved.
//
// Soft-TMA: deep-pipelined gmem→LDS→consume without async-copy hardware
// (gfx1030 / RDNA2). ROCm C++ reimplementation of the design proven by the
// cuda-oxide soft-TMA research line (scripts/soft_tma_bench/gen_kernels.py
// `lds_bN`, closed 2026-11-04 at 553 GB/s = 96.1% of the 575.5 GB/s
// empirical ceiling), whose upstream inspiration is aiter's own
// s_clause-batch + vmcnt(N) partial-drain software pipelining.
//
// Pipeline (one wave32 per block; each lane moves one 16 B quad-slice of
// every 512 B quad):
//   prologue: issue up to BATCH float4 loads into register group A
//   loop:     issue next BATCH into group B   (stays in flight)
//             s_waitcnt vmcnt(BATCH)           <- PARTIAL drain: guarantees
//                                                group A landed while group B
//                                                is still outstanding
//             write group A -> LDS slot (phase)
//             s_waitcnt lgkmcnt(0)             <- LDS write visible
//             read back + f32 accumulate
//             flip LDS phase (double buffer)
//   tail:     s_waitcnt vmcnt(0) for the last (possibly partial) group, then
//             remaining quads go through LDS serially (no overlap — same
//             shape as the ISA kernel's parity tails).
//
// The load-bearing instruction is the vmcnt(N) PARTIAL drain — plain HIP has
// no builtin for it; this header carries it via inline asm (constraint "n":
// BATCH is a compile-time immediate, required by the s_waitcnt encoder).
// Verified on gfx1030/ROCm 7.2: hipcc accepts it and the explicit wait
// survives the LLVM amdgcn backend without extra drains (cuda-oxide
// catalogue §3 item 4).
//
// Register group ping-pong keeps up to 2×BATCH float4 in flight → depth
// rule: outstanding vector-memory ops ≤ 63 → BATCH ≤ 21 (upstream ran
// B = 4/8/16). LDS budget: 2 × BATCH × 512 B.
#ifndef ROCM_DEMO_DEMOS_EMULATION_SOFT_TMA_SOFT_TMA_HPP
#define ROCM_DEMO_DEMOS_EMULATION_SOFT_TMA_SOFT_TMA_HPP

#include <hip/hip_runtime.h>

#include <cstddef>
#include <cstdint>

namespace aiter_lab {

template <int BATCH>
__global__ void __launch_bounds__(32) soft_tma_reduce(const float4* __restrict__ src,
                                                      float4* __restrict__ out,
                                                      int quads_per_block) {
    static_assert(BATCH >= 1 && BATCH <= 21, "outstanding VM ops must stay <= 63");
    __shared__ float4 lds[2 * BATCH * 32];
    static_assert(sizeof(lds) <= 64 * 1024, "LDS budget (64 KiB/CU)");

    const int lane = threadIdx.x & 31;
    const long quad_base = static_cast<long>(blockIdx.x) * quads_per_block;
    const int total = quads_per_block;
    float4 acc = {0.f, 0.f, 0.f, 0.f};

    // Register groups are ping-ponged by DUPLICATING the loop body (ISA
    // style, cf. lds_b4's loop_a + two parity tails). A `groupA = groupB`
    // array copy inside a dynamic loop makes the compiler spill both groups
    // to local memory (measured ~1000x slowdown); duplicated constant-index
    // bodies keep everything in registers.
    float4 gA[BATCH], gB[BATCH];
    int issued = 0;  // quads handed to the memory system so far
    int nA = 0;      // valid entries in gA (BATCH except after the prologue)
    int phase = 0;

    auto consume = [&](float4* slot_base, int valid) {
        asm volatile("s_waitcnt lgkmcnt(0)" ::: "memory");
        for (int b = 0; b < valid; ++b) {
            const float4 v = slot_base[b * 32 + lane];
            acc.x += v.x;
            acc.y += v.y;
            acc.z += v.z;
            acc.w += v.w;
        }
    };

    // Prologue: issue up to BATCH quads into gA.
    for (; nA < BATCH && issued < total; ++nA, ++issued) {
        gA[nA] = src[(quad_base + issued) * 32 + lane];
    }

    // Main loop: two duplicated halves (register ping-pong by body, not by
    // copy — a group-copy in a dynamic loop spills to local memory). Each
    // half: issue into the OTHER group only when a full batch remains, then
    // drain+consume the CURRENT group. Invariant: at half-A entry nA
    // describes gA; at half-B entry nA describes gB.
    while (true) {
        // ── Half A: prev = gA (nA entries in flight), next = gB ──
        const bool fullA = (total - issued) >= BATCH;
        if (fullA) {
            for (int b = 0; b < BATCH; ++b, ++issued) {
                gB[b] = src[(quad_base + issued) * 32 + lane];
            }
            asm volatile("s_waitcnt vmcnt(%0)" :: "n"(BATCH));  // gA landed
        } else {
            asm volatile("s_waitcnt vmcnt(0)" ::: "memory");
        }
        {
            float4* slot = lds + phase * BATCH * 32;
            for (int b = 0; b < nA; ++b) slot[b * 32 + lane] = gA[b];
            consume(slot, nA);
            phase ^= 1;
        }
        if (!fullA) {
            nA = 0;
            break;
        }
        nA = BATCH;  // gB is now the in-flight group

        // ── Half B: prev = gB, next = gA ──
        const bool fullB = (total - issued) >= BATCH;
        if (fullB) {
            for (int b = 0; b < BATCH; ++b, ++issued) {
                gA[b] = src[(quad_base + issued) * 32 + lane];
            }
            asm volatile("s_waitcnt vmcnt(%0)" :: "n"(BATCH));  // gB landed
        } else {
            asm volatile("s_waitcnt vmcnt(0)" ::: "memory");
        }
        {
            float4* slot = lds + phase * BATCH * 32;
            for (int b = 0; b < nA; ++b) slot[b * 32 + lane] = gB[b];
            consume(slot, nA);
            phase ^= 1;
        }
        if (!fullB) {
            nA = 0;
            break;
        }
        nA = BATCH;  // gA is in flight again
    }

    // Tail: drain whatever group A still holds (nA == 0 when nothing is in
    // flight), then quads never issued (< BATCH) go through LDS serially.
    asm volatile("s_waitcnt vmcnt(0)" ::: "memory");
    {
        float4* slot = lds + phase * BATCH * 32;
        for (int b = 0; b < nA; ++b) slot[b * 32 + lane] = gA[b];
        consume(slot, nA);
        phase ^= 1;
    }
    for (; issued < total; ++issued) {
        const float4 v_in = src[(quad_base + issued) * 32 + lane];
        float4* s = lds + phase * BATCH * 32;
        s[lane] = v_in;
        asm volatile("s_waitcnt lgkmcnt(0)" ::: "memory");
        const float4 v = s[lane];
        acc.x += v.x;
        acc.y += v.y;
        acc.z += v.z;
        acc.w += v.w;
    }

    out[static_cast<long>(blockIdx.x) * 32 + lane] = acc;
}

// Host launcher. blocks*32 threads; each block reduces quads_per_block
// quads (its slice [block*qpb, (block+1)*qpb)). BATCH in {1..21}; 4/8/16 are
// the upstream-verified depths.
template <int BATCH>
hipError_t launch_soft_tma_reduce(const float4* src, float4* out, int blocks,
                                  int quads_per_block, hipStream_t stream = nullptr) {
    soft_tma_reduce<BATCH><<<blocks, 32, 0, stream>>>(src, out, quads_per_block);
    return hipGetLastError();
}

}  // namespace aiter_lab

#endif  // ROCM_DEMO_DEMOS_EMULATION_SOFT_TMA_SOFT_TMA_HPP
