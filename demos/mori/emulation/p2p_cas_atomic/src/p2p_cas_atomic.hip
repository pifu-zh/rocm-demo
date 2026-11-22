// Demo: P2P 原子的 CAS-loop 软件仿真 —— mori "无原生原子介质"的软件原子母本
//
// 上游出处: ROCm/mori @ c5bdc391
//   - include/mori/core/transport/p2p/device_primitives.hpp:286-503（NonFetch）与
//     :417-503（Fetch 型）：AMO_ADD/AND/OR/XOR/SWAP/COMPARE_SWAP 全部用
//     AtomicCompareExchangeSystem 循环实现 —— 因为 P2P 介质（hipIpc 映射的
//     远端显存）不保证有原生原子。这是 mori 自己的"软件原子仿真"层。
//
// 本 demo 在 gfx1030 上回答两个问题：
//   Q1 语义等价：CAS-loop 版与硬件原子版在同一数据上产生完全一致的结果吗？
//      - fetch_add: 返回票据多重集合 == {0..N-1}（无重复无遗漏），终值 == N
//      - fetch_and/or/xor: 终值 == 独立 host 参考折叠（可交换可结合 → 顺序无关）
//      - compare_swap 单发协议: 恰好一个线程成功（重置协议语义）
//   Q2 代价：高争用下 CAS-loop 相对硬件原子的吞吐比例（informational）
//
// 验证等级目标: HARDWARE_PASS

#include <hip/hip_runtime.h>
#include <cstdio>
#include <cstdint>
#include <cstdlib>
#include <vector>
#include <algorithm>

#define HIP_CHECK(x) do { hipError_t e_=(x); if(e_!=hipSuccess){ \
  printf("HIP ERROR %s @%s:%d\n", hipGetErrorString(e_), __FILE__, __LINE__); exit(1);} } while(0)

// ---- mori 风格的 CAS-loop 原子（镜像 p2p/device_primitives.hpp 的实现模式）----
__device__ __forceinline__ unsigned int cas_fetch_add(unsigned int* p, unsigned int val) {
  unsigned int old = __atomic_load_n(p, __ATOMIC_RELAXED);
  while (true) {
    unsigned int next = old + val;
    if (__atomic_compare_exchange_n(p, &old, next, /*weak=*/false,
                                     __ATOMIC_ACQ_REL, __ATOMIC_RELAXED))
      return old;                                   // 返回旧值 = fetch 语义
    // old 已被比较交换失败更新为最新值，继续（mori: AtomicCompareExchangeSystem 循环）
  }
}
__device__ __forceinline__ unsigned int cas_fetch_fold(unsigned int* p, unsigned int val, int op) {
  unsigned int old = __atomic_load_n(p, __ATOMIC_RELAXED);
  while (true) {
    unsigned int next = old;
    if (op == 0) next &= val; else if (op == 1) next |= val; else next ^= val;
    if (__atomic_compare_exchange_n(p, &old, next, false, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED))
      return old;
  }
}
__device__ __forceinline__ bool cas_compare_swap(unsigned int* p, unsigned int expect, unsigned int repl) {
  unsigned int old = expect;
  return __atomic_compare_exchange_n(p, &old, repl, false, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED);
}

// ---- 高争用 stress kernel ----
constexpr unsigned int kThreads = 64u * 1024u;
constexpr int kReps = 4;

__global__ void stress_cas(unsigned int* ctr, unsigned int* fold, unsigned int* once,
                           unsigned int* tickets, int op) {
  unsigned int tid = blockIdx.x * (unsigned)blockDim.x + threadIdx.x;
  if (tid >= kThreads) return;
  for (int r = 0; r < kReps; ++r) {
    if (op == 0) {                                   // fetch_add：票号唯一性
      unsigned int t = cas_fetch_add(&ctr[0], 1u);
      tickets[tid * kReps + r] = t;
    } else if (op <= 3) {                            // and/or/xor 折叠
      cas_fetch_fold(&fold[0], tid * 2654435761u + r * 40503u + 1u, op - 1);
    } else {                                         // compare_swap 单发重置协议
      // 语义：initial 0；第一个 CAS(0 → gen) 成功者胜出；其余立刻失败
      if (cas_compare_swap(&once[0], 0u, 0xABCD0000u + tid)) atomicAdd(&once[1], 1u);
    }
  }
}

// ---- 硬件原子对照（同一数据形状，独立实现）----
__global__ void stress_hw(unsigned int* ctr, unsigned int* tickets) {
  unsigned int tid = blockIdx.x * (unsigned)blockDim.x + threadIdx.x;
  if (tid >= kThreads) return;
  for (int r = 0; r < kReps; ++r)
    tickets[tid * kReps + r] = atomicAdd(&ctr[0], 1u);
}

