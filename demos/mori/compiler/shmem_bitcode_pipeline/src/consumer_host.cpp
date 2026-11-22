// consumer_host.cpp — hipModule 驱动（Triton 同款加载路径: 加载 code object →
// hipModuleGetGlobal 初始化 globalGpuStates → hipModuleGetFunction → Launch）
#include <hip/hip_runtime.h>
#include <cstdio>
#include <vector>

int main() {
  setvbuf(stdout, NULL, _IONBF, 0);
  hipDeviceProp_t prop; if (hipGetDeviceProperties(&prop, 0) != hipSuccess) return 1;
  printf("device=%s\n", prop.gcnArchName);

  hipModule_t mod;
  hipError_t e = hipModuleLoad(&mod, "results/ir/full.co");
  if (e != hipSuccess) { printf("hipModuleLoad FAIL: %s\n", hipGetErrorString(e)); return 2; }

  // 初始化 globalGpuStates（mangled name 与上游精确一致）
  const char* kSym = "_ZN4mori5shmem15globalGpuStatesE";
  hipDeviceptr_t gSym = nullptr;
  size_t gSize = 0;
  e = hipModuleGetGlobal(&gSym, &gSize, mod, kSym);
  printf("hipModuleGetGlobal(%s): %s (size=%zu)\n", kSym, hipGetErrorString(e), gSize);
  if (e != hipSuccess) return 2;

  struct GpuStates { unsigned long long addend; unsigned int selfPe, nPes; };
  GpuStates gs{7ULL, 0u, 1u};
  e = hipMemcpy(gSym, &gs, sizeof gs, hipMemcpyHostToDevice);
  printf("global init (addend=7): %s\n", hipGetErrorString(e));
  if (e != hipSuccess) return 2;

  hipFunction_t fn;
  e = hipModuleGetFunction(&fn, mod, "consumer_kernel");
  if (e != hipSuccess) { printf("hipModuleGetFunction FAIL: %s\n", hipGetErrorString(e)); return 2; }

  const int n = 1024;
  unsigned int *dSrc, *dDst;
  if (hipMalloc(&dSrc, n * 4) != hipSuccess) return 1;
  if (hipMalloc(&dDst, n * 4) != hipSuccess) return 1;
  std::vector<unsigned int> hSrc(n), hDst(n, 0);
  for (int i = 0; i < n; ++i) hSrc[i] = (unsigned)(i * 3 + 1);
  hipMemcpy(dSrc, hSrc.data(), n * 4, hipMemcpyHostToDevice);

  void* params[] = {&dDst, &dSrc, (void*)&n};
  e = hipModuleLaunchKernel(fn, 1, 1, 1, 256, 1, 1, 0, nullptr, params, nullptr);
  if (e != hipSuccess) { printf("launch FAIL: %s\n", hipGetErrorString(e)); return 2; }
  hipDeviceSynchronize();
  hipMemcpy(hDst.data(), dDst, n * 4, hipMemcpyDeviceToHost);

  int mism = 0;
  for (int i = 0; i < n; ++i)
    if (hDst[i] != hSrc[i] + 7u) ++mism;
  printf("consumer run (Triton-style module path): mism=%d/%d, expect src+7 -> %s\n",
         mism, n, mism == 0 ? "PASS" : "FAIL");
  return mism == 0 ? 0 : 1;
}
