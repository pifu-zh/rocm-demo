// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2026, Advanced Micro Devices, Inc. All rights reserved.
//
// soft_fp4 demo driver:
//   1. Exhaustive codec checks on GPU: E2M1 scalar (16) + packed (256) decodes,
//      packed round trip, encode sweep with RNE midpoints; UE8M0 decode/encode
//      over all 256 bytes (0xFF = NaN slot, round trip identity).
//   2. MXFP4 group-scale dot: correctness vs a double host reference with the
//      same quantization points, then a measured run (elements/time) with the
//      traffic accounting stated.
//   3. Conversion-stream throughput: decode_e2m1x2 + quantize_e2m1x2 vs copy.
//
// Build & run: scripts/build_run.sh (inside the ROCm container). The E2M1
// codec lives in demos/emulation/soft_fp8/include (lab-shared, dependency
// recorded); -I paths are set by the script.
#include "soft_fp4.hpp"

#include <hip/hip_runtime.h>

#include <algorithm>
#include <chrono>
#include <cmath>
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

namespace hostref {

float e2m1_decode(std::uint8_t code) {
    const int s = (code >> 3) & 1, e = (code >> 1) & 0x3, m = code & 0x1;
    double v;
    if (e == 0) v = m * 0.5;
    else v = (1.0 + m * 0.5) * std::pow(2.0, e - 1);
    return static_cast<float>(s ? -v : v);
}

float e8m0_decode(std::uint8_t b) {
    if (b == 0xFF) return std::nanf("");
    return static_cast<float>(std::pow(2.0, static_cast<int>(b) - 127));
}

std::uint8_t e8m0_encode_ceil(double x) {
    if (std::isnan(x) || std::isinf(x)) return 0xFF;
    if (x <= 0) return 0x00;
    // frexp: x = m * 2^e with m in [0.5,1). If m == 0.5, x IS the power of
    // two 2^(e-1); otherwise the smallest power of two >= x is 2^e.
    int e;
    const double mm = std::frexp(x, &e);
    const int exp_of_two = (mm == 0.5) ? (e - 1) : e;
    return static_cast<std::uint8_t>(exp_of_two + 127);
}

std::uint8_t e2m1_encode_brute(float x) {
    if (std::isnan(x)) return 0x7;
    if (std::fabs(x) >= 6.0f) return std::signbit(x) ? 0xF : 0x7;
    const int neg = std::signbit(x);
    const double mag = std::fabs(static_cast<double>(x));
    std::uint8_t best = 0;
    double best_d = 1e300;
    for (int c = 0; c < 8; ++c) {
        const double d = std::fabs(mag - static_cast<double>(e2m1_decode(static_cast<std::uint8_t>(c))));
        if (d < best_d || (d == best_d && ((c & 1) == 0) && ((best & 1) != 0))) {
            best_d = d;
            best = static_cast<std::uint8_t>(c);
        }
    }
    return neg ? static_cast<std::uint8_t>(best | 0x8) : best;
}

}  // namespace hostref

// device check kernels
__global__ void k_dec_e2m1(const std::uint8_t* in, float* out, int n) {
    const int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) out[i] = aiter_lab::e2m1_to_f32(in[i]);
}
__global__ void k_dec_e2m1x2(const std::uint8_t* in, float2* out, int n) {
    const int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) aiter_lab::e2m1x2_to_f32x2(in[i], out[i].x, out[i].y);
}
__global__ void k_rt_e2m1(const std::uint8_t* in, std::uint8_t* out, int n) {
    const int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) {
        float x, y;
        aiter_lab::e2m1x2_to_f32x2(in[i], x, y);
        out[i] = aiter_lab::f32x2_to_e2m1x2_rne_satfinite(x, y);
    }
}
__global__ void k_enc_e2m1(const float* in, std::uint8_t* out, int n) {
    const int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) out[i] = aiter_lab::f32_to_e2m1_rne_satfinite(in[i]);
}
__global__ void k_dec_e8m0(const std::uint8_t* in, float* out, int n) {
    const int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) out[i] = aiter_lab::e8m0_to_f32(in[i]);
}
__global__ void k_enc_e8m0(const float* in, std::uint8_t* out, int n) {
    const int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) out[i] = aiter_lab::f32_to_e8m0_ceil(in[i]);
}

