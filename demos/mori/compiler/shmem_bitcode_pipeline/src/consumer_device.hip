// consumer_device.hip — Triton-consumer 的设备侧模拟：kernel 调用 bitcode 里的
// extern 函数 + 引用 extern 全局（真实消费端=Triton 把 extern BC 链进自己的模块）
#include <hip/hip_runtime.h>
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

extern "C" __global__ void consumer_kernel(unsigned int* dst, const unsigned int* src, int n) {
  mori::shmem::device_add_one(dst, src, n);
}
