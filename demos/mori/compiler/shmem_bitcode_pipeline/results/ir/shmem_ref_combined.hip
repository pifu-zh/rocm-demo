// shmem_globals.hip — 设备全局状态 TU（mori shmem 的 globalGpuStates 对应物）
// 结构体+变量与上游同名同 namespace，mangled name 应精确复现
// `_ZN4mori5shmem15globalGpuStatesE`（core.py:171 的验证目标）
namespace mori {
namespace shmem {

struct GpuStates {
  unsigned long long addend;   // 演示用: 消费 kernel 的加数
  unsigned int selfPe;         // mori GpuStates 里有 myPe/nPes——保留字段占位
  unsigned int nPes;
};

// 零初始化设备全局（rdc 链接后由消费端 host 初始化或读零值）
__device__ GpuStates globalGpuStates;

}  // namespace shmem
}  // namespace mori

// shmem_api.hip — 设备 API TU（mori shmem_device_api 的最小对应物：读 GpuStates 的设备函数）
#include <cstdint>
#include <hip/hip_runtime.h>
namespace mori {
namespace shmem {


extern __device__ GpuStates globalGpuStates;   // 定义在 globals TU（llvm-link 合并）

// 设备 API: dst[i] = src[i] + addend —— Triton/FlyDSL kernel 的 extern 调用形态。
// noinline+used: 整程序设备编译会内联并删除未被 kernel 引用的 __device__ 函数
// （实测 nm 消失）；extern 库必须保活——mori 用 llvm.used 同理
__attribute__((noinline, used))
__device__ void device_add_one(unsigned int* dst, const unsigned int* src, int n) {
  for (int i = threadIdx.x; i < n; i += blockDim.x)   // 需 cooperative 启动
    dst[i] = src[i] + (unsigned int)globalGpuStates.addend;
}
// 带局部作用域的第二个函数: -O0 下会产生 llvm.lifetime 内在函数（Triton 兼容性
// 步骤的清除对象——core.py:99-171 的正则目标）
__device__ unsigned int device_pick(const unsigned int* src, int idx) {
  unsigned int local = src[idx];
  { unsigned int biased = local + (unsigned int)globalGpuStates.addend; local = biased; }
  return local;
}

}  // namespace shmem
}  // namespace mori

// barrier 式内核（mori shmem 模块的 faithful 形态: shmem 模块含 __global__ barrier
// kernel——同时保证 device_add_one 被引用而存活于 whole-program 编译产物）
extern "C" __global__ void shmem_internal_test_kernel(unsigned int* dst,
                                                      const unsigned int* src, int n) {
  mori::shmem::device_add_one(dst, src, n);
}
