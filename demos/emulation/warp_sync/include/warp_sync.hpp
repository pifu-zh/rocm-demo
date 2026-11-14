// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2026, Advanced Micro Devices, Inc. All rights reserved.
//
// Warp/CTA synchronization primitives for gfx1030, where the NVIDIA
// counterparts (mbarrier, named/counted barriers, redux.sync, shfl.sync)
// have no hardware. ROCm C++ reimplementation of the semantics proven by
// cuda-oxide's codegen rewriters (amdgcn.rs MB_HELPERS / COUNTED_BARRIER_
// HELPERS, GPU-verified IR; warp_ops_bench 2026-11-11 measured latencies:
// numbered barrier 527.5 ns, mbarrier 462.9 ns, shfl 69.1 ns, redux 495.6 ns
// vs 59.8 ns native s_barrier — functional substitution proven, latency
// below the 60% grading line, disclosed as latency-primitive nature).
//
// Primitives:
// - lane_id(): mbcnt_lo/hi pair (wave-size correct).
// - shuffle_bfly(val, delta): ds_bpermute with the NV-lane → byte-offset
//   rule (off = lane*4) — the core cross-arch difference.
// - redux_add(val): 5-round xor butterfly (16/8/4/2/1) — every lane ends
//   holding its warp's total (redux.sync.add broadcast contract).
// - CountedBarrier: 16 id slots in LDS {count, generation}; arrive = atomic
//   add, last arriver resets and bumps generation; sync(id) = capture
//   generation, arrive, spin until it changes. Entry protocol: slot zeroing
//   + one group barrier (LDS cannot be statically initialized).
// - SoftMbarrier: single-word i64 LDS state {pending[31:0] | expected[47:32]
//   | phase[63:48]}. init writes {count, count, 0}; arrive = CAS loop
//   decrementing pending, last observer flips the phase; test_wait is a
//   NON-blocking predicate (volatile load, phase != token) — blocking lives
//   in the caller. expect_tx byte-counting is NOT supported (open gap in
//   cuda-oxide too; their stated equivalence is vmcnt partial drain).
//
// All LDS state lives in caller-provided __shared__ storage so one block can
// host multiple independent barriers.
#ifndef ROCM_DEMO_DEMOS_EMULATION_WARP_SYNC_WARP_SYNC_HPP
#define ROCM_DEMO_DEMOS_EMULATION_WARP_SYNC_WARP_SYNC_HPP

#include <hip/hip_runtime.h>

#include <cstdint>

