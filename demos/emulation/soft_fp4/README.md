# demo: soft_fp4 — MXFP4（E2M1+UE8M0）软编解码 + 组 scale 点积（gfx1030）

## 验证等级

**HARDWARE_PASS + PERFORMANCE_MEASURED**（gfx1030 / RX 6950 XT，ROCm 7.2.4，2026-11-13）
穷举（解码 512 + 往返 256 + 编码 sweep 108 + e8m0 256×2）0 失败；MXFP4 点积界内；转换流吞吐已测。

## 原理

MXFP4 = E2M1 数据 nibble + 每 32 元素 UE8M0 幂二 scale。gfx1030 无 fp4 转换硬件。
**SF（scale folding）结构**：组 scale 在组内 f32 FFMA 和之外相乘
`C[m,n] = Σ_g SFA[m,g]·SB[g,n]·(Σ_{k∈g} decA·decB)`——热循环是纯解码 nibble 数学，
每个组一次 scale 乘法（aiter/DeepGEMM 量化 GEMM 的核心结构）。

## 上游出处

- E2M1 编解码契约：cuda-oxide `crates/cuda-device/src/fp8.rs:78-87,207-245,271-326`
  （CUDA `__nv_fp4x2_e2m1` 语义，lane 0 低 nibble）；aiter 侧软路径
  `csrc/kernels/quant_mxfp4.cu:45-79`（scalar even_round_e2m1，非 gfx950 回退）。
- e8m0 ceil/RoundUp 契约：aiter `csrc/include/quant_amax_floor.h` + 本 lab
  `core/hadamard_quant` 的 `ceil_pow2_e8m0`。
- SF 折叠：aiter `csrc/kernels/quant_mxfp4_gemm.cu` / DeepGEMM 路线（[hist] 3.05 TFLOPS）。
- 谱系：`docs/EMULATION_CATALOG.md` E2。

## 独立实现（依赖声明）

`include/soft_fp4.hpp`：UE8M0 编解码（**新增件**，cuda-oxide 缺失项：ceil/RoundUp
契约 + 0xFF NaN 槽 + **f32 subnormal 输入特判**——2^-127 是幂二但 f32 位域
mantissa≠0，通用 ++e 规则会错位到 2^-126）+ MXFP4 组 scale 点积 kernel +
转换流 kernel。E2M1 编解码**复用** `demos/emulation/soft_fp8/include/soft_fp8.hpp`
（include 路径在脚本设置；依赖记录于 docs/DEPENDENCY_GRAPH.md）。

## Hardware Matrix

| 架构 | 状态 |
|---|---|
| gfx1030 | ✅ 本 demo（真机穷举 + 点积 + 吞吐） |
| gfx942 | 无 fp4 硬件；软件路径同构可用，未验证 |
| gfx950/1250 | 有 packed fp4 cvt（aiter 路径）+ MFMA/WMMA fp4（32x32x64/16x16x128）；软件路径冗余 |
| 通用 | E2M1/E8M0 位操作无架构依赖 |

## Build & Run

```bash
hipcc -x hip --offload-arch=gfx1030 -O3 src/main.hip -I include -I ../soft_fp8/include -o soft_fp4_demo
./soft_fp4_demo
```

## Results（2026-11-13，容器 gfx-m1）

| 检查族 | 项数 | 结果 |
|---|---|---|
| E2M1 标量解码 16 + packed 512 | 528 | PASS |
| E2M1 packed 往返 256 | 256 | PASS |
| E2M1 编码 sweep（RNE ties/satfinite/NaN） | 108 | PASS |
| UE8M0 解码 256 + 往返 256（ceil 契约） | 512 | PASS |
| MXFP4 组 scale 点积 32×64×128（4 组） | 2048 | PASS（界内 0.000） |

吞吐（64 Mi pairs）：decode_e2m1x2 **482.7 GB/s**、quantize **545.0 GB/s**
（9 B/pair 口径：8 B f32 侧 + 1 B fp4 侧）——与 soft_fp8 同结论：软转换完全
隐藏在内存带宽之后（完美替代档）。

## 开发中抓到的 bug

1. **UE8M0 解码 byte=0**（2^-127 = f32 subnormal）：指数域组装会 flush 到 0 →
   特判 0x00400000 位型。
2. **UE8M0 ceil 对 f32 subnormal 输入**：2^-127 幂二但 subnormal 表示的
   mantissa≠0，通用 "mantissa≠0 → ++e" 规则错位到 2^-126 → 特判：subnormal
   输入按最高位 + ceil 重新映射（双侧同步修）。
3. 值得记录：aiter 的 ceil_pow2 契约里 **byte 0 覆盖 [0, 2^-126) 的全部
   underflow 值**（含 0），与 OCP 的 NaN 槽约定（0xFF）共同构成软件路径的
   完整域。

## 未验证事项

- MXFP4 GEMM（仅点积；tiled GEMM 组合跟进）
- aiter 的 `MxScaleRoundMode` 四种舍入公式（本 demo 只钉 ceil 一种）
- 其他架构
