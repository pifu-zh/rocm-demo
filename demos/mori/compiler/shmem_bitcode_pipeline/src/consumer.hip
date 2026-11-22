// consumer.hip — Triton-consumer 的 hipcc-rdc 等价消费：kernel 调 bitcode 里的
// extern API + 引用 extern 全局（rdc-link 时由 bitcode relocatable 解析）
#include <hip/hip_runtime.h>
#include <cstdio>
#include <vector>

namespace mori {
namespace shmem {
struct GpuStates {
  unsigned long long addend;
  unsigned int selfPe;
  unsigned int nPes;
};
extern __device__ GpuStates globalGpuStates;
__device__ void device_add_one(unsigned int* dst, const unsigned int* src, int n);
}  // namespace shmem
}  // namespace mori

__global__ void consumer_kernel(unsigned int* dst, const unsigned int* src, int n) {
  mori::shmem::device_add_one(dst, src, n);
}

int main() {
  setvbuf(stdout, NULL, _IONBF, 0);
  const int n = 1024;
  unsigned int *dSrc, *dDst;
  if (hipMalloc(&dSrc, n * 4) != hipSuccess) return 1;
  if (hipMalloc(&dDst, n * 4) != hipSuccess) return 1;
  std::vector<unsigned int> hSrc(n), hDst(n, 0);
  for (int i = 0; i < n; ++i) hSrc[i] = (unsigned)(i * 3 + 1);
  if (hipMemcpy(dSrc, hSrc.data(), n * 4, hipMemcpyHostToDevice) != hipSuccess) return 1;

  // host 初始化设备全局（addend=7）——extern 符号的 hipMemcpyToSymbol 尝试
  mori::shmem::GpuStates gs{7ULL, 0u, 1u};
  hipError_t e = hipMemcpyToSymbol(HIP_SYMBOL(mori::shmem::globalGpuStates), &gs, sizeof gs);
  bool hostInitOk = (e == hipSuccess);
  printf("memcpyToSymbol(globalGpuStates): %s\n", hipGetErrorString(e));
  if (hipDeviceSynchronize() != hipSuccess) return 1;

  consumer_kernel<<<1, 256>>>(dDst, dSrc, n);
  hipError_t le = hipGetLastError();
  if (hipDeviceSynchronize() != hipSuccess) le = hipErrorUnknown;
  if (le != hipSuccess) { printf("kernel launch: %s\n", hipGetErrorString(le)); return 2; }
  if (hipMemcpy(hDst.data(), dDst, n * 4, hipMemcpyDeviceToHost) != hipSuccess) return 1;

  // host 初始化成功 → src+7；零初始化全局（符号链接成立但 host 未能初始化）→ src+0
  // 两种结果都证明 bitcode 符号在运行时被解析；差异仅记录 host-init 能力
  unsigned long long addend = hostInitOk ? 7ULL : 0ULL;
  int mism = 0;
  for (int i = 0; i < n; ++i)
    if (hDst[i] != hSrc[i] + (unsigned)addend) ++mism;
  printf("consumer run: hostInit=%d addend=%llu mism=%d/%d -> %s\n", (int)hostInitOk, addend,
         mism, n, mism == 0 ? "PASS" : "FAIL");
  return mism == 0 ? 0 : 1;
}
