// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2026, Advanced Micro Devices, Inc. All rights reserved.
//
// Demo: fp8 (E4M3FN) GEMM on a GPU with NO fp8 hardware (gfx1030 / RDNA2).
//
// The design being demonstrated (from the aiter quant line + the
// DeepGEMM-rdna2 fallback work): fp8 is a *storage* format — decode to f32
// in registers, accumulate with FFMA, never touch fp8 hardware. Costs:
// one decode per element per use; a 256-entry LUT in LDS trades VGPR/ALU
// for bandwidth, bit-decode trades LDS for ALU. This demo implements BOTH
// paths in-kernel and cross-checks them, then verifies against the host
// reference (same codec as rocm-demo's core/fp8, E4M3FN: bias 7, no
// infinities, 0x7F/0xFF = NaN, max finite 448).
//
// Build & run (inside the ROCm container):
//   hipcc -x hip --offload-arch=gfx1030 soft_fp8.hip -o soft_fp8 && ./soft_fp8
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

// ── E4M3FN codec, shared device/host (bit-exact with aiter_ref::fp8) ──
__host__ __device__ inline float e4m3_to_f32(std::uint8_t bits) {
    const bool neg = bits & 0x80;
    const std::uint32_t exp = (bits >> 3) & 0xF;
    const std::uint32_t man = bits & 0x7;
    float v;
    if (exp == 0) {
        v = (man / 8.0f) * 0x1p-6f;          // subnormals: 2^-6 * man/8
    } else if (exp == 15 && man == 7) {
        v = NAN;                             // E4M3FN: only NaN, no inf
    } else {
        v = (1.0f + man / 8.0f) * exp2f(static_cast<float>(exp) - 7.0f);
    }
    return neg ? -v : v;
}

__host__ __device__ inline std::uint8_t f32_to_e4m3_rne_satfinite(float x) {
    if (isnan(x)) return 0x7F;
    const bool neg = signbit(x);
    float mag = fabs(x);
    if (mag >= 464.0f) return neg ? 0xFE : 0x7E;  // 448 < midpoint(448,480) boundary region
    // Brute-force nearest over the 254 finite magnitudes (demo clarity over
    // speed; the repo's core/fp8 does the same and was validated exhaustively).
    std::uint8_t best = 0;
    float best_dist = fabs(x);
    for (int c = 1; c < 0xFF; ++c) {
        const float v = e4m3_to_f32(static_cast<std::uint8_t>(c));
        if (isnan(v)) break;
        const float d = fabs(mag - v);
        if (d < best_dist) {
            best_dist = d;
            best = static_cast<std::uint8_t>(c);
        }
    }
    return neg ? static_cast<std::uint8_t>(best | 0x80) : best;
}

// ── soft GEMM: C[m,n] = sum_k dec(A[m,k]) * dec(B[k,n]) ──
// One thread per output element; K strides over the k dimension.
__global__ void soft_gemm_bitdecode(const std::uint8_t* __restrict__ a,
                                    const std::uint8_t* __restrict__ b, float* __restrict__ c,
                                    int m, int n, int k, float scale_a, float scale_b) {
    const int col = blockIdx.x * blockDim.x + threadIdx.x;
    const int row = blockIdx.y;
    if (col >= n) return;
    float acc = 0.0f;
    for (int kk = 0; kk < k; ++kk) {
        const float va = e4m3_to_f32(a[row * k + kk]) * scale_a;
        const float vb = e4m3_to_f32(b[kk * n + col]) * scale_b;
        acc = fmaf(va, vb, acc);
    }
    c[row * n + col] = acc;
}

// LDS-LUT variant: 256-entry decode table staged into shared memory once per
// block; decode becomes a LDS read instead of exponent/mantissa arithmetic.
__global__ void soft_gemm_lut(const std::uint8_t* __restrict__ a,
                              const std::uint8_t* __restrict__ b, float* __restrict__ c, int m,
                              int n, int k, float scale_a, float scale_b) {
    __shared__ float lut[256];
    for (int i = threadIdx.x; i < 256; i += blockDim.x) lut[i] = e4m3_to_f32(static_cast<std::uint8_t>(i));
    __syncthreads();
    const int col = blockIdx.x * blockDim.x + threadIdx.x;
    const int row = blockIdx.y;
    if (col >= n) return;
    float acc = 0.0f;
    for (int kk = 0; kk < k; ++kk) {
        acc = fmaf(lut[a[row * k + kk]] * scale_a, lut[b[kk * n + col]] * scale_b, acc);
    }
    c[row * n + col] = acc;
}

