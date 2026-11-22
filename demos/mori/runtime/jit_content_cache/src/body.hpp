// body.hpp — ② kernel body：只被 Render() 生成的 device TU include
// （mori 对应物 ep_intranode_kernel.hpp：__device__ body，模板参数为 structural NTTP Cfg）
#ifndef MORI_LAB_DEMO5_BODY_HPP
#define MORI_LAB_DEMO5_BODY_HPP
#include "cfg.hpp"

template <RedCfg kCfg>
__device__ void ReductionBody(const float* __restrict__ in, float* __restrict__ out, int n) {
  __shared__ float warpSum[16];
  const int tid = threadIdx.x;
  const int lane = tid % kWaveSize;
  const int warp = tid / kWaveSize;
  float acc = 0.f;
  for (int i = blockIdx.x * BlockThreads(kCfg) + tid; i < n;
       i += (int)gridDim.x * BlockThreads(kCfg))
    acc += in[i];
  #pragma unroll
  for (int off = kWaveSize / 2; off > 0; off >>= 1)
    acc += __shfl_down(acc, off, kWaveSize);
  if (lane == 0) warpSum[warp] = acc;
  __syncthreads();
  if (warp == 0 && lane < kCfg.warpPerBlock) {
    float v = warpSum[lane];
    #pragma unroll
    for (int off = kWaveSize / 2; off > 0; off >>= 1)
      v += __shfl_down(v, off, kWaveSize);
    // grid 无同步原语可跨 block 读他人 scratch —— 用原子累加（正确且与顺序无关：
    // 输入全是 0.25 的倍数且中间和 < 2^24，浮点加法逐位精确）
    if (lane == 0) atomicAdd(out, v);
  }
}
#endif
