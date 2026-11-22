// vmm_flat_va_probe.cpp — CCO LSA 的物理层前提探测（HIP 7.16 API 形态）
//
// 上游出处: ROCm/mori @ c5bdc391, src/cco/cco_init.cpp
//   - :726-744  hipMemAddressReserve(lsaSize*perRank) flat VA
//   - :826-963  ccoMemAlloc: hipMemCreate/hipMemMap/hipMemSetAccess
//   - :1373-1420 window 互映射: fabric handle / dma-buf FD（SCM_RIGHTS 回退）
//   本机 HIP 7.16 的 handle 枚举 = hipMemHandleTypePosixFileDescriptor / Fabric
//   （无 "Generic" 名——版本差异实证；mori 有 ROCm 版本分支）。
//   fork 场景 POSIX FD 直接继承，子进程无需 SCM_RIGHTS 传递。
//
// 探测层：
//   P1 平坦 VA 多槽位 reserve
//   P2 物理块 create(FD 可导出) + map 到槽位 + setAccess
//   P3 flat VA 槽位写读回（槽位语义）
//   P4 fork 子进程继承 FD → 映射同一物理块到自己的槽位 → 读 parent 写的数据
//      （LSA 互映射的物理前提）
// 验证等级目标: HARDWARE_PASS(probe)
#include <hip/hip_runtime.h>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cstdint>
#include <unistd.h>
#include <sys/wait.h>

static const size_t kSlot = 2ULL * 1024 * 1024 * 1024;   // 2GB/槽

static int runChild(hipMemGenericAllocationHandle_t h, void* childSlot) {
  setvbuf(stdout, NULL, _IONBF, 0);
  hipDeviceProp_t prop; hipGetDeviceProperties(&prop, 0);
  printf("[child] device=%s\n", prop.gcnArchName);
  hipError_t e = hipMemMap(childSlot, kSlot, 0, h, 0);
  if (e != hipSuccess) { printf("[child] P4 hipMemMap FAILED: %s\n", hipGetErrorString(e)); return 1; }
  hipMemAccessDesc desc;
  desc.location.type = hipMemLocationTypeDevice; desc.location.id = 0;
  desc.flags = hipMemAccessFlagsProtReadWrite;
  e = hipMemSetAccess(childSlot, kSlot, &desc, 1);
  if (e != hipSuccess) { printf("[child] P4 hipMemSetAccess FAILED: %s\n", hipGetErrorString(e)); return 1; }
  uint64_t rbuf[64], want[64];
  e = hipMemcpy(rbuf, childSlot, sizeof rbuf, hipMemcpyDeviceToHost);
  if (e != hipSuccess) { printf("[child] P4 D2H FAILED: %s\n", hipGetErrorString(e)); return 1; }
  int mism = 0;
  for (int i = 0; i < 64; ++i) want[i] = 0xDEADBEEFCAFE0000ull + (uint64_t)i;
  for (int i = 0; i < 64; ++i)
    if (rbuf[i] != want[i]) ++mism;
  printf("[child] P4 cross-process VMM read: mismatch=%d/64 -> %s\n", mism,
         mism == 0 ? "PASS（LSA 互映射物理前提成立）" : "FAIL");
  hipMemUnmap(childSlot, kSlot);
  return (mism == 0) ? 0 : 1;
}

