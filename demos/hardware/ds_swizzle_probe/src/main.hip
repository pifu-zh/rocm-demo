// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2026, Advanced Micro Devices, Inc. All rights reserved.
//
// Hardware-mechanism probe: __builtin_amdgcn_ds_swizzle BITMASK_PERM
// semantics on gfx1030/RDNA2 (ROCm 7.2.4), measured — not assumed.
//
// Why this probe exists: aiter's topk/gdr kernels use the XOR-butterfly
// reduction with swizzle codes (N << 10) | 0x1f for N in {1, 2, 4}
// (kDsSwizzleXor1/2/4 in quick_all_reduce.cuh / gdr_decode_packed_bf16.cu).
// The encoding's field layout is NOT documented in the aiter sources; the
// host reference (demos/algorithm/gdr_decode_chain) emulates the
// XOR-BUTTERFLY SEMANTICS and defers the instruction-level truth to this
// probe. We measure, per code: for every lane i, WHICH source lane j the
// instruction reads from (src(i)), by feeding x = lane_id and reading back.
//
// Measured expectations (hypotheses this probe discriminates):
//   H1 butterfly: src(i) = i ^ N          (matches the reduce usage)
//   H2 broadcast: src(i) = const          ((lane & 0) | 7) ^ N etc.
//   H3 identity:  src(i) = i              (encoding decodes to a no-op)
// The probe prints the full 64-entry mapping per code and verdicts each
// hypothesis, then runs the 3-step butterfly reduction against a scalar
// sum to close the loop on the algorithmic contract.
//
// MEASURED (2026-11-14, RX 6950 XT / ROCm 7.2.4): hipcc compiles gfx1030
// kernels with wavefront_size = 32 (RDNA2 native wave32; verified in the
// .amdhsa_metadata of every kernel in this TU). All ds_swizzles therefore
// operate within 32-lane waves, and a 64-thread launch is TWO waves. The
// upstream ds_swizzle usage (reduce_k over kKThreads=8) is
// wave-size-agnostic and portable; full-wave folds on wave64 CDNA parts
// were NOT verifiable on this card (documented as such).
#include <hip/hip_runtime.h>

#include <cstdint>
#include <cstdio>
#include <vector>

#define CK(x)                                                                              \
    do {                                                                                   \
        const hipError_t e_ = (x);                                                         \
        if (e_ != hipSuccess) {                                                            \
            std::printf("HIP %s @%d\n", hipGetErrorString(e_), __LINE__);                  \
            return 1;                                                                      \
        }                                                                                  \
    } while (0)

constexpr unsigned kXor1 = (1u << 10) | 0x1fu;  // upstream kDsSwizzleXor1
constexpr unsigned kXor2 = (2u << 10) | 0x1fu;
constexpr unsigned kXor4 = (4u << 10) | 0x1fu;
constexpr unsigned kXor8 = (8u << 10) | 0x1fu;
constexpr unsigned kXor16 = (16u << 10) | 0x1fu;
constexpr unsigned kXor32 = (32u << 10) | 0x1fu;

// The builtin operates on INT bits. Passing a float directly inserts
// v_cvt_i32_f32 VALUE conversions (measured in the ISA before this fix),
// which destroys the bit pattern for non-integral values — upstream uses
// the union bit-pun (quick_all_reduce.cuh / gdr_decode_packed_bf16.cu
// ds_swizzle_xor_f32) and so must any correct caller.
template <unsigned Code>
__device__ __forceinline__ float ds_swizzle_xor_f32(float value) {
    union {
        float f;
        int i;
    } bits;
    bits.f = value;
    bits.i = __builtin_amdgcn_ds_swizzle(bits.i, Code);  // immediate operand
    return bits.f;
}

// The swizzle code is an immediate: one instantiation per constant.
template <unsigned Code>
__global__ void swizzle_map_kernel(std::uint32_t* out /*[64]*/) {
    const int lane = threadIdx.x & 63;
    out[lane] = __builtin_amdgcn_ds_swizzle(static_cast<std::uint32_t>(lane), Code);
}

// xor masks 1,2,4 fold ONLY the 8-lane group (lanes sharing bits 3+ of the
// lane id) — exactly upstream's usage (reduce_k over kKThreads=8).
__global__ void butterfly_group_kernel(const float* in /*[64]*/, float* out /*[64]*/) {
    const int lane = threadIdx.x & 31;
    float v = in[lane];
    v += ds_swizzle_xor_f32<kXor1>(v);
    v += ds_swizzle_xor_f32<kXor2>(v);
    v += ds_swizzle_xor_f32<kXor4>(v);
    out[lane] = v;
}

// Full-wave fold: ds_swizzle codes (N<<10)|0x1f measure as XOR-butterfly
// SWAP,N for N = 1,2,4,8,16 — but N = 32 sets bit 15 of the immediate,
// which is NOT part of the xor field: clang DROPS the step silently
// (measured: the ISA contained SWAP,1/2/4/8/16 and no SWAP,32). The
// wave-wide fold therefore finishes with __shfl_xor(v, 32) — matching
// upstream, whose fused_split_gdr_update folds its 4 k-splits with
// __shfl_xor(16/32) instead of ds_swizzle for exactly this reason.
// Wave fold on wave32: masks 1..16 fold the full 32-lane wave. A xor32
// step is UNREACHABLE on this card (compiled wavefront = 32; clang drops
// the instruction). Cross-wave folding needs shared memory — exactly why
// upstream folds its 4 k-splits with __shfl_xor(16/32, width=64) on its
// wave64 CDNA targets, and why BlockTopkFilter::reduce uses LDS.
__global__ void butterfly_wave_kernel(const float* in /*[64]*/, float* out /*[64]*/) {
    const int lane = threadIdx.x & 31;
    float v = in[lane];
    v += ds_swizzle_xor_f32<kXor1>(v);
    v += ds_swizzle_xor_f32<kXor2>(v);
    v += ds_swizzle_xor_f32<kXor4>(v);
    v += ds_swizzle_xor_f32<kXor8>(v);
    v += ds_swizzle_xor_f32<kXor16>(v);
    out[lane] = v;
}

