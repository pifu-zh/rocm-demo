// Demo: GPU→CPU 发布协议（doorbell/status 发布序）—— proxy ring 的硬件内存序核心
//
// 上游出处: ROCm/mori @ c5bdc391
//   - include/mori/core/transport/rdma/proxy/proxy_device_primitives.hpp:58-77:
//       ProxyPostWrite：填 payload → `__threadfence_system()` → 置 status=PENDING
//       （release 语义手工实现；注释明言 CPU 侧依赖此序）
//   - include/mori/core/transport/rdma/proxy/proxy_types.hpp:31-99:
//       ProxyRing{gpu_head; ProxyCmd cmds[65536]}，128B cmd，status ∈ {FREE,PENDING,COMPLETED}
//   - src/application/transport/rdma/proxy/proxy_thread.cpp:290-410:
//       CPU MainLoop 轮询 gpu_head，取 PENDING 命令消费后回写 COMPLETED
//   - 同文件 :39-47: 设备自旋等待插入 `__builtin_amdgcn_s_sleep(1)` 背压
//
// 本 demo 在单张 gfx1030 上复刻该协议的最小闭环（"CPU proxy" 退化为宿主线程）：
//   1) 正确版: payload(64B+校验和) → __threadfence_system → relaxed store(status=PENDING)
//      宿主 acquire 读 status → 校验 payload 完整 —— 压力轮次零撕裂。
//   2) 违规版: 去掉 fence —— 内存模型层面 UB。实测记录撕裂率，并讨论为何在
//      PCIe posted-write 有序的本机组合上可能"看起来也能用"（诚实记录，不夸大）。
//   3) 设备侧自旋卫生: 等 host 置 flag 时，带 s_sleep 背压 vs 纯自旋的往返延迟对照
//      （mori ProxyWaitSlotFree 的模式，informational）。
//
// 验证等级目标: HARDWARE_PASS

#include <hip/hip_runtime.h>
#include <atomic>
#include <cstdio>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <chrono>
#include <thread>
#include <vector>

#define HIP_CHECK(x) do { hipError_t e_=(x); if(e_!=hipSuccess){ \
  printf("HIP ERROR %s @%s:%d\n", hipGetErrorString(e_), __FILE__, __LINE__); exit(1);} } while(0)

// ---- 复刻 mori 的状态机与命令布局（proxy_types.hpp:56-84 缩小版）----
enum Status : int { ST_FREE = 0, ST_PENDING = 1, ST_COMPLETED = 2 };
constexpr int kPayloadWords = 16;               // 64B payload（mori ProxyCmd 128B 的一半）
struct Cmd {
  volatile int status;                          // 命令状态（对齐的 4B 原子可见单位）
  unsigned long long seq;
  unsigned int payload[kPayloadWords];          // 校验对象
};
static unsigned int checksum(const unsigned int* p, int n) {
  unsigned int c = 2166136261u;
  for (int i = 0; i < n; ++i) { c = (c ^ p[i]) * 16777619u; }
  return c;
}

// ---- 设备端生产者 ----
// with_fence=true  : mori 协议（payload → threadfence_system → status）
// with_fence=false : 违规（无 fence）
__global__ void producer_kernel(Cmd* cmds, int ncmds, unsigned long long baseSeq,
                                int with_fence, unsigned int* outErr) {
  int i = blockIdx.x * blockDim.x + threadIdx.x;
  if (i >= ncmds) return;
  Cmd* c = &cmds[i];
  // 1) payload（多字 store，跨不同地址）
  unsigned int v = (unsigned int)(baseSeq + i) * 2654435761u;
  for (int w = 0; w < kPayloadWords; ++w) c->payload[w] = v ^ (w * 0x9e3779b9u);
  c->seq = baseSeq + i;
  // 2) 发布
  if (with_fence) __threadfence_system();       // ← mori proxy_device_primitives.hpp:74 的位置
  __atomic_store_n(&c->status, ST_PENDING, __ATOMIC_RELAXED);
  (void)outErr;
}

// ---- 设备端自旋等待（host→device 方向，测 s_sleep 背压）----
__global__ void waiter_kernel(volatile int* flag, unsigned long long* cycles, int use_sleep) {
  // 只让一个线程测延迟，避免争用噪声
  if (threadIdx.x == 0 && blockIdx.x == 0) {
    unsigned long long t0 = clock64();
    while (__atomic_load_n((const int*)flag, __ATOMIC_RELAXED) == 0) {
      if (use_sleep) __builtin_amdgcn_s_sleep(2);   // mori ProxyWaitSlotFree 模式（每轮短睡）
    }
    unsigned long long t1 = clock64();
    // 补一次 acquire（mori oneshot_sdma_kernel.hpp:119-128 的 light-spin 出口补偿思想）
    __atomic_thread_fence(__ATOMIC_ACQUIRE);
    *cycles = t1 - t0;
  }
}

