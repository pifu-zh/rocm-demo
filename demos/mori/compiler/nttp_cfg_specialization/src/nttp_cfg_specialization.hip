// Demo: structural NTTP 配置特化 —— mori JIT v2 的编译期特化机制（B-05）
//
// 上游出处: ROCm/mori @ c5bdc391
//   - include/mori/ops/dispatch_combine_v2/ep_cfg.hpp: EpCfg 是 structural type，
//     **整个 struct 值**作为非类型模板参数传入 kernel body（C++20）：
//         template <EpCfg kCfg, typename T> __device__ void Body(EpArgs);
//     kernel 内所有开关都是 `if constexpr (kCfg.xxx)`，不是 `#if`。
//     （docs/MORI_JIT_V2_DESIGN.md §3.1：#if 条件来自命令行 -D，带外、不进缓存 key；
//       if constexpr 条件来自 Cfg 字段——进 key、有类型、有守护。）
//   - src/ops/dispatch_combine_v2/ep_spec.cpp:197-289: RenderSource 生成完整 TU，
//     `constexpr EpCfg kCfg = EpCfg{.hiddenDim=...}` + extern "C" 入口 + 描述性 EntryName。
//
// 本 demo 复刻这一机制的最小形态：一个向量化拷贝 kernel，
//   struct CopyCfg { int vecBytes; int unroll; bool nontemporal; };
//   template <CopyCfg kCfg> __global__ void copy_kernel(...)
// 不同 Cfg 值 → 不同实例化 → **可观察的 ISA 差异**（向量宽度/NT 提示/展开次数），
// 并与"运行时 if 分支"的同一逻辑对照，量化两条路的产物与耗时。
//
// 验证等级目标: HARDWARE_PASS（正确性实跑） + STATIC_ANALYSIS_PASS（ISA 产物对照）

#include <hip/hip_runtime.h>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>

#define HIP_CHECK(x) do { hipError_t e_=(x); if(e_!=hipSuccess){ \
  printf("HIP ERROR %s @%s:%d\n", hipGetErrorString(e_), __FILE__, __LINE__); exit(1);} } while(0)

// ---- mori 式 structural Cfg（C++20 NTTP）----
struct CopyCfg {
  int  vecBytes;
  int  unroll;
  bool nontemporal;
};
constexpr bool operator==(const CopyCfg& a, const CopyCfg& b) {
  return a.vecBytes == b.vecBytes && a.unroll == b.unroll && a.nontemporal == b.nontemporal;
}

// 单次向量加载（镜像 mori device_primitives.hpp 的宽度阶梯：
// 16B NT 由两个 8B NT 组成 —— device_primitives.hpp:150-155/216-220）
template <int VB, bool NT>
__device__ __forceinline__ void ld_st(const char* src, char* dst) {
  if constexpr (VB == 16) {
    if constexpr (NT) {
      const __attribute__((__aligned__(8))) unsigned long long* s8 =
          reinterpret_cast<const unsigned long long*>(src);
      __attribute__((__aligned__(8))) unsigned long long* d8 =
          reinterpret_cast<unsigned long long*>(dst);
      unsigned long long a = __builtin_nontemporal_load(s8);
      unsigned long long b = __builtin_nontemporal_load(s8 + 1);
      __builtin_nontemporal_store(a, d8);
      __builtin_nontemporal_store(b, d8 + 1);
    } else {
      uint4 v = *reinterpret_cast<const uint4*>(src);
      *reinterpret_cast<uint4*>(dst) = v;
    }
  } else if constexpr (VB == 8) {
    if constexpr (NT) {
      const unsigned long long* s8 = reinterpret_cast<const unsigned long long*>(src);
      unsigned long long* d8 = reinterpret_cast<unsigned long long*>(dst);
      unsigned long long a = __builtin_nontemporal_load(s8);
      __builtin_nontemporal_store(a, d8);
    } else {
      uint2 v = *reinterpret_cast<const uint2*>(src);
      *reinterpret_cast<uint2*>(dst) = v;
    }
  } else {  // VB == 4
    int v = *reinterpret_cast<const int*>(src);
    *reinterpret_cast<int*>(dst) = v;
  }
}

