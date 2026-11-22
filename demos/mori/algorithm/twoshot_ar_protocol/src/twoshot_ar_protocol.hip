// twoshot_ar_protocol.hip — mori twoshot AllReduce 协议模拟（2-rank IPC 介质，A-06/A-07）
//
// 上游出处: ROCm/mori @ c5bdc391
//   - include/mori/collective/allreduce/twoshot_sdma_kernel.hpp:177-385
//     SdmaReduceScatterKernel 三相: scatter(每目的推 input 分片) → 世代 flag + 自旋
//     → 纯本地 reduce；:393-512 AllGatherSdmaKernel（推 reduced 分片到所有 rank 的槽）
//   - :511 "Flags are monotonic generation tokens (AMO_SET), so no reset is needed"
//     —— 世代 token 免清零纪律（A-07）
//   - twoshot_sdma_common.hpp:37-43,220-229 CrossPeBarrier 槽位复用握手（防 L2 alias）
//   - ccl_kernel_args.hpp:74-81 genCounter 设备侧世代号（防 graph 重放陷阱，另见
//     demos/runtime/graph_gen_counter）
//
// 介质差异（如实标注）: mori 数据面=SDMA 引擎（写绕过 L2，与 CU 写在 L2 上 alias——
// 这正是槽位复用握手的存在理由）；本模拟数据面=IPC 堆上的 SM store（同 GPU 共享 L2
// 天然一致），握手防御对象消失，但 scatter/flag/reduce/AG 的协议结构与世代 token
// 纪律逐件保留。SDMA 引擎面在 demos/hardware/sdma5_copy_experiment 另测。
//
// 测试: 2-rank 连续 3 世代 twoshot AR（每世代新输入、槽位零复位复用）+ host double/
// 逐位参考校验。
// 验证等级目标: HARDWARE_PASS（协议级模拟）
#include <hip/hip_runtime.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <sys/socket.h>
#include <unistd.h>
#include <cerrno>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cstdint>
#include <cmath>
#include <vector>