int main() {
  hipDeviceProp_t prop; HIP_CHECK(hipGetDeviceProperties(&prop, 0));
  printf("device=%s warpSize=%d CU=%d\n", prop.gcnArchName, prop.warpSize, prop.multiProcessorCount);

  constexpr int kCmds = 4096;                    // ring 大小（mori 65536 的缩小版）
  constexpr int kRounds = 200;                   // 压力轮次
  Cmd* cmds;
  // host-mapped + portability：GPU 写、CPU 读（mori init.cpp:618-637 同款 hipHostRegister 语义）
  HIP_CHECK(hipHostMalloc(&cmds, kCmds * sizeof(Cmd), hipHostMallocMapped | hipHostMallocPortable));
  unsigned int* dErr; HIP_CHECK(hipMalloc(&dErr, 4));

  long long fenceErrs = 0, racyErrs = 0, fenceTornRounds = 0, racyTornRounds = 0;

  for (int mode = 0; mode < 2; ++mode) {
    const int withFence = (mode == 0);
    for (int round = 0; round < kRounds; ++round) {
      // reset: 全 FREE
      for (int i = 0; i < kCmds; ++i) cmds[i].status = ST_FREE;
      std::atomic_thread_fence(std::memory_order_seq_cst);

      producer_kernel<<<(kCmds + 255) / 256, 256>>>(cmds, kCmds,
          (unsigned long long)round * kCmds, withFence, dErr);
      HIP_CHECK(hipGetLastError());

      // 宿主消费者：acquire 读 status，PENDING 后校验 payload（mori proxy_thread.cpp:90-207 的最小化）
      int torn = 0;
      for (int i = 0; i < kCmds; ++i) {
        Cmd* c = &cmds[i];
        while (__atomic_load_n(&c->status, __ATOMIC_ACQUIRE) != ST_PENDING) { /* 自旋 */ }
        // 校验：payload 的每字都应等于该 seq 的期望值
        unsigned int v = (unsigned int)((unsigned long long)round * kCmds + i) * 2654435761u;
        for (int w = 0; w < kPayloadWords; ++w) {
          if (c->payload[w] != (v ^ (w * 0x9e3779b9u))) { ++torn; break; }
        }
        __atomic_store_n(&c->status, ST_COMPLETED, __ATOMIC_RELAXED);
      }
      HIP_CHECK(hipDeviceSynchronize());
      if (withFence) { fenceErrs += torn; if (torn) ++fenceTornRounds; }
      else           { racyErrs  += torn; if (torn) ++racyTornRounds; }
    }
    printf("%s protocol: %d rounds x %d cmds, torn_payloads=%lld (torn_rounds=%lld)\n",
           withFence ? "fence(mori)" : "racy(no fence)", kRounds, kCmds,
           withFence ? fenceErrs : racyErrs, withFence ? fenceTornRounds : racyTornRounds);
  }

  // ---- s_sleep 背压对照（信息性）----
  volatile int* flag; unsigned long long* dCycles;
  HIP_CHECK(hipHostMalloc(&flag, 4, hipHostMallocMapped));
  HIP_CHECK(hipMalloc(&dCycles, 8));
  double msSleep[2] = {0, 0};
  for (int variant = 0; variant < 2; ++variant) {
    *flag = 0;
    hipEvent_t e0, e1; hipEventCreate(&e0); hipEventCreate(&e1);
    waiter_kernel<<<1, 64>>>(flag, dCycles, variant);
    HIP_CHECK(hipGetLastError());
    std::this_thread::sleep_for(std::chrono::microseconds(200));  // 让 kernel 先自旋一会儿
    HIP_CHECK(hipEventRecord(e0));
    *flag = 1;
    HIP_CHECK(hipEventRecord(e1));
    HIP_CHECK(hipEventSynchronize(e1));
    float ms; hipEventElapsedTime(&ms, e0, e1);
    msSleep[variant] = ms;
    unsigned long long cyc; HIP_CHECK(hipMemcpy(&cyc, dCycles, 8, hipMemcpyDeviceToHost));
    printf("waiter %s: host-flag->wakeup=%.1fus, spin_cycles=%llu (信息性)\n",
           variant ? "s_sleep" : "plain-spin", ms * 1000.0, cyc);
    hipEventDestroy(e0); hipEventDestroy(e1);
  }

  int failures = (fenceErrs != 0) ? 1 : 0;   // 正确版必须零撕裂；违规版只记录不判失败
  printf("%s\n", failures == 0 ? "ALL PASS" : "HAS FAILURES");
  printf("note: racy 变体撕裂=%lld —— UB 在本机 PCIe 组合上的实测表现见上（不作为正确性依据）\n", racyErrs);
  return failures;
}