// NTTP kernel：全部开关 if constexpr，编译期定型
template <CopyCfg kCfg>
__global__ void copy_nttp_kernel(const char* __restrict__ src, char* __restrict__ dst, size_t nbytes) {
  constexpr size_t VB = kCfg.vecBytes;
  const size_t vecs = nbytes / VB;
  size_t i = blockIdx.x * (size_t)blockDim.x + threadIdx.x;
  const size_t stride = (size_t)gridDim.x * blockDim.x;
  // unroll 因子编译期已知 → 主循环按 kCfg.unroll 展开
  for (; i + (kCfg.unroll - 1) * stride < vecs; i += kCfg.unroll * stride) {
    #pragma unroll
    for (int u = 0; u < kCfg.unroll; ++u)
      ld_st<VB, kCfg.nontemporal>(src + (i + u * stride) * VB, dst + (i + u * stride) * VB);
  }
  for (; i < vecs; i += stride)  // 尾部
    ld_st<VB, kCfg.nontemporal>(src + i * VB, dst + i * VB);
  // 字节尾部（vecBytes 对齐余量），逐字节
  for (size_t b = vecs * VB + threadIdx.x; b < nbytes; b += stride)
    dst[b] = src[b];
}

// 运行时对照版：同一逻辑但 vecBytes/unroll/nt 全是运行时值（模拟能用 -D + 运行时 if 的混搭）
__global__ void copy_rt_kernel(const char* __restrict__ src, char* __restrict__ dst,
                               size_t nbytes, int vecBytes, bool nontemporal) {
  const size_t VB = vecBytes;
  const size_t vecs = nbytes / VB;
  size_t i = blockIdx.x * (size_t)blockDim.x + threadIdx.x;
  const size_t stride = (size_t)gridDim.x * blockDim.x;
  for (; i < vecs; i += stride) {
    if (vecBytes == 16) {
      if (nontemporal) ld_st<16, true>(src + i * VB, dst + i * VB);
      else             ld_st<16, false>(src + i * VB, dst + i * VB);
    } else if (vecBytes == 8) {
      if (nontemporal) ld_st<8, true>(src + i * VB, dst + i * VB);
      else             ld_st<8, false>(src + i * VB, dst + i * VB);
    } else {
      ld_st<4, false>(src + i * VB, dst + i * VB);
    }
  }
  for (size_t b = vecs * VB + threadIdx.x; b < nbytes; b += stride)
    dst[b] = src[b];
}

// mori 式入口名：Cfg 自编码（ep_spec.cpp:199-216 的 EntryName 思想）
template <CopyCfg kCfg> constexpr const char* entry_name() {
  return kCfg.nontemporal
      ? (kCfg.vecBytes == 16 ? "copy_v16_nt" : (kCfg.vecBytes == 8 ? "copy_v8_nt" : "copy_v4_nt"))
      : (kCfg.vecBytes == 16 ? "copy_v16" : (kCfg.vecBytes == 8 ? "copy_v8" : "copy_v4"));
}

static void fill(char* p, size_t n, unsigned seed) {
  unsigned x = seed;
  for (size_t i = 0; i < n; ++i) { x = x * 1664525u + 1013904223u; p[i] = (char)(x >> 16); }
}

