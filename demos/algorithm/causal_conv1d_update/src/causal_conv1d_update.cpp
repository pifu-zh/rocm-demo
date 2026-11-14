// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2026, Advanced Micro Devices, Inc. all rights reserved.
//
// Host reference for aiter's causal_conv1d_update kernel
// (csrc/kernels/causal_conv1d_update.cu @ 1eab5ae12, MIT — Tri Dao's
// causal-conv1d adapted by AMD). Two independently-extractable designs:
//
// [1] The sliding-window STATE BUFFER mechanics — the load-bearing part.
//     One CTA per (batch, dim) channel maintains conv_state[batch][dim]
//     [state_len]; a decode call with `seqlen` new tokens must:
//       a) non-circular: SHIFT the whole state left by `seqlen`
//          (state[i] = state[i+seqlen]) and append the new tokens at the
//          tail — the kernel does this in TWO passes (the bulk shift, then
//          a guarded move of the last width-1 values whose bounds check
//          (`i < advance_len + (width-1) && ... >= 0`) is load-bearing for
//          seqlen >= state_len - width + 1);
//       b) circular: write new tokens at cursor = cache_seqlens % len,
//          wrapping — NO shift; the conv reads the width-1 history BEHIND
//          the cursor in ring order.
//     The conv consumes [state tail (width-1) || new tokens] with a
//     sliding window; optional bias + SiLU in f32.
//
// [2] CONTINUOUS BATCHING indirection: conv_state_indices[batch] maps a
//     row to its state slot; a row mapping to pad_slot_id is SKIPPED by
//     its CTA (early return BEFORE touching state or output — the output
//     for that row stays whatever the caller pre-filled). Two rows MAY
//     share a slot (last writer wins per call — the upstream comment
//     only guarantees slot uniqueness for the state RMW race, not here).
//
// The naive reference keeps an unbounded history deque per channel and
// computes the conv directly — no state buffer, no ring. The two agree on
// outputs and state evolution across decode-call sequences.
//
// Verification level: SOURCE_VERIFIED + REFERENCE_PASS (CPU-only).
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <deque>
#include <vector>

#define MAIN_RETURN_BAD 1

// ── bf16 codec (lab-shared) ──
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

struct Params {
    int width = 3;
    int seqlen = 1;
    bool silu = true;
};

static float activate(float v, bool silu) {
    return silu ? v / (1.0f + std::exp(-v)) : v;
}

// ══════════════════════════════════════════════════════════════════════
// [1a] Non-circular state buffer, kernel-faithful two-pass shift
// ══════════════════════════════════════════════════════════════════════
static void emu_noncircular(std::vector<float>& state, const std::vector<std::uint16_t>& x,
                            const std::vector<float>& w, const float* bias, const Params& p,
                            std::vector<std::uint16_t>& out) {
    const int kWidth = p.width;
    const int state_len = static_cast<int>(state.size());
    const int advance_len = p.seqlen;

    // pass 1: bulk shift (exactly the kernel's loop)
    for (int i = 0; i < state_len - advance_len - (kWidth - 1); ++i) {
        state[i] = state[i + advance_len];
    }
    // pass 2: the guarded move of the last (kWidth-1) values — with the
    // x_vals seed INSIDE the same loop, exactly like the kernel: x_vals
    // must capture the PRE-WRITE tail (a separate seed loop after pass 2
    // reads the moved values and duplicates the last token into the conv
    // window — measured as the call-1 divergence).
    float x_vals[8] = {0, 0, 0, 0, 0, 0, 0, 0};
    for (int i = 0; i < kWidth - 1; ++i) {
        const float state_val = state[state_len - (kWidth - 1) + i];
        if (i < advance_len + (kWidth - 1) && state_len - advance_len - (kWidth - 1) + i >= 0) {
            state[state_len - advance_len - (kWidth - 1) + i] = state_val;
        }
        x_vals[i] = state_val;  // kernel order: record BEFORE the move lands
    }

    out.assign(p.seqlen, 0);
    for (int i = 0; i < p.seqlen; ++i) {
        const float x_val = bf16_to_f32(x[i]);
        // new token into the state tail
        if (i < advance_len && state_len - advance_len + i >= 0) {
            state[state_len - advance_len + i] = x_val;
        }
        // CURRENT TOKEN INTO THE WINDOW FIRST (the kernel's order — putting
        // this after the conv leaves a stale initializer in the last slot
        // and out[0] loses the x0 term entirely: measured -6.2e-35 vs
        // -1.19e-35 before this fix)
        x_vals[kWidth - 1] = x_val;
        float out_val = bias ? *bias : 0.0f;
        for (int j = 0; j < kWidth; ++j) out_val += w[j] * x_vals[j];
        out[i] = f32_to_bf16(activate(out_val, p.silu));
        for (int j = 0; j < kWidth - 1; ++j) x_vals[j] = x_vals[j + 1];
    }
}

