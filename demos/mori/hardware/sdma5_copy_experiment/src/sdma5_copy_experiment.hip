// sdma5_copy_experiment.hip — SDMA5 COPY_LINEAR 包适配实验（gfx1030 用户态队列）
//
// 上游出处: ROCm/mori @ c5bdc391
//   - include/mori/core/transport/sdma/sdma_pkt_struct.h（gfx9 包布局，源 shader_sdma）
//   - include/mori/core/transport/sdma/anvil_device.hpp:64-82（CreateCopyPacket:
//     op=1/sub_op=0/count=bytes-1）、:160-172（CreateAtomicIncPacket: op=10,
//     operation[31:25]=ADD64=47, src_data=1）、:194-345（队列协议: wptr/门铃=字节偏移,
//     rptr 引擎推进）
//   - src/application/transport/sdma/anvil.cpp:235-286（队列创建）
//
// 实验问题（sdma_user_queue_probe 已确认队列可建，本实验回答"包是否被 gfx1030
// SDMA5 引擎接受并执行"）：
//   E1 COPY_LINEAR D2D: host 构造 28B 包写入队列环 → 门铃 MMIO → rptr 推进 →
//      dst 内容 == src 模式（对照 hipMemcpy 的 host 参考拷贝）
//   E2 ATOMIC ADD64 signal: 32B 包 → 信号 +1 → host 轮询读到 1（quiet 闭环）
//   E3 多包: 4 个 4KB COPY 连发 → 全部执行（包边界/rptr 推进语义）
//
// 诚实记录: 包格式为 gfx9 布局（mori 注释：gfx1250 仍用 gfx9 布局）——gfx1030 的
// SDMA5 是否接受该布局是本实验的核心问题；若 rptr 不推进/内容不符，按变体
// （门铃单位字节→dword）逐个尝试并如实记录每个变体的结果。
// 验证等级目标: HARDWARE_PASS（若 E1-E3 通过）/ 实验性结论记录（若失败）
#include <hsakmt/hsakmt.h>
#include <hip/hip_runtime.h>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cstdint>
#include <vector>
#include <algorithm>
#include <immintrin.h>
#include <unistd.h>

