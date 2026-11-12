// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2026, Advanced Micro Devices, Inc. All rights reserved.
//
// Demo: MXFP4 (E2M1 + e8m0 group scales) dot product on a GPU with NO fp4
// hardware (gfx1030 / RDNA2), demonstrating the **scale-folding (SF) GEMM
// structure** from the aiter/DeepGEMM quant line:
//
//   C[m,n] = sum_g  SFA[m,g] * SFB[g,n] * ( sum_{k in group g} dec(A)·dec(B) )
//
// The per-group scales multiply OUTSIDE the group's inner sum, so the hot
// loop is pure fp32 FFMA over decoded nibbles; one scale product per group
// instead of per element. E2M1: values 0/.5/1/1.5/2/3/4/6 (bias 1, subnormal
// 0.5·man); e8m0 scale byte = 2^(byte-127). Nibble order pinned: element 2i
// in the low nibble of byte i/2 (matches aiter_ref::hadamard_quant).
//
// Build & run (inside the ROCm container):
//   hipcc -x hip --offload-arch=gfx1030 soft_fp4.hip -o soft_fp4 && ./soft_fp4
#include <hip/hip_runtime.h>
#include <cmath>
#include <cstdint>
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

// ── E2M1 codec, shared device/host (matches aiter_ref::hadamard_quant) ──
__host__ __device__ inline float e2m1_to_f32(std::uint8_t code) {
    const bool neg = code & 0x8;
    const std::uint32_t exp = (code >> 1) & 0x3;
    const std::uint32_t man = code & 0x1;
    float v;
    if (exp == 0) {
        v = man * 0.5f;                       // subnormal slot: 0 or 0.5
    } else {
        v = (1.0f + man * 0.5f) * exp2f(static_cast<float>(exp) - 1.0f);
    }
    return neg ? -v : v;
}

__host__ __device__ inline float e8m0_to_f32(std::uint8_t byte) {
    return exp2f(static_cast<float>(byte) - 127.0f);
}

__device__ inline std::uint8_t get_nibble(const std::uint8_t* packed, int i) {
    const std::uint8_t byte = packed[i / 2];
    return (i % 2 == 0) ? (byte & 0xF) : (byte >> 4);
}

// One thread per output element; K groups of GROUP elements each. The inner
// group sum is scale-free FFMA; scales fold in once per group.
constexpr int GROUP = 32;

__global__ void soft_fp4_dot(const std::uint8_t* __restrict__ a_packed,   // [m, k/2]
                             const std::uint8_t* __restrict__ b_packed,   // [k, n/2] fp4 along k? B packed [k, n/2]: nibbles over n
                             const std::uint8_t* __restrict__ sfa,        // [m, k/GROUP] e8m0
                             const std::uint8_t* __restrict__ sfb,        // [k/GROUP, n] e8m0
                             float* __restrict__ c, int m, int n, int k) {
    const int col = blockIdx.x * blockDim.x + threadIdx.x;
    const int row = blockIdx.y;
    if (col >= n) return;
    const int groups = k / GROUP;
    float acc = 0.0f;
    for (int g = 0; g < groups; ++g) {
        float inner = 0.0f;
        const int base = g * GROUP;
        #pragma unroll 8
        for (int i = 0; i < GROUP; ++i) {
            const int kk = base + i;
            const float va = e2m1_to_f32(get_nibble(a_packed + static_cast<long>(row) * (k / 2), kk));
            const float vb = e2m1_to_f32(get_nibble(b_packed + static_cast<long>(kk) * (n / 2), col));
            inner = fmaf(va, vb, inner);
        }
        // Scale folding: one multiply per group, outside the inner sum.
        acc = fmaf(inner, e8m0_to_f32(sfa[row * groups + g]) * e8m0_to_f32(sfb[g * n + col]),
                   acc);
    }
    c[row * n + col] = acc;
}