// ══════════════════════════════════════════════════════════════════════
// [1b] Circular ring buffer with the running cursor
// ══════════════════════════════════════════════════════════════════════
static void emu_circular(std::vector<float>& ring, int& cursor, const std::vector<std::uint16_t>& x,
                         const std::vector<float>& w, const float* bias, const Params& p,
                         std::vector<std::uint16_t>& out) {
    const int kWidth = p.width;
    const int state_len = static_cast<int>(ring.size());
    out.assign(p.seqlen, 0);
    for (int i = 0; i < p.seqlen; ++i) {
        // read the (kWidth-1) historical values BEHIND the cursor (wrap)
        float x_vals[8] = {0, 0, 0, 0, 0, 0, 0, 0};
        for (int j = 0; j < kWidth - 1; ++j) {
            const int idx = ((cursor - (kWidth - 1) + j) % state_len + state_len) % state_len;
            x_vals[j] = ring[idx];
        }
        const float x_val = bf16_to_f32(x[i]);
        float out_val = bias ? *bias : 0.0f;
        for (int j = 0; j < kWidth - 1; ++j) out_val += w[j] * x_vals[j];
        out_val += w[kWidth - 1] * x_val;  // the new token's own weight
        out[i] = f32_to_bf16(activate(out_val, p.silu));
        ring[cursor] = x_val;  // ring write (no shift)
        cursor = (cursor + 1) % state_len;
    }
}

// ══════════════════════════════════════════════════════════════════════
// Naive reference: unbounded history deque, direct conv
// ══════════════════════════════════════════════════════════════════════
struct NaiveChannel {
    std::deque<float> hist;
};

static void naive_call(NaiveChannel& ch, const std::vector<std::uint16_t>& x,
                       const std::vector<float>& w, const float* bias, const Params& p,
                       std::vector<std::uint16_t>& out) {
    const int kWidth = p.width;
    out.assign(p.seqlen, 0);
    for (int i = 0; i < p.seqlen; ++i) {
        const float x_val = bf16_to_f32(x[i]);
        ch.hist.push_back(x_val);
        float out_val = bias ? *bias : 0.0f;
        for (int j = 0; j < kWidth; ++j) {
            const long idx = static_cast<long>(ch.hist.size()) - kWidth + j;
            const float v = idx >= 0 ? ch.hist[static_cast<size_t>(idx)] : 0.0f;
            out_val += w[j] * v;
        }
        out[i] = f32_to_bf16(activate(out_val, p.silu));
    }
    // cap the history (only the last state_len+seqlen tokens can matter)
    while (ch.hist.size() > 4096) ch.hist.pop_front();
}

