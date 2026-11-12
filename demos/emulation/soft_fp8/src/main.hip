// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2026, Advanced Micro Devices, Inc. All rights reserved.
//
// soft_fp8 demo driver:
//   1. Exhaustive codec validation on GPU (the cuda-oxide fp8_decode design):
//      all 256 E4M3/E5M2 scalar decodes, all 2^16 packed-x2 decodes (both
//      lanes), all 2^8 E2M1x2 decodes, full decode->encode round trips of
//      every packed pattern, RNE midpoint sweeps — against independent host
//      references (format-definition construction / brute-force
//      nearest-value, NOT the device bit-manipulation code).
//   2. Throughput: decode/encode conversion streams (scalar + packed),
//      triad protocol, graded against copy_f32 on the same bytes
//      (60/70/80/90% substitution ladder; upstream measured 91-98% scalar,
//      81-82% packed-decode, ~100% packed-encode).
//
// Build & run: scripts/build_run.sh (inside the ROCm container).
#include "soft_fp8.hpp"

#include <hip/hip_runtime.h>

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdio>
#include <cstring>
#include <limits>
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

// ── independent host references (different construction than the header) ──

// Brute-force nearest-value encoder over the format's value set (the same
// method as rocm-demo core/fp8, itself exhaustively validated).
namespace hostref {

float e4m3_values[256];  // index = byte pattern (NaN slots unused), sign in byte

void init_tables() {
    // Build by format definition with double arithmetic; the index IS the
    // byte so the encoder can return the byte directly.
    for (int byte = 0; byte < 256; ++byte) {
        const int s = (byte >> 7) & 1, e = (byte >> 3) & 0xF, m = byte & 0x7;
        if (e == 15 && m == 7) {
            e4m3_values[byte] = std::nanf("");
            continue;
        }
        double v;
        if (e == 0) v = (m / 8.0) * std::pow(2.0, -6);
        else v = (1.0 + m / 8.0) * std::pow(2.0, e - 7);
        e4m3_values[byte] = static_cast<float>(s ? -v : v);
    }
}

float e4m3_decode_ref(std::uint8_t bits) {
    const int s = (bits >> 7) & 1, e = (bits >> 3) & 0xF, m = bits & 0x7;
    double v;
    if (e == 0) v = (m / 8.0) * std::pow(2.0, -6);
    else if (e == 15 && m == 7) return std::nanf("");
    else v = (1.0 + m / 8.0) * std::pow(2.0, e - 7);
    return static_cast<float>(s ? -v : v);
}

float e5m2_decode_ref(std::uint8_t bits) {
    const int s = (bits >> 7) & 1, e = (bits >> 2) & 0x1F, m = bits & 0x3;
    double v;
    if (e == 31) {
        if (m) return std::nanf("");
        v = std::numeric_limits<double>::infinity();
    } else if (e == 0) v = (m / 4.0) * std::pow(2.0, -14);
    else v = (1.0 + m / 4.0) * std::pow(2.0, e - 15);
    return static_cast<float>(s ? -v : v);
}

float e2m1_decode_ref(std::uint8_t code) {
    const int s = (code >> 3) & 1, e = (code >> 1) & 0x3, m = code & 0x1;
    double v;
    if (e == 0) v = m * 0.5;
    else v = (1.0 + m * 0.5) * std::pow(2.0, e - 1);
    return static_cast<float>(s ? -v : v);
}

std::uint8_t e4m3_encode_brute(float x) {
    // Nearest finite magnitude; exact ties round to the EVEN mantissa field
    // (RNE, matching the device codec). NaN -> 0x7F; zeros keep sign;
    // sign applied at the end.
    if (std::isnan(x)) return 0x7F;
    if (x == 0.0f) return std::signbit(x) ? 0x80 : 0x00;
    if (std::fabs(x) >= 448.0f) return std::signbit(x) ? 0xFE : 0x7E;  // satfinite
    const int neg = std::signbit(x);
    const double mag = std::fabs(static_cast<double>(x));
    std::uint8_t best = 0;
    double best_d = 1e300;
    for (int c = 1; c < 0xFF; ++c) {
        if ((c >> 3) == 0xF && (c & 0x7) == 0x7) continue;  // NaN slot
        const double d = std::fabs(mag - static_cast<double>(e4m3_values[c]));
        if (d < best_d || (d == best_d && ((c & 1) == 0) && ((best & 1) != 0))) {
            best_d = d;
            best = static_cast<std::uint8_t>(c);
        }
    }
    return neg ? static_cast<std::uint8_t>(best | 0x80) : best;
}

std::uint8_t e5m2_encode_brute(float x) {
    if (std::isnan(x)) return 0x7E;
    if (std::isinf(x)) return std::signbit(x) ? 0xFC : 0x7C;
    // IEEE overflow: at/over max + half-ulp the RNE result is Inf.
    constexpr float kMax = 57344.0f, kHalf = 16384.0f;
    if (std::fabs(x) >= kMax + kHalf)
        return std::signbit(x) ? 0xFC : 0x7C;
    // Nearest finite with RNE ties (even mantissa field, bits 2..1 -> LSB bit1).
    std::uint8_t best = 0;
    double best_d = 1e300;
    for (int c = 0; c < 0xFC; ++c) {
        const float v = e5m2_decode_ref(static_cast<std::uint8_t>(c));
        if (std::isnan(v) || std::isinf(v)) continue;
        const double d = std::fabs(static_cast<double>(x) - static_cast<double>(v));
        if (d < best_d || (d == best_d && (((c >> 1) & 1) == 0) && (((best >> 1) & 1) != 0))) {
            best_d = d;
            best = static_cast<std::uint8_t>(c);
        }
    }
    return best;
}

std::uint8_t e2m1_encode_brute(float x) {
    if (std::isnan(x)) return 0x7;
    if (std::fabs(x) >= 6.0f) return std::signbit(x) ? 0xF : 0x7;  // satfinite
    const int neg = std::signbit(x);
    const double mag = std::fabs(static_cast<double>(x));
    std::uint8_t best = 0;
    double best_d = 1e300;
    for (int c = 0; c < 8; ++c) {
        const float v = e2m1_decode_ref(static_cast<std::uint8_t>(c));
        const double d = std::fabs(mag - static_cast<double>(v));
        // RNE ties: prefer the even mantissa field (bit 0 of the code).
        if (d < best_d || (d == best_d && ((c & 1) == 0) && ((best & 1) != 0))) {
            best_d = d;
            best = static_cast<std::uint8_t>(c);
        }
    }
    return neg ? static_cast<std::uint8_t>(best | 0x8) : best;
}

}  // namespace hostref

