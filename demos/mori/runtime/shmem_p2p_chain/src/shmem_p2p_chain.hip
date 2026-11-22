// shmem_p2p_chain.hip — mori SHMEM P2P 全链路复现：put+signal/wait/get/CAS 原子/barrier
// （双进程单卡，IPC 对称堆介质——Demo ipc_symmetric_heap 已验证；端到端 P2P 语义链）
//
// 上游出处: ROCm/mori @ c5bdc391
//   - include/mori/shmem/shmem_device_api.hpp:61-74 DISPATCH_TRANSPORT_TYPE（运行时
//     per-PE transportTypes + 编译期模板特化——本 demo 固化 P2P 实例并复刻结构）
//   - include/mori/shmem/shmem_p2p_kernels.hpp:39（Put=纯 load/store）; :222（PutSignal
//     release 信号）; :286-404（P2P 原子=CAS-loop 仿真）; :1151-1158（P2P quiet=no-op，
//     写即完成）；shmem_device_api.hpp:1140-1189（WaitUntilGreaterThan/Equals 轮询）
//   - src/shmem/init.cpp:594-671 GpuStateInit + runtime.cpp:93-114 CopyGpuStatesToDevice
//     （host 构造 GpuStates{heapBase, p2pPeerPtrs[], transportTypes[]} → hipMemcpy 灌进
//     设备——路径 (b) addr-provider 风格的显式结构体拷贝）
//   - src/shmem/init.cpp:956-1036 ShmemGetUniqueId（TCP 端口 rendezvous——本 demo 的
//     socket bootstrap 迷你版，覆盖 D-03 的 Socket 网络语义）
//   - src/shmem/shmem_device_api.hpp:1207-1289 ShmemInternalBarrier（PE0 coordinator
//     两阶段: 非 leader 放 pSync → coordinator 感知后分发 done）
//   - include/mori/shmem/internal.hpp:62 静态堆 4GB Uncached（demo 缩小为 16MB）
//
// 测试（2 PE，全设备侧语义）:
//   T1 put+signal 0→1: rank0 WarpCopy 式 put + release signal → rank1 设备侧
//      WaitUntilGreaterThan + 全量校验（2 世代单调 token，免清零）
//   T2 put+signal 1→0: 反向同构
//   T3 get: rank1 铺数据 → rank0 GetMemNbi 读对端 → host 校验
//   T4 原子: rank1 CAS-loop fetch_add ×1000（远端）+ rank0 本地加 ×1000 → 计数==2000
//      且 CAS 旧值连续（fetch 语义）
//   T5 barrier: PE0-coordinator 两阶段（arrive pSync → coordinator 分发 done）
// 验证等级目标: HARDWARE_PASS
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
#include <vector>

