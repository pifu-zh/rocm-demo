// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2026, Advanced Micro Devices, Inc. All rights reserved.
//
// Demo: compiler/toolchain interfaces used across the aiter-adaptation
// research line, each as a minimal working example on gfx1030:
//
//   1. hipRTC — compile a kernel from a source string at RUNTIME, then run
//      it (the JIT leg of aiter's three-level compile cache).
//   2. AMDGCN builtins — __builtin_amdgcn_* intrinsics that have no HIP
//      API: a lane-crossing permute and the buffer_load→LDS passthrough
//      (llvm.amdgcn.raw.buffer.load.lds, the load aiter only issues on
//      gfx942 but RDNA2 hardware also implements).
//   3. Offline ISA code-object loading (clang -x assembler ->
//      hipModuleLoadData) is demonstrated by gpu/soft_tma.hip; llvm-mc
//      negative probes are documented in gpu/README.md.
//
// Build & run (inside the ROCm container):
//   hipcc -x hip --offload-arch=gfx1030 toolchain.hip -o toolchain -lhiprtc && ./toolchain
#include <hip/hip_runtime.h>
#include <hip/hiprtc.h>
#include <cmath>
#include <cstdio>
#include <cstring>
#include <string>
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

// ── 1. hipRTC: runtime-compiled kernel ──
static const char* kRtcSource = R"(
extern "C" __global__ void rtc_scale(const float* in, float* out, float s, int n) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) out[i] = in[i] * s;
}
)";

int run_rtc() {
    hiprtcProgram prog;
    if (hiprtcCreateProgram(&prog, kRtcSource, "rtc_scale.cu", 0, nullptr, nullptr) !=
        HIPRTC_SUCCESS) {
        std::printf("hiprtcCreateProgram failed\n");
        return 1;
    }
    // gfx1030 target, like the offline build.
    const char* opts[] = {"--gpu-architecture=gfx1030"};
    const hiprtcResult rc = hiprtcCompileProgram(prog, 1, opts);
    if (rc != HIPRTC_SUCCESS) {
        size_t log_size = 0;
        hiprtcGetProgramLogSize(prog, &log_size);
        std::vector<char> log(log_size ? log_size : 1);
        hiprtcGetProgramLog(prog, log.data());
        std::printf("hiprtc compile failed: %s\n%s\n", hiprtcGetErrorString(rc), log.data());
        return 1;
    }
    size_t code_size = 0;
    hiprtcGetCodeSize(prog, &code_size);
    std::vector<char> code(code_size);
    hiprtcGetCode(prog, code.data());
    hiprtcDestroyProgram(&prog);

    hipModule_t mod;
    CK(hipModuleLoadData(&mod, code.data()));
    hipFunction_t fn;
    CK(hipModuleGetFunction(&fn, mod, "rtc_scale"));  // extern "C" keeps the name

    const int n = 1024;
    std::vector<float> hin(n), hout(n, 0.0f);
    for (int i = 0; i < n; ++i) hin[i] = static_cast<float>(i);
    float *din, *dout;
    CK(hipMalloc(&din, n * 4));
    CK(hipMalloc(&dout, n * 4));
    CK(hipMemcpy(din, hin.data(), n * 4, hipMemcpyHostToDevice));
    float s = 2.5f;
    void* args[] = {&din, &dout, &s, const_cast<int*>(&n)};
    CK(hipModuleLaunchKernel(fn, 16, 1, 1, 64, 1, 1, 0, nullptr, args, nullptr));
    CK(hipDeviceSynchronize());
    CK(hipMemcpy(hout.data(), dout, n * 4, hipMemcpyDeviceToHost));
    int bad = 0;
    for (int i = 0; i < n; ++i)
        if (hout[i] != hin[i] * 2.5f) ++bad;
    hipFree(din);
    hipFree(dout);
    hipModuleUnload(mod);
    std::printf("1. hipRTC runtime compile+run: %s (%d/%d wrong)\n", bad ? "FAIL" : "PASS", bad,
                n);
    return bad ? 1 : 0;
}

// ── 2a. builtin with no HIP API: lane permute (bpermute reads any lane's
// value by bit offset — the warp-shuffle primitive the substitution
// catalogue's warp ops build on) ──
__global__ void builtin_bpermute(const int* in, int* out) {
    const int lane = threadIdx.x & 31;
    const int v = in[lane];
    // Read lane (lane ^ 1)'s value: byte-offset addressing = lane * 4.
    const int swapped = __builtin_amdgcn_ds_bpermute((lane ^ 1) * 4, v);
    out[lane] = swapped;
}

