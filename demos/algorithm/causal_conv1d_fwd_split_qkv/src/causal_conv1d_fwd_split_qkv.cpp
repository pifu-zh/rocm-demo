// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2026, Advanced Micro Devices, Inc. all rights reserved.
//
// Host emulation of aiter's prefill causal conv1d with fused split q/k/v
// output (csrc/kernels/causal_conv1d_fwd_split_qkv.cu @ 1eab5ae12, MIT).
//
// The kernel's contract, as pinned from the source:
//   * grid.x decodes a flattened (sequence, chunk) schedule through
//     batch_ptr[pid] / token_chunk_offset_ptr[pid]; TM is the chunk length
//     (templated {8,16,32,64} on device; 32 here).
//   * each (pid, gfeat) pair is independent: a depthwise causal conv of
//     width KW=4 over x[token-3..token] + bias, then SiLU, written as bf16.
//   * the pre-window for token < 3 of a chunk starting at tok_start < 3
//     comes from conv_states[slot][gfeat][0..2] (slot = cache_indices[seq],
//     has_initial_state gates it; without it the window is zeros). Chunks
//     with tok_start >= 3 read their window straight from x — chunks >= 1
//     never touch the state, so there is no inter-chunk ordering hazard.
//   * the conv output is routed: gfeat < k_dim -> q_out, < 2*k_dim ->
//     k_out, else v_out; each output is [T, k_dim] token-major.
//   * EXACTLY ONE CTA per sequence updates the persistent tail — chunk 0,
//     which writes the last min(3, ...) tokens of the WHOLE sequence (it
//     reads across its own sequence, not just its chunk): seqlen >= 3 ->
//     raw x passthrough of the last 3 tokens; seqlen 1/2 -> the old state
//     slides (and is zeroed first when has_initial_state is 0).
//   * pad sequences (cache_indices[seq] == pad_slot_id) return before any
//     read or write.
//
// Two schedules over the same contract cross-validate each other:
//   run_chunked — the kernel's (seq, chunk) schedule, per-chunk windows;
//   run_flat    — one rolling-window pass per sequence, outputs only.
// Both apply identical float ops in identical order per token, so the
// outputs must match BITWISE (u16 equality) — a stronger oracle than a
// tolerance compare.

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <vector>

// ── lab-shared primitives (self-contained copies, same as sibling demos) ──
static inline float bf16_to_f32(std::uint16_t h) {
    std::uint32_t u = static_cast<std::uint32_t>(h) << 16;
    float f;
    std::memcpy(&f, &u, 4);
    return f;
}
static inline std::uint16_t f32_to_bf16(float f) {
    std::uint32_t u;
    std::memcpy(&u, &f, 4);
    const std::uint32_t lsb = (u >> 16) & 1;
    return static_cast<std::uint16_t>((u + 0x7FFFu + lsb) >> 16);
}
struct Lcg {
    std::uint64_t s;
    explicit Lcg(std::uint64_t seed) : s(seed) {}
    std::uint32_t next() {
        s = s * 6364136223846793005ULL + 1442695040888963407ULL;
        return static_cast<std::uint32_t>(s >> 33);
    }
    float uniform(float lo, float hi) {
        return lo + (hi - lo) * (static_cast<float>(next() >> 8) / 16777216.f);
    }
};

// ── the job (one host struct per kernel argument set) ──
constexpr int KW = 4;   // conv width
constexpr int TM = 32;  // chunk length (device templates {8,16,32,64})

struct SplitJob {
    int dim = 0, k_dim = 0, T = 0, num_slots = 0;
    int pad_slot_id = -1;
    bool has_bias = false, do_silu = false;
    std::vector<std::uint16_t> x;            // [T, dim] bf16, token-major
    std::vector<std::uint16_t> w;            // [dim, KW] bf16
    std::vector<std::uint16_t> bias;         // [dim] bf16
    std::vector<int> batch_ptr, token_chunk_offset_ptr, query_start_loc;
    std::vector<int> cache_indices, has_initial_state;
    std::vector<std::uint16_t> conv_states;  // [slot][gfeat][w] bf16, w fastest
};