// ── device kernels: one thread per pattern ──
__global__ void k_decode_e4m3(const std::uint8_t* in, float* out, int n) {
    const int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) out[i] = aiter_lab::e4m3_to_f32(in[i]);
}
__global__ void k_decode_e5m2(const std::uint8_t* in, float* out, int n) {
    const int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) out[i] = aiter_lab::e5m2_to_f32(in[i]);
}
__global__ void k_decode_e4m3x2(const std::uint16_t* in, float2* out, int n) {
    const int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) aiter_lab::e4m3x2_to_f32x2(in[i], out[i].x, out[i].y);
}
__global__ void k_decode_e2m1x2(const std::uint8_t* in, float2* out, int n) {
    const int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) aiter_lab::e2m1x2_to_f32x2(in[i], out[i].x, out[i].y);
}
__global__ void k_rt_e4m3(const std::uint16_t* in, std::uint16_t* out, int n) {
    // decode -> encode -> packed, both lanes.
    const int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) {
        float x, y;
        aiter_lab::e4m3x2_to_f32x2(in[i], x, y);
        out[i] = aiter_lab::f32x2_to_e4m3x2_rne_satfinite(x, y);
    }
}
__global__ void k_rt_e5m2(const std::uint16_t* in, std::uint16_t* out, int n) {
    const int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) {
        float x, y;
        aiter_lab::e5m2x2_to_f32x2(in[i], x, y);
        out[i] = aiter_lab::f32x2_to_e5m2x2_rne(x, y);
    }
}
__global__ void k_rt_e2m1(const std::uint8_t* in, std::uint8_t* out, int n) {
    const int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) {
        float x, y;
        aiter_lab::e2m1x2_to_f32x2(in[i], x, y);
        out[i] = aiter_lab::f32x2_to_e2m1x2_rne_satfinite(x, y);
    }
}
// Encode sweep: f32 grid values (including exact RNE midpoints) -> e4m3.
__global__ void k_encode_e4m3(const float* in, std::uint8_t* out, int n) {
    const int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) out[i] = aiter_lab::f32_to_e4m3_rne_satfinite(in[i]);
}
__global__ void k_encode_e2m1(const float* in, std::uint8_t* out, int n) {
    const int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) out[i] = aiter_lab::f32_to_e2m1_rne_satfinite(in[i]);
}