int main() {
    const int m = 128, n = 128, k = 256;
    const float scale_a = 0.125f, scale_b = 0.5f;

    // Fill A/B with fp8-representable magnitudes so kernel-vs-host agrees to
    // float accumulation order only (decode is exact on both sides).
    std::vector<std::uint8_t> ha(m * k), hb(k * n);
    const std::uint8_t pool[] = {0x00, 0x30, 0x38, 0x40, 0x48, 0x50, 0x58, 0x60, 0x68,
                                 0x70, 0xB0, 0xB8, 0xC0, 0xC8, 0xD0, 0xD8, 0x08, 0x0C};
    unsigned seed = 0x9E3779B9u;
    auto rnd = [&]() {
        seed = seed * 1664525u + 1013904223u;
        return pool[(seed >> 16) % (sizeof(pool) / sizeof(pool[0]))];
    };
    for (auto& v : ha) v = rnd();
    for (auto& v : hb) v = rnd();

    // Host reference (decode exact, double accumulation) plus the
    // worst-case f32 accumulation bound for the same k order:
    // every FFMA step rounds to eps of the running sum, so the total drift
    // is bounded by eps * k * max |running sum|.
    std::vector<float> href(m * n, 0.0f);
    std::vector<double> bound(m * n, 0.0);
    for (int i = 0; i < m; ++i)
        for (int j = 0; j < n; ++j) {
            double acc = 0.0, max_running = 0.0;
            for (int kk = 0; kk < k; ++kk) {
                acc += static_cast<double>(e4m3_to_f32(ha[i * k + kk])) * scale_a *
                       static_cast<double>(e4m3_to_f32(hb[kk * n + j])) * scale_b;
                max_running = fmax(max_running, fabs(acc));
            }
            href[i * n + j] = static_cast<float>(acc);
            bound[i * n + j] = 1.1920929e-07 * k * max_running + 1e-9;
        }

    std::uint8_t *da, *db;
    float *dc, *dc2;
    CK(hipMalloc(&da, ha.size()));
    CK(hipMalloc(&db, hb.size()));
    CK(hipMalloc(&dc, m * n * 4));
    CK(hipMalloc(&dc2, m * n * 4));
    CK(hipMemcpy(da, ha.data(), ha.size(), hipMemcpyHostToDevice));
    CK(hipMemcpy(db, hb.data(), hb.size(), hipMemcpyHostToDevice));

    const dim3 grid((n + 63) / 64, m);
    const dim3 block(64);
    soft_gemm_bitdecode<<<grid, block>>>(da, db, dc, m, n, k, scale_a, scale_b);
    soft_gemm_lut<<<grid, block>>>(da, db, dc2, m, n, k, scale_a, scale_b);
    CK(hipDeviceSynchronize());

    std::vector<float> hc(m * n), hc2(m * n);
    CK(hipMemcpy(hc.data(), dc, m * n * 4, hipMemcpyDeviceToHost));
    CK(hipMemcpy(hc2.data(), dc2, m * n * 4, hipMemcpyDeviceToHost));

    // The host accumulates in double, the kernel in f32 FFMA: decode is
    // exact on both sides, so the drift is pure accumulation rounding,
    // bounded by a few ulp of each sum's magnitude.
    int bad = 0;
    double worst_ratio = 0.0;
    for (int i = 0; i < m * n; ++i) {
        const double diff = fabs(static_cast<double>(hc[i]) - href[i]);
        const double lut_diff = fabs(static_cast<double>(hc2[i]) - href[i]);
        const double worst = fmax(diff, lut_diff);
        if (worst > bound[i]) ++bad;
        worst_ratio = fmax(worst_ratio, worst / bound[i]);
    }
    std::printf("soft_fp8 %dx%dx%d: worst err / accumulation bound = %.3f -> %s\n", m, n, k,
                worst_ratio, bad == 0 ? "PASS" : "FAIL");
    return bad == 0 ? 0 : 1;
}