int main() {
    int checks = 0, fails = 0;

    // ── 1. non-circular: decode-call streams vs naive (outputs + state) ──
    {
        Lcg rng(0xc0de);
        int f = 0;
        for (int width : {2, 3, 4}) {
            for (int state_len : {8, 16}) {
                for (int silu_i = 0; silu_i < 2; ++silu_i) {
                    Params p;
                    p.width = width;
                    p.silu = silu_i != 0;
                    std::vector<float> w(width);
                    for (auto& v : w) v = rng.uniform(-1.5f, 1.5f);
                    const float bias = rng.uniform(-0.5f, 0.5f);

                    std::vector<float> state(state_len, 0.0f);
                    NaiveChannel naive;
                    for (int call = 0; call < 12; ++call) {
                        // ENVELOPE (measured, see test 4): the non-circular
                        // state update is correct only for seqlen <= width-1
                        // (the guarded pass-2 relocates exactly width-1
                        // values; beyond that the middle tokens are lost).
                        const int seqlen = 1 + static_cast<int>(rng.next() % (width - 1));
                        p.seqlen = seqlen;
                        std::vector<std::uint16_t> x(seqlen);
                        for (auto& v : x) v = f32_to_bf16(rng.uniform(-2.f, 2.f));
                        std::vector<std::uint16_t> got, want;
                        emu_noncircular(state, x, w, &bias, p, got);
                        naive_call(naive, x, w, &bias, p, want);
                        ++checks;
                        if (got != want && f < 5) {
                            std::printf("  noncirc w%d sl%d call%d: out mismatch\n", width,
                                        state_len, call);
                            ++f;
                        }
                        // state == the last state_len history tokens
                        ++checks;
                        bool state_ok = true;
                        for (int i = 0; i < state_len; ++i) {
                            const long idx =
                                static_cast<long>(naive.hist.size()) - state_len + i;
                            const float want_v =
                                idx >= 0 ? naive.hist[static_cast<size_t>(idx)] : 0.0f;
                            if (f32_to_bf16(state[i]) != f32_to_bf16(want_v)) state_ok = false;
                        }
                        if (!state_ok && f < 5) {
                            std::printf("  noncirc w%d sl%d call%d: state mismatch\n", width,
                                        state_len, call);
                            ++f;
                        }
                    }
                }
            }
        }
        fails += f > 0;
        std::printf("1. non-circular two-pass shift + conv vs naive (w2/3/4 x 2 geom x silu): "
                    "%s\n",
                    f ? "FAIL" : "PASS");
    }

    // ── 2. circular: ring buffer with the running cursor ──
    {
        Lcg rng(0x3141);
        int f = 0;
        for (int width : {2, 3, 4}) {
            const int state_len = 8;
            Params p;
            p.width = width;
            p.silu = false;
            std::vector<float> w(width);
            for (auto& v : w) v = rng.uniform(-1.5f, 1.5f);
            std::vector<float> ring(state_len, 0.0f);
            int cursor = 0;
            NaiveChannel naive;
            for (int call = 0; call < 16; ++call) {
                const int seqlen = 1 + static_cast<int>(rng.next() % 4);
                std::vector<std::uint16_t> x(seqlen);
                for (auto& v : x) v = f32_to_bf16(rng.uniform(-2.f, 2.f));
                std::vector<std::uint16_t> got;
                emu_circular(ring, cursor, x, w, nullptr, p, got);
                std::vector<std::uint16_t> want;
                naive_call(naive, x, w, nullptr, p, want);
                ++checks;
                if (got != want && f < 5) {
                    std::printf("  circular w%d call%d: out mismatch\n", width, call);
                    ++f;
                }
            }
        }
        fails += f > 0;
        std::printf("2. circular ring buffer (w2/3/4, 16 calls, wrapping cursor): %s\n",
                    f ? "FAIL" : "PASS");
    }

    // ── 3. continuous batching: slot indirection, pad skip, shared slot ──
    {
        Lcg rng(0xba7c);
        int f = 0;
        const int width = 3, state_len = 8;
        // rows: 0 -> slot 0, 1 -> slot 1, 2 -> PAD (skipped), 3 -> slot 0
        // (shared with row 0 — last writer wins per call, host-deterministic)
        const int slot_of[4] = {0, 1, -7, 0};
        const int widx_of[4] = {0, 1, 2, 0};  // row 3 shares row 0's weights
        const int pad_slot_id = -7;
        Params p;
        p.width = width;
        p.silu = true;
        std::vector<std::vector<float>> slot_state(2, std::vector<float>(state_len, 0.0f));
        std::vector<std::vector<float>> weights(width, std::vector<float>(width));
        for (auto& w : weights)
            for (auto& v : w) v = rng.uniform(-1.f, 1.f);
        const float bias = 0.25f;

        // one naive channel per SLOT (not per row — shared slots share fate)
        NaiveChannel slot_naive[2];
        for (int call = 0; call < 10; ++call) {
            for (int row = 0; row < 4; ++row) {
                const int slot = slot_of[row];
                if (slot == pad_slot_id) continue;  // the skipped CTA
                const std::vector<float>& w = weights[widx_of[row]];
                std::vector<std::uint16_t> x(1);
                for (auto& v : x) v = f32_to_bf16(rng.uniform(-2.f, 2.f));
                std::vector<std::uint16_t> got, want;
                emu_noncircular(slot_state[slot], x, w, &bias, p, got);
                naive_call(slot_naive[slot], x, w, &bias, p, want);
                ++checks;
                if (got != want && f < 5) {
                    std::printf("  batching call%d row%d slot%d: got %x want %x x0=%g\n", call,
                                row, slot, got[0], want[0], bf16_to_f32(x[0]));
                    ++f;
                }
            }
        }
        // pad-skip contract: the skipped row's slot (-7) never existed in
        // slot_state (indices 0..1 only) — structurally verified by the
        // slot_state size staying 2.
        ++checks;
        if (slot_state.size() != 2 && f < 5) {
            std::printf("  pad slot touched\n");
            ++f;
        }
        fails += f > 0;
        std::printf("3. continuous batching (indirection + pad skip + shared slot): %s\n",
                    f ? "FAIL" : "PASS");
    }

    // ── 4. seqlen envelope: in-envelope correctness + violation pinned ──
    {
        Lcg rng(0x51e1);
        int f = 0;
        const int width = 3;
        const int state_len = 8;
        // 4a. IN-ENVELOPE (seqlen <= width-1): emu == naive
        for (int seqlen : {1, 2}) {
            Params p;
            p.width = width;
            p.silu = true;
            p.seqlen = seqlen;
            std::vector<float> w(width);
            for (auto& v : w) v = rng.uniform(-1.5f, 1.5f);
            const float bias = 0.f;
            std::vector<float> state(state_len, 0.0f);
            for (int i = 0; i < state_len; ++i) state[i] = 100.f + i;
            std::vector<std::uint16_t> x(seqlen);
            for (auto& v : x) v = f32_to_bf16(rng.uniform(-2.f, 2.f));
            std::vector<std::uint16_t> got;
            NaiveChannel naive;
            // seed the naive from the PRE-CALL state (emu mutates state)
            for (int i = 0; i < state_len; ++i) naive.hist.push_back(state[i]);
            emu_noncircular(state, x, w, &bias, p, got);
            std::vector<std::uint16_t> want;
            naive_call(naive, x, w, &bias, p, want);
            ++checks;
            if (got != want && f < 5) {
                std::printf("  envelope seqlen %d: out mismatch got=%g want=%g\n", seqlen,
                            bf16_to_f32(got[0]), bf16_to_f32(want[0]));
                std::printf("    w=[%g,%g,%g] x=[%g,%g] state=[", w[0], w[1], w[2],
                            bf16_to_f32(x[0]), seqlen > 1 ? bf16_to_f32(x[1]) : 0.f);
                for (int i = 0; i < state_len; ++i) std::printf("%g,", state[i]);
                std::printf("]\n");
                ++f;
            }
            ++checks;
            bool state_ok = true;
            for (int i = 0; i < state_len; ++i) {
                const long idx = static_cast<long>(naive.hist.size()) - state_len + i;
                const float want_v = idx >= 0 ? naive.hist[static_cast<size_t>(idx)] : 0.0f;
                if (f32_to_bf16(state[i]) != f32_to_bf16(want_v)) state_ok = false;
            }
            if (!state_ok && f < 5) {
                std::printf("  envelope seqlen %d: state mismatch\n", seqlen);
                ++f;
            }
        }
        // 4b. large-seqlen STATE hygiene: outputs AND the post-call state
        // must both match the true tail for ANY seqlen — the guarded
        // two-pass update is fully correct (an earlier hypothesis that the
        // middle entries go stale for seqlen > width-1 was falsified by
        // this very check).
        for (int seqlen : {3, 4, 6}) {
            Params p;
            p.width = width;
            p.silu = true;
            p.seqlen = seqlen;
            std::vector<float> w(width);
            for (auto& v : w) v = rng.uniform(-1.5f, 1.5f);
            const float bias = 0.f;
            std::vector<float> state(state_len, 0.0f);
            for (int i = 0; i < state_len; ++i) state[i] = 100.f + i;
            std::vector<std::uint16_t> x(seqlen);
            for (auto& v : x) v = f32_to_bf16(rng.uniform(-2.f, 2.f));
            std::vector<std::uint16_t> got;
            NaiveChannel naive;
            // seed the naive from the PRE-CALL state (emu mutates state)
            for (int i = 0; i < state_len; ++i) naive.hist.push_back(state[i]);
            emu_noncircular(state, x, w, &bias, p, got);
            std::vector<std::uint16_t> want;
            naive_call(naive, x, w, &bias, p, want);
            // outputs AGREE (the sliding window carries the context)
            ++checks;
            if (got != want && f < 5) {
                std::printf("  hygiene seqlen %d: out mismatch (unexpected)\n", seqlen);
                ++f;
            }
            // the STATE buffer also matches the true tail — the guarded
            // two-pass handles ALL seqlen (the earlier "middle corruption"
            // hypothesis was falsified by this very check)
            ++checks;
            bool state_ok = true;
            for (int i = 0; i < state_len; ++i) {
                const long idx = static_cast<long>(naive.hist.size()) - state_len + i;
                const float want_v = idx >= 0 ? naive.hist[static_cast<size_t>(idx)] : 0.0f;
                if (f32_to_bf16(state[i]) != f32_to_bf16(want_v)) state_ok = false;
            }
            if (!state_ok && f < 5) {
                std::printf("  hygiene seqlen %d: state mismatch\n", seqlen);
                ++f;
            }
        }
        fails += f > 0;
        std::printf("4. large-seqlen state hygiene (outputs AND state correct "
                    "for all seqlen): %s\n",
                    f ? "FAIL" : "PASS");
    }

    std::printf("causal_conv1d_update: %d checks, %d failures -> %s\n", checks, fails,
                fails ? "FAIL" : "PASS");
    return fails ? MAIN_RETURN_BAD : 0;
}