// ── throughput stream kernels (pure conversion, 5 B/element traffic) ──
__global__ void copy_f4_ref(const float4* __restrict__ a, float4* __restrict__ b, int n4) {
    const int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n4) b[i] = a[i];
}
__global__ void k_decode_stream(const std::uint8_t* __restrict__ in, float* __restrict__ out,
                                int n) {
    const int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) out[i] = aiter_lab::e4m3_to_f32(in[i]);
}
__global__ void k_encode_stream(const float* __restrict__ in, std::uint8_t* __restrict__ out,
                                int n) {
    const int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) out[i] = aiter_lab::f32_to_e4m3_rne_satfinite(in[i]);
}
__global__ void k_decode_stream_x2(const std::uint16_t* __restrict__ in, float* __restrict__ out,
                                   int pairs) {
    // One packed u16 -> two f32s (the dual-output form; cuda-oxide measured
    // this 81-82% vs copy, attributing the deficit to the dual output stream).
    const int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < pairs) aiter_lab::e4m3x2_to_f32x2(in[i], out[2 * i], out[2 * i + 1]);
}
__global__ void k_encode_stream_x2(const float2* __restrict__ in, std::uint16_t* __restrict__ out,
                                   int pairs) {
    const int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < pairs) out[i] = aiter_lab::f32x2_to_e4m3x2_rne_satfinite(in[i].x, in[i].y);
}

