// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2026, Advanced Micro Devices, Inc. All rights reserved.
//
// Hardware-mechanism demo host: buffer_load -> LDS passthrough (m0 +
// lane*4) via the hand-written ISA kernel src/lds_probe_pipeline.s
// (assembled by scripts/build_run.sh, loaded with hipModuleLoadData).
// The measured constraints are documented in the .s header and README.md.
#include <hip/hip_runtime.h>

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

int main(int argc, char** argv) {
    FILE* f = fopen(argc > 1 ? argv[1] : "lds_probe.co", "rb");
    if (!f) {
        std::printf("no code object\n");
        return 1;
    }
    fseek(f, 0, SEEK_END);
    long n = ftell(f);
    fseek(f, 0, SEEK_SET);
    std::vector<char> img(n);
    if (fread(img.data(), 1, n, f) != static_cast<size_t>(n)) return 1;
    fclose(f);
    hipModule_t mod;
    CK(hipModuleLoadData(&mod, img.data()));
    hipFunction_t fn;
    CK(hipModuleGetFunction(&fn, mod, "lds_probe"));
    unsigned gin[32], gout[32];
    for (int i = 0; i < 32; ++i) gin[i] = 0xAB0000u + i;
    unsigned *dg, *dout;
    CK(hipMalloc(&dg, 128));
    CK(hipMalloc(&dout, 128));
    CK(hipMemcpy(dg, gin, 128, hipMemcpyHostToDevice));
    int n32 = 32;
    void* args[] = {&dg, &dout, &n32};
    CK(hipModuleLaunchKernel(fn, 1, 1, 1, 32, 1, 1, 0, nullptr, args, nullptr));
    CK(hipDeviceSynchronize());
    CK(hipMemcpy(gout, dout, 128, hipMemcpyDeviceToHost));
    int bad = 0;
    for (int i = 0; i < 32; ++i)
        if (gout[i] != 0xAB0000u + i) ++bad;
    std::printf("lds passthrough: %s\n", bad ? "FAIL" : "PASS");
    return bad;
}