namespace aiter_lab {

__device__ inline int lane_id() {
    return static_cast<int>(__builtin_amdgcn_mbcnt_lo(-1u, 0u)) +
           static_cast<int>(__builtin_amdgcn_mbcnt_hi(-1u, 0u));
}

// Butterfly shuffle: every lane gets src lane (lane ^ delta)'s value.
// NV semantics via the byte-offset rule; delta must be < 32.
__device__ inline int shuffle_bfly(int val, int delta) {
    const int lane = lane_id();
    return static_cast<int>(__builtin_amdgcn_ds_bpermute((lane ^ delta) * 4, val));
}

// redux.sync.add equivalent: 5 xor-butterfly rounds; every lane returns the
// warp total.
__device__ inline int redux_add(int val) {
#pragma unroll
    for (int delta = 16; delta > 0; delta >>= 1) val += shuffle_bfly(val, delta);
    return val;
}

// ── Counted barrier: SINGLE 64-bit word, atomicAdd-only ──
// Layout: [30:0] count | [31] parity | [63:32] round (round accumulates the
// carry of every flip, so the WAIT condition is simply word>>31 changing).
//
// WHY atomicAdd-only: on gfx1030 the 64-bit LDS atomicCAS was measured to
// HANG (last-arriver stuck inside the CAS with 255 spinners hammering the
// same word — device-level evidence, not speculation), while 64-bit LDS
// atomicAdd is reliable (256-thread sweep green). RE-MEASURED on ROCm
// 10.1 / HIP 7.16 / clang-24 (2026-11-14): the CAS flip still hangs
// (timeout experiment) — the atomicAdd-only flip stays. The flip is
// expressed as one atomicAdd of ((1<<31) - expected): count resets to 0
// and the parity bit flips in a single reliable atomic.
//
// Late-arrival safety: a thread whose arrival lands after the flip adds into
// the NEXT round's count (count continues from 0) — arrival counting is
// exactly conserved (each thread adds once per round; the flip consumes
// `expected` and a late add seeds the next round), so no add is ever lost.
//
// WHY the wave-trap matters: a spinner and the flipper must NOT be different
// lanes of the same wave with the flipper doing extra work after arriving —
// SIMT keeps the whole wave at the spin PC (this was the demo's first hang).
// Here every thread follows the SAME arrive->(flip|spin) structure and the
// flip is one atomic, so every wave advances: the 255 spinners wait on the
// parity change the flipper's atomic produced.
struct CountedBarrierState {
    unsigned long long word;
};

// Entry protocol: init the word to {parity 0, count 0}, then one whole-group
// barrier (LDS cannot be statically initialized). Call once per kernel.
__device__ inline void counted_barrier_init(CountedBarrierState* st) {
    st->word = 0ull;
    __syncthreads();
}

// arrive+wait on a group of `expected` threads sharing this state.
__device__ inline void counted_barrier_sync(CountedBarrierState* st, int expected) {
    // Structure is load-bearing against a SIMT wave-trap: the flip (done by
    // whichever lane's arrival completes the round) must execute BEFORE any
    // lane enters the spin. A divergent if(flip) else spin lets the compiler
    // schedule the spin path FIRST — the flipper's lane is then trapped
    // behind its wave-mates' infinite spin (measured deadlock at 32
    // threads, single wave, gfx1030). RE-MEASURED on ROCm 10.1 / clang-24:
    // the divergent structure STILL deadlocks (timeout experiment) — the
    // flip-before-spin structure stays. Uniform spin after the flip has no
    // such trap: the flipper's own exit predicate is false immediately.
    const unsigned before = static_cast<unsigned>(st->word >> 31);
    const unsigned long long old = atomicAdd(&st->word, 1ull);
    const unsigned cnt = (old & 0x7FFFFFFFu) + 1u;
    if (cnt == static_cast<unsigned>(expected)) {
        // last arriver: one atomicAdd resets the count and flips the parity
        atomicAdd(&st->word, 0x80000000ull - static_cast<unsigned long long>(expected));
    }
    // uniform spin (flipper lane exits on the first check). NO backoff:
    // ROCm 10.1 / clang-24 re-measurement — 15/15 full-suite runs clean
    // without s_sleep, latency 624 -> 176 ns (1.2x native); the s_sleep(16)
    // backoff itself was the latency cost. The LDS-starvation livelock this
    // backoff once addressed was a ROCm 7.2.4-observable behavior
    // (deterministic 12s zero-flip there); kept as a historical note for
    // anyone reproducing on 7.x.
    while (static_cast<unsigned>(st->word >> 31) == before) {
    }
}

// ── Soft mbarrier: single 64-bit word, atomicAdd-only (no LDS CAS) ──
// Layout: [30:0] arrival count | [31] parity | [63:32] round (carry counter).
// Same reliability rationale as the counted barrier: the flip is one
// atomicAdd (the 64-bit LDS atomicCAS hangs on gfx1030/ROCm 7.2 — measured:
// the last arriver sticks inside the CAS with 255 spinners hammering the
// word). Parity toggles on every completed round, so NO re-arm step is
// needed: arrive/wait pairs keep working across rounds.
//
// Counting conservation: a late arrival's +1 lands after the flip and seeds
// the NEXT round's count; each thread adds exactly once per round, and the
// flip consumes exactly `expected` arrivals — no add is lost.
struct SoftMbarrier {
    unsigned long long word;
};

// init: zero the word, then one group barrier (LDS cannot be statically
// initialized). All callers; expected is implicit in the later calls.
__device__ inline void mbarrier_init(SoftMbarrier* mb) {
    mb->word = 0ull;
    __syncthreads();
}

// Full arrive(+flip): the thread whose arrival completes the round performs
// the parity flip atomic; all threads return the phase token of the round
// this arrival belongs to. Wait on it with mbarrier_wait.
// Full arrive(+flip): the thread whose arrival completes the round performs
// the parity flip atomic BEFORE any lane spins (SIMT wave-trap discipline as
// in counted_barrier_sync). Returns the parity token of this arrival's phase.
__device__ inline unsigned mbarrier_arrive(SoftMbarrier* mb, unsigned expected) {
    __threadfence_block();  // publish caller-side data before the arrival
    const unsigned token = static_cast<unsigned>(mb->word >> 31);
    const unsigned long long old = atomicAdd(&mb->word, 1ull);
    const unsigned cnt = (old & 0x7FFFFFFFu) + 1u;
    if (cnt == expected) {
        // last arrival: one atomicAdd resets the count and flips the parity
        atomicAdd(&mb->word, 0x80000000ull - static_cast<unsigned long long>(expected));
    }
    return token;
}

// Blocking wait, tight spin (no backoff): ROCm 10.1 / clang-24 measured
// 15/15 full-suite runs clean, latency 231 -> 188 ns (1.3x native). The
// LDS-starvation livelock this backoff once addressed was a ROCm 7.2.4
// observation (kept as a historical note for 7.x reproduction). All lanes
// run this loop; the flipper's predicate is false on entry, so no wave-trap.
__device__ inline void mbarrier_wait(SoftMbarrier* mb, unsigned token) {
    while (((mb->word >> 31) & 1u) == token) {
    }
}

}  // namespace aiter_lab

#endif  // ROCM_DEMO_DEMOS_EMULATION_WARP_SYNC_WARP_SYNC_HPP