// ── 2b. buffer_load→LDS passthrough (b32) — the "RDNA2 hardware has it but
// aiter never used it outside gfx942" load. Two implementations compared:
//   * hand-written ISA (lds_probe in soft_tma_pipeline.co, loaded via
//     hipModule): explicit V# (config 0x31014000 — zero config silently hits
//     the OOB fill-zero path) + explicit m0; this is the form the research
//     line trust-probed on real hardware.
//   * the __builtin_amdgcn_raw_ptr_buffer_load_lds builtin: compiles and
//     runs, but on gfx1030/ROCm 7.2 it folds the shared-array base into
//     m0=0 while the array sits at LDS offset 128 — every result shifts by
//     +32 dwords. A real miscompile finding, reported as measured (the
//     catalogue discipline: verify primitives yourself, don't trust
//     declarations).
#include <cstdlib>

int run_builtins(int argc, char** argv) {
    // 2a: lane swap check.
    int hin[32], hout[32];
    for (int i = 0; i < 32; ++i) hin[i] = 100 + i;
    int *din, *dout;
    CK(hipMalloc(&din, 128));
    CK(hipMalloc(&dout, 128));
    CK(hipMemcpy(din, hin, 128, hipMemcpyHostToDevice));
    hipLaunchKernelGGL(builtin_bpermute, 1, 32, 0, 0, din, dout);
    CK(hipDeviceSynchronize());
    CK(hipMemcpy(hout, dout, 128, hipMemcpyDeviceToHost));
    int bad = 0;
    for (int i = 0; i < 32; ++i)
        if (hout[i] != 100 + (i ^ 1)) ++bad;
    std::printf("2a. __builtin_amdgcn_ds_bpermute lane^1: %s\n", bad ? "FAIL" : "PASS");

    // 2b: passthrough via raw ISA kernel.
    const char* co_path = argc > 1 ? argv[1] : "soft_tma_pipeline.co";
    FILE* f = fopen(co_path, "rb");
    if (!f) {
        std::printf("2b. cannot open %s\n", co_path);
        return 1;
    }
    fseek(f, 0, SEEK_END);
    const long sz = ftell(f);
    fseek(f, 0, SEEK_SET);
    std::vector<char> img(sz);
    if (fread(img.data(), 1, sz, f) != static_cast<size_t>(sz)) return 1;
    fclose(f);
    hipModule_t mod;
    CK(hipModuleLoadData(&mod, img.data()));
    hipFunction_t fn;
    CK(hipModuleGetFunction(&fn, mod, "lds_probe"));

    // One wave32 per workgroup: the passthrough path was trust-probed in
    // this shape (multi-wave shares m0 and faults).
    unsigned int gin[32], gout_isa[32];
    for (int i = 0; i < 32; ++i) gin[i] = 0xAB000u + i;
    unsigned int *dgin, *dgout;
    CK(hipMalloc(&dgin, 128));
    CK(hipMalloc(&dgout, 128));
    CK(hipMemcpy(dgin, gin, 128, hipMemcpyHostToDevice));
    int n = 32;
    void* args[] = {&dgin, &dgout, &n};
    CK(hipModuleLaunchKernel(fn, 1, 1, 1, 32, 1, 1, 0, nullptr, args, nullptr));
    CK(hipDeviceSynchronize());
    CK(hipMemcpy(gout_isa, dgout, 128, hipMemcpyDeviceToHost));
    int bad_isa = 0;
    for (int i = 0; i < 32; ++i)
        if (gout_isa[i] != 0xAB000u + i) ++bad_isa;
    std::printf("2b. buffer_load->LDS passthrough, raw ISA (m0 + V# 0x31014000, 1 wave): %s\n",
                bad_isa ? "FAIL" : "PASS");

    hipFree(din);
    hipFree(dout);
    hipFree(dgin);
    hipFree(dgout);
    hipModuleUnload(mod);
    return (bad || bad_isa) ? 1 : 0;
}

int main(int argc, char** argv) {
    int rc = run_rtc();
    rc |= run_builtins(argc, argv);
    std::printf("toolchain demo: %s\n", rc ? "FAIL" : "PASS");
    return rc;
}
