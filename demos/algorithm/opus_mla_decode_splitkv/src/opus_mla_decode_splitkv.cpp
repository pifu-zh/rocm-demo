// SPDX-License-Identifier: MIT
// Copyright (C) 2026, Advanced Micro Devices, Inc. All rights reserved.
//
// Host reference for aiter's opus MLA decode split-KV pipeline (gfx950-only on
// device): the scheduler/ABI + per-split decode math + split-KV reduce, as
// pinned from csrc/kernels/mla/opus_mla_decode_fwd.cu, csrc/kernels/mla/opus/
// mla_decode_kargs.h, csrc/include/mla_reduce_kernels.cuh and the device
// consumption in opus/gfx950/mla_decode_a8w8_16mx1_32nx4.hpp @
// 1eab5ae12c93af3c8c660202d9a413f637c2f011 (MIT). The MFMA tile machinery
// itself is device-line (prebuilt .co objects); this demo pins everything a
// host can verify about the pipeline.
//
// The contract, as pinned from the source:
//   * FROZEN KERNEL-ARGUMENT ABI (static_asserts upstream, mirrored here):
//     work_info 32 B; merged decode kargs 136 B with work_info_set at 80 and
//     softmax_scale at 116; the a8w8 extension +16 B (two descale pointers);
//     the mxfp8 kargs 176 B with work_info_set at 112 and softmax_scale at
//     172. The .co files are compiled against these byte layouts -- any field
//     change requires a rebuild, so the offsets ARE the interface.
//   * WORK SCHEDULER: one work item per (pseudo-batch, split):
//     {batch_idx, partial_slot, qo_start/end, kv_start/end, kv_offset}.
//     kv_start/end index the batch's kv_indices token list; kv_offset =
//     original batch KV end - this split's kv_end (mla.py folds heads into
//     pseudo-batches: batch_idx indexes the FOLDED q_indptr while kv_indptr
//     stays per original batch, so the causal diagonal is recovered as
//     qo_start - kv_start + kv_end + kv_offset - q_indptr[batch_idx+1]).
//     partial_slot < 0 = work item owns the whole request -> final output
//     written directly, no reduce.
//   * MERGED d=576 BUFFERS: one row per (token, head); rope is the +512
//     slice. stride_kv_page = 576 and the fp8 builds run page_size 1 (the
//     rope DMA deals a 16-token line and cannot carry a per-lane within-page
//     offset), so kv_indices[t] addresses token records directly.
//   * PER-SPLIT DECODE MATH (from the device kernel):
//     qk_scale = softmax_scale * descale_q * descale_k -- the QK descales
//     ride the softmax temperature and the PV MFMA consumes RAW fp8;
//     per row: m = max(score), l = sum(exp(score - m)),
//     partial O = (l > 0) ? descale_k * sum(exp(score-m) * V8) / l : 0
//     (V8 = the record's first 512 dims, raw fp8 -- "softmax normalisation
//     and the V descale in one multiply"; l == 0 means every score masked,
//     O must be 0 rather than NaN), partial LSE = m + log(l).
//   * SPLIT-KV REDUCE (mla_reduce_v1): max_lse over splits, sum_lse =
//     sum(exp(lse_s - max_lse)), global_lse = (sum == 0 || NaN) ? INFINITY
//     : log(sum_lse) + max_lse, lse_scale_s = exp(lse_s - global_lse),
//     O = sum(lse_scale_s * O_s). The algebra closes ONLY because each
//     split's partial output is normalized within its split.
//   * LARGE-KV FALLBACK: a buffer descriptor's num_records is 32 bits, so a
//     KV cache >= 4 GiB wraps the bound and every load beyond returns zero
//     silently; page_size 1 puts one tile's 32 tokens at per-lane unrelated
//     offsets so the descriptor cannot be rebased per tile -- the large path
//     switches KV addressing to a flat 64-bit pointer (global_load_lds) at a
//     measured ~1-2% cost. A hardware-limitation -> software-path case.
//
// Two host schedules cross-validate:
//   run_pipeline -- scheduler -> split decode -> reduce merge;
//   run_reference -- one full-range softmax pass per (batch, head), an
//                    independent flat implementation.
// Split reordering makes float results differ, so O compares within a
// tolerance; the structural contracts (causal no-op at q=1, the merge
// algebra identity, lse_scale convexity) compare bitwise.

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <cstddef>
#include <cstdio>
#include <cstring>
#include <limits>
#include <vector>