// SiLU exactly as the device expresses it: acc * rcp(1 + exp2(-acc*log2e)).
// Host uses the equivalent expf form; both schedules share it, so the
// cross-validation is unaffected.
static inline float silu(float a) {
    return a / (1.f + std::exp(-a));
}

// One depthwise conv output: window (x0,x1,x2) precedes x3.
static inline float conv_step(const SplitJob& j, int gfeat, float x0, float x1,
                              float x2, float x3) {
    const float wr0 = bf16_to_f32(j.w[static_cast<long>(gfeat) * KW + 0]);
    const float wr1 = bf16_to_f32(j.w[static_cast<long>(gfeat) * KW + 1]);
    const float wr2 = bf16_to_f32(j.w[static_cast<long>(gfeat) * KW + 2]);
    const float wr3 = bf16_to_f32(j.w[static_cast<long>(gfeat) * KW + 3]);
    const float bias = j.has_bias ? bf16_to_f32(j.bias[gfeat]) : 0.f;
    float acc = bias + wr0 * x0 + wr1 * x1 + wr2 * x2 + wr3 * x3;
    return j.do_silu ? silu(acc) : acc;
}

// Output routing: gfeat -> (tensor, local feature index).
static inline std::uint16_t* route(const SplitJob& j, std::uint16_t* q,
                                   std::uint16_t* k, std::uint16_t* v,
                                   int gfeat, int& out_feat) {
    if (gfeat < j.k_dim) { out_feat = gfeat; return q; }
    if (gfeat < 2 * j.k_dim) { out_feat = gfeat - j.k_dim; return k; }
    out_feat = gfeat - 2 * j.k_dim;
    return v;
}

// ── schedule 1: the kernel's (seq, chunk) decode ──
static void run_chunked(SplitJob& j, std::uint16_t* q, std::uint16_t* k,
                        std::uint16_t* v) {
    const long scs0 = static_cast<long>(j.dim) * (KW - 1);
    for (std::size_t pid = 0; pid < j.batch_ptr.size(); ++pid) {
        const int seq_idx = j.batch_ptr[pid];
        const int chunk_idx = j.token_chunk_offset_ptr[pid];
        const int slot = j.cache_indices[seq_idx];
        if (slot == j.pad_slot_id) continue;  // pad: return before any access
        const int seq_start = j.query_start_loc[seq_idx];
        const int seqlen = j.query_start_loc[seq_idx + 1] - seq_start;
        const int tok_start = chunk_idx * TM;
        if (tok_start >= seqlen) continue;

        for (int gfeat = 0; gfeat < j.dim; ++gfeat) {
            // pre-window: x if the chunk starts deep enough, else the state
            float x0 = 0.f, x1 = 0.f, x2 = 0.f;
            if (tok_start >= 3) {
                x0 = bf16_to_f32(j.x[static_cast<long>(seq_start + tok_start - 3) * j.dim + gfeat]);
                x1 = bf16_to_f32(j.x[static_cast<long>(seq_start + tok_start - 2) * j.dim + gfeat]);
                x2 = bf16_to_f32(j.x[static_cast<long>(seq_start + tok_start - 1) * j.dim + gfeat]);
            } else if (j.has_initial_state[seq_idx]) {
                const long sb = static_cast<long>(slot) * scs0 + static_cast<long>(gfeat) * (KW - 1);
                x0 = bf16_to_f32(j.conv_states[sb]);
                x1 = bf16_to_f32(j.conv_states[sb + 1]);
                x2 = bf16_to_f32(j.conv_states[sb + 2]);
            }

            int out_feat;
            std::uint16_t* out = route(j, q, k, v, gfeat, out_feat);
            const int count = std::min(TM, seqlen - tok_start);
            for (int i = 0; i < count; ++i) {
                const int tok = seq_start + tok_start + i;
                const float x3 = bf16_to_f32(j.x[static_cast<long>(tok) * j.dim + gfeat]);
                out[static_cast<long>(tok) * j.k_dim + out_feat] =
                    f32_to_bf16(conv_step(j, gfeat, x0, x1, x2, x3));
                x0 = x1; x1 = x2; x2 = x3;
            }
        }

        // the tail contract: chunk 0 alone, whole-sequence last tokens
        if (chunk_idx == 0) {
            for (int gfeat = 0; gfeat < j.dim; ++gfeat) {
                const long sb = static_cast<long>(slot) * scs0 + static_cast<long>(gfeat) * (KW - 1);
                if (seqlen >= 3) {
                    for (int w_i = 0; w_i < KW - 1; ++w_i)
                        j.conv_states[sb + w_i] =
                            j.x[static_cast<long>(seq_start + seqlen - 3 + w_i) * j.dim + gfeat];
                } else {
                    // (the device kernel also reads old0 but never uses it
                    // in the seqlen<3 branches — dead there, omitted here)
                    std::uint16_t old1 = j.conv_states[sb + 1];
                    std::uint16_t old2 = j.conv_states[sb + 2];
                    if (!j.has_initial_state[seq_idx]) old1 = old2 = 0;
                    if (seqlen == 1) {
                        j.conv_states[sb] = old1;
                        j.conv_states[sb + 1] = old2;
                        j.conv_states[sb + 2] = j.x[static_cast<long>(seq_start) * j.dim + gfeat];
                    } else if (seqlen == 2) {
                        j.conv_states[sb] = old2;
                        j.conv_states[sb + 1] = j.x[static_cast<long>(seq_start) * j.dim + gfeat];
                        j.conv_states[sb + 2] = j.x[static_cast<long>(seq_start + 1) * j.dim + gfeat];
                    }
                }
            }
        }
    }
}