int main() {
    const int m = 64, n = 64, k = 128;  // k = 4 groups of 32
    unsigned seed = 0x1234567u;
    auto rnd = [&]() {
        seed = seed * 1664525u + 1013904223u;
        return (seed >> 16) & 0xF;
    };

    // A: [m, k] nibbles; B: [k, n] nibbles; scales e8m0 bytes in [1..134]
    // (2^-126 .. 2^7 — the pool from fp4_group_quant's domain).
    std::vector<std::uint8_t> a(m * k / 2, 0), b(k * n / 2, 0);
    std::vector<std::uint8_t> sfa(m * (k / GROUP)), sfb((k / GROUP) * n);
    for (auto& v : a) v = static_cast<std::uint8_t>(rnd() | (rnd() << 4));
    for (auto& v : b) v = static_cast<std::uint8_t>(rnd() | (rnd() << 4));
    for (auto& v : sfa) v = static_cast<std::uint8_t>(120 + rnd() % 8);
    for (auto& v : sfb) v = static_cast<std::uint8_t>(120 + rnd() % 8);

    // Host reference in double, same fold structure.
    std::vector<float> href(m * n, 0.0f);
    std::vector<double> bound(m * n, 0.0);
    for (int i = 0; i < m; ++i)
        for (int j = 0; j < n; ++j) {
            double acc = 0.0, max_running = 0.0;
            for (int g = 0; g < k / GROUP; ++g) {
                double inner = 0.0;
                for (int t = 0; t < GROUP; ++t) {
                    const int kk = g * GROUP + t;
                    const auto an = static_cast<std::uint8_t>(
                        (kk % 2 == 0) ? (a[i * k / 2 + kk / 2] & 0xF) : (a[i * k / 2 + kk / 2] >> 4));
                    const auto bn = static_cast<std::uint8_t>(
                        (j % 2 == 0) ? (b[kk * n / 2 + j / 2] & 0xF) : (b[kk * n / 2 + j / 2] >> 4));
                    inner += static_cast<double>(e2m1_to_f32(an)) * e2m1_to_f32(bn);
                }
                const double sf = static_cast<double>(e8m0_to_f32(sfa[i * (k / GROUP) + g])) *
                                  e8m0_to_f32(sfb[g * n + j]);
                acc += inner * sf;
                max_running = fmax(max_running, fabs(acc));
            }
            href[i * n + j] = static_cast<float>(acc);
            bound[i * n + j] = 1.1920929e-07 * (k + k / GROUP) * max_running + 1e-9;
        }

    std::uint8_t *da, *db, *dsa, *dsb;
    float* dc;
    CK(hipMalloc(&da, a.size()));
    CK(hipMalloc(&db, b.size()));
    CK(hipMalloc(&dsa, sfa.size()));
    CK(hipMalloc(&dsb, sfb.size()));
    CK(hipMalloc(&dc, m * n * 4));
    CK(hipMemcpy(da, a.data(), a.size(), hipMemcpyHostToDevice));
    CK(hipMemcpy(db, b.data(), b.size(), hipMemcpyHostToDevice));
    CK(hipMemcpy(dsa, sfa.data(), sfa.size(), hipMemcpyHostToDevice));
    CK(hipMemcpy(dsb, sfb.data(), sfb.size(), hipMemcpyHostToDevice));

    const dim3 grid((n + 63) / 64, m);
    const dim3 block(64);
    soft_fp4_dot<<<grid, block>>>(da, db, dsa, dsb, dc, m, n, k);
    CK(hipDeviceSynchronize());

    std::vector<float> hc(m * n);
    CK(hipMemcpy(hc.data(), dc, m * n * 4, hipMemcpyDeviceToHost));

    int bad = 0;
    double worst_ratio = 0.0;
    for (int i = 0; i < m * n; ++i) {
        const double diff = fabs(static_cast<double>(hc[i]) - href[i]);
        if (diff > bound[i]) ++bad;
        worst_ratio = fmax(worst_ratio, diff / bound[i]);
    }
    std::printf("soft_fp4 %dx%dx%d (groups of %d): worst err / bound = %.3f -> %s\n", m, n, k,
                GROUP, worst_ratio, bad == 0 ? "PASS" : "FAIL");
    return bad == 0 ? 0 : 1;
}