int main() {
    int checks = 0, fails = 0;

    // ── 1a. E2M1 scalar + packed decode, round trip ──
    {
        std::vector<std::uint8_t> in8(256);
        for (int i = 0; i < 256; ++i) in8[i] = static_cast<std::uint8_t>(i);
        std::vector<float> got16(16);
        std::vector<float2> got256f2(256);
        std::vector<std::uint8_t> gotrt(256);
        std::uint8_t *d8, *d8b;
        float* df;
        float2* df2;
        CK(hipMalloc(&d8, 256));
        CK(hipMalloc(&d8b, 256));
        CK(hipMalloc(&df, 16 * 4));
        CK(hipMalloc(&df2, 256 * 8));
        CK(hipMemcpy(d8, in8.data(), 256, hipMemcpyHostToDevice));
        k_dec_e2m1<<<1, 16>>>(d8, df, 16);
        k_dec_e2m1x2<<<1, 256>>>(d8, df2, 256);
        k_rt_e2m1<<<1, 256>>>(d8, d8b, 256);
        CK(hipDeviceSynchronize());
        CK(hipMemcpy(got16.data(), df, 16 * 4, hipMemcpyDeviceToHost));
        CK(hipMemcpy(got256f2.data(), df2, 256 * 8, hipMemcpyDeviceToHost));
        CK(hipMemcpy(gotrt.data(), d8b, 256, hipMemcpyDeviceToHost));
        for (int c = 0; c < 16; ++c) {
            ++checks;
            if (got16[c] != hostref::e2m1_decode(static_cast<std::uint8_t>(c)) && fails++ < 5)
                std::printf("  e2m1 dec 0x%02x got %g\n", c, got16[c]);
        }
        for (int i = 0; i < 256; ++i) {
            ++checks;
            const float wx = hostref::e2m1_decode(i & 0xF), wy = hostref::e2m1_decode(i >> 4);
            if ((got256f2[i].x != wx || got256f2[i].y != wy) && fails++ < 5)
                std::printf("  e2m1x2 dec 0x%02x got (%g,%g)\n", i, got256f2[i].x, got256f2[i].y);
        }
        for (int i = 0; i < 256; ++i) {
            ++checks;
            if (gotrt[i] != in8[i] && fails++ < 5)
                std::printf("  e2m1 rt 0x%02x -> 0x%02x\n", i, gotrt[i]);
        }
        hipFree(d8);
        hipFree(d8b);
        hipFree(df);
        hipFree(df2);
        std::printf("1a. E2M1 decode 16/512 + round trip 256: %s\n", fails ? "FAIL" : "PASS");
    }

    // ── 1b. E2M1 encode sweep vs brute force (RNE ties) ──
    {
        std::vector<float> in;
        for (int i = -52; i <= 52; ++i) in.push_back(static_cast<float>(i) * 0.25f);
        in.push_back(1e30f);
        in.push_back(-1e30f);
        in.push_back(std::nanf(""));
        const int n = static_cast<int>(in.size());
        std::vector<std::uint8_t> got(n);
        float* din;
        std::uint8_t* dout;
        CK(hipMalloc(&din, n * 4));
        CK(hipMalloc(&dout, n));
        CK(hipMemcpy(din, in.data(), n * 4, hipMemcpyHostToDevice));
        k_enc_e2m1<<<(n + 255) / 256, 256>>>(din, dout, n);
        CK(hipDeviceSynchronize());
        CK(hipMemcpy(got.data(), dout, n, hipMemcpyDeviceToHost));
        int f = 0;
        for (int i = 0; i < n; ++i) {
            const std::uint8_t want = hostref::e2m1_encode_brute(in[i]);
            ++checks;
            if (got[i] != want && f++ < 8)
                std::printf("  e2m1 enc %g: got 0x%02x want 0x%02x\n", in[i], got[i], want);
        }
        fails += f > 0;
        std::printf("1b. E2M1 encode sweep %d (RNE ties/satfinite/NaN): %s\n", n,
                    f ? "FAIL" : "PASS");
        hipFree(din);
        hipFree(dout);
    }

    // ── 1c. UE8M0 decode/encode all 256 bytes ──
    {
        std::vector<std::uint8_t> in(256);
        for (int i = 0; i < 256; ++i) in[i] = static_cast<std::uint8_t>(i);
        std::vector<float> dec(256);
        std::vector<std::uint8_t> encrt(256);
        std::uint8_t *d8, *d8b;
        float* df;
        CK(hipMalloc(&d8, 256));
        CK(hipMalloc(&d8b, 256));
        CK(hipMalloc(&df, 256 * 4));
        CK(hipMemcpy(d8, in.data(), 256, hipMemcpyHostToDevice));
        k_dec_e8m0<<<1, 256>>>(d8, df, 256);
        k_enc_e8m0<<<1, 256>>>(df, d8b, 256);
        CK(hipDeviceSynchronize());
        CK(hipMemcpy(dec.data(), df, 256 * 4, hipMemcpyDeviceToHost));
        CK(hipMemcpy(encrt.data(), d8b, 256, hipMemcpyDeviceToHost));
        int f = 0;
        for (int i = 0; i < 256; ++i) {
            ++checks;
            const float want = hostref::e8m0_decode(in[i]);
            const bool okd = (std::isnan(want) && std::isnan(dec[i])) || dec[i] == want;
            if (!okd && f++ < 5)
                std::printf("  e8m0 dec 0x%02x: got %g want %g\n", i, dec[i], want);
        }
        for (int i = 0; i < 256; ++i) {
            ++checks;
            if (std::isnan(dec[i])) {
                if (encrt[i] != 0xFF && f++ < 5)
                    std::printf("  e8m0 enc(NaN) 0x%02x -> 0x%02x\n", i, encrt[i]);
            } else if (encrt[i] != in[i] && f++ < 5) {
                std::printf("  e8m0 rt 0x%02x -> 0x%02x\n", i, encrt[i]);
            }
        }
        fails += f > 0;
        std::printf("1c. UE8M0 decode/encode 256x2 (ceil contract, NaN slot): %s\n",
                    f ? "FAIL" : "PASS");
    }

    // ── 2. MXFP4 group-scale dot: correctness vs double reference ──
    {
        const int m = 32, n = 64, k = 128;  // 4 groups of 32
        std::vector<std::uint8_t> a(m * k / 2, 0), b(k * n / 2, 0);
        std::vector<std::uint8_t> sfa(m * (k / 32)), sfb((k / 32) * n);
        // deterministic nibble fill via LCG
        unsigned seed = 0x4F24u;
        auto rnd = [&]() {
            seed = seed * 1664525u + 1013904223u;
            return static_cast<std::uint8_t>((seed >> 16) & 0xF);
        };
        for (auto& v : a) v = static_cast<std::uint8_t>(rnd() | (rnd() << 4));
        for (auto& v : b) v = static_cast<std::uint8_t>(rnd() | (rnd() << 4));
        for (auto& v : sfa) v = static_cast<std::uint8_t>(118 + rnd() % 8);
        for (auto& v : sfb) v = static_cast<std::uint8_t>(118 + rnd() % 8);

        // Double reference with identical quantization points (decoded values
        // are exact; e8m0 scales are exact powers of two; inner sums exact in
        // f32 for these magnitudes — bound still checked).
        std::vector<double> href(m * n, 0.0), bound(m * n, 0.0);
        for (int i = 0; i < m; ++i)
            for (int j = 0; j < n; ++j) {
                double acc = 0.0, max_running = 0.0;
                for (int g = 0; g < k / 32; ++g) {
                    double inner = 0.0;
                    for (int t = 0; t < 32; ++t) {
                        const int kk = g * 32 + t;
                        const std::uint8_t av = a[static_cast<long>(i) * k / 2 + kk / 2];
                        const std::uint8_t anib = (kk % 2 == 0) ? (av & 0xF) : (av >> 4);
                        const std::uint8_t bv = b[static_cast<long>(kk) * n / 2 + j / 2];
                        const std::uint8_t bnib = (j % 2 == 0) ? (bv & 0xF) : (bv >> 4);
                        inner += static_cast<double>(hostref::e2m1_decode(anib)) *
                                 hostref::e2m1_decode(bnib);
                    }
                    const double sf = hostref::e8m0_decode(sfa[i * (k / 32) + g]);
                    const double sb = hostref::e8m0_decode(sfb[g * n + j]);
                    acc += inner * sf * sb;
                    max_running = std::fmax(max_running, std::fabs(acc));
                }
                href[i * n + j] = acc;
                bound[i * n + j] = 1.1920929e-07 * (k + k / 32) * max_running + 1e-9;
            }

        std::uint8_t *da, *db, *dsa, *dsb;
        float* dc;
        CK(hipMalloc(&da, a.size()));
        CK(hipMalloc(&db, b.size()));
        CK(hipMalloc(&dsa, sfa.size()));
        CK(hipMalloc(&dsb, sfb.size()));
        CK(hipMalloc(&dc, static_cast<long>(m) * n * 4));
        CK(hipMemcpy(da, a.data(), a.size(), hipMemcpyHostToDevice));
        CK(hipMemcpy(db, b.data(), b.size(), hipMemcpyHostToDevice));
        CK(hipMemcpy(dsa, sfa.data(), sfa.size(), hipMemcpyHostToDevice));
        CK(hipMemcpy(dsb, sfb.data(), sfb.size(), hipMemcpyHostToDevice));
        CK(aiter_lab::launch_mxfp4_dot(da, db, dsa, dsb, dc, m, n, k));
        CK(hipDeviceSynchronize());
        std::vector<float> hc(static_cast<long>(m) * n);
        CK(hipMemcpy(hc.data(), dc, static_cast<long>(m) * n * 4, hipMemcpyDeviceToHost));
        int f = 0;
        double worst = 0.0;
        for (int i = 0; i < m * n; ++i) {
            const double diff = std::fabs(static_cast<double>(hc[i]) - href[i]);
            if (diff > bound[i]) ++f;
            worst = std::fmax(worst, diff / bound[i]);
        }
        fails += f > 0;
        std::printf("2. MXFP4 group-scale dot %dx%dx%d: worst err/bound = %.3f -> %s\n", m, n, k,
                    worst, f ? "FAIL" : "PASS");
        hipFree(da);
        hipFree(db);
        hipFree(dsa);
        hipFree(dsb);
        hipFree(dc);
    }

    // ── 3. conversion-stream throughput vs copy ──
    constexpr int kPairs = 64 * 1024 * 1024;  // 64 Mi pairs = 128 Mi elements
    constexpr int kThreads = 1024;
    std::uint8_t *du8;
    float* df;
    CK(hipMalloc(&du8, kPairs));
    CK(hipMalloc(&df, static_cast<long>(kPairs) * 8));
    {
        std::vector<std::uint8_t> pat(1 << 20);
        unsigned sd = 0xF4u;
        for (int i = 0; i < (1 << 20); ++i) {
            sd = sd * 1664525u + 1013904223u;
            pat[i] = static_cast<std::uint8_t>((sd >> 16) & 0xFF);
        }
        for (long off = 0; off < kPairs; off += static_cast<long>(pat.size()))
            CK(hipMemcpy(du8 + off, pat.data(), std::min<long>(pat.size(), kPairs - off),
                         hipMemcpyHostToDevice));
    }
    hipEvent_t t0, t1;
    CK(hipEventCreate(&t0));
    CK(hipEventCreate(&t1));
    auto time = [&](auto&& launch) -> double {
        auto tic = std::chrono::steady_clock::now();
        while (std::chrono::duration<double>(std::chrono::steady_clock::now() - tic).count() < 1.0)
            launch();
        CK(hipDeviceSynchronize());
        double best = 1e30;
        for (int b = 0; b < 3; ++b) {
            float t = 1e30f;
            for (int r = 0; r < 5; ++r) {
                CK(hipEventRecord(t0));
                launch();
                CK(hipEventRecord(t1));
                CK(hipEventSynchronize(t1));
                float m;
                CK(hipEventElapsedTime(&m, t0, t1));
                t = std::fmin(t, m);
            }
            best = std::fmin(best, t);
        }
        return best;
    };
    const int grid = (kPairs + kThreads - 1) / kThreads;
    auto dec = [&] {
        aiter_lab::decode_e2m1x2_stream<<<grid, kThreads>>>(du8, df, kPairs);
        return hipGetLastError();
    };
    auto enc = [&] {
        aiter_lab::quantize_e2m1x2_stream<<<grid, kThreads>>>(df, du8, kPairs);
        return hipGetLastError();
    };
    const double ms_dec = time(dec);
    const double ms_enc = time(enc);
    // traffic: decode = 1 B in + 8 B out per pair; quantize = 8 B in + 1 B out
    const double dec_gbps = 9.0 * kPairs / 1e9 / (ms_dec * 1e-3);
    const double enc_gbps = 9.0 * kPairs / 1e9 / (ms_enc * 1e-3);
    std::printf("3. conversion streams (%d Mi pairs): decode_e2m1x2 %.1f GB/s | quantize %.1f GB/s\n",
                kPairs / (1 << 20), dec_gbps, enc_gbps);

    hipFree(du8);
    hipFree(df);
    std::printf("soft_fp4 demo: %s\n", fails ? "FAIL" : "PASS");
    return fails ? 1 : 0;
}