int main() {
  hipDeviceProp_t prop; HIP_CHECK(hipGetDeviceProperties(&prop, 0));
  printf("device=%s warpSize=%d CU=%d\n", prop.gcnArchName, prop.warpSize, prop.multiProcessorCount);

  unsigned int *dCtr, *dFold, *dOnce, *dTkt;
  HIP_CHECK(hipMalloc(&dCtr, 4)); HIP_CHECK(hipMalloc(&dFold, 4));
  HIP_CHECK(hipMalloc(&dOnce, 16)); HIP_CHECK(hipMalloc(&dTkt, (size_t)kThreads * kReps * 4));
  const int blocks = (kThreads + 255) / 256;
  int failures = 0;

  // ---- Q1a: fetch_add 票据唯一性（CAS vs 硬件，各自独立跑）----
  std::vector<unsigned int> tickets((size_t)kThreads * kReps);
  for (int variant = 0; variant < 2; ++variant) {
    HIP_CHECK(hipMemset(dCtr, 0, 4));
    if (variant == 0) stress_cas<<<blocks, 256>>>(dCtr, dFold, dOnce, dTkt, 0);
    else              stress_hw <<<blocks, 256>>>(dCtr, dTkt);
    HIP_CHECK(hipGetLastError()); HIP_CHECK(hipDeviceSynchronize());
    HIP_CHECK(hipMemcpy(tickets.data(), dTkt, tickets.size() * 4, hipMemcpyDeviceToHost));
    std::vector<unsigned int> sorted = tickets;
    std::sort(sorted.begin(), sorted.end());
    bool uniq = true;
    for (size_t i = 0; i < sorted.size(); ++i) if (sorted[i] != (unsigned)i) { uniq = false; break; }
    unsigned int finalV; HIP_CHECK(hipMemcpy(&finalV, dCtr, 4, hipMemcpyDeviceToHost));
    bool ok = uniq && finalV == kThreads * kReps;
    printf("%s fetch_add: tickets_unique=%s final=%u(期望%u) -> %s\n",
           variant ? "hw  " : "cas ", uniq ? "y" : "N", finalV, kThreads * kReps,
           ok ? "PASS" : "FAIL");
    if (!ok) ++failures;
  }

  // ---- Q1b: and/or/xor 折叠终值（host 独立参考 vs CAS 结果）----
  const char* opName[3] = {"and", "or", "xor"};
  for (int op = 1; op <= 3; ++op) {
    unsigned int init = (op == 1) ? 0xFFFFFFFFu : 0u;
    HIP_CHECK(hipMemcpy(dFold, &init, 4, hipMemcpyHostToDevice));
    stress_cas<<<blocks, 256>>>(dCtr, dFold, dOnce, dTkt, op);
    HIP_CHECK(hipDeviceSynchronize());
    unsigned int got; HIP_CHECK(hipMemcpy(&got, dFold, 4, hipMemcpyDeviceToHost));
    // host 参考：对同一操作数集合做顺序无关折叠
    unsigned int ref = init;
    for (unsigned int tid = 0; tid < kThreads; ++tid)
      for (int r = 0; r < kReps; ++r) {
        unsigned int v = tid * 2654435761u + (unsigned)r * 40503u + 1u;
        if (op == 1) ref &= v; else if (op == 2) ref |= v; else ref ^= v;
      }
    bool ok = got == ref;
    printf("cas fold_%s: got=%08x ref=%08x -> %s\n", opName[op - 1], got, ref, ok ? "PASS" : "FAIL");
    if (!ok) ++failures;
  }

  // ---- Q1c: compare_swap 单发协议（kThreads 线程争抢一个 CAS，恰一人成功）----
  {
    unsigned int zero[2] = {0, 0};
    HIP_CHECK(hipMemcpy(dOnce, zero, 8, hipMemcpyHostToDevice));
    stress_cas<<<blocks, 256>>>(dCtr, dFold, dOnce, dTkt, 4);
    HIP_CHECK(hipDeviceSynchronize());
    unsigned int once[2]; HIP_CHECK(hipMemcpy(once, dOnce, 8, hipMemcpyDeviceToHost));
    bool ok = once[1] == 1;   // 恰好一个线程的重置成功（kReps 轮每轮一个？——见下）
    // 注：kReps=4 轮间没有重置 once[0]，因此第 2..4 轮全部失败 → 累计成功数应为 1
    printf("cas compare_swap single-winner: winners=%u(期望1) final=%08x -> %s\n",
           once[1], once[0], ok ? "PASS" : "FAIL");
    if (!ok) ++failures;
  }

  // ---- Q2: 高争用吞吐对比（信息性）----
  {
    hipEvent_t e0, e1; hipEventCreate(&e0); hipEventCreate(&e1);
    float ms[2];
    for (int variant = 0; variant < 2; ++variant) {
      HIP_CHECK(hipMemset(dCtr, 0, 4));
      HIP_CHECK(hipEventRecord(e0));
      if (variant == 0) stress_cas<<<blocks, 256>>>(dCtr, dFold, dOnce, dTkt, 0);
      else              stress_hw <<<blocks, 256>>>(dCtr, dTkt);
      HIP_CHECK(hipEventRecord(e1)); HIP_CHECK(hipEventSynchronize(e1));
      hipEventElapsedTime(&ms[variant], e0, e1);
    }
    printf("contention throughput (信息性): cas=%.3fms hw=%.3fms ratio=%.1fx slower\n",
           ms[0], ms[1], ms[0] / ms[1]);
    hipEventDestroy(e0); hipEventDestroy(e1);
  }

  printf("%s\n", failures == 0 ? "ALL PASS" : "HAS FAILURES");
  return failures;
}
