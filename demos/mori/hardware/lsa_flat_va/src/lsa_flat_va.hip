// lsa_flat_va.hip — CCO LSA 完整 demo：平坦 VA 对称窗口 + peer_va 公式寻址 + epoch barrier
// （双进程单 GPU；HIP 各自独立初始化；FD 经 SCM_RIGHTS 传递——mori cco_init.cpp 的 FD 回退路径）
//
// 上游出处: ROCm/mori @ c5bdc391
//   - src/cco/cco_init.cpp:726-744   hipMemAddressReserve(lsaSize*perRank) 平坦 VA 多槽位
//   - include/mori/cco/cco.hpp:288-305,695-701 对等地址公式（本 demo stride=256MB 缩小版）:
//       peer_va = winBase + peerLsaRank * stride + offset
//   - include/mori/cco/cco.hpp:649-816 ccoLsaBarrierSession:
//       arrive = threadFenceSystem 后 RELAXED store(epoch+1) 到对端 inbox
//       wait   = ACQUIRE 轮询自己 inbox + 无符号回绕比较 (got-(epoch+1))<=INT_MAX 免清零
//   - cco_init.cpp:1399-1420 window 互映射的 FD 路径（SCM_RIGHTS）
//
// 拓扑（CCO 对称槽位思想）:
//   parent(rank0): flatVA[槽0=窗口A(自建)] [槽1=窗口B(child 经 FD map)]
//   child (rank1): flatVA[槽0=窗口B(自建)] [槽1=窗口A(parent 经 FD map)]
//   两端以同一公式寻址对端 → LSA put = 对 peer_va 的普通 global store（"地址可计算"，
//   与 SHMEM 的查表寻址本质不同）
//
// 测试: L1 parent→child put（child 侧内核校验）; L2 child→parent put（parent 校验）;
//       L3 epoch barrier 双向 4 轮（回绕比较免清零）
// 验证等级目标: HARDWARE_PASS
#include <hip/hip_runtime.h>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cstdint>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/wait.h>

