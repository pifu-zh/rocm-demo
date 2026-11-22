// consumer_all.hip — 源级等价消费（单 TU 合并版）
// 语义与流水线 bitcode 所代表的内容一致（同一 API/全局定义），单 TU 规避 hipcc
// 非 rdc 模式跨 TU 不解析 __device__ 符号的 quirk（实测: ld.lld undefined hidden symbol）
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
__device__ GpuStates globalGpuStates;   // 零初始化设备全局（host 下方初始化为 7）

__device__ void device_add_one(unsigned int* dst, const unsigned int* src, int n) {
  for (int i = threadIdx.x; i < n; i += blockDim.x)
    dst[i] = src[i] + (unsigned int)globalGpuStates.addend;
}

}  // namespace shmem
}  // namespace mori

__global__ void consumer_kernel(unsigned int* dst, const unsigned int* src, int n) {
  mori::shmem::device_add_one(dst, src, n);
}

int main() {
  setvbuf(stdout, NULL, _IONBF, 0);
  hipDeviceProp_t prop;
  if (hipGetDeviceProperties(&prop, 0) != hipSuccess) return 1;
  printf("device=%s\n", prop.gcnArchName);
  const int n = 1024;
  unsigned int *dSrc, *dDst;
  if (hipMalloc(&dSrc, n * 4) != hipSuccess) return 1;
  if (hipMalloc(&dDst, n * 4) != hipSuccess) return 1;
  std::vector<unsigned int> hSrc(n), hDst(n, 0);
  for (int i = 0; i < n; ++i) hSrc[i] = (unsigned)(i * 3 + 1);
  if (hipMemcpy(dSrc, hSrc.data(), n * 4, hipMemcpyHostToDevice) != hipSuccess) return 1;

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

  unsigned long long addend = hostInitOk ? 7ULL : 0ULL;
  int mism = 0;
  for (int i = 0; i < n; ++i)
    if (hDst[i] != hSrc[i] + (unsigned)addend) ++mism;
  printf("consumer run: hostInit=%d addend=%llu mism=%d/%d -> %s\n", (int)hostInitOk, addend,
         mism, n, mism == 0 ? "PASS" : "FAIL");
  return mism == 0 ? 0 : 1;
}