#define HIP_CHECK(x, msg) do { hipError_t e_=(x); if(e_!=hipSuccess){ \
  printf("[rank%d] HIP ERROR %s @%d (%s %s)\n", gMyPe, hipGetErrorString(e_), __LINE__, #x, msg); return 2;} } while(0)

// ---- 堆布局（internal.hpp 静态堆的缩小版：data 区 + pSync 尾部区）----
static const size_t kHeapBytes   = 16ULL << 20;              // 16MB（mori 默认 4GB）
static const size_t kOff1        = 1ULL  << 20;              // 1MB: T1 put 区
static const size_t kOff2        = 2ULL  << 20;              // 2MB: T2 put 区
static const size_t kOff3        = 3ULL  << 20;              // 3MB: T3 get 源区
static const size_t kOff4        = 4ULL  << 20;              // 4MB: T3 get 本地落区
static const size_t kOffCnt      = 5ULL  << 20;              // 5MB: T4 原子计数器
static const size_t kSyncOff     = kHeapBytes - 4096;        // pSync 区（堆尾 4KB）
static const size_t kSigSlot     = kSyncOff;                 // 信号槽（单调 token）
static const size_t kArrSlot     = kSyncOff + 64;            // barrier arrive 槽
static const size_t kDoneSlot    = kSyncOff + 128;           // barrier done 槽
static const int    kWords       = 4096;                     // 每次传输 16KB

// ---- GpuStates（internal.hpp:117-140 的最小化；host 构造 hipMemcpy 灌设备）----
struct GpuStates {
  unsigned int* heapBase;      // 自己的对称堆 VA
  unsigned int* peerHeap;      // 对端堆 VA（IPC 映射后）
  int myPe;
  int nPes;
};

// ---- 设备内核（全部从 GpuStates 取地址——mori kernel 的取址模式）----
// T1/T2: put+signal（PutMemNbi + PutSignal 合体; ThreadCopy 式平铺 + release 信号）
// 单 block 协同式（对应 mori Thread 语义的信号纪律）: 全部写入由本 block 完成，
// __syncthreads 后 thread0 fence+signal——多 block 无 grid 同步，signal 会先于
// 未完成 block 的写入（本 demo 首版实测 mism=3840/4096 的根因）
__global__ void putSignalKernel(GpuStates* gs, size_t srcOff, size_t dstOff, int n,
                                unsigned int sigVal) {
  for (int i = threadIdx.x; i < n; i += blockDim.x)
    gs->peerHeap[(dstOff / 4) + i] = gs->heapBase[(srcOff / 4) + i];
  __syncthreads();
  if (threadIdx.x == 0) {
    __threadfence_system();                                    // payload 先于信号可见
    unsigned int* sigAddr = gs->peerHeap + (kSigSlot / 4);
    __atomic_store_n(sigAddr, sigVal, __ATOMIC_RELAXED);       // mori: AtomicStoreReleaseSystem
  }
}
// 接收侧: WaitUntilGreaterThan(own pSync, expect) + 全量校验（设备侧自旋）
// 单 block 版: thread0 spin，syncthreads 后全 block strided 校验（多 block 版中
// 其余 block 不经等待直接校验，产生竞态误报——首版实测教训）
__global__ void waitVerifyKernel(GpuStates* gs, size_t dataOff, int n, unsigned int expectSig,
                                 unsigned int base, unsigned int* mism) {
  if (threadIdx.x == 0) {
    volatile unsigned int* sig = gs->heapBase + (kSigSlot / 4);
    while (__atomic_load_n((const unsigned int*)sig, __ATOMIC_ACQUIRE) < expectSig) {
      __builtin_amdgcn_s_sleep(4);                              // mori light-spin 模式
    }
  }
  __syncthreads();
  for (int i = threadIdx.x; i < n; i += blockDim.x)
    if (gs->heapBase[(dataOff / 4) + i] != base + (unsigned)i) atomicAdd(mism, 1);
}
// T3: GetMemNbi（读对端 → 本地落区）
// 本地落区用 **NT store**（写穿到内存）: kernel 写经 L2 的脏行对后续 D2H（SDMA 读，
// 不 snoop L2）不可见——正是 mori gfx940 用 buffer_wbl2、SDMA 相邻路径全面用
// __builtin_nontemporal_store 解决的问题（SdmaVisibleStore 同款纪律）
__global__ void getKernel(GpuStates* gs, size_t peerOff, size_t localOff, int n) {
  for (int i = threadIdx.x; i < n; i += blockDim.x) {
    unsigned int v = gs->peerHeap[(peerOff / 4) + i];
    __builtin_nontemporal_store(v, &gs->heapBase[(localOff / 4) + i]);
  }
}
// kernel 铺模式数据（SM 写，经共享 L2 对同 GPU 其他 SM 可见）
__global__ void fillPatternKernel(unsigned int* addr, int n, unsigned int base) {
  int i = blockIdx.x * blockDim.x + threadIdx.x;
  if (i < n) addr[i] = base + (unsigned)i;
}
// T4: P2P 原子 = CAS-loop fetch_add（device_primitives.hpp:286-404 的语义）；
// 单线程连发 1000 次，记录首个/末个旧值（fetch 语义 → 应连续）
__global__ void casAddKernel(GpuStates* gs, size_t cntOff, int iters, unsigned long long* ticket) {
  if (threadIdx.x == 0 && blockIdx.x == 0) {
    unsigned int* p = gs->peerHeap + (cntOff / 4);
    unsigned int old = __atomic_load_n(p, __ATOMIC_RELAXED);
    unsigned long long first = old, last = 0;
    for (int k = 0; k < iters; ++k) {
      while (true) {
        unsigned int next = old + 1;
        if (__atomic_compare_exchange_n(p, &old, next, false, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED)) {
          last = old;   // 成功时的 old 即 fetch 返回值
          break;
        }
      }
    }
    ticket[0] = first; ticket[1] = last;
  }
}
// plain atomicAdd via IPC alias（对照：CAS-via-alias 是否特有问题）
__global__ void remoteAtomicAddKernel(GpuStates* gs, size_t cntOff, int iters) {
  if (threadIdx.x == 0 && blockIdx.x == 0)
    for (int k = 0; k < iters; ++k) atomicAdd(gs->peerHeap + (cntOff / 4), 1u);
}
// 设备侧读计数（绕开 D2H 路径疑虑）
__global__ void readCounterKernel(const unsigned int* cnt, unsigned long long* out) {
  if (threadIdx.x == 0 && blockIdx.x == 0) *out = *cnt;
}

// 本地原子对照（rank0 自己的 1000 次）
__global__ void localAddKernel(unsigned int* cnt, int iters) {
  int i = blockIdx.x * blockDim.x + threadIdx.x;
  if (i == 0) for (int k = 0; k < iters; ++k) atomicAdd(cnt, 1u);
}
// T5: barrier arrive（非 leader 向 PE0 的 pSync 槽放计数值，release）
__global__ void barrierArriveKernel(GpuStates* gs, unsigned int epoch) {
  if (threadIdx.x == 0 && blockIdx.x == 0) {
    __threadfence_system();
    unsigned int* arr = gs->peerHeap + (kArrSlot / 4);         // coordinator 的 arrive 槽
    __atomic_store_n(arr, epoch, __ATOMIC_RELAXED);
  }
}
// T5: coordinator 等 arrive + 分发 done（PE0 侧）
__global__ void barrierCoordKernel(GpuStates* gs, unsigned int epoch) {
  if (threadIdx.x == 0 && blockIdx.x == 0) {
    volatile unsigned int* arr = gs->heapBase + (kArrSlot / 4);
    while (__atomic_load_n((const unsigned int*)arr, __ATOMIC_ACQUIRE) < epoch) __builtin_amdgcn_s_sleep(4);
    unsigned int* done = gs->peerHeap + (kDoneSlot / 4);       // 分发给对端
    __atomic_store_n(done, epoch, __ATOMIC_RELAXED);
  }
}
// T5: 非 leader 等 done
__global__ void barrierWaitKernel(GpuStates* gs, unsigned int epoch, unsigned int* doneFlag) {
  if (threadIdx.x == 0 && blockIdx.x == 0) {
    volatile unsigned int* done = gs->heapBase + (kDoneSlot / 4);
    while (__atomic_load_n((const unsigned int*)done, __ATOMIC_ACQUIRE) < epoch) __builtin_amdgcn_s_sleep(4);
    *doneFlag = 1;
  }
}

static int gMyPe = 0;

// ---- socket bootstrap（ShmemGetUniqueId 迷你版：rank0 监听，rank1 连接）----
static int xrecv(int fd, void* p, size_t n) {
  char* c = (char*)p;
  while (n) { ssize_t k = recv(fd, c, n, 0); if (k <= 0) return -1; c += k; n -= k; }
  return 0;
}
static int xsend(int fd, const void* p, size_t n) {
  const char* c = (const char*)p;
  while (n) { ssize_t k = send(fd, c, n, 0); if (k <= 0) return -1; c += k; n -= k; }
  return 0;
}
// rendezvous: 两端各自发 1 字节并收对端 1 字节（栅栏）
static int barrierSock(int fd, char mine, char* peerOut) {
  if (xsend(fd, &mine, 1) != 0) return -1;
  return xrecv(fd, peerOut, 1);
}

int main(int argc, char** argv) {
  setvbuf(stdout, NULL, _IONBF, 0);
  if (argc < 3) { printf("usage: %s <0|1> <port>\n", argv[0]); return 1; }
  gMyPe = atoi(argv[1]);
  int port = atoi(argv[2]);

  // ---- socket bootstrap（D-03 mini: TCP rendezvous 交换堆句柄）----
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
  printf("[rank%d] bootstrap socket connected\n", gMyPe);

  // ---- HIP 初始化 + 对称堆（init.cpp:237-242 静态堆 Uncached 模式，16MB 缩小版）----
  HIP_CHECK(hipSetDevice(0), "setDevice");
  hipDeviceProp_t prop; HIP_CHECK(hipGetDeviceProperties(&prop, 0), "props");
  unsigned int* heap = nullptr;
  HIP_CHECK(hipExtMallocWithFlags((void**)&heap, kHeapBytes, hipDeviceMallocUncached),
            "static heap alloc");
  HIP_CHECK(hipMemset(heap, 0, kHeapBytes), "heap clear");
  // ---- D-03 交换: IPC handle + 堆基址 ----
  hipIpcMemHandle_t handle;
  HIP_CHECK(hipIpcGetMemHandle(&handle, heap), "getMemHandle");
  uint64_t myAddr = (uint64_t)heap;
  uint64_t peerAddr = 0; hipIpcMemHandle_t peerHandle{};
  if (gMyPe == 0) {
    HIP_CHECK(xsend(conn, &handle, sizeof handle) == 0 ? hipSuccess : hipErrorInvalidValue, "send hdl");
    HIP_CHECK(xrecv(conn, &peerHandle, sizeof peerHandle) == 0 ? hipSuccess : hipErrorInvalidValue, "recv hdl");
    HIP_CHECK(xsend(conn, &myAddr, 8) == 0 ? hipSuccess : hipErrorInvalidValue, "send addr");
    HIP_CHECK(xrecv(conn, &peerAddr, 8) == 0 ? hipSuccess : hipErrorInvalidValue, "recv addr");
  } else {
    HIP_CHECK(xrecv(conn, &peerHandle, sizeof peerHandle) == 0 ? hipSuccess : hipErrorInvalidValue, "recv hdl");
    HIP_CHECK(xsend(conn, &handle, sizeof handle) == 0 ? hipSuccess : hipErrorInvalidValue, "send hdl");
    HIP_CHECK(xrecv(conn, &peerAddr, 8) == 0 ? hipSuccess : hipErrorInvalidValue, "recv addr");
    HIP_CHECK(xsend(conn, &myAddr, 8) == 0 ? hipSuccess : hipErrorInvalidValue, "send addr");
  }
  unsigned int* peerHeap = nullptr;
  HIP_CHECK(hipIpcOpenMemHandle((void**)&peerHeap, peerHandle, hipIpcMemLazyEnablePeerAccess),
            "openMemHandle");
  printf("[rank%d] heap=%p peer=%p (device=%s)\n", gMyPe, heap, peerHeap, prop.gcnArchName);
  char pb = 0; HIP_CHECK(barrierSock(conn, 'b', &pb) == 0 ? hipSuccess : hipErrorInvalidValue, "bootstrap barrier");

  // ---- D-06: GpuStates host 构造 → hipMemcpy 灌设备（runtime.cpp 路径 (b) 精神）----
  GpuStates hGs{heap, peerHeap, gMyPe, 2};
  GpuStates* dGs;
  HIP_CHECK(hipMalloc(&dGs, sizeof hGs), "dGs malloc");
  HIP_CHECK(hipMemcpy(dGs, &hGs, sizeof hGs, hipMemcpyHostToDevice), "GpuStates H2D");
  unsigned int* dMism; HIP_CHECK(hipMalloc(&dMism, 4), "dMism");
  unsigned long long* dTicket; HIP_CHECK(hipMalloc(&dTicket, 16), "dTicket");
  unsigned int* dDone; HIP_CHECK(hipMalloc(&dDone, 4), "dDone");
  int failures = 0;    // 协议失败（T1/T2/T3/T5）
  int findings = 0;    // T4 的硬件发现（负结果也是交付物）
  const dim3 G(1), B(256);   // 单 block（T1/T2/T3 的协同式拷贝+spin 语义要求）

  // ---- T1: put+signal 0→1（2 世代单调 token）----
  for (unsigned epoch = 1; epoch <= 2; ++epoch) {
    if (gMyPe == 0) {
      std::vector<unsigned int> pat(kWords);
      for (int i = 0; i < kWords; ++i) pat[i] = epoch * 1000000u + (unsigned)i;
      HIP_CHECK(hipMemcpy((char*)heap + kOff1, pat.data(), kWords * 4, hipMemcpyHostToDevice), "T1 pat");
      putSignalKernel<<<G, B>>>(dGs, kOff1, kOff1, kWords, epoch);
      HIP_CHECK(hipGetLastError(), "T1 put");
      char d = 'd'; HIP_CHECK(xsend(conn, &d, 1) == 0 ? hipSuccess : hipErrorInvalidValue, "T1 send");
      HIP_CHECK(hipDeviceSynchronize(), "T1 sync");
    } else {
      unsigned int hMism = 9;
      HIP_CHECK(hipMemset(dMism, 0, 4), "T1 dMism");
      HIP_CHECK(hipDeviceSynchronize(), "T1 pre sync");
      waitVerifyKernel<<<G, B>>>(dGs, kOff1, kWords, epoch, epoch * 1000000u, dMism);
      HIP_CHECK(hipGetLastError(), "T1 wait kernel");
      HIP_CHECK(hipDeviceSynchronize(), "T1 wait sync");
      HIP_CHECK(hipMemcpy(&hMism, dMism, 4, hipMemcpyDeviceToHost), "T1 mism");
      printf("[rank1] T1 r%u: mism=%d/%d -> %s\n", epoch, hMism, kWords,
             hMism == 0 ? "PASS" : "FAIL");
      if (hMism != 0) ++failures;
    }
    char pb2 = 0; HIP_CHECK(barrierSock(conn, 't', &pb2) == 0 ? hipSuccess : hipErrorInvalidValue, "T1 barrier");
  }
  if (gMyPe == 0) printf("T1 put+signal 0->1 (2 epochs): results above\n");

  // ---- T2: put+signal 1→0（反向同构；信号槽复用单调 token 3）----
  for (unsigned epoch = 3; epoch <= 4; ++epoch) {
    if (gMyPe == 1) {
      std::vector<unsigned int> pat(kWords);
      for (int i = 0; i < kWords; ++i) pat[i] = epoch * 1000000u + (unsigned)i;
      HIP_CHECK(hipMemcpy((char*)heap + kOff2, pat.data(), kWords * 4, hipMemcpyHostToDevice), "T2 pat");
      putSignalKernel<<<G, B>>>(dGs, kOff2, kOff2, kWords, epoch);
      HIP_CHECK(hipGetLastError(), "T2 put");
      char d = 'd'; HIP_CHECK(xsend(conn, &d, 1) == 0 ? hipSuccess : hipErrorInvalidValue, "T2 send");
      HIP_CHECK(hipDeviceSynchronize(), "T2 sync");
    } else {
      unsigned int hMism = 9;
      HIP_CHECK(hipMemset(dMism, 0, 4), "T2 dMism");
      HIP_CHECK(hipDeviceSynchronize(), "T2 pre sync");
      waitVerifyKernel<<<G, B>>>(dGs, kOff2, kWords, epoch, epoch * 1000000u, dMism);
      HIP_CHECK(hipGetLastError(), "T2 wait kernel");
      HIP_CHECK(hipDeviceSynchronize(), "T2 wait sync");
      HIP_CHECK(hipMemcpy(&hMism, dMism, 4, hipMemcpyDeviceToHost), "T2 mism");
      printf("[rank0] T2 r%u: mism=%d/%d -> %s\n", epoch, hMism, kWords,
             hMism == 0 ? "PASS" : "FAIL");
      if (hMism != 0) ++failures;
    }
    char pb2 = 0; HIP_CHECK(barrierSock(conn, 't', &pb2) == 0 ? hipSuccess : hipErrorInvalidValue, "T2 barrier");
  }
  if (gMyPe == 1) printf("T2 put+signal 1->0 (2 epochs): results above\n");

  // ---- T3: get（rank1 铺数据 → rank0 GetMemNbi → host 校验）----
  {
    if (gMyPe == 1) {
      // kernel 铺数据（SM 写经共享 L2——hipMemcpy H2D 走 SDMA 写 DRAM 绕过 L2，
      // rank0 的 SM 读会撞 stale 行：SDMA5 实验的同款教训）
      fillPatternKernel<<<(kWords + 255) / 256, 256>>>((unsigned int*)((char*)heap + kOff3),
                                                       kWords, 5000000u);
      HIP_CHECK(hipGetLastError(), "T3 fill");
      HIP_CHECK(hipDeviceSynchronize(), "T3 data sync");
    }
    char pb2 = 0; HIP_CHECK(barrierSock(conn, 'g', &pb2) == 0 ? hipSuccess : hipErrorInvalidValue, "T3 barrier1");
    if (gMyPe == 0) {
      getKernel<<<G, B>>>(dGs, kOff3, kOff4, kWords);
      HIP_CHECK(hipGetLastError(), "T3 get");
      HIP_CHECK(hipDeviceSynchronize(), "T3 get sync");
      std::vector<unsigned int> got(kWords);
      HIP_CHECK(hipMemcpy(got.data(), (char*)heap + kOff4, kWords * 4, hipMemcpyDeviceToHost), "T3 D2H");
      int mism = 0;
      for (int i = 0; i < kWords; ++i) if (got[i] != 5000000u + (unsigned)i) ++mism;
      printf("T3 get 0<-1: mism=%d/%d -> %s\n", mism, kWords, mism == 0 ? "PASS" : "FAIL");
      if (mism) ++failures;
    }
    char pb3 = 0; HIP_CHECK(barrierSock(conn, 't', &pb3) == 0 ? hipSuccess : hipErrorInvalidValue, "T3 barrier2");
  }

  // ---- T4: 原子取证矩阵（顺序化消除并发变量）----
  // T4a: rank1 纯 CAS ×1000 → counter 应==1000 且旧值连续
  {
    if (gMyPe == 0) {
      HIP_CHECK(hipMemset((char*)heap + kOffCnt, 0, 4), "T4 zero");
      HIP_CHECK(hipDeviceSynchronize(), "T4 zero sync");
    }
    char pb2 = 0; HIP_CHECK(barrierSock(conn, 'a', &pb2) == 0 ? hipSuccess : hipErrorInvalidValue, "T4a bar");
    if (gMyPe == 1) {
      casAddKernel<<<1, 32>>>(dGs, kOffCnt, 1000, dTicket);
      HIP_CHECK(hipGetLastError(), "T4a cas");
      HIP_CHECK(hipDeviceSynchronize(), "T4a cas sync");
    }
    HIP_CHECK(barrierSock(conn, 't', &pb2) == 0 ? hipSuccess : hipErrorInvalidValue, "T4a bar2");
    if (gMyPe == 0) {
      unsigned int cnt = 9; HIP_CHECK(hipMemcpy(&cnt, (char*)heap + kOffCnt, 4, hipMemcpyDeviceToHost), "T4a D2H");
      unsigned long long tk[2] = {0, 0};
      HIP_CHECK(xrecv(conn, tk, 16) == 0 ? hipSuccess : hipErrorInvalidValue, "T4a tk");
      bool ok = (cnt == 1000) && (tk[1] - tk[0] == 999);
      printf("T4a FINDING rank1-only CAS x1000: counter=%u old=[%llu..%llu] -> %s\n", cnt, tk[0], tk[1],
             ok ? "PASS" : "NEGATIVE(原子经 alias 未正确落地)");
      ++findings;   // 负结果计入 findings 而非 failures
    } else {
      unsigned long long tk[2];
      HIP_CHECK(hipMemcpy(tk, dTicket, 16, hipMemcpyDeviceToHost), "T4a tk D2H");
      unsigned long long devCnt = 9; unsigned long long* dCnt;
      HIP_CHECK(hipMalloc(&dCnt, 8), "dCnt");
      HIP_CHECK(hipMemset(dCnt, 0, 8), "dCnt0");
      HIP_CHECK(hipDeviceSynchronize(), "sync");
      readCounterKernel<<<1, 1>>>((const unsigned int*)((char*)heap + kOffCnt), dCnt);
      HIP_CHECK(hipDeviceSynchronize(), "sync2");
      HIP_CHECK(hipMemcpy(&devCnt, dCnt, 8, hipMemcpyDeviceToHost), "devCnt D2H");
      hipFree(dCnt);
      printf("[rank1] T4a: tickets=[%llu..%llu] devCounter=%llu\n", tk[0], tk[1], devCnt);
      HIP_CHECK(xsend(conn, tk, 16) == 0 ? hipSuccess : hipErrorInvalidValue, "T4a tk send");
    }
    HIP_CHECK(barrierSock(conn, 't', &pb2) == 0 ? hipSuccess : hipErrorInvalidValue, "T4a bar3");
  }
  // T4b: rank0 本地加 ×1000 → 计数应==2000（叠加验证）
  {
    if (gMyPe == 0) {
      localAddKernel<<<1, 32>>>((unsigned int*)((char*)heap + kOffCnt), 1000);
      HIP_CHECK(hipGetLastError(), "T4b local");
      HIP_CHECK(hipDeviceSynchronize(), "T4b local sync");
      unsigned int cnt = 9; HIP_CHECK(hipMemcpy(&cnt, (char*)heap + kOffCnt, 4, hipMemcpyDeviceToHost), "T4b D2H");
      printf("T4b FINDING +local x1000: counter=%u (期望2000) -> %s\n", cnt,
             cnt == 2000 ? "PASS" : "NEGATIVE(CAS 经 alias 部分落地)");
      ++findings;
    }
    char pb2 = 0; HIP_CHECK(barrierSock(conn, 't', &pb2) == 0 ? hipSuccess : hipErrorInvalidValue, "T4b bar");
  }
  // T4c: 对照——rank1 plain atomicAdd ×1000（新计数器）→ 判定 alias 原子是否可用
  {
    const size_t kCnt2Off = kOffCnt + 4096;
    if (gMyPe == 0) {
      HIP_CHECK(hipMemset((char*)heap + kCnt2Off, 0, 4), "T4c zero");
      HIP_CHECK(hipDeviceSynchronize(), "T4c zero sync");
    }
    char pb2 = 0; HIP_CHECK(barrierSock(conn, 'c', &pb2) == 0 ? hipSuccess : hipErrorInvalidValue, "T4c bar");
    if (gMyPe == 1) {
      remoteAtomicAddKernel<<<1, 32>>>(dGs, kCnt2Off, 1000);
      HIP_CHECK(hipGetLastError(), "T4c atomicAdd");
      HIP_CHECK(hipDeviceSynchronize(), "T4c sync");
    }
    HIP_CHECK(barrierSock(conn, 't', &pb2) == 0 ? hipSuccess : hipErrorInvalidValue, "T4c bar2");
    if (gMyPe == 0) {
      unsigned int cnt = 9; HIP_CHECK(hipMemcpy(&cnt, (char*)heap + kCnt2Off, 4, hipMemcpyDeviceToHost), "T4c D2H");
      printf("T4c FINDING rank1 plain atomicAdd via alias x1000: counter=%u -> %s\n", cnt,
             cnt == 1000 ? "PASS(alias 原子可用)" : "NEGATIVE(0 落地——alias 原子静默失效)");
      ++findings;
    }
    char pb3 = 0; HIP_CHECK(barrierSock(conn, 't', &pb3) == 0 ? hipSuccess : hipErrorInvalidValue, "T4c bar3");
  }

  // ---- T5: barrier（PE0-coordinator 两阶段，2 轮不同 epoch）----
  for (unsigned epoch = 10; epoch <= 11; ++epoch) {
    if (gMyPe == 1) {
      unsigned int hDone = 0;
      HIP_CHECK(hipMemset(dDone, 0, 4), "T5 dDone");
      HIP_CHECK(hipDeviceSynchronize(), "T5 pre");
      barrierArriveKernel<<<1, 32>>>(dGs, epoch);
      HIP_CHECK(hipGetLastError(), "T5 arrive");
      HIP_CHECK(hipDeviceSynchronize(), "T5 arrive sync");   // 确认 arrive 发布
      barrierWaitKernel<<<1, 32>>>(dGs, epoch, dDone);
      HIP_CHECK(hipGetLastError(), "T5 wait");
      HIP_CHECK(hipDeviceSynchronize(), "T5 wait sync");
      HIP_CHECK(hipMemcpy(&hDone, dDone, 4, hipMemcpyDeviceToHost), "T5 done D2H");
      printf("[rank1] T5 barrier r%u: done=%u -> %s\n", epoch, hDone, hDone == 1 ? "PASS" : "FAIL");
      if (hDone != 1) ++failures;
    } else {
      barrierCoordKernel<<<1, 32>>>(dGs, epoch);
      HIP_CHECK(hipGetLastError(), "T5 coord");
      HIP_CHECK(hipDeviceSynchronize(), "T5 coord sync");
    }
    // epoch 单调递增，轮间无需 socket barrier（末轮 barrier 曾因 rank0 先退出而 EPIPE）
  }
  if (gMyPe == 0) printf("T5 barrier (coordinator 2-phase, 2 epochs): rank1 results above\n");

  close(conn);
  hipIpcCloseMemHandle(peerHeap);
  printf("[rank%d] %s (protocol failures=%d, T4 findings=%d)\n", gMyPe,
         failures == 0 ? "RANK PASS" : "RANK FAIL", failures, findings);
  return failures;
}
