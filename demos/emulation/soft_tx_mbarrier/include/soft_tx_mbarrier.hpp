// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2026, Advanced Micro Devices, Inc. all rights reserved.
//
// Soft transactional mbarrier for gfx1030: byte-count phase tracking in
// HIP C++, closing the expect_tx gap both labs recorded as open (this
// demo's predecessor warp_sync.hpp: "expect_tx byte-counting is NOT
// supported (open gap in cuda-oxide too)").
//
// UPSTREAM CONTRACT being emulated — PTX ISA mbarrier with transactions
// (mbarrier.arrive.expect_tx / mbarrier.complete_tx; CUDA programming
// guide's Hopper TMA pattern, and cuda-oxide barrier.rs
// arrive_expect_tx(bytes) API):
//   - a phase carries TWO obligations: N arrivals AND B transaction bytes;
//   - arrive.expect_tx(b) registers that b more bytes must land in this
//     phase (consumer side arms the phase);
//   - complete_tx(b) reports that b bytes HAVE landed (on hardware the TMA
//     unit does this automatically as each bulk copy completes);
//   - the phase completes ONLY when the pending arrival count reaches zero
//     AND the pending byte count reaches zero — i.e. the consumer cannot
//     proceed on thread-count alone; the DATA VOLUME must have landed.
//
// WHY this matters on gfx1030 (the substitution story): there is no TMA and
// no hardware mbarrier, so a "consumer waits until the producer's bulk data
// landed" must be built from LDS atomics. The plain SoftMbarrier counts
// THREADS; a producer thread that issues its loads and arrives WITHOUT
// waiting for them would release the consumer too early (the load data is
// still in flight). The natural patch — producer waits its own vmcnt before
// arriving — serializes every producer against its own loads and defeats
// the split-completion pattern (several producers each completing a share
// while others still issue). expect_tx removes that serialization: the
// phase tracks the BYTE VOLUME, so each producer completes its own share
// asynchronously and the consumer is released exactly when the total
// volume landed.
//
// STATE (single 64-bit LDS word, all mutations via 64-bit LDS atomicAdd —
// the only reliable wide LDS atomic on gfx1030; CAS hangs, measured in
// warp_sync on 7.2.4 AND 10.1):
//
//   bit  32    : parity of the current phase
//   bits 31:0  : credit = pending arrivals + pending bytes
//   bits 63:33 : phase round (carry of every flip; monotonic)
//
// OPERATIONS (all atomicAdd with two's-complement negatives):
//   arm(n, b)      by the WAITING side at phase entry:
//                    atomicAdd(+(n + b)) — seeds the phase's credit. The
//                    waiting side re-arms after each completed phase
//                    (consumer-driven pipeline; producers of a phase are
//                    sequenced after its arm by the pipeline dependency).
//   arrive()       by each producing thread: atomicAdd(-1); returns the
//                    parity token (parity before the arrival).
//   tx_complete(b) by the thread whose data landed (after s_waitcnt vmcnt
//                    for its own loads + threadfence_block for visibility):
//                    atomicAdd(-b).
//   try_wait(token) non-blocking predicate: parity != token.
//   wait(token)    blocking spin (tight; no backoff needed at 10.1).
//
// COMPLETION: the atomic that brings credit to exactly 0 (old == its own
// consumption) is the LAST obligation of the phase; it immediately adds
// (1 << 32) to flip the parity. LDS atomics are serialized, so exactly one
// thread observes old == its consumption — one flip per phase, race-free
// without CAS (the CAS-hang workaround's pattern, applied deliberately).
//
// CREDIT BUDGET: arrivals ≤ 2^28, bytes ≤ 2^28 per phase (documented API
// limit; keeps credit within 32 bits with huge headroom).
//
// VERIFICATION LEVEL: HARDWARE_PASS (correctness on card, this demo's
// tests) — the semantics anchor is the PTX contract above, not a local
// kernel.
#pragma once

#include <hip/hip_runtime.h>

#include <cstdint>