int main() {
  setvbuf(stdout, NULL, _IONBF, 0);
  hipDeviceProp_t prop; hipGetDeviceProperties(&prop, 0);
  printf("device=%s warpSize=%d\n", prop.gcnArchName, prop.warpSize);
  int fail = 0;
  void* flat = nullptr;
  hipMemGenericAllocationHandle_t h1 = {};
  hipError_t e;

  // P1
  e = hipMemAddressReserve(&flat, kSlot * 2, kSlot, 0, 0);
  if (e != hipSuccess) { printf("P1 hipMemAddressReserve FAILED: %s\n", hipGetErrorString(e));
    printf("PROBE RESULT: P1 failed（平坦 VA 不可用——LSA 线在此环境不可行）\n"); return 1; }
  printf("P1 flat VA reserved: base=%p span=4GB (2x2GB slots)\n", flat);

  // P2
  hipMemAllocationProp ap = {};
  ap.type = hipMemAllocationTypePinned;
  ap.location.type = hipMemLocationTypeDevice; ap.location.id = 0;
  ap.requestedHandleType = hipMemHandleTypePosixFileDescriptor;
  ap.allocFlags.gpuDirectRDMACapable = 0;
  e = hipMemCreate(&h1, kSlot, &ap, 0);
  if (e != hipSuccess) { printf("P2 hipMemCreate FAILED: %s\n", hipGetErrorString(e)); return 1; }
  e = hipMemMap(flat, kSlot, 0, h1, 0);
  if (e != hipSuccess) { printf("P2 hipMemMap FAILED: %s\n", hipGetErrorString(e)); return 1; }
  hipMemAccessDesc desc;
  desc.location.type = hipMemLocationTypeDevice; desc.location.id = 0;
  desc.flags = hipMemAccessFlagsProtReadWrite;
  e = hipMemSetAccess(flat, kSlot, &desc, 1);
  if (e != hipSuccess) { printf("P2 hipMemSetAccess FAILED: %s\n", hipGetErrorString(e)); return 1; }
  printf("P2 create+map+setAccess: SUCCESS\n");

  // P3: 槽位写读回 —— 必须走设备路径（hipMemcpy）；host 直接写 VMM 页 = SEGV（实测教训，
  //      mori cco 全部经 kernel/memcpy 访问 LSA 槽位，从不裸指针写）
  {
    uint64_t hbuf[64], rbuf[64];
    for (int i = 0; i < 64; ++i) hbuf[i] = 0xDEADBEEFCAFE0000ull + (uint64_t)i;
    e = hipMemcpy(flat, hbuf, sizeof hbuf, hipMemcpyHostToDevice);
    if (e != hipSuccess) { printf("P3 H2D FAILED: %s\n", hipGetErrorString(e)); return 1; }
    e = hipMemcpy(rbuf, flat, sizeof rbuf, hipMemcpyDeviceToHost);
    if (e != hipSuccess) { printf("P3 D2H FAILED: %s\n", hipGetErrorString(e)); return 1; }
    int m = memcmp(hbuf, rbuf, sizeof hbuf);
    printf("P3 flat-VA slot roundtrip via device path: %s\n", m == 0 ? "PASS" : "FAIL");
    if (m) ++fail;
  }

  // P4: 导出 POSIX FD handle → fork（fd 直接继承）→ 子进程映射自己槽位
  hipMemGenericAllocationHandle_t shared = {};
  e = hipMemExportToShareableHandle(&shared, h1, hipMemHandleTypePosixFileDescriptor, 0);
  if (e != hipSuccess) {
    printf("P4 export FD handle FAILED: %s（LSA 互映射在本机不可用——实测结论）\n",
           hipGetErrorString(e));
    ++fail;
  } else {
    printf("P4 exported FD handle=%d\n", (int)(intptr_t)shared);
    void* childSlot = (void*)((uintptr_t)flat + kSlot);
    pid_t pid = fork();
    if (pid == 0) { int r = runChild(shared, childSlot); fflush(stdout); _exit(r); }
    int st = 0; waitpid(pid, &st, 0);
    int rc = WEXITSTATUS(st);
    printf("P4 child rc=%d -> %s\n", rc, rc == 0 ? "PASS" : "FAIL");
    if (rc != 0) ++fail;
  }

  hipMemUnmap(flat, kSlot);
  hipMemRelease(h1);
  hipMemAddressFree(flat, kSlot * 2);
  printf("PROBE RESULT: %s (%d failed layer)\n", fail == 0 ? "ALL PASS" : "PARTIAL/FAIL", fail);
  return fail;
}