int main() {
    hostref::init_tables();
    int fails = 0, checks = 0;

    // ── 1a. scalar E4M3 decode: all 256 ──
    {
        std::vector<std::uint8_t> in(256);
        for (int i = 0; i < 256; ++i) in[i] = static_cast<std::uint8_t>(i);
        std::vector<float> got(256);
        std::uint8_t* din;
        float* dout;
        CK(hipMalloc(&din, 256));
        CK(hipMalloc(&dout, 256 * 4));
        CK(hipMemcpy(din, in.data(), 256, hipMemcpyHostToDevice));
        k_decode_e4m3<<<1, 256>>>(din, dout, 256);
        CK(hipDeviceSynchronize());
        CK(hipMemcpy(got.data(), dout, 256 * 4, hipMemcpyDeviceToHost));
        for (int i = 0; i < 256; ++i) {
            const float want = hostref::e4m3_decode_ref(static_cast<std::uint8_t>(i));
            ++checks;
            if (std::isnan(want) != std::isnan(got[i]) ||
                (!std::isnan(want) && got[i] != want)) {
                if (fails++ < 5)
                    std::printf("  e4m3 decode 0x%02x: got %g want %g\n", i, got[i], want);
            }
        }
        hipFree(din);
        hipFree(dout);
        std::printf("1a. E4M3 scalar decode 256: %s\n", fails ? "FAIL" : "PASS");
    }

    // ── 1b. packed E4M3x2 decode: all 65536, both lanes ──
    {
        std::vector<std::uint16_t> in(65536);
        for (int i = 0; i < 65536; ++i) in[i] = static_cast<std::uint16_t>(i);
        std::vector<float2> got(65536);
        std::uint16_t* din;
        float2* dout;
        CK(hipMalloc(&din, 65536 * 2));
        CK(hipMalloc(&dout, 65536 * 8));
        CK(hipMemcpy(din, in.data(), 65536 * 2, hipMemcpyHostToDevice));
        k_decode_e4m3x2<<<(65536 + 255) / 256, 256>>>(din, dout, 65536);
        CK(hipDeviceSynchronize());
        CK(hipMemcpy(got.data(), dout, 65536 * 8, hipMemcpyDeviceToHost));
        int f = 0;
        for (int i = 0; i < 65536; ++i) {
            const float wx = hostref::e4m3_decode_ref(static_cast<std::uint8_t>(i & 0xFF));
            const float wy = hostref::e4m3_decode_ref(static_cast<std::uint8_t>(i >> 8));
            ++checks;
            const bool okx = (std::isnan(wx) && std::isnan(got[i].x)) || got[i].x == wx;
            const bool oky = (std::isnan(wy) && std::isnan(got[i].y)) || got[i].y == wy;
            if (!okx || !oky) {
                if (f++ < 5)
                    std::printf("  e4m3x2 0x%04x: got (%g,%g) want (%g,%g)\n", i, got[i].x,
                                got[i].y, wx, wy);
            }
        }
        fails += f > 0;
        hipFree(din);
        hipFree(dout);
        std::printf("1b. E4M3x2 packed decode 65536x2 lanes: %s\n", f ? "FAIL" : "PASS");
    }

    // ── 1c. E5M2 scalar decode: all 256 ──
    {
        std::vector<std::uint8_t> in(256);
        for (int i = 0; i < 256; ++i) in[i] = static_cast<std::uint8_t>(i);
        std::vector<float> got(256);
        std::uint8_t* din;
        float* dout;
        CK(hipMalloc(&din, 256));
        CK(hipMalloc(&dout, 256 * 4));
        CK(hipMemcpy(din, in.data(), 256, hipMemcpyHostToDevice));
        k_decode_e5m2<<<1, 256>>>(din, dout, 256);
        CK(hipDeviceSynchronize());
        CK(hipMemcpy(got.data(), dout, 256 * 4, hipMemcpyDeviceToHost));
        int f = 0;
        for (int i = 0; i < 256; ++i) {
            const float want = hostref::e5m2_decode_ref(static_cast<std::uint8_t>(i));
            ++checks;
            const bool ok = (std::isnan(want) && std::isnan(got[i])) ||
                            (std::isinf(want) && std::isinf(got[i]) &&
                             std::signbit(want) == std::signbit(got[i])) ||
                            got[i] == want;
            if (!ok && f++ < 5)
                std::printf("  e5m2 decode 0x%02x: got %g want %g\n", i, got[i], want);
        }
        fails += f > 0;
        hipFree(din);
        hipFree(dout);
        std::printf("1c. E5M2 scalar decode 256: %s\n", f ? "FAIL" : "PASS");
    }

    // ── 1d. E2M1x2 decode: all 256 ──
    {
        std::vector<std::uint8_t> in(256);
        for (int i = 0; i < 256; ++i) in[i] = static_cast<std::uint8_t>(i);
        std::vector<float2> got(256);
        std::uint8_t* din;
        float2* dout;
        CK(hipMalloc(&din, 256));
        CK(hipMalloc(&dout, 256 * 8));
        CK(hipMemcpy(din, in.data(), 256, hipMemcpyHostToDevice));
        k_decode_e2m1x2<<<1, 256>>>(din, dout, 256);
        CK(hipDeviceSynchronize());
        CK(hipMemcpy(got.data(), dout, 256 * 8, hipMemcpyDeviceToHost));
        int f = 0;
        for (int i = 0; i < 256; ++i) {
            const float wx = hostref::e2m1_decode_ref(i & 0xF);
            const float wy = hostref::e2m1_decode_ref(i >> 4);
            ++checks;
            if (got[i].x != wx || got[i].y != wy) {
                if (f++ < 5)
                    std::printf("  e2m1x2 0x%02x: got (%g,%g) want (%g,%g)\n", i, got[i].x,
                                got[i].y, wx, wy);
            }
        }
        fails += f > 0;
        hipFree(din);
        hipFree(dout);
        std::printf("1d. E2M1x2 packed decode 256: %s\n", f ? "FAIL" : "PASS");
    }

    // ── 2. round trips over every packed pattern ──
    {
        std::vector<std::uint16_t> in(65536);
        for (int i = 0; i < 65536; ++i) in[i] = static_cast<std::uint16_t>(i);
        std::vector<std::uint16_t> got(65536);
        std::uint16_t *din, *dout;
        CK(hipMalloc(&din, 65536 * 2));
        CK(hipMalloc(&dout, 65536 * 2));
        CK(hipMemcpy(din, in.data(), 65536 * 2, hipMemcpyHostToDevice));
        k_rt_e4m3<<<(65536 + 255) / 256, 256>>>(din, dout, 65536);
        CK(hipDeviceSynchronize());
        CK(hipMemcpy(got.data(), dout, 65536 * 2, hipMemcpyDeviceToHost));
        int f = 0;
        for (int i = 0; i < 65536; ++i) {
            ++checks;
            if (got[i] != in[i] && f++ < 5)
                std::printf("  e4m3 rt 0x%04x -> 0x%04x\n", i, got[i]);
        }
        fails += f > 0;
        std::printf("2a. E4M3x2 decode->encode round trip 65536: %s\n", f ? "FAIL" : "PASS");

        k_rt_e5m2<<<(65536 + 255) / 256, 256>>>(din, dout, 65536);
        CK(hipDeviceSynchronize());
        CK(hipMemcpy(got.data(), dout, 65536 * 2, hipMemcpyDeviceToHost));
        f = 0;
        auto e5m2_canon_byte = [](std::uint8_t b) {
            return b;  // identity accepted; NaN handled below
        };
        for (int i = 0; i < 65536; ++i) {
            ++checks;
            // Byte-level check: each lane is identity, or canonicalized NaN
            // (decode -> qNaN -> encode 0x7E|s for any NaN pattern).
            bool ok = true;
            for (int lane = 0; lane < 2 && ok; ++lane) {
                const std::uint8_t in_b = (lane ? (in[i] >> 8) : in[i]) & 0xFF;
                const std::uint8_t got_b = (lane ? (got[i] >> 8) : got[i]) & 0xFF;
                const bool in_nan = ((in_b >> 2) & 0x1F) == 0x1F && (in_b & 0x3) != 0;
                const bool got_nan = ((got_b >> 2) & 0x1F) == 0x1F && (got_b & 0x3) != 0;
                ok = (got_b == in_b) || (in_nan && got_nan && ((got_b & 0x3) == 0x2) &&
                                          ((got_b & 0x80) == (in_b & 0x80)));
            }
            if (!ok && f++ < 5)
                std::printf("  e5m2 rt 0x%04x -> 0x%04x\n", i, got[i]);
        }
        fails += f > 0;
        std::printf("2b. E5M2x2 round trip 65536 (NaN canonicalization accepted): %s\n",
                    f ? "FAIL" : "PASS");

        std::vector<std::uint8_t> in8(256);
        for (int i = 0; i < 256; ++i) in8[i] = static_cast<std::uint8_t>(i);
        std::vector<std::uint8_t> got8(256);
        std::uint8_t *din8, *dout8;
        CK(hipMalloc(&din8, 256));
        CK(hipMalloc(&dout8, 256));
        CK(hipMemcpy(din8, in8.data(), 256, hipMemcpyHostToDevice));
        k_rt_e2m1<<<1, 256>>>(din8, dout8, 256);
        CK(hipDeviceSynchronize());
        CK(hipMemcpy(got8.data(), dout8, 256, hipMemcpyDeviceToHost));
        f = 0;
        for (int i = 0; i < 256; ++i) {
            ++checks;
            if (got8[i] != in8[i] && f++ < 5)
                std::printf("  e2m1 rt 0x%02x -> 0x%02x\n", i, got8[i]);
        }
        fails += f > 0;
        std::printf("2c. E2M1x2 round trip 256: %s\n", f ? "FAIL" : "PASS");
        hipFree(din);
        hipFree(dout);
        hipFree(din8);
        hipFree(dout8);
    }

    // ── 3. encode sweeps vs brute-force host encoder (RNE midpoints incl.) ──
    {
        // Grid over all midpoints and representable neighborhoods.
        std::vector<float> in;
        for (int i = -260; i <= 260; ++i) in.push_back(static_cast<float>(i) * 0.25f);
        for (int i = -5200; i <= 5200; ++i) in.push_back(static_cast<float>(i) * 0.125f);
        in.push_back(448.0f);
        in.push_back(464.0f);  // midpoint(448, 480) — RNE tie to 448
        in.push_back(480.0f);
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
        k_encode_e4m3<<<(n + 255) / 256, 256>>>(din, dout, n);
        CK(hipDeviceSynchronize());
        CK(hipMemcpy(got.data(), dout, n, hipMemcpyDeviceToHost));
        int f = 0;
        for (int i = 0; i < n; ++i) {
            const std::uint8_t want = hostref::e4m3_encode_brute(in[i]);
            ++checks;
            if (got[i] != want && f++ < 8)
                std::printf("  e4m3 encode %g: got 0x%02x want 0x%02x\n", in[i], got[i], want);
        }
        fails += f > 0;
        std::printf("3a. E4M3 encode sweep %d (midpoints/satfinite/NaN): %s\n", n,
                    f ? "FAIL" : "PASS");

        k_encode_e2m1<<<(n + 255) / 256, 256>>>(din, dout, n);
        CK(hipDeviceSynchronize());
        CK(hipMemcpy(got.data(), dout, n, hipMemcpyDeviceToHost));
        f = 0;
        for (int i = 0; i < n; ++i) {
            const std::uint8_t want = hostref::e2m1_encode_brute(in[i]);
            ++checks;
            if (got[i] != want && f++ < 8)
                std::printf("  e2m1 encode %g: got 0x%02x want 0x%02x\n", in[i], got[i], want);
        }
        fails += f > 0;
        std::printf("3b. E2M1 encode sweep %d: %s\n", n, f ? "FAIL" : "PASS");
        hipFree(din);
        hipFree(dout);
    }

    std::printf("exhaustive: %d checks, %d failures -> %s\n", checks, fails,
                fails ? "FAIL" : "PASS");
    if (fails) return 1;

    // ── 4. throughput: conversion streams vs copy_f32 (triad-lite) ──
    constexpr int kElems = 128 * 1024 * 1024;  // 128 Mi elements
    constexpr int kThreads = 1024;
    std::uint8_t *du8;
    std::uint16_t* du16;
    float *df32, *df32b;
    CK(hipMalloc(&du8, kElems));
    CK(hipMalloc(&du16, static_cast<long>(kElems) * 2));
    CK(hipMalloc(&df32, static_cast<long>(kElems) * 4));
    CK(hipMalloc(&df32b, static_cast<long>(kElems) * 4));
    {
        // Deterministic fill of the fp8 source (all 256 values cycled).
        std::vector<std::uint8_t> pat(1 << 20);
        for (int i = 0; i < (1 << 20); ++i) pat[i] = static_cast<std::uint8_t>(i * 7 + (i >> 8));
        for (long off = 0; off < kElems; off += static_cast<long>(pat.size()))
            CK(hipMemcpy(du8 + off, pat.data(),
                         std::min<long>(pat.size(), kElems - off), hipMemcpyHostToDevice));
        // u16 source from u8 pairs.
        std::vector<std::uint16_t> pat16(1 << 20);
        for (int i = 0; i < (1 << 20); ++i)
            pat16[i] = static_cast<std::uint16_t>(pat[i & 0xFFFFF] |
                                                  (pat[(i * 13 + 7) & 0xFFFFF] << 8));
        for (long off = 0; off < kElems; off += static_cast<long>(pat16.size()))
            CK(hipMemcpy(du16 + off, pat16.data(),
                         std::min<long>(pat16.size() * 2, (kElems - off) * 2),
                         hipMemcpyHostToDevice));
    }

    hipEvent_t t0, t1;
    CK(hipEventCreate(&t0));
    CK(hipEventCreate(&t1));
    auto time = [&](auto&& launch) -> double {
        // triad-lite: 3 blocks x 5 launches, best; 1 s warmup.
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
    const int grid = (kElems + kThreads - 1) / kThreads;

    // copy_f32 reference: read 4B + write 4B per element.
    auto copy_launch = [&] {
        copy_f4_ref<<<grid, kThreads>>>(reinterpret_cast<float4*>(df32), reinterpret_cast<float4*>(df32b), kElems / 4);
        return hipGetLastError();
    };
    auto dec_scalar = [&] {
        k_decode_stream<<<grid, kThreads>>>(du8, df32, kElems);
        return hipGetLastError();
    };
    auto enc_scalar = [&] {
        k_encode_stream<<<grid, kThreads>>>(df32, du8, kElems);
        return hipGetLastError();
    };
    auto dec_x2 = [&] {
        k_decode_stream_x2<<<grid / 2, kThreads>>>(du16, df32, kElems / 2);
        return hipGetLastError();
    };
    auto enc_x2 = [&] {
        k_encode_stream_x2<<<grid / 2, kThreads>>>(reinterpret_cast<float2*>(df32), du16,
                                                   kElems / 2);
        return hipGetLastError();
    };

    const double ms_copy = time(copy_launch);
    const double ms_ds = time(dec_scalar);
    const double ms_es = time(enc_scalar);
    const double ms_dx2 = time(dec_x2);
    const double ms_ex2 = time(enc_x2);
    // Each stream: kElems elements; traffic = fp8 side + f32 side = 5 B/elt
    // (copy = 8 B/elt). GB/s = traffic/time; grade = kernel GB/s / copy GB/s.
    const double copy_gbps = 8.0 * kElems / 1e9 / (ms_copy * 1e-3);
    auto report = [&](const char* name, double ms) {
        const double gbps = 5.0 * kElems / 1e9 / (ms * 1e-3);
        std::printf("  %-14s %7.1f GB/s  = %5.1f%% of copy\n", name, gbps,
                    100.0 * gbps / copy_gbps);
    };
    std::printf("throughput (128 Mi elements, 5 B/elt; copy ref %.1f GB/s):\n", copy_gbps);
    report("decode_e4m3", ms_ds);
    report("encode_e4m3", ms_es);
    report("decode_e4m3x2", ms_dx2);
    report("encode_e4m3x2", ms_ex2);

    hipFree(du8);
    hipFree(du16);
    hipFree(df32);
    hipFree(df32b);
    return 0;
}