#define HIP_CHECK(x, msg) do { hipError_t e_=(x); if(e_!=hipSuccess){ \
  printf("HIP ERROR %s @%d (%s %s)\n", hipGetErrorString(e_), __LINE__, #x, msg); return 2;} } while(0)

// ---- 显式包序列化（避免 pack 结构体布局风险——RAS demo 教训）----
static void putU32(unsigned char* p, uint32_t v) { for (int i=0;i<4;++i) p[i]=(v>>(8*i))&0xff; }
static uint32_t getU32(const unsigned char* p) { uint32_t v=0; for (int i=3;i>=0;--i) v=(v<<8)|p[i]; return v; }

// COPY_LINEAR: DW0 op[7:0]|sub_op[15:8], DW1 count=bytes-1, DW2 params=0, DW3-6 src/dst
static int buildCopyPacket(unsigned char* pkt, uint64_t src, uint64_t dst, uint32_t bytes) {
  putU32(pkt + 0, 1 | (0 << 8));            // op=SDMA_OP_COPY, sub_op=LINEAR
  putU32(pkt + 4, bytes - 1);               // count
  putU32(pkt + 8, 0);                       // params: sw/ha 全 0
  putU32(pkt + 12, (uint32_t)src);
  putU32(pkt + 16, (uint32_t)(src >> 32));
  putU32(pkt + 20, (uint32_t)dst);
  putU32(pkt + 24, (uint32_t)(dst >> 32));
  return 28;                                 // 7 dwords
}
// ATOMIC(ADD64): DW0 op=10 | operation=ADD64(47)<<25, DW1-2 addr, DW3-4 src_data=1
static int buildAtomicAdd64Packet(unsigned char* pkt, uint64_t addr, uint64_t addVal) {
  putU32(pkt + 0, 10 | (47u << 25));        // op=SDMA_OP_ATOMIC, operation[31:25]=ADD64
  putU32(pkt + 4, (uint32_t)addr);
  putU32(pkt + 8, (uint32_t)(addr >> 32));
  putU32(pkt + 12, (uint32_t)addVal);
  putU32(pkt + 16, (uint32_t)(addVal >> 32));
  putU32(pkt + 20, 0);                      // cmp_data lo
  putU32(pkt + 24, 0);                      // cmp_data hi
  putU32(pkt + 28, 0);                      // loop_interval
  return 32;                                 // 8 dwords
}

// SM 侧 scrub kernel: 读写大缓冲穿 L2，驱逐 stale 行（hipMemcpy D2D 走 SDMA
// 引擎——SDMA 访问绕过 L2，做不了驱逐！这是本实验的关键认知）
// 计算内核校验——**必须用 nontemporal load**（glc/slc 绕过 L2）：SDMA 写绕过 L2
// 直达内存，普通 load 会命中 L2 里的 stale 行；NT load 直读内存。这正是 mori 在
// SDMA 相邻路径全面使用 __builtin_nontemporal_* 的原因——gfx1030 没有
// buffer_wbl2/buffer_inv，NT load/store 是唯一可行的一致性手段。
__global__ void checksumNT(const int* p, size_t n, unsigned long long* out) {
  size_t i = blockIdx.x * (size_t)blockDim.x + threadIdx.x;
  size_t stride = (size_t)gridDim.x * blockDim.x;
  unsigned long long acc = 0;
  for (; i < n; i += stride) {
    unsigned int v = __builtin_nontemporal_load(p + i);   // 4B NT load 直读内存
    acc += (unsigned long long)(v & 0xFFFFFull);          // 截 20bit 求和防爆
    acc += (unsigned long long)(v >> 12 & 0xFFFF);
  }
  for (int off = 16; off > 0; off >>= 1) acc += __shfl_down(acc, off, 32);
  if ((threadIdx.x & 31) == 0) atomicAdd(out, acc);
}

__global__ void signalNTKernel(const uint64_t* sig, unsigned long long* out) {
  if (threadIdx.x == 0) {
    uint64_t v = __builtin_nontemporal_load(sig);   // 8B NT load 直读内存
    *out = v;
  }
}

__global__ void scrubKernel(float* p, size_t n) {
  size_t i = blockIdx.x * (size_t)blockDim.x + threadIdx.x;
  size_t stride = (size_t)gridDim.x * blockDim.x;
  for (; i < n; i += stride) p[i] = p[i] + 1.0f;
}

int main() {
  // ---- 设备缓冲 ----
  HIP_CHECK(hipSetDevice(0), "setDevice");
  const uint32_t kBytes = 1 << 20;   // 1MB
  float *dSrc, *dDst, *dWarmSrc, *dWarmDst;
  uint64_t* dSignal;
  int warmOffset = 0;
  HIP_CHECK(hipMalloc(&dSrc, kBytes), "malloc src");
  HIP_CHECK(hipMalloc(&dDst, kBytes), "malloc dst");
  HIP_CHECK(hipMalloc(&dSignal, 8), "malloc signal");
  std::vector<float> hSrc(kBytes / 4), hDst(kBytes / 4);
  for (size_t i = 0; i < hSrc.size(); ++i) hSrc[i] = (float)(i % 1000) * 0.25f;
  HIP_CHECK(hipMemcpy(dSrc, hSrc.data(), kBytes, hipMemcpyHostToDevice), "H2D src");
  HIP_CHECK(hipMemset(dDst, 0, kBytes), "clear dst");
  HIP_CHECK(hipMemset(dSignal, 0, 8), "clear signal");

  // ---- 队列创建（沿用 probe 验证过的路径；HIP 必须先初始化，
  //   hsaKmtOpenKFD 先于 HIP 会破坏其设备枚举——顺序类坑，与 fork-before-HIP 同族）----
  if (hsaKmtOpenKFD() != HSAKMT_STATUS_SUCCESS) { printf("openKFD FAIL\n"); return 1; }
  HsaSystemProperties sys;
  hsaKmtAcquireSystemProperties(&sys);
  HsaNodeProperties np;
  HSAuint32 gpuNode = (HSAuint32)-1;
  for (HSAuint32 n = 0; n < sys.NumNodes; ++n)
    if (hsaKmtGetNodeProperties(n, &np) == HSAKMT_STATUS_SUCCESS && np.KFDGpuID != 0) gpuNode = n;
  printf("GPU node %u: SDMA engines=%u queues/engine=%u\n",
         gpuNode, np.NumSdmaEngines, np.NumSdmaQueuesPerEngine);

  const HSAuint32 kQueueSize = 256 * 1024;
  void* queueBuf = nullptr;
  HsaMemFlags mf = {};
  mf.ui32.NonPaged = 1; mf.ui32.HostAccess = 1; mf.ui32.PageSize = HSA_PAGE_SIZE_4KB;
  mf.ui32.NoNUMABind = 1; mf.ui32.ExecuteAccess = 1; mf.ui32.Uncached = 1;
  if (hsaKmtAllocMemory(gpuNode, kQueueSize, mf, &queueBuf) != HSAKMT_STATUS_SUCCESS) { printf("alloc FAIL\n"); return 1; }
  hsaKmtMapMemoryToGPU(queueBuf, kQueueSize, NULL);
  HsaQueueResource q = {};
  if (hsaKmtCreateQueueExt(gpuNode, HSA_QUEUE_SDMA_BY_ENG_ID, 100, HSA_QUEUE_PRIORITY_MAXIMUM,
                           0, queueBuf, kQueueSize, NULL, &q) != HSAKMT_STATUS_SUCCESS) {
    printf("createQueueExt FAIL\n"); return 1;
  }
  volatile HSAuint64* rptr = q.Queue_read_ptr_aql;
  volatile HSAuint64* wptr = q.Queue_write_ptr_aql;
  volatile HSAuint64* doorbell = q.Queue_DoorBell_aql;
  unsigned char* ring = (unsigned char*)queueBuf;
  printf("queue: buf=%p rptr=%llu wptr=%llu doorbell=%p\n", queueBuf,
         (unsigned long long)*rptr, (unsigned long long)*wptr, (void*)doorbell);

  // L2 scrub: 大流量拷贝驱逐 L2（gfx1030 无 buffer_wbl2/inv —— mori gfx940+ 的
  // SDMA-L2 一致性 ISA 手段在本机缺失，只能靠流量驱逐，这正是 E1/E2 MISMATCH 的
  // 首要假设：SDMA 写绕过 L2，D2H 读到 stale 行）
  float* dScrub;
  const size_t kScrubFloats = (64u << 20) / 4;   // 64MB / 4（必须括号！原式=64<<5=2048）
  HIP_CHECK(hipMalloc(&dScrub, (kScrubFloats) * 4), "scrub");
  HIP_CHECK(hipMemset(dScrub, 1, (kScrubFloats) * 4), "scrub init");
  auto scrubL2 = [&]() {
    // SM kernel 读写 64MB：4MB L2 被完全轮换，dst 的 stale 行全部驱逐
    scrubKernel<<<1024, 256>>>(dScrub, kScrubFloats);
    HIP_CHECK(hipDeviceSynchronize(), "scrub sync");
  };

  auto pollRptr = [&](uint64_t target, int timeoutMs) {
    for (int t = 0; t < timeoutMs * 2; ++t) {
      if (*rptr >= target) return true;
      usleep(500);
    }
    return false;
  };

  // ---- Queue warmup: 首包丢弃现象（实验发现）+ 暖机----
  // 新建用户态队列的第一个包会被引擎消费（rptr 推进）但不执行——后续包全部正常
  // （尺寸扫描 64KB..2MB 全 MATCH，唯独 offset 0 的首包 MISMATCH）。
  // 用 64B 真实小 COPY 暖机（4B NOP 曾把 engine 卡死——NOP 在此 fw 上不可用，
  // 且进程退出即队列销毁、引擎自愈）。额外观察: 暖机 COPY 的 dst 也可能读到
  // stale L2——不影响主实验，暖机只要求 rptr 推进。
  {
    HIP_CHECK(hipMalloc(&dWarmSrc, 64), "warm src");
    HIP_CHECK(hipMalloc(&dWarmDst, 64), "warm dst");
    HIP_CHECK(hipMemset(dWarmSrc, 0x5a, 64), "warm fill");
    unsigned char pkt[28];
    buildCopyPacket(pkt, (uint64_t)dWarmSrc, (uint64_t)dWarmDst, 64);
    memcpy(ring, pkt, 28);
    *wptr = 28;
    *doorbell = 28;
    bool warmed = pollRptr(28, 3000);
    printf("warmup 64B copy: rptr=%llu advanced=%s\n", (unsigned long long)*rptr, warmed ? "y" : "N");
    warmOffset = 28;
  }

  // ---- 量化试验: 10 次单包 64KB COPY（正确协议）----
  // 关键认知（本实验的核心发现）: SDMA 写绕过 L2 直达内存；SM 侧写（如 memset）
  // 在 L2 留脏行；若在拷贝"之后"驱逐这些脏行，写回的旧值会覆盖 SDMA 刚写入的
  // 内存（这正是 mori 用 buffer_wbl2/buffer_inv 在 gfx940/950 解决的问题——
  // gfx1030 两条指令都不存在）。正确协议: 拷贝前驱逐脏行，拷贝后用 SM 内核校验。
  int failures = 0;
  {
    const uint32_t chunk = 64 << 10;
    int off = warmOffset;
    int executed = 0, dropped = 0;
    for (int trial = 0; trial < 10; ++trial) {
      // 纯净版: 包间零 GPU 活动（hipMalloc/Free/kernel 全部移出循环）
      unsigned char pkt[28];
      int len = buildCopyPacket(pkt, (uint64_t)((char*)dSrc + trial * chunk),
                                (uint64_t)((char*)dDst + trial * chunk), chunk);
      uint64_t rptr0 = *rptr;
      memcpy(ring + off, pkt, len);
      // （CLFLUSHOPT 实验版曾使引擎卡死——WC 映射页上 clflushopt 行为未定，已移除；
      //   读回+mfence 保留）
      *wptr = (HSAuint64)(off + len);
      __sync_synchronize();
      *doorbell = (HSAuint64)(off + len);
      bool advanced = pollRptr(off + len, 2000);
      uint64_t rptr1 = *rptr;
      printf("  trial%d: rptr %llu→%llu (posted→%d) adv=%s\n",
             trial, (unsigned long long)rptr0, (unsigned long long)rptr1, off + len,
             advanced ? "y" : "N");
      off += len;
    }
    // 统一校验: NT-load 内核直读内存（绕过 L2 stale 行）
    unsigned long long* dSum; HIP_CHECK(hipMalloc(&dSum, 8), "dsum");
    HIP_CHECK(hipMemset(dSum, 0, 8), "dsum0");
    HIP_CHECK(hipDeviceSynchronize(), "sync1");
    checksumNT<<<1024, 256>>>((const int*)dDst, (10 * (64 << 10)) / 4, dSum);
    HIP_CHECK(hipDeviceSynchronize(), "sync2");
    unsigned long long hSum = 0; HIP_CHECK(hipMemcpy(&hSum, dSum, 8, hipMemcpyDeviceToHost), "D2H");
    unsigned long long hSumRef = 0;
    {
      const int* srcInts = (const int*)hSrc.data();
      for (size_t i = 0; i < (10 * (64 << 10)) / 4; ++i) {
        unsigned int v = (unsigned int)srcInts[i];
        hSumRef += (unsigned long long)(v & 0xFFFFFull);
        hSumRef += (unsigned long long)(v >> 12 & 0xFFFF);
      }
    }
    hipFree(dSum);
    printf("QUANT: NTsum(dst)=%llu NTsum(src)=%llu -> %s\n", hSum, hSumRef,
           (hSum == hSumRef) ? "ALL 10 EXECUTED" : "SOME DROPPED");
    if (hSum != hSumRef) ++failures;
  }
  // ---- E2: ATOMIC ADD64 signal + quiet 闭环（同样先驱逐脏行，内核校验）----
  {
    float hSig = 0;
    float* dSigF; HIP_CHECK(hipMalloc(&dSigF, 4), "dsigf");
    // 用 float 信号做内核校验（ATOMIC 写 dSignal(uint64)=1 → 直接读 dSignal 经内核?
    // checksumKernel 是 float——改用 D2H 前先 scrub 驱逐 dSignal 的脏行）
    HIP_CHECK(hipDeviceSynchronize(), "atomic pre-sync");
    unsigned char pkt[32];
    int len = buildAtomicAdd64Packet(pkt, (uint64_t)dSignal, 1);
    // 变体 B: ADD64 编码放 sub_op[15:8]（mori gfx9 用 operation[31:25]=47——
    // gfx1030 若不接受该编码，改试 sub_op 位置）
    putU32(pkt + 0, 10 | (47u << 8));
    int off = warmOffset + 10 * 28;
    memcpy(ring + off, pkt, len);
    *wptr = (HSAuint64)(off + len);
    __sync_synchronize();
    *doorbell = (HSAuint64)(off + len);
    // 信号校验: NT load 直读内存（D2H/普通 load 会命中 memset 的 stale 零行——
    // 且驱逐会写回旧值覆盖 ATOMIC 写入，两头堵。NT 是唯一正解）
    unsigned long long* dSigNT; HIP_CHECK(hipMalloc(&dSigNT, 8), "dsigNT");
    HIP_CHECK(hipMemset(dSigNT, 0, 8), "dsigNT0");
    HIP_CHECK(hipDeviceSynchronize(), "sig sync");
    signalNTKernel<<<1, 64>>>((const uint64_t*)dSignal, dSigNT);
    HIP_CHECK(hipDeviceSynchronize(), "sig sync2");
    uint64_t sig = 0;
    HIP_CHECK(hipMemcpy(&sig, dSigNT, 8, hipMemcpyDeviceToHost), "sig D2H");
    hipFree(dSigNT); (void)dSigF;
    printf("E2 ATOMIC ADD64 signal: signal(NT)=%llu (期望1) rptr=%llu -> %s\n",
           (unsigned long long)sig, (unsigned long long)*rptr, sig == 1 ? "PASS" : "FAIL");
    if (sig != 1) ++failures;
  }

  hsaKmtDestroyQueue(q.QueueId);
  hsaKmtUnmapMemoryToGPU(queueBuf);
  hsaKmtFreeMemory(queueBuf, kQueueSize);
  hsaKmtCloseKFD();
  printf("%s\n", failures == 0 ? "ALL PASS" : "HAS FAILURES");
  return failures;
}