#define HIP_CHECK(x, msg) do { hipError_t e_=(x); if(e_!=hipSuccess){ \
  printf("[rank%d] HIP ERROR %s @%d (%s %s)\n", gMyPe, hipGetErrorString(e_), __LINE__, #x, msg); return 2;} } while(0)

static int gMyPe = 0;
static const int kShardWords = 2048;
static const int kNumPe = 2;
static constexpr int kPeer = 1;   // 2-rank 固定对端（device 代码也引用）                    // 每分片 8KB（0.5 步长可精确表示）
// 堆布局（word 偏移）: input(2 分片) | gather(按源 rank 索引 2 分片) | result(2 分片) | flags(2)
static const size_t kOffInput  = 0;
static const size_t kOffGather = (size_t)2 * kShardWords * 4;
static const size_t kOffResult = (size_t)4 * kShardWords * 4;
static const size_t kOffFlags  = (size_t)6 * kShardWords * 4;   // [0]=scatter flag, [1]=ag flag
static const size_t kHeapBytes = (size_t)6 * kShardWords * 4 + 256;

struct GpuStates {
  unsigned int* heapBase;      // 自己堆 VA
  unsigned int* peerHeap;      // 对端堆 VA（IPC 映射）
  int myPe, nPes;
};

// Phase1 scatter: rank p 发送自己的 shard(1-p) 到对端 gather 槽(1-p)
// （对端 reduce shard(1-p) 时需要本 rank 的该分片；槽按"目的分片号"索引）
__global__ void scatterKernel(GpuStates* gs, unsigned int epoch) {
  const int shard = 1 - gs->myPe;                       // 对端要 reduce 的分片
  unsigned int* src = gs->heapBase + (kOffInput/4) + (size_t)shard * kShardWords;
  unsigned int* dst = gs->peerHeap + (kOffGather/4) + (size_t)shard * kShardWords;
  // plain load/store（同 GPU 共享 L2，对端 SM store 经 alias VA 与本地读一致——
  // p2p_chain T1/T2 实证；NT load 在 IPC alias 内存上实测返回 -0.0 垃圾，弃用）
  for (int i = threadIdx.x; i < kShardWords; i += blockDim.x) dst[i] = src[i];
  __syncthreads();
  if (threadIdx.x == 0) {
    __threadfence_system();
    unsigned int* flag = gs->peerHeap + (kOffFlags/4);   // flags[0]=scatter flag
    __atomic_store_n(flag, epoch, __ATOMIC_RELAXED);     // 单调世代 token（免清零）
  }
}
// Phase2 reduce: result shard p = own input shard p + gather 槽 p（对端 input shard p）
__global__ void reduceKernel(GpuStates* gs) {
  const int shard = gs->myPe;
  const unsigned int* own   = gs->heapBase + (kOffInput/4) + (size_t)shard * kShardWords;
  const unsigned int* gathered = gs->heapBase + (kOffGather/4) + (size_t)shard * kShardWords;
  unsigned int* out = gs->heapBase + (kOffResult/4) + (size_t)shard * kShardWords;
  // NT store 写穿（mori SdmaVisibleStore 同款纪律）: SM 写经 L2 的脏行对 D2H
  // （SDMA 读，不 snoop L2）不可见——首版实测 result 读出 NaN/0
  for (int i = threadIdx.x; i < kShardWords; i += blockDim.x) {
    // 浮点语义 reduce: 位型整数加 ≠ 浮点加（0x42340000+0x421A0000=0x844E0000≈
    // -0.0，首版"sum=-0.0"的来源——mori WarpAccum 用 float 加同理）
    float fa, fb, fs;
    __builtin_memcpy(&fa, &own[i], 4);
    __builtin_memcpy(&fb, &gathered[i], 4);
    fs = fa + fb;
    unsigned int v;
    __builtin_memcpy(&v, &fs, 4);
    __builtin_nontemporal_store(v, &out[i]);
  }
  // 取证: dump kernel 视角的 gather/own 头部（NT 读直取内存）
  if (threadIdx.x == 0 && blockIdx.x == 0) {
    unsigned int* dbg = gs->heapBase + (kOffFlags/4) + 16;
    for (int k = 0; k < 8; ++k) {
      __builtin_nontemporal_store(gathered[k], &dbg[k]);
      __builtin_nontemporal_store(own[k], &dbg[8 + k]);
    }
  }
}
// Phase3 AG: rank p 发送自己的 result shard p 到对端 result 槽 p + 世代 flag
__global__ void allGatherKernel(GpuStates* gs, unsigned int epoch) {
  const int shard = gs->myPe;
  unsigned int* src = gs->heapBase + (kOffResult/4) + (size_t)shard * kShardWords;
  unsigned int* dst = gs->peerHeap + (kOffResult/4) + (size_t)shard * kShardWords;
  for (int i = threadIdx.x; i < kShardWords; i += blockDim.x) dst[i] = src[i];
  __syncthreads();
  if (threadIdx.x == 0) {
    __threadfence_system();
    unsigned int* flag = gs->peerHeap + (kOffFlags/4) + 1;   // flags[1]=ag flag
    __atomic_store_n(flag, epoch, __ATOMIC_RELAXED);
  }
}
// AG 接收等待: 对端 result 槽(1-p) 就绪 + 本地 shard(1-p) 已有 → 全量齐备（设备侧自旋）
__global__ void waitAgKernel(GpuStates* gs, unsigned int epoch, unsigned int* status) {
  if (threadIdx.x == 0 && blockIdx.x == 0) {
    volatile unsigned int* flag = gs->heapBase + (kOffFlags/4) + 1;
    while (__atomic_load_n((const unsigned int*)flag, __ATOMIC_ACQUIRE) < epoch)
      __builtin_amdgcn_s_sleep(4);
    *status = 1;
  }
}

// ---- socket helpers（D-03 mini）----
static int xsend(int fd, const void* p, size_t n) {
  const char* c = (const char*)p;
  while (n) { ssize_t k = send(fd, c, n, 0); if (k <= 0) return -1; c += k; n -= k; }
  return 0;
}
static int xrecv(int fd, void* p, size_t n) {
  char* c = (char*)p;
  while (n) { ssize_t k = recv(fd, c, n, 0); if (k <= 0) return -1; c += k; n -= k; }
  return 0;
}
static int barrierSock(int fd, char mine, char* peerOut) {
  if (xsend(fd, &mine, 1) != 0) return -1;
  return xrecv(fd, peerOut, 1);
}

int main(int argc, char** argv) {
  setvbuf(stdout, NULL, _IONBF, 0);
  if (argc < 3) { printf("usage: %s <0|1> <port>\n", argv[0]); return 1; }
  gMyPe = atoi(argv[1]);
  int port = atoi(argv[2]);

  int sock = socket(AF_INET, SOCK_STREAM, 0);
  int one = 1; setsockopt(sock, IPPROTO_TCP, TCP_NODELAY, &one, sizeof one);
  sockaddr_in addr{}; addr.sin_family = AF_INET; addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
  addr.sin_port = htons((uint16_t)port);
  int conn = -1;
  if (gMyPe == 0) {
    int lfd = socket(AF_INET, SOCK_STREAM, 0);
    setsockopt(lfd, SOL_SOCKET, SO_REUSEADDR, &one, sizeof one);
    if (bind(lfd, (sockaddr*)&addr, sizeof addr) != 0) { perror("bind"); return 1; }
    listen(lfd, 2);
    conn = accept(lfd, nullptr, nullptr);
    close(lfd);
  } else {
    for (int i = 0; i < 100; ++i) {
      conn = socket(AF_INET, SOCK_STREAM, 0);
      setsockopt(conn, IPPROTO_TCP, TCP_NODELAY, &one, sizeof one);
      if (connect(conn, (sockaddr*)&addr, sizeof addr) == 0) break;
      close(conn); conn = -1; usleep(50000);
    }
    if (conn < 0) { printf("[rank1] connect FAIL\n"); return 1; }
  }

  HIP_CHECK(hipSetDevice(0), "setDevice");
  hipDeviceProp_t prop; HIP_CHECK(hipGetDeviceProperties(&prop, 0), "props");
  // 关键实测: hipDeviceMallocUncached 堆的本地 VA=非缓存（DRAM 直读），而 IPC
  // alias VA=回写缓存——同一物理页两种策略 → 跨进程不连贯（对端 scatter 写进 L2
  // 脏行，本端非缓存读拿陈旧零 → AR 结果 NaN/全零）。改用普通缓存分配（标准 HIP
  // 内存模型，同 GPU 单 L2 对两 VA 一致）。mori 在 gfx942 上 Uncached+IPC 可用
  // （L2 行为不同），gfx1030 上不可行——ARCH_MATRIX 记录。
  unsigned int* heap = nullptr;
  HIP_CHECK(hipMalloc((void**)&heap, kHeapBytes), "heap");
  HIP_CHECK(hipMemset(heap, 0, kHeapBytes), "heap clear");
  hipIpcMemHandle_t handle;
  HIP_CHECK(hipIpcGetMemHandle(&handle, heap), "getHandle");
  uint64_t myAddr = (uint64_t)heap, peerAddr = 0;
  hipIpcMemHandle_t peerHandle{};
  if (gMyPe == 0) {
    HIP_CHECK(xsend(conn, &handle, sizeof handle) == 0 ? hipSuccess : hipErrorInvalidValue, "send h");
    HIP_CHECK(xrecv(conn, &peerHandle, sizeof peerHandle) == 0 ? hipSuccess : hipErrorInvalidValue, "recv h");
    HIP_CHECK(xsend(conn, &myAddr, 8) == 0 ? hipSuccess : hipErrorInvalidValue, "send a");
    HIP_CHECK(xrecv(conn, &peerAddr, 8) == 0 ? hipSuccess : hipErrorInvalidValue, "recv a");
  } else {
    HIP_CHECK(xrecv(conn, &peerHandle, sizeof peerHandle) == 0 ? hipSuccess : hipErrorInvalidValue, "recv h");
    HIP_CHECK(xsend(conn, &handle, sizeof handle) == 0 ? hipSuccess : hipErrorInvalidValue, "send h");
    HIP_CHECK(xrecv(conn, &peerAddr, 8) == 0 ? hipSuccess : hipErrorInvalidValue, "recv a");
    HIP_CHECK(xsend(conn, &myAddr, 8) == 0 ? hipSuccess : hipErrorInvalidValue, "send a");
  }
  unsigned int* peerHeap = nullptr;
  HIP_CHECK(hipIpcOpenMemHandle((void**)&peerHeap, peerHandle, hipIpcMemLazyEnablePeerAccess), "openHandle");
  printf("[rank%d] heap=%p peer=%p (device=%s)\n", gMyPe, heap, peerHeap, prop.gcnArchName);

  GpuStates hGs{heap, peerHeap, gMyPe, kNumPe};
  GpuStates* dGs; HIP_CHECK(hipMalloc(&dGs, sizeof hGs), "dGs");
  HIP_CHECK(hipMemcpy(dGs, &hGs, sizeof hGs, hipMemcpyHostToDevice), "GpuStates H2D");
  unsigned int* dStatus; HIP_CHECK(hipMalloc(&dStatus, 4), "dStatus");

  const int total = kShardWords * kNumPe;
  std::vector<float> input(total), got(total), base(total);
  float delta = 0.0f;   // 世代增量（两 rank 同式同值 → 期望值 host 可独立推导）
  for (int i = 0; i < total; ++i) base[i] = (float)((i * 7 + gMyPe * 13) % 97) * 0.5f;
  input = base;
  HIP_CHECK(hipMemcpy((char*)heap + kOffInput, input.data(), total * 4, hipMemcpyHostToDevice), "input H2D");

  int failures = 0;
  for (unsigned epoch = 1; epoch <= 3; ++epoch) {
    if (epoch >= 2) {   // 新世代输入（槽位零复位复用——世代 token 纪律）
      delta += (float)epoch;
      for (int i = 0; i < total; ++i) input[i] = base[i] + delta;
      HIP_CHECK(hipMemcpy((char*)heap + kOffInput, input.data(), total * 4, hipMemcpyHostToDevice), "re-H2D");
      HIP_CHECK(hipDeviceSynchronize(), "input sync");
    }
    char pb = 0;
    HIP_CHECK(barrierSock(conn, 's', &pb) == 0 ? hipSuccess : hipErrorInvalidValue, "ep start");

    // Phase1 scatter（双端各自执行；SM store 经共享 L2 对同 GPU 对端可见）
    scatterKernel<<<1, 256>>>(dGs, epoch);
    HIP_CHECK(hipGetLastError(), "scatter");
    HIP_CHECK(hipDeviceSynchronize(), "scatter sync");
    HIP_CHECK(barrierSock(conn, '1', &pb) == 0 ? hipSuccess : hipErrorInvalidValue, "phase1 bar");

    // 取证: D2H gather 槽(myPe)头 4 词 + flags 头 2 词
    {
      float g[4]; unsigned int fl[2];
      HIP_CHECK(hipMemcpy(g, (char*)heap + kOffGather + (size_t)gMyPe * kShardWords * 4, 16, hipMemcpyDeviceToHost), "gather D2H");
      HIP_CHECK(hipMemcpy(fl, (char*)heap + kOffFlags, 8, hipMemcpyDeviceToHost), "flags D2H");
      printf("[rank%d] forensics gather[myPe][0..3]=%.2f %.2f %.2f %.2f flags=[%u %u] raw=%08x %08x\n",
             gMyPe, g[0], g[1], g[2], g[3], fl[0], fl[1],
             *(unsigned int*)&g[0], *(unsigned int*)&g[1]);
    }

    // Phase2 本地 reduce
    reduceKernel<<<1, 256>>>(dGs);
    HIP_CHECK(hipGetLastError(), "reduce");
    HIP_CHECK(hipDeviceSynchronize(), "reduce sync");
    HIP_CHECK(barrierSock(conn, '2', &pb) == 0 ? hipSuccess : hipErrorInvalidValue, "phase2 bar");
    {
      float dbg[16];
      HIP_CHECK(hipMemcpy(dbg, (char*)heap + kOffFlags + 64, 64, hipMemcpyDeviceToHost), "dbg D2H");
      printf("[rank%d] kernel-saw gather=%.1f %.1f %.1f %.1f | own=%.1f %.1f %.1f %.1f | out0=%.2f\n",
             gMyPe, dbg[0], dbg[1], dbg[2], dbg[3], dbg[8], dbg[9], dbg[10], dbg[11], dbg[16 - 8]);
    }

    // Phase3 AG + 设备侧等待
    if (gMyPe == 1) {   // rank1 先推（rank0 等 rank1 的 ag flag）
      allGatherKernel<<<1, 256>>>(dGs, epoch);
      HIP_CHECK(hipGetLastError(), "ag");
      HIP_CHECK(hipDeviceSynchronize(), "ag sync");
    }
    if (gMyPe == 0) {
      HIP_CHECK(hipMemset(dStatus, 0, 4), "dStatus0");
      waitAgKernel<<<1, 64>>>(dGs, epoch, dStatus);
      HIP_CHECK(hipGetLastError(), "wait ag");
      HIP_CHECK(hipDeviceSynchronize(), "wait sync");
      unsigned int st = 0; HIP_CHECK(hipMemcpy(&st, dStatus, 4, hipMemcpyDeviceToHost), "st D2H");
      if (st != 1) { printf("[rank0] epoch%u: ag wait FAIL\n", epoch); ++failures; }
    }
    // rank0 的 AG 推送（rank1 等待其 ag flag）
    allGatherKernel<<<1, 256>>>(dGs, epoch);
    HIP_CHECK(hipGetLastError(), "ag0");
    HIP_CHECK(hipDeviceSynchronize(), "ag0 sync");
    if (gMyPe == 1) {
      HIP_CHECK(hipMemset(dStatus, 0, 4), "dStatus0");
      waitAgKernel<<<1, 64>>>(dGs, epoch, dStatus);
      HIP_CHECK(hipGetLastError(), "wait ag1");
      HIP_CHECK(hipDeviceSynchronize(), "wait sync1");
      unsigned int st = 0; HIP_CHECK(hipMemcpy(&st, dStatus, 4, hipMemcpyDeviceToHost), "st D2H");
      if (st != 1) { printf("[rank1] epoch%u: ag wait FAIL\n", epoch); ++failures; }
    }
    HIP_CHECK(barrierSock(conn, '3', &pb) == 0 ? hipSuccess : hipErrorInvalidValue, "phase3 bar");

    // 双侧全量校验（结果 = 双输入逐元素和；0.5 步长 + 和<2^24 → 逐位精确 memcmp）
    double gotSum = 0;
    HIP_CHECK(hipMemcpy(got.data(), (char*)heap + kOffResult, total * 4, hipMemcpyDeviceToHost), "result D2H");
    for (int i = 0; i < total; ++i) gotSum += got[i];
    int otherPe = 1 - gMyPe;
    int mism = 0;
    std::vector<float> expected(total);
    for (int i = 0; i < total; ++i) {
      float a = input[i];                                            // 本端（ rank p 输入）
      float b = (float)((i * 7 + otherPe * 13) % 97) * 0.5f + delta; // 对端（同式同 delta）
      expected[i] = a + b;
      if (got[i] != expected[i]) ++mism;
      gotSum += got[i];
    }
    double refSum = 0;
    for (int i = 0; i < total; ++i) refSum += (double)expected[i];
    bool ok = (mism == 0);
    printf("[rank%d] epoch%u: AR mism=%d/%d sum=%.1f ref=%.1f -> %s\n", gMyPe, epoch,
           mism, total, gotSum, refSum, ok ? "PASS" : "FAIL");
    printf("[rank%d]   got[0..5]=%.3f %.3f %.3f %.3f %.3f %.3f  exp[0..5]=%.3f %.3f %.3f %.3f %.3f %.3f\n",
           gMyPe, got[0], got[1], got[2], got[3], got[4], got[5],
           expected[0], expected[1], expected[2], expected[3], expected[4], expected[5]);
    printf("[rank%d]   got[2046..2051]=%.3f %.3f %.3f %.3f %.3f %.3f\n", gMyPe,
           got[2046], got[2047], got[2048], got[2049], got[2050], got[2051]);
    if (!ok) ++failures;
    HIP_CHECK(barrierSock(conn, 'e', &pb) == 0 ? hipSuccess : hipErrorInvalidValue, "epoch bar");
  }
  close(conn);
  printf("[rank%d] %s (failures=%d)\n", gMyPe, failures == 0 ? "RANK PASS" : "RANK FAIL", failures);
  return failures;
}
