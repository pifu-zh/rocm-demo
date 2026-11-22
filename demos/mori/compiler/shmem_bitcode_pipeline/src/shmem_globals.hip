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
