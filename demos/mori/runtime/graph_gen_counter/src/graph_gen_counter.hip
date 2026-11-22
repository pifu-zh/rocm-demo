// Demo: 设备侧世代计数器 vs host 冻结 token —— hipGraph 重放陷阱（E-15）
//
// 上游出处: ROCm/mori @ c5bdc391
//   - include/mori/collective/ccl_kernel_args.hpp:74-81:
//       CclAllgatherArgs::genCounter 是**设备侧世代计数器指针**——
//       "graph capture 时 host 造的 token 会被冻结，重放时 wait 恒真导致读到在途数据"
//   - include/mori/collective/allgather/oneshot_sdma_kernel.hpp:131-137:
//       "kernel 自己 +1 并在全员 flag 到齐后写回"
//   - docs/MORI_JIT_V2_DESIGN.md §4: 跨设备 barrier 的 epoch 由设备侧自增
//       （dispatch 结尾 atomicAdd(xdbFlag,1)），否则捕获把定值冻进图里
//
// 本 demo 用单卡双 stream 复现该陷阱的可观测形态：
//   producer(stream A): 自旋 ~数 µs → 写 64 word (值=epoch*1000+i) → threadfence → flag=epoch
//   consumer(stream B): 自旋等 flag>=gen → 读 64 word → 与期望比对
//   图捕获 consumer 一次，反复重放；producer 常规发射（每次新 epoch）。
//
//   变体 A（陷阱）: gen 是**捕获期冻结的立即数**。重放 r≥2 时 flag 已是 r-1 世代，
//     wait 恒真 → consumer 在 producer-r 写完之前就读 → 读到旧世代/半成品。
//   变体 B（mori 修法）: gen 是**设备计数器指针**，consumer 每次重放运行时
//     atomicAdd(counter,1)+1 得到本世代 → 等到 producer-r 的 flag → 永远正确。
//
// 陷阱是真实的数据竞争（这正是它的本质），故用"捕获率统计"呈现：重复 R 轮，
// 统计两条变体的错误重放数。验证等级目标: HARDWARE_PASS
#include <hip/hip_runtime.h>
#include <cstdio>
#include <cstdlib>
#include <vector>

