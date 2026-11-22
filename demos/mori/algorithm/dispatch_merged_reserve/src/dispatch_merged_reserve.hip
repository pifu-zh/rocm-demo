// Demo: EPv1 dispatch 的"合并远端原子预留"（merged remote RMW）
//
// 上游出处: ROCm/mori @ c5bdc391, src/ops/dispatch_combine/intranode.hpp
//   EpDispatchIntraNodeKernel_body Phase 2 (:153-161):
//     每个 (block, destPe) 只发**一次**远端 atomicAdd 预留 s_N[p] 个连续槽位，
//     而不是每个 (token, expert) 各发一次 —— 把 O(tokens*topk) 次跨设备 RMW
//     压到 O(blocks * npes) 次。Phase 3 (:163-212) 用 SMEM 里的 base + 本地游标
//     写入各自槽位。
//
// 本 demo 把 "destPe 的远端槽位" 退化为同一 GPU 上 per-peer 的槽位数组
// （多 peer = 多段连续缓冲），协议结构不变：
//   Phase 1: block 内 SMEM 计数（含 mori 式 topk dedup：laneId < k 的 lane
//            发现更早槽位同 dest 则丢弃 —— intranode.hpp:117-150）
//   Phase 2: 每 (block,peer) 一次 atomicAdd(offsets[p], s_N[p]) 预留整段
//   Phase 3: base + 游标写入 (token,k) 记录
// 对照版本：per-pair 原子（naive），每条路由一次 atomicAdd。
//
// 正确性: 与 host 参考实现比较 —— 每 peer 收到的 (token,k) 多重集合完全一致、
//         槽位零重叠零遗漏、offset 终值 == 收到总数。
// 开销:   统计两条路径各自的 atomicAdd 次数（仅插桩用）。
//
// 验证等级目标: HARDWARE_PASS（gfx1030 容器实跑）

#include <hip/hip_runtime.h>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <vector>
#include <set>
#include <map>
#include <numeric>
#include <algorithm>

#define HIP_CHECK(x) do { hipError_t e_=(x); if(e_!=hipSuccess){ \
  printf("HIP ERROR %s @%s:%d\n", hipGetErrorString(e_), __FILE__, __LINE__); exit(1);} } while(0)

constexpr int kNumPeers    = 8;     // npes（模拟对端数）
constexpr int kTopK        = 8;     // numExpertPerToken（mori 默认 8）
constexpr int kMaxTokens   = 65536; // 每次迭代的 token 数
constexpr int kBlockTokens = 512;   // 每 block 处理的 token 数（mori: tokenNumPerBlock）
constexpr int kBlockWarps  = 8;
constexpr int kBlockThreads= kBlockWarps * 64; // mori 假定 wave64 组织；gfx1030 wave32 也成立
constexpr int kIters       = 3;     // 重复 3 个世代（复用 offsets，验证 reset 语义）

struct Route {  // 路由表: 每 token 的 topk 个目的 peer（0..kNumPeers-1）
  int dest[kMaxTokens][kTopK];
};

// ---------------- Naive: 每 (token,k) 一次原子 ----------------
__global__ void DispatchNaiveKernel(const int* __restrict__ route, int* __restrict__ offsets,
                                    int2* __restrict__ lists, /*per-peer 连续槽*/
                                    int numTokens, int slotCap, unsigned long long* statRmw) {
  int tid = blockIdx.x * blockDim.x + threadIdx.x;
  for (int t = tid; t < numTokens; t += gridDim.x * blockDim.x) {
    for (int k = 0; k < kTopK; ++k) {
      int p = route[t * kTopK + k];
      // dedup: 与 mori Phase 1 相同 —— 若更早槽位 j<k 的 dest 相同则跳过
      bool dup = false;
      for (int j = 0; j < k; ++j) if (route[t * kTopK + j] == p) dup = true;
      if (dup) continue;
      int slot = atomicAdd(&offsets[p], 1);          // 每条路由一次远端 RMW
      atomicAdd(statRmw, 1ULL);
      lists[(size_t)p * slotCap + slot] = make_int2(t, k);
    }
  }
}