int main() {
  hipDeviceProp_t prop; HIP_CHECK(hipGetDeviceProperties(&prop, 0));
  printf("device=%s warpSize=%d CU=%d\n", prop.gcnArchName, prop.warpSize, prop.multiProcessorCount);

  // 大小刻意含"非整除"尾巴（12MB + 3,000,003 B），测尾部路径
  const size_t NBYTES = (12u << 20) + 3000003u;
  char *dSrc, *dDst, *dDstRt;
  HIP_CHECK(hipMalloc(&dSrc, NBYTES)); HIP_CHECK(hipMalloc(&dDst, NBYTES)); HIP_CHECK(hipMalloc(&dDstRt, NBYTES));
  std::vector<char> hSrc(NBYTES), hDst(NBYTES);
  fill(hSrc.data(), NBYTES, 7);
  HIP_CHECK(hipMemcpy(dSrc, hSrc.data(), NBYTES, hipMemcpyHostToDevice));

  const int GRID = 40 * 8, BLOCK = 256;  // 40 CU 的整数倍网格
  int failures = 0;

  // 4 个特化实例（RenderSource 会把每个 Cfg 渲染成独立 TU；这里一个 TU 显式实例化等效）
  {
    constexpr CopyCfg c1{16, 4, true};
    constexpr CopyCfg c2{8, 4, true};
    constexpr CopyCfg c3{16, 1, false};
    constexpr CopyCfg c4{4, 2, false};
    copy_nttp_kernel<c1><<<GRID, BLOCK>>>(dSrc, dDst, NBYTES); HIP_CHECK(hipGetLastError());
    copy_nttp_kernel<c2><<<GRID, BLOCK>>>(dSrc, dDst, NBYTES); HIP_CHECK(hipGetLastError());
    copy_nttp_kernel<c3><<<GRID, BLOCK>>>(dSrc, dDst, NBYTES); HIP_CHECK(hipGetLastError());
    copy_nttp_kernel<c4><<<GRID, BLOCK>>>(dSrc, dDst, NBYTES); HIP_CHECK(hipGetLastError());
    HIP_CHECK(hipDeviceSynchronize());
    HIP_CHECK(hipMemcpy(hDst.data(), dDst, NBYTES, hipMemcpyDeviceToHost));
    printf("nttp entry=%s memcmp=%s\n", entry_name<c1>(),
           memcmp(hDst.data(), hSrc.data(), NBYTES) == 0 ? "PASS" : "FAIL");
    if (memcmp(hDst.data(), hSrc.data(), NBYTES) != 0) ++failures;
    // 其余三个特化各来一遍独立校验
    for (int which = 0; which < 3; ++which) {
      HIP_CHECK(hipMemset(dDst, 0, NBYTES));
      if (which == 0) copy_nttp_kernel<c2><<<GRID, BLOCK>>>(dSrc, dDst, NBYTES);
      if (which == 1) copy_nttp_kernel<c3><<<GRID, BLOCK>>>(dSrc, dDst, NBYTES);
      if (which == 2) copy_nttp_kernel<c4><<<GRID, BLOCK>>>(dSrc, dDst, NBYTES);
      HIP_CHECK(hipDeviceSynchronize());
      HIP_CHECK(hipMemcpy(hDst.data(), dDst, NBYTES, hipMemcpyDeviceToHost));
      bool ok = memcmp(hDst.data(), hSrc.data(), NBYTES) == 0;
      printf("nttp entry=%s memcmp=%s\n",
             which == 0 ? entry_name<c2>() : which == 1 ? entry_name<c3>() : entry_name<c4>(),
             ok ? "PASS" : "FAIL");
      if (!ok) ++failures;
    }
  }

  // 运行时版正确性 + 对照计时
  auto bench = [&](bool nttp_v16_nt) {
    hipEvent_t e0, e1; hipEventCreate(&e0); hipEventCreate(&e1);
    const int reps = 20;
    HIP_CHECK(hipEventRecord(e0));
    for (int r = 0; r < reps; ++r) {
      if (nttp_v16_nt) { constexpr CopyCfg c{16, 4, true}; copy_nttp_kernel<c><<<GRID, BLOCK>>>(dSrc, dDst, NBYTES); }
      else copy_rt_kernel<<<GRID, BLOCK>>>(dSrc, dDstRt, NBYTES, 16, true);
    }
    HIP_CHECK(hipEventRecord(e1)); HIP_CHECK(hipEventSynchronize(e1));
    float ms; hipEventElapsedTime(&ms, e0, e1);
    hipEventDestroy(e0); hipEventDestroy(e1);
    return ms / reps;
  };
  copy_rt_kernel<<<GRID, BLOCK>>>(dSrc, dDstRt, NBYTES, 16, true);
  HIP_CHECK(hipDeviceSynchronize());
  std::vector<char> hRt(NBYTES);
  HIP_CHECK(hipMemcpy(hRt.data(), dDstRt, NBYTES, hipMemcpyDeviceToHost));
  bool rtOk = memcmp(hRt.data(), hSrc.data(), NBYTES) == 0;
  printf("rt    entry=copy_rt_v16_nt memcmp=%s\n", rtOk ? "PASS" : "FAIL");
  if (!rtOk) ++failures;

  float tNttp = bench(true), tRt = bench(false);
  double bytes = (double)NBYTES * 2;
  printf("timing(信息性): nttp_v16u4=%.3fms (%.0f GB/s)  rt_v16_nt=%.3fms (%.0f GB/s)\n",
         tNttp, bytes / tNttp / 1e6, tRt, bytes / tRt / 1e6);

  printf("%s\n", failures == 0 ? "ALL PASS" : "HAS FAILURES");
  return failures == 0 ? 0 : 1;
}