// ── schedule 2: one rolling pass per sequence (outputs only) ──
static void run_flat(const SplitJob& j, std::uint16_t* q, std::uint16_t* k,
                     std::uint16_t* v) {
    const long scs0 = static_cast<long>(j.dim) * (KW - 1);
    for (std::size_t seq_idx = 0; seq_idx + 1 < j.query_start_loc.size(); ++seq_idx) {
        const int slot = j.cache_indices[seq_idx];
        if (slot == j.pad_slot_id) continue;
        const int seq_start = j.query_start_loc[seq_idx];
        const int seqlen = j.query_start_loc[seq_idx + 1] - seq_start;
        for (int gfeat = 0; gfeat < j.dim; ++gfeat) {
            float x0 = 0.f, x1 = 0.f, x2 = 0.f;
            if (j.has_initial_state[seq_idx]) {
                const long sb = static_cast<long>(slot) * scs0 + static_cast<long>(gfeat) * (KW - 1);
                x0 = bf16_to_f32(j.conv_states[sb]);
                x1 = bf16_to_f32(j.conv_states[sb + 1]);
                x2 = bf16_to_f32(j.conv_states[sb + 2]);
            }
            int out_feat;
            std::uint16_t* out = route(j, q, k, v, gfeat, out_feat);
            for (int i = 0; i < seqlen; ++i) {
                const int tok = seq_start + i;
                const float x3 = bf16_to_f32(j.x[static_cast<long>(tok) * j.dim + gfeat]);
                out[static_cast<long>(tok) * j.k_dim + out_feat] =
                    f32_to_bf16(conv_step(j, gfeat, x0, x1, x2, x3));
                x0 = x1; x1 = x2; x2 = x3;
            }
        }
    }
}