// ── lab-shared primitives ──
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
// NaN-free random fp8: real cache records never carry NaN (the encoder
// clamps to FP8_MAX), so 0x7F/0xFF never occur. Magnitudes capped at 0x40
// (|v| <= 1.875*2 = 3.75) to model actual quantized activations -- full-range
// random bytes put the QK dot at ~1e8, lse at ~680, and the merge weights'
// float error at ulp(680) = 6e-5, swamping the convexity check.
static inline std::uint8_t rand_fp8(Lcg& rng) {
    const std::uint32_t mag = rng.next() % 0x41u;
    const std::uint32_t sign = (rng.next() & 1u) << 7;
    return static_cast<std::uint8_t>(mag | sign);
}
static inline float e4m3_to_f32(std::uint8_t b) {
    const std::uint32_t sign = (b & 0x80u) ? 0x80000000u : 0u;
    const std::uint32_t rest = b & 0x7Fu;
    float out;
    if ((rest >> 3) == 0 && (rest & 7) != 0) {
        out = static_cast<float>(rest) * 0.001953125f;
    } else if (rest == 0x7F) {
        out = std::nanf("");
    } else {
        const std::uint32_t bits = (rest << 20) + ((127 - 7) << 23);
        std::memcpy(&out, &bits, 4);
    }
    std::uint32_t u;
    std::memcpy(&u, &out, 4);
    u |= sign;
    std::memcpy(&out, &u, 4);
    return out;
}