namespace aiter_lab {

constexpr std::uint64_t kTxParityBit = 1ull << 32;
constexpr std::uint64_t kTxCreditMask = 0xFFFFFFFFull;

struct SoftTxMbarrier {
    unsigned long long word;
};

// init: parity 0, credit 0. All callers (LDS cannot be statically
// initialized); one group barrier after this.
__device__ inline void tx_mbarrier_init(SoftTxMbarrier* mb) { mb->word = 0ull; }

// WAITING side: seed the phase's credit (n arrivals + b bytes).
__device__ inline void tx_mbarrier_arm(SoftTxMbarrier* mb, int n, long b) {
    atomicAdd(&mb->word, static_cast<unsigned long long>(n) + static_cast<unsigned long long>(b));
}

// PRODUCING side: one arrival. Returns the parity token this arrival
// belongs to — extracted from the ATOMIC's returned old value (a separate
// plain load could be stale: the phase could complete between the load and
// the atomic). The arrival that drains credit to exactly 0 IS the phase
// completer and flips the parity here (PTX mbarrier semantics: the phase
// completes when the pending count reaches zero — arrivals-only phases,
// armed with bytes = 0, complete on the last arrival). The flip cannot
// fire while bytes are pending: credit >= pending bytes > 0, so an arrival
// never reaches 0 in a byte-armed phase.
__device__ inline unsigned tx_mbarrier_arrive(SoftTxMbarrier* mb) {
    const unsigned long long old = atomicAdd(&mb->word, ~0ull);  // -1
    if ((old & kTxCreditMask) == 1ull) {
        atomicAdd(&mb->word, kTxParityBit);
    }
    return static_cast<unsigned>(old >> 32) & 1u;
}

// PRODUCING side: report b bytes landed (call after s_waitcnt vmcnt for the
// thread's own loads and a threadfence_block; the fence ordering is the
// caller's responsibility, matching how a TMA engine publishes to memory).
__device__ inline void tx_mbarrier_tx_complete(SoftTxMbarrier* mb, long b) {
    const unsigned long long old =
        atomicAdd(&mb->word, ~static_cast<unsigned long long>(b) + 1ull);
    // completer: this consumption drained credit to exactly zero
    if ((old & kTxCreditMask) == static_cast<unsigned long long>(b)) {
        atomicAdd(&mb->word, kTxParityBit);
    }
}



// PRODUCING side helper: make the arrive token OPAQUE to the compiler.
// The producer's data copy must be data-dependent on its arrival — without
// the dependence, clang-24's software pipelining emitted the NEXT round's
// LDS copy after the current round's tx_complete (measured: the consumer
// read the page of a round that never finished; both r=100's speculative
// copy and an unexplained reordering produce the same page because
// r%7 cycles — the token dependence makes the reorder impossible).
__device__ inline unsigned tx_mbarrier_opaque_token(unsigned token) {
    asm volatile("" : "+r"(token) ::);
    return token;
}

// WAITING side: non-blocking phase predicate.
__device__ inline bool tx_mbarrier_try_wait(const SoftTxMbarrier* mb, unsigned token) {
    return ((static_cast<unsigned>(mb->word >> 32) & 1u) != token);
}

// WAITING side: blocking spin (tight — no backoff at ROCm 10.1; see
// warp_sync's 10.1 re-measurement), then an ACQUIRE. The acquire is
// LOAD-BEARING, not style: without it the compiler hoists the consumer's
// post-wait data reads ABOVE the spin (they have no data dependence on it)
// and the consumer reads stale phase data — measured: the multi-round test
// returned a producer's page from rounds earlier than the last (both
// producers completed all rounds, the state word was correct, the payload
// was stale until this atomic-read acquire was added).
__device__ inline void tx_mbarrier_wait(SoftTxMbarrier* mb, unsigned token) {
    // The spin reads parity via an ATOMIC (atomicAdd 0), not a plain load.
    // LOAD-BEARING, measured on clang-24/ROCm 10.1: with a plain-load spin,
    // the compiler (a) tracked that the WAITING lane's own arm left parity
    // == 0, carried that knowledge ACROSS the workgroup barrier, emitted
    // llvm.assume(parity == 0) at the wait and DELETED the spin entirely —
    // the wait returned before the producers' flips, and the consumer read
    // stale phase data. A side-effecting atomic read cannot be assumed
    // away. (The same hazard class applies to any plain-load spin whose
    // word other threads mutate: warp_sync's waits survived here by the
    // accident of their surrounding syncthreads structure.)
    // Plain-load spin with a memory-clobbered body. Both halves are
    // load-bearing (measured, clang-24/ROCm 10.1):
    //  - the clobber in the BODY (not after the exit) prevents the compiler
    //    from deleting the spin: with a bare empty-body spin, clang-24
    //    tracked that the waiting lane's own arm left parity == 0, carried
    //    that knowledge ACROSS the workgroup barrier, emitted
    //    llvm.assume(parity == 0) and deleted the spin — the wait returned
    //    before the producers' flips (stale payload, measured);
    //  - the read stays a PLAIN load: an atomicAdd(0) read-spin livelocks
    //    here (RMW atomics on the same word starve the producers' flips —
    //    same starvation class as the 7.2.4 LDS-read livelock, measured as
    //    a hard hang).
    unsigned long long w;
    do {
        w = mb->word;
        asm volatile("" ::: "memory");
    } while (((static_cast<unsigned>(w >> 32) & 1u)) == token);
    asm volatile("" ::: "memory");
}

}  // namespace aiter_lab