// ---------------- Merged: mori Phase1/2/3 结构 ----------------
__global__ void DispatchMergedKernel(const int* __restrict__ route, int* __restrict__ offsets,
                                     int2* __restrict__ lists, int numTokens, int slotCap,
                                     unsigned long long* statRmw) {
  __shared__ int sN[kNumPeers];
  __shared__ int sBase[kNumPeers];
  int tidInBlock = threadIdx.x;
  int tokBegin = blockIdx.x * kBlockTokens;
  int tokEnd   = min(tokBegin + kBlockTokens, numTokens);

  // Phase 1: SMEM 计数（mori: block 内每 destPe 计数进 s_N[8], intranode.hpp:117-150）
  if (tidInBlock < kNumPeers) { sN[tidInBlock] = 0; sBase[tidInBlock] = 0; }
  __syncthreads();
  for (int t = tokBegin + tidInBlock; t < tokEnd; t += kBlockThreads) {
    for (int k = 0; k < kTopK; ++k) {
      int p = route[t * kTopK + k];
      bool dup = false;
      for (int j = 0; j < k; ++j) if (route[t * kTopK + j] == p) dup = true;
      if (!dup) atomicAdd(&sN[p], 1);              // SMEM 内竞争，非远端
    }
  }
  __syncthreads();

  // Phase 2: 每 (block,peer) 一次远端原子预留整段（mori intranode.hpp:153-161）
  if (tidInBlock < kNumPeers && sN[tidInBlock] > 0) {
    sBase[tidInBlock] = atomicAdd(&offsets[tidInBlock], sN[tidInBlock]);
    atomicAdd(statRmw, 1ULL);                      // 一次 RMW 覆盖 sN 个槽
  }
  __syncthreads();

  // Phase 3: base + 本地游标写槽（mori :163-212；游标用 SMEM 计数器）
  __shared__ int sCursor[kNumPeers];
  if (tidInBlock < kNumPeers) sCursor[tidInBlock] = 0;
  __syncthreads();
  for (int t = tokBegin + tidInBlock; t < tokEnd; t += kBlockThreads) {
    for (int k = 0; k < kTopK; ++k) {
      int p = route[t * kTopK + k];
      bool dup = false;
      for (int j = 0; j < k; ++j) if (route[t * kTopK + j] == p) dup = true;
      if (dup) continue;
      int slot = sBase[p] + atomicAdd(&sCursor[p], 1);  // SMEM 游标，无远端 RMW
      lists[(size_t)p * slotCap + slot] = make_int2(t, k);
    }
  }
}

// ---------------- Host 参考: 期望的 per-peer 多重集合 ----------------
static std::vector<std::multiset<std::pair<int,int>>> RefRoute(const Route& r, int numTokens) {
  std::vector<std::multiset<std::pair<int,int>>> exp(kNumPeers);
  for (int t = 0; t < numTokens; ++t)
    for (int k = 0; k < kTopK; ++k) {
      int p = r.dest[t][k];
      bool dup = false;
      for (int j = 0; j < k; ++j) if (r.dest[t][j] == p) dup = true;
      if (!dup) exp[p].insert({t, k});
    }
  return exp;
}