#define HIP_CHECK(x, msg) do { hipError_t e_=(x); if(e_!=hipSuccess){ \
  printf("HIP ERROR %s @%d (%s %s)\n", hipGetErrorString(e_), __LINE__, #x, msg); return 2;} } while(0)

static const size_t kStride = 256ULL << 20;   // 每槽 256MB（mori perRank 4GB 缩小版）
static const size_t kWin    = 64ULL << 20;    // 窗口 64MB
static const int    kPatWords = 4096;
static const size_t kPatOff  = 4096;          // 模式数据在窗口内的偏移（0 处是 inbox）

// ---- FD 传递（SCM_RIGHTS，mori FD 回退路径的传输机制）----
static int sendFd(int sock, int fd) {
  char dummy = 'F';
  struct iovec iov{ &dummy, 1 };
  union { struct cmsghdr h; char buf[CMSG_SPACE(sizeof(int))]; } u{};
  msghdr msg{};
  msg.msg_iov = &iov; msg.msg_iovlen = 1;
  msg.msg_control = u.buf; msg.msg_controllen = sizeof u.buf;
  cmsghdr* c = CMSG_FIRSTHDR(&msg);
  c->cmsg_level = SOL_SOCKET; c->cmsg_type = SCM_RIGHTS; c->cmsg_len = CMSG_LEN(sizeof(int));
  memcpy(CMSG_DATA(c), &fd, sizeof fd);
  return sendmsg(sock, &msg, 0) >= 0 ? 0 : -1;
}
static int recvFd(int sock) {
  char dummy;
  struct iovec iov{ &dummy, 1 };
  union { struct cmsghdr h; char buf[CMSG_SPACE(sizeof(int))]; } u{};
  msghdr msg{};
  msg.msg_iov = &iov; msg.msg_iovlen = 1;
  msg.msg_control = u.buf; msg.msg_controllen = sizeof u.buf;
  if (recvmsg(sock, &msg, 0) < 0) return -1;
  cmsghdr* c = CMSG_FIRSTHDR(&msg);
  if (!c || c->cmsg_type != SCM_RIGHTS) return -1;
  int fd; memcpy(&fd, CMSG_DATA(c), sizeof fd);
  return fd;
}

// ---- 设备内核 ----
// LSA put: 对 peer_va 的普通 global store（一个公式寻到对端，无查表——CCO 核心）
__global__ void lsaPutKernel(unsigned int* peerVa, const unsigned int* pat, int n) {
  int i = blockIdx.x * blockDim.x + threadIdx.x;
  if (i < n) peerVa[i] = pat[i];
}
// 校验: 比较自己窗口里的数据（含 threadfence 后的可见性）
__global__ void lsaCheckKernel(const unsigned int* myView, int n, unsigned int base,
                               unsigned int* mism) {
  int i = blockIdx.x * blockDim.x + threadIdx.x;
  if (i < n && myView[i] != base + (unsigned)i) atomicAdd(mism, 1);
}
// epoch barrier（cco.hpp:649-816 最小化）: fence→RELAXED arrive→ACQUIRE wait+回绕比较
__global__ void epochBarrierKernel(volatile unsigned int* inboxPeer, volatile unsigned int* inboxMine,
                                   unsigned int epoch) {
  if (threadIdx.x == 0) {
    __threadfence_system();
    __atomic_store_n((unsigned int*)inboxPeer, epoch + 1, __ATOMIC_RELAXED);
    while (true) {
      unsigned int got = __atomic_load_n((unsigned int*)inboxMine, __ATOMIC_ACQUIRE);
      if ((unsigned int)(got - (epoch + 1)) <= 0x7FFFFFFFu) break;   // 回绕比较免清零
      __builtin_amdgcn_s_sleep(4);
    }
  }
}

// ---- 单侧装配（两阶段，防 VMM 并发竞态与 FD 交换死锁）----
// 阶段 1: 各自独立完成 flat VA + 自建块→槽0（两进程经 socket 握手串行执行）
static int setupOwn(void** flatOut, hipMemGenericAllocationHandle_t* hOwn, int* myFdOut) {
  void* flat = nullptr;
  HIP_CHECK(hipMemAddressReserve(&flat, kStride * 2, kStride, 0, 0), "reserve 2x256MB");
  hipMemGenericAllocationHandle_t h;
  hipMemAllocationProp ap = {};
  ap.type = hipMemAllocationTypePinned;
  ap.location.type = hipMemLocationTypeDevice; ap.location.id = 0;
  ap.requestedHandleType = hipMemHandleTypePosixFileDescriptor;
  HIP_CHECK(hipMemCreate(&h, kWin, &ap, 0), "create own block");
  HIP_CHECK(hipMemMap(flat, kWin, 0, h, 0), "map own slot0");
  hipMemAccessDesc desc;
  desc.location.type = hipMemLocationTypeDevice; desc.location.id = 0;
  desc.flags = hipMemAccessFlagsProtReadWrite;
  HIP_CHECK(hipMemSetAccess(flat, kWin, &desc, 1), "setAccess own");
  hipMemGenericAllocationHandle_t myExport;
  HIP_CHECK(hipMemExportToShareableHandle(&myExport, h, hipMemHandleTypePosixFileDescriptor, 0),
            "export own");
  *flatOut = flat; *hOwn = h; *myFdOut = (int)(intptr_t)myExport;
  return 0;
}
// 阶段 2: FD 交换 + 对端块→槽1（child 先发自己的 FD，parent 收到后回发）
static int mapPeer(int sock, bool childSide, void* flat, void** slot1Out) {
  hipMemAccessDesc desc;
  desc.location.type = hipMemLocationTypeDevice; desc.location.id = 0;
  desc.flags = hipMemAccessFlagsProtReadWrite;
  int peerFd = -1;
  if (childSide) {
    // child: 先发自己 FD 再收 parent FD（parent 先收后发，无死锁）
    return -1;  // 占位——child 侧在 runChild 内联处理
  }
  peerFd = recvFd(sock);
  if (peerFd < 0) { printf("recvFd FAIL\n"); return 1; }
  void* slot1 = (void*)((uintptr_t)flat + kStride);
  HIP_CHECK(hipMemMap(slot1, kWin, 0, (hipMemGenericAllocationHandle_t)peerFd, 0), "map peer slot1");
  HIP_CHECK(hipMemSetAccess(slot1, kWin, &desc, 1), "setAccess peer");
  *slot1Out = slot1;
  return 0;
}

static int runChild(int sock) {
  setvbuf(stdout, NULL, _IONBF, 0);
  hipDeviceProp_t prop; HIP_CHECK(hipGetDeviceProperties(&prop, 0), "child props");
  printf("[child] device=%s\n", prop.gcnArchName);
  char rc_; if (recv(sock, &rc_, 1, 0) != 1) return 1;   // 等 parent 完成 VMM 自建装配
  printf("[child] parent ready, starting own setup\n");
  void *flat, *slot1; hipMemGenericAllocationHandle_t hB;
  int myFd = -1;
  if (setupOwn(&flat, &hB, &myFd) != 0) return 1;
  printf("[child] own block ready, exchanging FDs\n");
  // FD 交换: child 先发 → parent 收；parent 回发 → child 收
  if (sendFd(sock, myFd) != 0) { printf("sendFd FAIL\n"); return 1; }
  int peerFd = recvFd(sock);
  if (peerFd < 0) { printf("recvFd FAIL\n"); return 1; }
  // SCM_RIGHTS 收到的 FD 必须经显式 import 才是合法 handle（直接强转会在 hipMemMap 段错误）
  hipMemGenericAllocationHandle_t hPeer;
  HIP_CHECK(hipMemImportFromShareableHandle(&hPeer, (void*)(intptr_t)peerFd,
                                            hipMemHandleTypePosixFileDescriptor), "child import peer FD");
  slot1 = (void*)((uintptr_t)flat + kStride);
  {
    hipMemAccessDesc desc;
    desc.location.type = hipMemLocationTypeDevice; desc.location.id = 0;
    desc.flags = hipMemAccessFlagsProtReadWrite;
    HIP_CHECK(hipMemMap(slot1, kWin, 0, hPeer, 0), "child map peer slot1");
    HIP_CHECK(hipMemSetAccess(slot1, kWin, &desc, 1), "child setAccess peer");
  }
  printf("[child] LSA windows mapped (slot0=own B, slot1=peer A)\n");

  char c;
  // === L1: 等 parent put 后校验自己的窗口（槽 0 = parent 写的 peer_va 目标）===
  if (recv(sock, &c, 1, 0) != 1) return 1;
  {
    unsigned int* dMism; HIP_CHECK(hipMalloc(&dMism, 4), "dMism");
    HIP_CHECK(hipMemset(dMism, 0, 4), "dMism0");
    HIP_CHECK(hipDeviceSynchronize(), "sync");
    lsaCheckKernel<<<(kPatWords + 255) / 256, 256>>>(
        (const unsigned int*)((uintptr_t)flat + kPatOff), kPatWords, 1000000u, dMism);
    HIP_CHECK(hipGetLastError(), "check kernel");
    HIP_CHECK(hipDeviceSynchronize(), "sync2");
    unsigned int mism = 9;
    HIP_CHECK(hipMemcpy(&mism, dMism, 4, hipMemcpyDeviceToHost), "mism D2H");
    hipFree(dMism);
    printf("[child] L1 verify (kernel reads own window): mism=%d/%d -> %s\n", mism, kPatWords,
           mism == 0 ? "PASS" : "FAIL");
    char r = (mism == 0) ? 'P' : 'F';
    if (send(sock, &r, 1, 0) != 1) return 1;
    if (mism != 0) return 1;
  }
  // === L2: child → parent LSA put（peer_va = 槽 1 = parent 的窗口 A）===
  {
    std::vector<unsigned int> pat(kPatWords);
    for (int i = 0; i < kPatWords; ++i) pat[i] = 7000000u + (unsigned)i;
    unsigned int* dPat; HIP_CHECK(hipMalloc(&dPat, kPatWords * 4), "dPat");
    HIP_CHECK(hipMemcpy(dPat, pat.data(), kPatWords * 4, hipMemcpyHostToDevice), "pat H2D");
    unsigned int* peerVa = (unsigned int*)((uintptr_t)slot1 + kPatOff);
    lsaPutKernel<<<(kPatWords + 255) / 256, 256>>>(peerVa, dPat, kPatWords);
    HIP_CHECK(hipGetLastError(), "child put");
    HIP_CHECK(hipDeviceSynchronize(), "child put sync");
    printf("[child] L2 LSA put to peer_va done\n");
    if (send(sock, "D", 1, 0) != 1) return 1;
  }
  // === L3: epoch barrier 双向 4 轮 ===
  if (recv(sock, &c, 1, 0) != 1) return 1;
  volatile unsigned int* myInbox = (volatile unsigned int*)flat;       // 槽 0 头
  volatile unsigned int* peerInbox = (volatile unsigned int*)slot1;    // 槽 1 头
  for (unsigned int ep = 0; ep < 4; ++ep) {
    epochBarrierKernel<<<1, 64>>>(peerInbox, myInbox, ep);
    HIP_CHECK(hipGetLastError(), "child barrier");
    HIP_CHECK(hipDeviceSynchronize(), "child barrier sync");
  }
  printf("[child] L3 epoch barrier x4 done\n");
  if (send(sock, "B", 1, 0) != 1) return 1;
  hipMemUnmap(slot1, kWin); hipMemRelease(hB);
  hipMemUnmap(flat, kWin); hipMemAddressFree(flat, kStride * 2);
  return 0;
}

int main() {
  setvbuf(stdout, NULL, _IONBF, 0);
  int sv[2];
  if (socketpair(AF_UNIX, SOCK_STREAM, 0, sv) != 0) { perror("socketpair"); return 1; }
  // fork 必须先于任何 HIP 调用（fork 进已初始化的 HIP runtime = UB——Demo 6 教训）
  pid_t pid = fork();
  if (pid == 0) { close(sv[0]); int rc = runChild(sv[1]); fflush(stdout); _exit(rc); }
  close(sv[1]);

  hipDeviceProp_t prop; HIP_CHECK(hipGetDeviceProperties(&prop, 0), "props");
  printf("device=%s warpSize=%d\n", prop.gcnArchName, prop.warpSize);
  int failures = 0;

  void *flat, *slot1; hipMemGenericAllocationHandle_t hA;
  int myFd = -1;
  if (setupOwn(&flat, &hA, &myFd) != 0) { printf("parent own setup FAIL\n"); return 1; }
  printf("[parent] own block ready\n");
  if (send(sv[0], "R", 1, 0) != 1) return 1;              // 放行 child 开始 VMM 自建（串行化）
  // FD 交换: 先收 child 的，再回发自己的
  int peerFd = recvFd(sv[0]);
  if (peerFd < 0) { printf("recvFd FAIL\n"); return 1; }
  if (sendFd(sv[0], myFd) != 0) { printf("sendFd FAIL\n"); return 1; }
  hipMemGenericAllocationHandle_t hPeer;
  HIP_CHECK(hipMemImportFromShareableHandle(&hPeer, (void*)(intptr_t)peerFd,
                                            hipMemHandleTypePosixFileDescriptor), "parent import peer FD");
  slot1 = (void*)((uintptr_t)flat + kStride);
  {
    hipMemAccessDesc desc;
    desc.location.type = hipMemLocationTypeDevice; desc.location.id = 0;
    desc.flags = hipMemAccessFlagsProtReadWrite;
    HIP_CHECK(hipMemMap(slot1, kWin, 0, hPeer, 0), "parent map peer slot1");
    HIP_CHECK(hipMemSetAccess(slot1, kWin, &desc, 1), "parent setAccess peer");
  }
  printf("[parent] LSA windows mapped (slot0=own A, slot1=peer B)\n");

  // === L1: parent → child LSA put（peer_va = 槽 1 = child 的窗口 B）===
  {
    std::vector<unsigned int> pat(kPatWords);
    for (int i = 0; i < kPatWords; ++i) pat[i] = 1000000u + (unsigned)i;
    unsigned int* dPat; HIP_CHECK(hipMalloc(&dPat, kPatWords * 4), "dPat");
    HIP_CHECK(hipMemcpy(dPat, pat.data(), kPatWords * 4, hipMemcpyHostToDevice), "pat H2D");
    unsigned int* peerVa = (unsigned int*)((uintptr_t)slot1 + kPatOff);
    lsaPutKernel<<<(kPatWords + 255) / 256, 256>>>(peerVa, dPat, kPatWords);
    HIP_CHECK(hipGetLastError(), "parent put");
    HIP_CHECK(hipDeviceSynchronize(), "parent put sync");
    printf("[parent] L1 LSA put to peer_va done\n");
    if (send(sv[0], "G", 1, 0) != 1) return 1;
    char r = 'F'; if (recv(sv[0], &r, 1, 0) != 1) return 1;
    printf("[parent] L1 child-side verify: %s\n", r == 'P' ? "PASS" : "FAIL");
    if (r != 'P') ++failures;
  }
  // === L2 校验: child 写到了 parent 的窗口 A（槽 0）===
  {
    char c; if (recv(sv[0], &c, 1, 0) != 1) return 1;
    unsigned int* dMism; HIP_CHECK(hipMalloc(&dMism, 4), "dMism");
    HIP_CHECK(hipMemset(dMism, 0, 4), "dMism0");
    HIP_CHECK(hipDeviceSynchronize(), "sync");
    lsaCheckKernel<<<(kPatWords + 255) / 256, 256>>>(
        (const unsigned int*)((uintptr_t)flat + kPatOff), kPatWords, 7000000u, dMism);
    HIP_CHECK(hipGetLastError(), "check kernel");
    HIP_CHECK(hipDeviceSynchronize(), "sync2");
    unsigned int mism = 9;
    HIP_CHECK(hipMemcpy(&mism, dMism, 4, hipMemcpyDeviceToHost), "mism D2H");
    hipFree(dMism);
    printf("[parent] L2 verify (kernel reads own window): mism=%d/%d -> %s\n", mism, kPatWords,
           mism == 0 ? "PASS" : "FAIL");
    if (mism != 0) ++failures;
  }
  // === L3: epoch barrier 双向 4 轮（两进程并发 rendezvous）===
  if (send(sv[0], "G", 1, 0) != 1) return 1;
  volatile unsigned int* myInbox = (volatile unsigned int*)flat;
  volatile unsigned int* peerInbox = (volatile unsigned int*)slot1;
  for (unsigned int ep = 0; ep < 4; ++ep) {
    epochBarrierKernel<<<1, 64>>>(peerInbox, myInbox, ep);
    HIP_CHECK(hipGetLastError(), "parent barrier");
    HIP_CHECK(hipDeviceSynchronize(), "parent barrier sync");
  }
  char b = 'F'; if (recv(sv[0], &b, 1, 0) != 1) return 1;
  printf("[parent] L3 epoch barrier x4 (both sides rendezvous): %s\n", b == 'B' ? "PASS" : "FAIL");
  if (b != 'B') ++failures;

  int stt = 0; waitpid(pid, &stt, 0);
  int childRc = WEXITSTATUS(stt);
  printf("child_rc=%d -> %s\n", childRc,
         (failures == 0 && childRc == 0) ? "ALL PASS" : "HAS FAILURES");
  hipMemUnmap(slot1, kWin); hipMemRelease(hA);
  hipMemUnmap(flat, kWin); hipMemAddressFree(flat, kStride * 2);
  return (failures == 0 && childRc == 0) ? 0 : 1;
}