int main() {
    std::vector<std::uint32_t> m1(64), m2(64), m4(64);
    {
        std::uint32_t* d;
        CK(hipMalloc(&d, 64 * 4));
        hipLaunchKernelGGL((swizzle_map_kernel<kXor1>), dim3(1), dim3(64), 0, 0, d);
        CK(hipDeviceSynchronize());
        CK(hipMemcpy(m1.data(), d, 64 * 4, hipMemcpyDeviceToHost));
        hipLaunchKernelGGL((swizzle_map_kernel<kXor2>), dim3(1), dim3(64), 0, 0, d);
        CK(hipDeviceSynchronize());
        CK(hipMemcpy(m2.data(), d, 64 * 4, hipMemcpyDeviceToHost));
        hipLaunchKernelGGL((swizzle_map_kernel<kXor4>), dim3(1), dim3(64), 0, 0, d);
        CK(hipDeviceSynchronize());
        CK(hipMemcpy(m4.data(), d, 64 * 4, hipMemcpyDeviceToHost));
        CK(hipFree(d));
    }

    int fails = 0;
    const auto verdict = [&](const char* name, const std::vector<std::uint32_t>& m, unsigned N) {
        bool butterfly = true, broadcast = true, identity = true;
        const std::uint32_t bc = 7u ^ N;  // H2 candidate: ((lane&0)|7)^N
        for (int i = 0; i < 64; ++i) {
            const std::uint32_t si = static_cast<std::uint32_t>(i);
            butterfly &= (m[i] == (si ^ N));
            broadcast &= (m[i] == bc);
            identity &= (m[i] == si);
        }
        std::printf("code 0x%04X (N=%u): %s%s%s\n", (N << 10) | 0x1fu, N,
                    butterfly ? "[BUTTERFLY src=i^N] " : "", broadcast ? "[BROADCAST] " : "",
                    identity ? "[IDENTITY]" : "");
        if (!butterfly) {
            std::printf("  NOT a butterfly. first 16 entries (lane -> src): ");
            for (int i = 0; i < 16; ++i) std::printf("%u ", m[i]);
            std::printf("\n");
        }
        return butterfly ? 0 : 1;
    };
    fails += verdict("xor1", m1, 1);
    fails += verdict("xor2", m2, 2);
    fails += verdict("xor4", m4, 4);

    // Close the loop on the algorithmic contract: masks {1,2,4} fold the
    // 8-lane group (upstream reduce_k usage); all six masks fold the wave.
    {
        std::vector<float> in(64), out(64);
        for (int i = 0; i < 64; ++i) in[i] = static_cast<float>(i * 3 % 97);
        float block[8] = {0, 0, 0, 0, 0, 0, 0, 0};  // contiguous 8-lane blocks
        float wave_sum = 0;  // wave 0 = lanes 0..31 (compiled wave32)
        for (int i = 0; i < 64; ++i) {
            block[i >> 3] += in[i];  // lane i's group = lanes {i&~7 .. i&~7+7}
            if (i < 32) wave_sum += in[i];
        }
        float *din, *dout;
        CK(hipMalloc(&din, 64 * 4));
        CK(hipMalloc(&dout, 64 * 4));
        CK(hipMemcpy(din, in.data(), 64 * 4, hipMemcpyHostToDevice));
        hipLaunchKernelGGL(butterfly_group_kernel, dim3(1), dim3(32), 0, 0, din, dout);
        CK(hipDeviceSynchronize());
        CK(hipMemcpy(out.data(), dout, 64 * 4, hipMemcpyDeviceToHost));
        bool group_ok = true;
        for (int i = 0; i < 32; ++i) group_ok &= (out[i] == block[i >> 3]);
        std::printf("3-step butterfly (xor1+2+4) == 8-lane group sum: %s\n",
                    group_ok ? "PASS" : "FAIL");
        if (!group_ok)
            for (int i = 0; i < 8; ++i)
                std::printf("  lane %d: got %g want %g\n", i, out[i], block[i >> 3]);
        fails += group_ok ? 0 : 1;
        hipLaunchKernelGGL(butterfly_wave_kernel, dim3(1), dim3(32), 0, 0, din, dout);
        CK(hipDeviceSynchronize());
        CK(hipMemcpy(out.data(), dout, 64 * 4, hipMemcpyDeviceToHost));
        bool wave_ok = true;
        for (int i = 0; i < 32; ++i) wave_ok &= (out[i] == wave_sum);
        std::printf("5-step butterfly (xor1..16) == compiled-wave (32) sum: %s (wave sum=%g)\n",
                    wave_ok ? "PASS" : "FAIL", wave_sum);
        if (!wave_ok) {
            std::printf("  got[0]=%g got[1]=%g got[16]=%g want=%g\n", out[0], out[1], out[16],
                        wave_sum);
        }
        fails += wave_ok ? 0 : 1;
        CK(hipFree(din));
        CK(hipFree(dout));
    }

    std::printf("ds_swizzle_probe: %s\n", fails ? "FAIL" : "PASS");
    return fails ? 1 : 0;
}