int main() {
  hipDeviceProp_t prop; HIP_CHECK(hipGetDeviceProperties(&prop, 0));
  printf("device=%s warpSize=%d CU=%d\n", prop.gcnArchName, prop.warpSize, prop.multiProcessorCount);

  // 固定种子路由
  Route route;
  srand(42);
  for (int t = 0; t < kMaxTokens; ++t)
    for (int k = 0; k < kTopK; ++k) route.dest[t][k] = rand() % kNumPeers;

  const size_t totalPairs = (size_t)kMaxTokens * kTopK;
  const size_t slotCap = (size_t)kMaxTokens;  // 每 peer 槽上限（足够容纳，实测会小得多）
  std::vector<int> hRoute(totalPairs);
  for (int t = 0; t < kMaxTokens; ++t)
    for (int k = 0; k < kTopK; ++k) hRoute[t * kTopK + k] = route.dest[t][k];

  int* dRoute; HIP_CHECK(hipMalloc(&dRoute, totalPairs * 4));
  HIP_CHECK(hipMemcpy(dRoute, hRoute.data(), totalPairs * 4, hipMemcpyHostToDevice));
  int* dOffsets;  HIP_CHECK(hipMalloc(&dOffsets, kNumPeers * 4));
  int2* dLists;   HIP_CHECK(hipMalloc(&dLists, (size_t)kNumPeers * slotCap * sizeof(int2)));
  unsigned long long* dStat; HIP_CHECK(hipMalloc(&dStat, 8));

  const int numBlocks = (kMaxTokens + kBlockTokens - 1) / kBlockTokens;
  auto expected = RefRoute(route, kMaxTokens);
  // merged 路径的精确远端 RMW 次数：每 (block,peer) 恰一次（s_N>0 时）
  long long expMergedRmw = 0;
  for (int b = 0; b < numBlocks; ++b) {
    int cnt[kNumPeers] = {0};
    for (int t = b * kBlockTokens; t < std::min((b + 1) * kBlockTokens, kMaxTokens); ++t)
      for (int k = 0; k < kTopK; ++k) {
        int p = route.dest[t][k];
        bool dup = false;
        for (int j = 0; j < k; ++j) if (route.dest[t][j] == p) dup = true;
        if (!dup) ++cnt[p];
      }
    for (int p = 0; p < kNumPeers; ++p) if (cnt[p] > 0) ++expMergedRmw;
  }

  int failures = 0;
  for (int iter = 0; iter < kIters; ++iter) {
    for (int mode = 0; mode < 2; ++mode) {
      // reset offsets（mori 每世代由 recv 侧清零；这里 host 清零）
      HIP_CHECK(hipMemset(dOffsets, 0, kNumPeers * 4));
      HIP_CHECK(hipMemset(dStat, 0, 8));
      // 清 lists 哨兵 (-1,-1)
      HIP_CHECK(hipMemset(dLists, 0xFF, (size_t)kNumPeers * slotCap * sizeof(int2)));

      if (mode == 0)
        DispatchNaiveKernel<<<dim3(numBlocks), dim3(kBlockThreads), 0, 0>>>(
            dRoute, dOffsets, dLists, kMaxTokens, (int)slotCap, dStat);
      else
        DispatchMergedKernel<<<dim3(numBlocks), dim3(kBlockThreads), 0, 0>>>(
            dRoute, dOffsets, dLists, kMaxTokens, (int)slotCap, dStat);
      HIP_CHECK(hipGetLastError());
      HIP_CHECK(hipDeviceSynchronize());

      // 校验
      std::vector<int> hOff(kNumPeers);
      HIP_CHECK(hipMemcpy(hOff.data(), dOffsets, kNumPeers * 4, hipMemcpyDeviceToHost));
      unsigned long long hStat;
      HIP_CHECK(hipMemcpy(&hStat, dStat, 8, hipMemcpyDeviceToHost));
      long long expTotal = 0;
      for (int p = 0; p < kNumPeers; ++p) expTotal += (long long)expected[p].size();

      // 检查每 peer: 数量一致 + 多重集合一致 + 槽位无重叠（用 set 去重计数）
      bool ok = true;
      size_t written = 0;
      std::vector<int2> hList;
      for (int p = 0; p < kNumPeers; ++p) {
        hList.resize(hOff[p]);
        HIP_CHECK(hipMemcpy(hList.data(), dLists + (size_t)p * slotCap,
                            (size_t)hOff[p] * sizeof(int2), hipMemcpyDeviceToHost));
        std::multiset<std::pair<int,int>> got;
        std::set<int> slots;
        for (int s = 0; s < hOff[p]; ++s) {
          if (hList[s].x == -1 && hList[s].y == -1) { ok = false; }  // 未写槽（洞）
          got.insert({hList[s].x, hList[s].y});
          slots.insert((int)((size_t)p * slotCap + s));
        }
        written += got.size();
        if (!(got == expected[p])) ok = false;
      }
      if (hStat != (mode == 0 ? (unsigned long long)expTotal
                              : (unsigned long long)expMergedRmw)) ok = false;
      const char* name = mode == 0 ? "naive(per-pair atomic)" : "merged(mori Phase2)";
      printf("iter%d %-24s slots_used=%llu expected=%lld rmw=%llu offsets_ok=%s -> %s\n",
             iter, name, written, expTotal, hStat,
             (std::accumulate(hOff.begin(), hOff.end(), 0LL) == expTotal) ? "y" : "N",
             ok ? "PASS" : "FAIL");
      if (!ok) ++failures;
    }
  }

  // 带宽/延迟粗测（信息性，非验收项）
  auto bench = [&](int mode) {
    hipEvent_t e0, e1; hipEventCreate(&e0); hipEventCreate(&e1);
    HIP_CHECK(hipMemset(dOffsets, 0, kNumPeers * 4));
    HIP_CHECK(hipEventRecord(e0));
    if (mode == 0)
      DispatchNaiveKernel<<<dim3(numBlocks), dim3(kBlockThreads)>>>(
          dRoute, dOffsets, dLists, kMaxTokens, (int)slotCap, dStat);
    else
      DispatchMergedKernel<<<dim3(numBlocks), dim3(kBlockThreads)>>>(
          dRoute, dOffsets, dLists, kMaxTokens, (int)slotCap, dStat);
    HIP_CHECK(hipEventRecord(e1)); HIP_CHECK(hipEventSynchronize(e1));
    float ms; hipEventElapsedTime(&ms, e0, e1);
    hipEventDestroy(e0); hipEventDestroy(e1);
    return ms;
  };
  float msN = bench(0), msM = bench(1);
  printf("timing: naive=%.3fms merged=%.3fms (信息性)\n", msN, msM);

  printf("%s\n", failures == 0 ? "ALL PASS" : "HAS FAILURES");
  return failures == 0 ? 0 : 1;
}