static int checks = 0, fails = 0;
#define CHECK(cond)                                                                              \
    do {                                                                                         \
        ++checks;                                                                                \
        if (!(cond)) {                                                                           \
            ++fails;                                                                             \
            if (fails <= 20)                                                                     \
                std::printf("  CHECK failed at line %d: %s\n", __LINE__, #cond);                 \
        }                                                                                        \
    } while (0)

// ════════ 0. the frozen ABI, mirrored byte for byte ════════
// (field order and sizes transcribed from mla_decode_kargs.h; the host here
// is x86-64 LP64, same pointer width as the device build)
namespace abi {

struct WorkInfo {
    int batch_idx;
    int partial_slot;
    int qo_start;
    int qo_end;
    int kv_start;
    int kv_end;
    int kv_offset;
    int _pad;
};
struct DecodeKargs {
    const void* q_ptr;
    const void* kv_ptr;
    const void* out_ptr;
    const void* lse_ptr;
    const void* o_accum;
    const void* lse_accum;
    const int* q_indptr;
    const int* kv_indptr;
    const int* kv_indices;
    const int* work_indptr;
    const WorkInfo* work_info_set;
    int H;
    int total_tokens;
    int stride_q_b;
    int stride_q_h;
    int stride_o_b;
    int stride_o_h;
    int stride_kv_page;
    float softmax_scale;
    const int* g_kv_indptr;
    int cp_world_size;
    int cp_rank;
};
struct A8W8Kargs : DecodeKargs {
    const void* q_scale_ptr;
    const void* kv_scale_ptr;
};
struct Mxfp8Kargs {
    const void* q_nope_ptr;
    const void* q_scale_ptr;
    const void* q_rope_ptr;
    const void* kv_nope_ptr;
    const void* kv_scale_ptr;
    const void* kv_rope_ptr;
    const void* out_ptr;
    const void* lse_ptr;
    const void* o_accum;
    const void* lse_accum;
    const int* q_indptr;
    const int* kv_indptr;
    const int* kv_indices;
    const int* work_indptr;
    const WorkInfo* work_info_set;
    int H;
    int total_tokens;
    int stride_q_nope_b;
    int stride_q_nope_h;
    int stride_q_scale_b;
    int stride_q_scale_h;
    int stride_q_rope_b;
    int stride_q_rope_h;
    int stride_o_b;
    int stride_o_h;
    int stride_kv_nope_page;
    int stride_kv_scale_page;
    int stride_kv_rope_page;
    float softmax_scale;
};

static_assert(sizeof(WorkInfo) == 32, "work info ABI");
static_assert(sizeof(DecodeKargs) == 136, "merged kargs ABI");
static_assert(offsetof(DecodeKargs, work_info_set) == 80, "work_info_set offset");
static_assert(offsetof(DecodeKargs, softmax_scale) == 116, "softmax_scale offset");
static_assert(offsetof(DecodeKargs, cp_rank) == 132, "cp_rank offset");
static_assert(sizeof(A8W8Kargs) == sizeof(DecodeKargs) + 16, "a8w8 extension ABI");
static_assert(sizeof(Mxfp8Kargs) == 176, "mxfp8 kargs ABI");
static_assert(offsetof(Mxfp8Kargs, work_info_set) == 112, "mxfp8 work_info_set offset");
static_assert(offsetof(Mxfp8Kargs, softmax_scale) == 172, "mxfp8 softmax_scale offset");

constexpr int kHeadDimQk = 576;
constexpr int kHeadDimVo = 512;

}  // namespace abi

// ════════ the pipeline job ════════
struct MlaJob {
    int H = 0;                    // heads (per KV head; MLA has one KV head)
    int num_batches = 0;
    bool causal = false;
    int max_seqlen_q = 1;
    float softmax_scale = 1.0f;
    float descale_q = 1.0f;
    float descale_k = 1.0f;
    // fp8 activations/records, merged d=576 (nope [0,512) + rope [512,576))
    std::vector<std::uint8_t> q;        // [q_rows, H, 576]
    std::vector<std::uint8_t> kv;       // [total_tokens, 576]
    std::vector<int> q_indptr;          // [num_batches+1] row starts in q
    std::vector<int> kv_indptr;         // [num_batches+1] token-list starts
    std::vector<int> kv_indices;        // token list: logical -> physical row
    int splits = 1;                     // splits per batch (uniform; upstream varies)
    // outputs
    std::vector<float> out;             // [q_rows, H, 512]
    std::vector<float> lse;             // [q_rows, H]
    long q_rows() const { return static_cast<long>(q_indptr.back()); }
    long kv_tokens() const { return static_cast<long>(kv_indptr.back()); }
};

// per-split decode, the device kernel's math verbatim
struct SplitPartial {
    std::vector<float> o;    // normalized + descale_k applied
    std::vector<float> lse;  // m + log(l) per (row, head)
};

static SplitPartial decode_split(const MlaJob& j, const abi::WorkInfo& wi) {
    SplitPartial p;
    const int q_rows = wi.qo_end - wi.qo_start;
    const int kv_len = wi.kv_end - wi.kv_start;
    p.o.assign(static_cast<std::size_t>(q_rows) * j.H * abi::kHeadDimVo, 0.f);
    p.lse.assign(static_cast<std::size_t>(q_rows) * j.H, -std::numeric_limits<float>::infinity());
    const float qk_scale = j.softmax_scale * j.descale_q * j.descale_k;
    // causal diagonal per the device formula (pseudo-batch folding)
    const int causal_diagonal =
        wi.qo_start - wi.kv_start + wi.kv_end + wi.kv_offset - j.q_indptr[static_cast<std::size_t>(wi.batch_idx) + 1];

    for (int qr = 0; qr < q_rows; ++qr) {
        const long qrow = wi.qo_start + qr;
        // batch-relative q position for the causal mask
        const int q_pos = wi.qo_start + qr - j.q_indptr[static_cast<std::size_t>(wi.batch_idx)];
        for (int h = 0; h < j.H; ++h) {
            float m = -std::numeric_limits<float>::infinity();
            // pass 1: scores + max
            std::vector<float> sc(static_cast<std::size_t>(kv_len));
            for (int t = 0; t < kv_len; ++t) {
                const int phys = j.kv_indices[static_cast<std::size_t>(wi.kv_start + t)];
                const std::uint8_t* kp = &j.kv[static_cast<std::size_t>(phys) * abi::kHeadDimQk];
                const std::uint8_t* qp =
                    &j.q[static_cast<std::size_t>(qrow) * j.H * abi::kHeadDimQk +
                         static_cast<std::size_t>(h) * abi::kHeadDimQk];
                float acc = 0.f;
                for (int d = 0; d < abi::kHeadDimQk; ++d)
                    acc += e4m3_to_f32(qp[d]) * e4m3_to_f32(kp[d]);
                bool visible = true;
                if (j.causal && j.max_seqlen_q > 1) {
                    const int t_pos = wi.kv_start + t - j.kv_indptr[static_cast<std::size_t>(wi.batch_idx)];
                    visible = t_pos <= q_pos;
                }
                const float s = visible ? qk_scale * acc
                                        : -std::numeric_limits<float>::infinity();
                sc[static_cast<std::size_t>(t)] = s;
                m = std::fmax(m, s);
            }
            // pass 2: p sum + V accumulate (V8 = first 512 dims, raw fp8)
            float l = 0.f;
            std::vector<float> o(abi::kHeadDimVo, 0.f);
            if (m > -std::numeric_limits<float>::infinity()) {
                for (int t = 0; t < kv_len; ++t) {
                    const float e = std::exp(sc[static_cast<std::size_t>(t)] - m);
                    l += e;
                    const int phys = j.kv_indices[static_cast<std::size_t>(wi.kv_start + t)];
                    const std::uint8_t* vp = &j.kv[static_cast<std::size_t>(phys) * abi::kHeadDimQk];
                    for (int d = 0; d < abi::kHeadDimVo; ++d)
                        o[static_cast<std::size_t>(d)] += e * e4m3_to_f32(vp[d]);
                }
            }
            // "softmax normalisation and the V descale in one multiply";
            // l == 0 (all masked) -> O must be 0 rather than NaN
            const float o_scale = (l > 0.f) ? j.descale_k / l : 0.f;
            for (int d = 0; d < abi::kHeadDimVo; ++d)
                p.o[static_cast<std::size_t>((qr * j.H + h) * abi::kHeadDimVo + d)] =
                    o[static_cast<std::size_t>(d)] * o_scale;
            p.lse[static_cast<std::size_t>(qr * j.H + h)] =
                (l > 0.f) ? m + std::log(l) : -std::numeric_limits<float>::infinity();
        }
    }
    (void)causal_diagonal;  // pinned; the direct mask above is its semantics
    return p;
}

// ── schedule 1: scheduler -> split decode -> reduce ──
static void run_pipeline(MlaJob& j) {
    std::vector<abi::WorkInfo> work;
    std::vector<int> work_indptr(static_cast<std::size_t>(j.num_batches) + 1);
    // partial rows are assigned compactly in work order
    int next_partial = 0;
    for (int b = 0; b < j.num_batches; ++b) {
        work_indptr[static_cast<std::size_t>(b)] = static_cast<int>(work.size());
        const int kv_s = j.kv_indptr[static_cast<std::size_t>(b)];
        const int kv_e = j.kv_indptr[static_cast<std::size_t>(b) + 1];
        const int kv_len = kv_e - kv_s;
        const int S = std::min(j.splits, std::max(1, kv_len));
        const int chunk = (kv_len + S - 1) / S;
        for (int s = 0; s < S; ++s) {
            abi::WorkInfo wi{};
            wi.batch_idx = b;
            wi.qo_start = j.q_indptr[static_cast<std::size_t>(b)];
            wi.qo_end = j.q_indptr[static_cast<std::size_t>(b) + 1];
            wi.kv_start = kv_s + s * chunk;
            wi.kv_end = std::min(kv_e, wi.kv_start + chunk);
            wi.kv_offset = kv_e - wi.kv_end;
            if (S == 1) {
                wi.partial_slot = -1;  // owns the whole request: direct write
            } else {
                wi.partial_slot = next_partial++;
            }
            work.push_back(wi);
        }
    }
    work_indptr[static_cast<std::size_t>(j.num_batches)] = static_cast<int>(work.size());
    j.out.assign(static_cast<std::size_t>(j.q_rows()) * j.H * abi::kHeadDimVo, 0.f);
    j.lse.assign(static_cast<std::size_t>(j.q_rows()) * j.H, 0.f);

    for (const auto& wi : work) {
        if (wi.partial_slot < 0) {
            // direct: the whole-request item computes its final output itself
            SplitPartial p = decode_split(j, wi);
            const int q_rows = wi.qo_end - wi.qo_start;
            for (int qr = 0; qr < q_rows; ++qr)
                for (int h = 0; h < j.H; ++h) {
                    const long row = wi.qo_start + qr;
                    for (int d = 0; d < abi::kHeadDimVo; ++d)
                        j.out[static_cast<std::size_t>(row * j.H * abi::kHeadDimVo + h * abi::kHeadDimVo + d)] =
                            p.o[static_cast<std::size_t>((qr * j.H + h) * abi::kHeadDimVo + d)];
                    j.lse[static_cast<std::size_t>(row * j.H + h)] =
                        p.lse[static_cast<std::size_t>(qr * j.H + h)];
                }
        }
    }
    // multi-split items: decode their splits, then reduce per partial group
    std::vector<SplitPartial> parts;
    for (int b = 0; b < j.num_batches; ++b) {
        const int w0 = work_indptr[static_cast<std::size_t>(b)];
        const int w1 = work_indptr[static_cast<std::size_t>(b) + 1];
        if (w1 - w0 <= 1) continue;  // direct item(s) only
        parts.clear();
        for (int w = w0; w < w1; ++w) parts.push_back(decode_split(j, work[static_cast<std::size_t>(w)]));
        const int q_rows = work[static_cast<std::size_t>(w0)].qo_end - work[static_cast<std::size_t>(w0)].qo_start;
        for (int qr = 0; qr < q_rows; ++qr) {
            const long row = work[static_cast<std::size_t>(w0)].qo_start + qr;
            for (int h = 0; h < j.H; ++h) {
                // mla_reduce_v1: max_lse -> sum_lse -> global_lse (INFINITY
                // guard) -> lse_scale weights -> weighted partial sum
                float max_lse = -std::numeric_limits<float>::infinity();
                for (int s = 0; s < static_cast<int>(parts.size()); ++s)
                    max_lse = std::fmax(max_lse, parts[static_cast<std::size_t>(s)].lse[static_cast<std::size_t>(qr * j.H + h)]);
                float sum_lse = 0.f;
                for (int s = 0; s < static_cast<int>(parts.size()); ++s)
                    sum_lse += std::exp(parts[static_cast<std::size_t>(s)].lse[static_cast<std::size_t>(qr * j.H + h)] - max_lse);
                const float global_lse =
                    (sum_lse == 0.f || sum_lse != sum_lse)
                        ? std::numeric_limits<float>::infinity()
                        : std::log(sum_lse) + max_lse;
                j.lse[static_cast<std::size_t>(row * j.H + h)] = global_lse;
                for (int s = 0; s < static_cast<int>(parts.size()); ++s) {
                    const float w = std::exp(parts[static_cast<std::size_t>(s)].lse[static_cast<std::size_t>(qr * j.H + h)] - global_lse);
                    for (int d = 0; d < abi::kHeadDimVo; ++d)
                        j.out[static_cast<std::size_t>(row * j.H * abi::kHeadDimVo + h * abi::kHeadDimVo + d)] +=
                            w * parts[static_cast<std::size_t>(s)].o[static_cast<std::size_t>((qr * j.H + h) * abi::kHeadDimVo + d)];
                }
            }
        }
    }
}

// ── schedule 2: independent flat reference ──
static void run_reference(const MlaJob& j, std::vector<float>& out, std::vector<float>& lse) {
    const float qk_scale = j.softmax_scale * j.descale_q * j.descale_k;
    out.assign(static_cast<std::size_t>(j.q_rows()) * j.H * abi::kHeadDimVo, 0.f);
    lse.assign(static_cast<std::size_t>(j.q_rows()) * j.H, 0.f);
    for (int b = 0; b < j.num_batches; ++b) {
        const int kv_s = j.kv_indptr[static_cast<std::size_t>(b)];
        const int kv_e = j.kv_indptr[static_cast<std::size_t>(b) + 1];
        const int kv_len = kv_e - kv_s;
        for (int qr = j.q_indptr[static_cast<std::size_t>(b)]; qr < j.q_indptr[static_cast<std::size_t>(b) + 1]; ++qr) {
            const int q_pos = qr - j.q_indptr[static_cast<std::size_t>(b)];
            for (int h = 0; h < j.H; ++h) {
                const std::uint8_t* qp = &j.q[static_cast<std::size_t>(qr) * j.H * abi::kHeadDimQk +
                                              static_cast<std::size_t>(h) * abi::kHeadDimQk];
                float m = -std::numeric_limits<float>::infinity();
                std::vector<float> sc(static_cast<std::size_t>(std::max(kv_len, 1)));
                for (int t = 0; t < kv_len; ++t) {
                    const int phys = j.kv_indices[static_cast<std::size_t>(kv_s + t)];
                    const std::uint8_t* kp = &j.kv[static_cast<std::size_t>(phys) * abi::kHeadDimQk];
                    float acc = 0.f;
                    for (int d = 0; d < abi::kHeadDimQk; ++d)
                        acc += e4m3_to_f32(qp[d]) * e4m3_to_f32(kp[d]);
                    const bool visible = !j.causal || j.max_seqlen_q <= 1 ||
                                         (kv_s + t - kv_s) <= q_pos;
                    sc[static_cast<std::size_t>(t)] = visible ? qk_scale * acc
                                                              : -std::numeric_limits<float>::infinity();
                    m = std::fmax(m, sc[static_cast<std::size_t>(t)]);
                }
                float l = 0.f;
                std::vector<float> o(abi::kHeadDimVo, 0.f);
                if (m > -std::numeric_limits<float>::infinity()) {
                    for (int t = 0; t < kv_len; ++t) {
                        const float e = std::exp(sc[static_cast<std::size_t>(t)] - m);
                        l += e;
                        const int phys = j.kv_indices[static_cast<std::size_t>(kv_s + t)];
                        const std::uint8_t* vp = &j.kv[static_cast<std::size_t>(phys) * abi::kHeadDimQk];
                        for (int d = 0; d < abi::kHeadDimVo; ++d)
                            o[static_cast<std::size_t>(d)] += e * e4m3_to_f32(vp[d]);
                    }
                }
                const float o_scale = (l > 0.f) ? j.descale_k / l : 0.f;
                for (int d = 0; d < abi::kHeadDimVo; ++d)
                    out[static_cast<std::size_t>(qr * j.H * abi::kHeadDimVo + h * abi::kHeadDimVo + d)] =
                        o[static_cast<std::size_t>(d)] * o_scale;
                lse[static_cast<std::size_t>(qr * j.H + h)] =
                    (l > 0.f) ? m + std::log(l) : -std::numeric_limits<float>::infinity();
            }
        }
    }
}

static void fill_job(MlaJob& j, std::uint64_t seed) {
    Lcg rng(seed);
    const int lens[3] = {1 + static_cast<int>(rng.next() % 8), 7, 33};
    j.q_indptr = {0};
    j.kv_indptr = {0};
    std::vector<int> lensv;
    for (int b = 0; b < j.num_batches; ++b) {
        const int ql = (b == 0) ? 1 : 1 + static_cast<int>(rng.next() % j.max_seqlen_q);
        lensv.push_back(lens[b % 3]);
        j.q_indptr.push_back(j.q_indptr.back() + ql);
        j.kv_indptr.push_back(j.kv_indptr.back() + lens[b % 3]);
    }
    // physical records: shuffled identity so kv_indices is a real permutation
    const int total = j.kv_indptr.back();
    std::vector<int> phys(total);
    for (int i = 0; i < total; ++i) phys[static_cast<std::size_t>(i)] = i;
    for (int i = total - 1; i > 0; --i)
        std::swap(phys[static_cast<std::size_t>(i)],
                  phys[static_cast<std::size_t>(rng.next() % static_cast<std::uint32_t>(i + 1))]);
    j.kv_indices = phys;
    j.q.resize(static_cast<std::size_t>(j.q_rows()) * j.H * abi::kHeadDimQk);
    j.kv.resize(static_cast<std::size_t>(total) * abi::kHeadDimQk);
    for (auto& v : j.q) v = rand_fp8(rng);
    for (auto& v : j.kv) v = rand_fp8(rng);
    j.out.assign(static_cast<std::size_t>(j.q_rows()) * j.H * abi::kHeadDimVo, 0.f);
    j.lse.assign(static_cast<std::size_t>(j.q_rows()) * j.H, 0.f);
}

int main() {
    // ════ 0. ABI mirror ════
    {
        CHECK(sizeof(abi::WorkInfo) == 32);
        CHECK(sizeof(abi::DecodeKargs) == 136);
        CHECK(offsetof(abi::DecodeKargs, work_info_set) == 80);
        CHECK(offsetof(abi::DecodeKargs, softmax_scale) == 116);
        CHECK(offsetof(abi::DecodeKargs, cp_rank) == 132);
        CHECK(sizeof(abi::A8W8Kargs) == 152);  // 136 + two pointers
        CHECK(sizeof(abi::Mxfp8Kargs) == 176);
        CHECK(offsetof(abi::Mxfp8Kargs, work_info_set) == 112);
        CHECK(offsetof(abi::Mxfp8Kargs, softmax_scale) == 172);
        CHECK(abi::kHeadDimQk == 576 && abi::kHeadDimVo == 512);
    }

    // ════ 1. scheduler decode + causal diagonal formula ════
    {
        // a folded-heads batch: kv_indptr stays per ORIGINAL batch, so the
        // item's kv_offset = kv_e(original) - kv_end(split) restores the end
        MlaJob j;
        j.H = 2; j.num_batches = 2; j.max_seqlen_q = 3; j.splits = 2;
        j.q_indptr = {0, 3, 5};   // batch 0: 3 q rows, batch 1: 2
        j.kv_indptr = {0, 40, 41};
        const int kv_e0 = 40;
        abi::WorkInfo wi{};
        wi.batch_idx = 0;
        wi.qo_start = 0; wi.qo_end = 3;
        wi.kv_start = 20; wi.kv_end = 40;
        wi.kv_offset = kv_e0 - wi.kv_end;  // 0 for the last split
        const int diag_last = wi.qo_start - wi.kv_start + wi.kv_end + wi.kv_offset -
                              j.q_indptr[1];
        CHECK(diag_last == 0 - 20 + 40 + 0 - 3);
        abi::WorkInfo w0 = wi;
        w0.kv_end = 20;
        w0.kv_offset = kv_e0 - w0.kv_end;  // 20 for the first split
        const int diag_first = w0.qo_start - w0.kv_start + w0.kv_end + w0.kv_offset -
                               j.q_indptr[1];
        CHECK(diag_first == diag_last);  // the diagonal is split-independent
        // scheduler partition: splits cover [kv_s, kv_e) contiguously
        j.splits = 4;
        j.kv_indptr = {0, 33, 33};  // batch 1 empty
        fill_job(j, 0x11);
        std::vector<std::int64_t> covered(static_cast<std::size_t>(33), -1);
        int S = std::min(j.splits, 33);
        int chunk = (33 + S - 1) / S;
        int cnt = 0;
        for (int s = 0; s < S; ++s) {
            const int a = s * chunk, bnd = std::min(33, a + chunk);
            for (int t = a; t < bnd; ++t) covered[static_cast<std::size_t>(t)] = cnt;
            ++cnt;
        }
        bool full = true;
        for (int t = 0; t < 33; ++t)
            if (covered[static_cast<std::size_t>(t)] < 0) full = false;
        CHECK(full && cnt == 4);
    }

    // ════ 2. split pipeline vs flat reference + merge contracts ════
    {
        MlaJob j;
        j.H = 3; j.num_batches = 3; j.max_seqlen_q = 2; j.causal = false;
        j.splits = 3;
        j.softmax_scale = 0.125f; j.descale_q = 0.03f; j.descale_k = 0.02f;
        fill_job(j, 0x21);
        MlaJob ref = j;
        run_pipeline(j);
        std::vector<float> rout, rlse;
        run_reference(ref, rout, rlse);
        // O within tolerance (split reordering); values are convex
        // combinations of dequantized V, bounded by max|V|
        float max_v = 0.f;
        for (auto v : j.kv)
            max_v = std::fmax(max_v, std::fabs(e4m3_to_f32(v)));
        max_v *= j.descale_k;
        bool ok = true;
        for (std::size_t i = 0; i < j.out.size() && ok; ++i) {
            const float err = std::fabs(j.out[i] - rout[i]);
            if (err > 2e-5f * max_v + 1e-6f) {
                ok = false;
                std::printf("  G2DBG idx %zu pipe %.6g ref %.6g err %.3g\n", i,
                            j.out[i], rout[i], err);
            }
        }
        CHECK(ok);
        bool lse_ok = true;
        for (std::size_t i = 0; i < j.lse.size() && lse_ok; ++i) {
            const float err = std::fabs(j.lse[i] - rlse[i]);
            if (err > 1e-4f * std::fmax(1.f, std::fabs(rlse[i]))) {
                lse_ok = false;
                std::printf("  G2DBG lse %zu pipe %.6g ref %.6g\n", i, j.lse[i], rlse[i]);
            }
        }
        CHECK(lse_ok);
        // merge algebra identity: reconstruct O from the pipeline's own
        // per-split partials (recomputed in test) -- bitwise
        {
            // recompute batch 0's splits with the PIPELINE's own geometry and
            // re-merge with the same op order -- must match j.out bitwise
            MlaJob js = j;
            js.num_batches = 1;
            js.q_indptr = {0, j.q_indptr[1]};
            js.kv_indptr = {0, j.kv_indptr[1]};
            const int kv_len0 = j.kv_indptr[1];
            const int S0 = std::min(j.splits, std::max(1, kv_len0));
            const int chunk = (kv_len0 + S0 - 1) / S0;
            std::vector<SplitPartial> parts;
            for (int s = 0; s < S0; ++s) {
                abi::WorkInfo wi{};
                wi.batch_idx = 0;
                wi.qo_start = 0;
                wi.qo_end = static_cast<int>(js.q_rows());
                wi.kv_start = s * chunk;
                wi.kv_end = std::min(kv_len0, wi.kv_start + chunk);
                wi.kv_offset = kv_len0 - wi.kv_end;
                parts.push_back(decode_split(js, wi));
            }
            // merge with the same op order as reduce_merge, per row/head
            bool ident = true;
            for (long qr = 0; qr < js.q_rows() && ident; ++qr)
                for (int h = 0; h < js.H && ident; ++h) {
                    float max_lse = -std::numeric_limits<float>::infinity();
                    for (auto& p : parts)
                        max_lse = std::fmax(max_lse, p.lse[static_cast<std::size_t>(qr * js.H + h)]);
                    float sum_lse = 0.f;
                    for (auto& p : parts)
                        sum_lse += std::exp(p.lse[static_cast<std::size_t>(qr * js.H + h)] - max_lse);
                    const float gl = std::log(sum_lse) + max_lse;
                    for (int d = 0; d < abi::kHeadDimVo; ++d) {
                        float acc = 0.f;
                        for (int s = 0; s < S0; ++s) {
                            const float w = std::exp(parts[static_cast<std::size_t>(s)].lse[static_cast<std::size_t>(qr * js.H + h)] - gl);
                            acc += w * parts[static_cast<std::size_t>(s)].o[static_cast<std::size_t>(qr * js.H * abi::kHeadDimVo + h * abi::kHeadDimVo + d)];
                        }
                        if (acc != j.out[static_cast<std::size_t>(qr * js.H * abi::kHeadDimVo + h * abi::kHeadDimVo + d)])
                            ident = false;
                    }
                }
            CHECK(ident);
        }
        // lse_scale convexity: sum of exp(lse_s - global) == 1
        {
            // with S0 splits, weights per row/head sum to 1 (up to float eps)
            bool convex = true;
            MlaJob js = j;
            js.num_batches = 1;
            js.q_indptr = {0, j.q_indptr[1]};
            js.kv_indptr = {0, j.kv_indptr[1]};
            const int kv_len0 = j.kv_indptr[1];
            const int S0 = std::min(j.splits, std::max(1, kv_len0));
            const int chunk = (kv_len0 + S0 - 1) / S0;
            std::vector<SplitPartial> parts;
            for (int s = 0; s < S0; ++s) {
                abi::WorkInfo wi{};
                wi.batch_idx = 0;
                wi.qo_start = 0;
                wi.qo_end = static_cast<int>(js.q_rows());
                wi.kv_start = s * chunk;
                wi.kv_end = std::min(kv_len0, wi.kv_start + chunk);
                wi.kv_offset = kv_len0 - wi.kv_end;
                parts.push_back(decode_split(js, wi));
            }
            for (long qr = 0; qr < js.q_rows() && convex; ++qr)
                for (int h = 0; h < js.H && convex; ++h) {
                    float max_lse = -std::numeric_limits<float>::infinity();
                    for (auto& p : parts)
                        max_lse = std::fmax(max_lse, p.lse[static_cast<std::size_t>(qr * js.H + h)]);
                    float sum = 0.f;
                    for (auto& p : parts)
                        sum += std::exp(p.lse[static_cast<std::size_t>(qr * js.H + h)] - max_lse);
                    const float gl = std::log(sum) + max_lse;
                    float wsum = 0.f;
                    for (auto& p : parts)
                        wsum += std::exp(p.lse[static_cast<std::size_t>(qr * js.H + h)] - gl);
                    // the weights carry gl's rounding: ulp(|gl|) ~ |gl|*1.2e-7
                    if (std::fabs(wsum - 1.f) > 4e-7f * std::fmax(1.f, std::fabs(gl))) {
                        convex = false;
                        std::printf("  CVXDBG qr%ld h%d wsum %.9g (S0 %d, lse:", qr, h, wsum, S0);
                        for (auto& p : parts)
                            std::printf(" %.4g", p.lse[static_cast<std::size_t>(qr * js.H + h)]);
                        std::printf(")\n");
                    }
                }
            CHECK(convex);
        }
    }

    // ════ 3. direct path + causal no-op + all-masked guard ════
    {
        MlaJob j;
        j.H = 2; j.num_batches = 2; j.max_seqlen_q = 1; j.splits = 2;
        j.softmax_scale = 0.1f; j.descale_q = 0.02f; j.descale_k = 0.05f;
        fill_job(j, 0x31);
        // q=1: causal is a no-op (with one query token every local KV token is
        // in its causal past) -> bitwise identical outputs
        MlaJob jc = j;
        jc.causal = true;
        run_pipeline(j);
        run_pipeline(jc);
        CHECK(j.out == jc.out && j.lse == jc.lse);
        // all-masked row: under causal PREFIX semantics token 0 is visible to
        // every row, so the only fully-masked case is an EMPTY batch --
        // l == 0 -> O = 0 (not NaN), lse = -inf
        {
            MlaJob jm = j;
            jm.num_batches = 1;
            jm.causal = true;
            jm.max_seqlen_q = 4;
            jm.q_indptr = {0, 4};
            jm.kv_indptr = {0, 0};  // empty batch
            jm.kv_indices = {};
            jm.q.assign(static_cast<std::size_t>(4) * jm.H * abi::kHeadDimQk, 0);
            jm.kv.clear();
            run_pipeline(jm);
            bool masked_ok = true;
            for (int qr = 0; qr < 4 && masked_ok; ++qr)
                for (int h = 0; h < jm.H && masked_ok; ++h) {
                    if (jm.lse[static_cast<std::size_t>(qr * jm.H + h)] !=
                        -std::numeric_limits<float>::infinity())
                        masked_ok = false;
                    for (int d = 0; d < abi::kHeadDimVo; ++d)
                        if (jm.out[static_cast<std::size_t>(qr * jm.H * abi::kHeadDimVo + h * abi::kHeadDimVo + d)] != 0.f)
                            masked_ok = false;
                }
            CHECK(masked_ok);
            // causal row visibility: 2 kv tokens, rows see prefixes -- row 1's
            // output must equal a softmax over token 0 ONLY, differ from row 3
            {
                MlaJob jc = j;
                jc.num_batches = 1;
                jc.causal = true;
                jc.max_seqlen_q = 4;
                jc.q_indptr = {0, 4};
                jc.kv_indptr = {0, 2};
                jc.kv_indices = {0, 1};
                jc.q.resize(static_cast<std::size_t>(4) * jc.H * abi::kHeadDimQk);
                {
                    Lcg rng2(0x41);
                    for (auto& v : jc.q) v = rand_fp8(rng2);
                }
                // make all q rows identical: rows 1..3 share the same visible
                // kv prefix, so with equal queries their outputs are bitwise
                // equal -- the point of the check
                for (int r = 1; r < 4; ++r)
                    std::memcpy(&jc.q[static_cast<std::size_t>(r) * jc.H * abi::kHeadDimQk],
                                jc.q.data(), jc.H * abi::kHeadDimQk);
                jc.kv.assign(static_cast<std::size_t>(2) * abi::kHeadDimQk, 0);
                {
                    Lcg rng2(0x42);
                    for (auto& v : jc.kv) v = rand_fp8(rng2);
                }
                jc.out.assign(static_cast<std::size_t>(4) * jc.H * abi::kHeadDimVo, 0.f);
                jc.lse.assign(static_cast<std::size_t>(4) * jc.H, 0.f);
                run_pipeline(jc);
                bool vis_ok = true;
                for (int h = 0; h < jc.H && vis_ok; ++h)
                    for (int d = 0; d < abi::kHeadDimVo; ++d)
                        // rows 1..3 all see both tokens (q_pos >= 1): bitwise equal
                        if (jc.out[static_cast<std::size_t>(3 * jc.H * abi::kHeadDimVo + h * abi::kHeadDimVo + d)] !=
                            jc.out[static_cast<std::size_t>(1 * jc.H * abi::kHeadDimVo + h * abi::kHeadDimVo + d)])
                            vis_ok = false;
                CHECK(vis_ok);
                // row 0 sees token 0 only -> differs from row 3 (softmax over
                // two tokens unless token 1 is far weaker)
                CHECK(jc.lse[0] != jc.lse[3]);
            }
        }
    }

    // ════ 4. randomized master sweep ════
    {
        int rows = 0;
        for (int seed = 0; seed < 5; ++seed) {
            MlaJob j;
            j.H = 2 + static_cast<int>(seed % 2);
            j.num_batches = 3;
            j.max_seqlen_q = 1 + static_cast<int>(seed % 3);
            j.causal = (seed % 2) == 1;
            j.splits = 1 + static_cast<int>(seed % 4);
            j.softmax_scale = 0.2f;
            j.descale_q = 0.015f + 0.005f * static_cast<float>(seed);
            j.descale_k = 0.02f;
            fill_job(j, 0x9000u + static_cast<std::uint64_t>(seed));
            MlaJob ref = j;
            run_pipeline(j);
            std::vector<float> rout, rlse;
            run_reference(ref, rout, rlse);
            ++rows;
            float max_v = 0.f;
            for (auto v : j.kv)
                max_v = std::fmax(max_v, std::fabs(e4m3_to_f32(v)));
            max_v *= j.descale_k;
            bool ok = true;
            for (std::size_t i = 0; i < j.out.size() && ok; ++i) {
                const float err = std::fabs(j.out[i] - rout[i]);
                if (err > 2e-5f * max_v + 1e-6f) ok = false;
            }
            CHECK(ok);
            bool lse_ok = true;
            for (std::size_t i = 0; i < j.lse.size() && lse_ok; ++i) {
                const float err = std::fabs(j.lse[i] - rlse[i]);
                if (err > 1e-4f * std::fmax(1.f, std::fabs(rlse[i]))) lse_ok = false;
            }
            CHECK(lse_ok);
        }
        std::printf("  sweep: %d rows, split pipeline vs flat reference\n", rows);
        CHECK(rows == 5);
    }

    std::printf("opus_mla_decode_splitkv: %d checks, %d failures -> %s\n", checks, fails,
                fails ? "FAIL" : "PASS");
    return fails ? 1 : 0;
}