#define HIP_CHECK(x) do { hipError_t e_=(x); if(e_!=hipSuccess){ \
  printf("HIP ERROR %s @%s:%d (%s)\n", hipGetErrorString(e_), __FILE__, __LINE__, #x); exit(1);} } while(0)

constexpr int kWords = 64;
constexpr int kReplays = 200;
constexpr int kEpochBase = 1000;

__global__ void producer_kernel(unsigned int* buf, int* flag, int epoch, int spinUs) {
  if (threadIdx.x == 0) {
    // 拉宽窗口：让并发重放的 consumer 有机会落在写入窗口内
    unsigned long long t0 = clock64();
    unsigned long long target = t0 + (unsigned long long)spinUs * 27;  // ~27 cyc/ns 粗略
    while (clock64() < target) { }
    __threadfence_block();
    for (int i = 0; i < kWords; ++i) buf[i] = (unsigned)(epoch * kEpochBase + i);
    __threadfence_system();                       // payload 先于 flag 可见（发布序，Demo 3）
    __atomic_store_n(flag, epoch, __ATOMIC_RELAXED);
  }
}
// 变体 A: gen 冻结
__global__ void consumer_frozen(const unsigned int* buf, const int* flag, int gen,
                                unsigned int* out) {
  if (threadIdx.x == 0) {
    while (__atomic_load_n(flag, __ATOMIC_ACQUIRE) < gen) { __builtin_amdgcn_s_sleep(2); }
    for (int i = 0; i < kWords; ++i) out[i] = buf[i];
  }
}
// 变体 B: genCounter 设备指针（mori 修法）
__global__ void consumer_device_gen(const unsigned int* buf, const int* flag,
                                    int* genCounter, unsigned int* out) {
  if (threadIdx.x == 0) {
    int expected = atomicAdd(genCounter, 1) + 1;   // 本重放的世代（运行时取得）
    while (__atomic_load_n(flag, __ATOMIC_ACQUIRE) < expected) { __builtin_amdgcn_s_sleep(2); }
    for (int i = 0; i < kWords; ++i) out[i] = buf[i];
  }
}

static bool checkOut(const std::vector<unsigned int>& out, int epoch) {
  for (int i = 0; i < kWords; ++i)
    if (out[i] != (unsigned)(epoch * kEpochBase + i)) return false;
  return true;
}

int main() {
  hipDeviceProp_t prop; HIP_CHECK(hipGetDeviceProperties(&prop, 0));
  printf("device=%s warpSize=%d\n", prop.gcnArchName, prop.warpSize);

  unsigned int *dBuf, *dOut; int *dFlag, *dGenCounter;
  HIP_CHECK(hipMalloc(&dBuf, kWords * 4));
  HIP_CHECK(hipMalloc(&dOut, kWords * 4));
  HIP_CHECK(hipMalloc(&dFlag, 4));
  HIP_CHECK(hipMalloc(&dGenCounter, 4));
  HIP_CHECK(hipMemset(dFlag, 0, 4));
  HIP_CHECK(hipMemset(dGenCounter, 0, 4));
  std::vector<unsigned int> hOut(kWords);
  hipStream_t sa, sb;
  HIP_CHECK(hipStreamCreate(&sa)); HIP_CHECK(hipStreamCreate(&sb));

  // ---- 图捕获：consumer 各捕获一次（参数在捕获期冻结 —— 图语义）----
  hipGraph_t gFrozen, gDevice;
  hipGraphExec_t geFrozen, geDevice;
  const int kFrozenGen = 1;   // host 造的 token（捕获期定值 —— 陷阱根源）
  {
    HIP_CHECK(hipStreamBeginCapture(sb, hipStreamCaptureModeGlobal));
    consumer_frozen<<<1, 32, 0, sb>>>(dBuf, dFlag, kFrozenGen, dOut);
    HIP_CHECK(hipStreamEndCapture(sb, &gFrozen));
    HIP_CHECK(hipGraphInstantiate(&geFrozen, gFrozen, nullptr, nullptr, 0));
  }
  {
    HIP_CHECK(hipStreamBeginCapture(sb, hipStreamCaptureModeGlobal));
    consumer_device_gen<<<1, 32, 0, sb>>>(dBuf, dFlag, dGenCounter, dOut);
    HIP_CHECK(hipStreamEndCapture(sb, &gDevice));
    HIP_CHECK(hipGraphInstantiate(&geDevice, gDevice, nullptr, nullptr, 0));
  }

  int trapFrozen = 0, trapDevice = 0;
  for (int r = 1; r <= kReplays; ++r) {
    // ---- 变体 A ----
    HIP_CHECK(hipMemset(dOut, 0, kWords * 4));
    producer_kernel<<<1, 32, 0, sa>>>(dBuf, dFlag, r, 8);   // producer 常规发射（新 epoch）
    HIP_CHECK(hipGraphLaunch(geFrozen, sb));                 // consumer 图重放（gen 冻结=1）
    HIP_CHECK(hipStreamSynchronize(sa));
    HIP_CHECK(hipStreamSynchronize(sb));
    HIP_CHECK(hipMemcpy(hOut.data(), dOut, kWords * 4, hipMemcpyDeviceToHost));
    if (!checkOut(hOut, r)) ++trapFrozen;

    // ---- 变体 B（重置 flag 语义：flag 单调递增即可，无需清零）----
    HIP_CHECK(hipMemset(dOut, 0, kWords * 4));
    producer_kernel<<<1, 32, 0, sa>>>(dBuf, dFlag, r, 8);
    HIP_CHECK(hipGraphLaunch(geDevice, sb));
    HIP_CHECK(hipStreamSynchronize(sa));
    HIP_CHECK(hipStreamSynchronize(sb));
    HIP_CHECK(hipMemcpy(hOut.data(), dOut, kWords * 4, hipMemcpyDeviceToHost));
    if (!checkOut(hOut, r)) ++trapDevice;
  }
  printf("frozen-gen host token : trapped_replays=%d/%d -> %s\n",
         trapFrozen, kReplays, trapFrozen > 0 ? "TRAP OBSERVED（bug 复现）" : "no trap observed");
  printf("device-side genCounter: trapped_replays=%d/%d -> %s\n",
         trapDevice, kReplays, trapDevice == 0 ? "PASS（mori 修法有效）" : "FAIL");
  hipGraphExecDestroy(geFrozen); hipGraphExecDestroy(geDevice);
  hipGraphDestroy(gFrozen); hipGraphDestroy(gDevice);
  int failures = trapDevice;   // 只有 mori 修法不允许失败；陷阱变体按观测记录
  printf("%s\n", failures == 0 ? "ALL PASS" : "HAS FAILURES");
  return failures;
}