int main() {
    int checks = 0, fails = 0;

    // ── shared setup: 2 sequences (100, 70 tokens), dim = 3*k_dim ──
    constexpr int k_dim = 16;
    constexpr int dim = 3 * k_dim;
    constexpr int num_seqs = 2;
    constexpr int num_slots = 2;
    const int seq_lens[num_seqs] = {100, 70};
    int T = 0;
    std::vector<int> query_start_loc(num_seqs + 1);
    for (int s = 0; s < num_seqs; ++s) {
        query_start_loc[s] = T;
        T += seq_lens[s];
    }
    query_start_loc[num_seqs] = T;

    std::vector<int> batch_ptr, token_chunk_offset_ptr;
    for (int s = 0; s < num_seqs; ++s)
        for (int c = 0; c < (seq_lens[s] + TM - 1) / TM; ++c) {
            batch_ptr.push_back(s);
            token_chunk_offset_ptr.push_back(c);
        }

    SplitJob j;
    j.dim = dim;
    j.k_dim = k_dim;
    j.T = T;
    j.num_slots = num_slots;
    j.x.resize(static_cast<long>(T) * dim);
    {
        Lcg rng(0x604a);
        for (auto& v : j.x) v = f32_to_bf16(rng.uniform(-2.f, 2.f));
    }
    j.w.resize(static_cast<long>(dim) * KW);
    {
        Lcg rng(0x77);
        for (auto& v : j.w) v = f32_to_bf16(rng.uniform(-1.f, 1.f));
    }
    j.bias.resize(dim);
    {
        Lcg rng(0x88);
        for (auto& v : j.bias) v = f32_to_bf16(rng.uniform(-0.5f, 0.5f));
    }
    j.has_bias = true;
    j.do_silu = true;
    j.batch_ptr = batch_ptr;
    j.token_chunk_offset_ptr = token_chunk_offset_ptr;
    j.query_start_loc = query_start_loc;
    j.cache_indices = {0, 1};
    j.has_initial_state = {1, 0};
    j.pad_slot_id = -1;
    j.conv_states.assign(static_cast<long>(num_slots) * dim * (KW - 1), 0);
    {
        Lcg rng(0x9d);
        for (auto& v : j.conv_states) v = f32_to_bf16(rng.uniform(-1.f, 1.f));
    }

    auto outs = [](long n) {
        std::vector<std::uint16_t> t(static_cast<std::size_t>(n));
        std::fill(t.begin(), t.end(), static_cast<std::uint16_t>(0xDEAD));
        return t;
    };
    auto cmp_bitwise = [&](const std::vector<std::uint16_t>& a,
                           const std::vector<std::uint16_t>& b, long n) {
        long bad = 0;
        for (long i = 0; i < n; ++i)
            if (a[i] != b[i]) {
                ++bad;
                if (bad <= 3)
                    std::printf("  mismatch at %ld: %g vs %g\n", i,
                                bf16_to_f32(a[i]), bf16_to_f32(b[i]));
            }
        return bad;
    };

    // ── 0. schedule decode: every (seq, chunk) exactly once, full coverage ──
    {
        int f = 0;
        std::vector<int> seen(num_seqs, 0);
        long covered = 0;
        for (std::size_t pid = 0; pid < j.batch_ptr.size(); ++pid) {
            const int s = j.batch_ptr[pid];
            const int c = j.token_chunk_offset_ptr[pid];
            ++seen[s];
            if (c != seen[s] - 1 && f < 5) {  // chunks must arrive in order 0,1,..
                std::printf("  seq %d chunk %d out of order (seen %d)\n", s, c, seen[s]);
                ++f;
            }
            covered += std::min(TM, seq_lens[s] - c * TM);
        }
        ++checks;
        for (int s = 0; s < num_seqs; ++s)
            if (seen[s] != (seq_lens[s] + TM - 1) / TM && f < 5) {
                std::printf("  seq %d: %d chunk slots, want %d\n", s, seen[s],
                            (seq_lens[s] + TM - 1) / TM);
                ++f;
            }
        ++checks;
        if (covered != T && f < 5) {
            std::printf("  schedule covers %ld tokens, want %d\n", covered, T);
            ++f;
        }
        fails += f > 0;
        std::printf("0. schedule decode (%zu pids, %ld tokens covered): %s\n",
                    j.batch_ptr.size(), covered, f ? "FAIL" : "PASS");
    }

    // ── 1. chunked vs flat, bitwise + tail contract ──
    {
        int f = 0;
        auto jq = j;
        auto q = outs(static_cast<long>(T) * k_dim);
        auto k = outs(static_cast<long>(T) * k_dim);
        auto v = outs(static_cast<long>(T) * k_dim);
        run_chunked(jq, q.data(), k.data(), v.data());
        auto q2 = outs(static_cast<long>(T) * k_dim);
        auto k2 = outs(static_cast<long>(T) * k_dim);
        auto v2 = outs(static_cast<long>(T) * k_dim);
        run_flat(j, q2.data(), k2.data(), v2.data());
        ++checks;
        long bad = cmp_bitwise(q, q2, static_cast<long>(T) * k_dim) +
                   cmp_bitwise(k, k2, static_cast<long>(T) * k_dim) +
                   cmp_bitwise(v, v2, static_cast<long>(T) * k_dim);
        if (bad && f < 5) {
            std::printf("  outputs: %ld bitwise mismatches\n", bad);
            ++f;
        }
        // tail: conv_states hold the last 3 tokens of each sequence, raw
        ++checks;
        bool tail_ok = true;
        for (int seq = 0; seq < num_seqs && tail_ok; ++seq) {
            const int slot = j.cache_indices[seq];
            const int start = query_start_loc[seq];
            if (seq_lens[seq] < 3) continue;
            for (int gfeat = 0; gfeat < dim && tail_ok; ++gfeat)
                for (int w_i = 0; w_i < KW - 1; ++w_i) {
                    const std::uint16_t want =
                        j.x[static_cast<long>(start + seq_lens[seq] - 3 + w_i) * dim + gfeat];
                    const std::uint16_t got =
                        jq.conv_states[static_cast<long>(slot) * dim * (KW - 1) +
                                       static_cast<long>(gfeat) * (KW - 1) + w_i];
                    if (got != want) { tail_ok = false; break; }
                }
        }
        if (!tail_ok && f < 5) {
            std::printf("  tail update: conv_states don't hold last 3 tokens\n");
            ++f;
        }
        fails += f > 0;
        std::printf("1. chunked vs flat bitwise (T=%d, dim %d) + tail: %s\n", T, dim,
                    f ? "FAIL" : "PASS");
    }

    // ── 2. pad slot skip ──
    {
        int f = 0;
        auto j2 = j;
        j2.cache_indices[1] = 99;
        j2.pad_slot_id = 99;
        auto q = outs(static_cast<long>(T) * k_dim);
        auto k = outs(static_cast<long>(T) * k_dim);
        auto v = outs(static_cast<long>(T) * k_dim);
        run_chunked(j2, q.data(), k.data(), v.data());
        // seq 1's outputs stay at the sentinel; slot 0's tail still updated
        const int s1_start = query_start_loc[1];
        const int s1_len = query_start_loc[2] - s1_start;
        ++checks;
        bool pad_ok = true;
        for (int t = 0; t < s1_len && pad_ok; ++t)
            for (int c = 0; c < k_dim; ++c) {
                if (q[static_cast<long>(s1_start + t) * k_dim + c] !=
                    static_cast<std::uint16_t>(0xDEAD))
                    { pad_ok = false; break; }
            }
        if (!pad_ok && f < 5) {
            std::printf("  pad row output was written\n");
            ++f;
        }
        ++checks;
        bool slot0_ok = true;
        for (int gfeat = 0; gfeat < dim && slot0_ok; ++gfeat)
            for (int w_i = 0; w_i < KW - 1; ++w_i) {
                const std::uint16_t want =
                    j.x[static_cast<long>(query_start_loc[0] + seq_lens[0] - 3 + w_i) * dim + gfeat];
                const std::uint16_t got =
                    j2.conv_states[static_cast<long>(0) * dim * (KW - 1) +
                                   static_cast<long>(gfeat) * (KW - 1) + w_i];
                if (got != want) { slot0_ok = false; break; }
            }
        if (!slot0_ok && f < 5) {
            std::printf("  slot 0 corrupted by pad skip\n");
            ++f;
        }
        fails += f > 0;
        std::printf("2. pad slot skip (pad untouched, non-pad intact): %s\n",
                    f ? "FAIL" : "PASS");
    }

    // ── 3. short sequences (seqlen 1/2 branch of the tail contract) ──
    {
        int f = 0;
        constexpr int d3 = dim;
        SplitJob s;
        s.dim = d3;
        s.k_dim = k_dim;
        s.T = 3;
        s.num_slots = 2;
        s.has_bias = true;
        s.do_silu = true;
        s.pad_slot_id = -1;
        s.x.resize(3L * d3);
        {
            Lcg rng(0x31);
            for (auto& v : s.x) v = f32_to_bf16(rng.uniform(-2.f, 2.f));
        }
        s.w = j.w;
        s.bias = j.bias;
        s.query_start_loc = {0, 1, 3};
        s.batch_ptr = {0, 1};
        s.token_chunk_offset_ptr = {0, 0};
        s.cache_indices = {0, 1};
        s.has_initial_state = {1, 1};
        s.conv_states.assign(2L * d3 * (KW - 1), 0);
        {
            Lcg rng(0x41);
            for (auto& v : s.conv_states) v = f32_to_bf16(rng.uniform(-1.f, 1.f));
        }
        const std::vector<std::uint16_t> pre = s.conv_states;
        auto q = outs(3L * k_dim);
        auto k = outs(3L * k_dim);
        auto v = outs(3L * k_dim);
        run_chunked(s, q.data(), k.data(), v.data());
        // seqlen 1 (slot 0): state = [old1, old2, x0]; seqlen 2 (slot 1): [old2, x0, x1]
        ++checks;
        bool s1_ok = true;
        for (int gfeat = 0; gfeat < d3 && s1_ok; ++gfeat) {
            const long sb = static_cast<long>(gfeat) * (KW - 1);
            if (s.conv_states[sb] != pre[sb + 1] ||
                s.conv_states[sb + 1] != pre[sb + 2] ||
                s.conv_states[sb + 2] != s.x[static_cast<long>(gfeat)])
                s1_ok = false;
        }
        if (!s1_ok && f < 5) {
            std::printf("  seqlen 1 slide wrong\n");
            ++f;
        }
        ++checks;
        bool s2_ok = true;
        for (int gfeat = 0; gfeat < d3 && s2_ok; ++gfeat) {
            const long sb = static_cast<long>(1) * d3 * (KW - 1) + static_cast<long>(gfeat) * (KW - 1);
            if (s.conv_states[sb] != pre[sb + 2] ||
                s.conv_states[sb + 1] != s.x[static_cast<long>(1) * d3 + gfeat] ||
                s.conv_states[sb + 2] != s.x[static_cast<long>(2) * d3 + gfeat])
                s2_ok = false;
        }
        if (!s2_ok && f < 5) {
            std::printf("  seqlen 2 slide wrong\n");
            ++f;
        }
        // outputs for short seqs still agree with flat. run_chunked's tail
        // contract already slid s.conv_states (seqlen<3 branch) — restore the
        // snapshot so run_flat reads the same INITIAL window run_chunked read.
        s.conv_states = pre;
        ++checks;
        auto q2 = outs(3L * k_dim);
        auto k2 = outs(3L * k_dim);
        auto v2 = outs(3L * k_dim);
        run_flat(s, q2.data(), k2.data(), v2.data());
        const long bad = cmp_bitwise(q, q2, 3L * k_dim) +
                         cmp_bitwise(k, k2, 3L * k_dim) +
                         cmp_bitwise(v, v2, 3L * k_dim);
        if (bad && f < 5) {
            std::printf("  short-seq outputs: %ld bitwise mismatches\n", bad);
            ++f;
        }
        fails += f > 0;
        std::printf("3. short sequences (seqlen 1/2 state slide): %s\n",
                    f ? "FAIL" : "PASS");
    }

    std::printf("causal_conv1d_fwd_split_qkv: %d checks, %d failures -> %s\n",
                checks, fails, fails ? "FAIL" : "PASS");
    return fails ? 1 : 0;
}
