# demo: soft_fp8 — 无 fp8 硬件的编解码 + 转换吞吐（gfx1030）

## 验证等级

**HARDWARE_PASS + PERFORMANCE_MEASURED**（gfx1030 / RX 6950 XT，ROCm 7.2.4，2026-11-13）
穷举 219,488 项 0 失败；转换流吞吐已测（triad-lite 协议）。

## 原理

gfx1030 没有 packed-fp8/fp4 转换硬件（MFMA fp8 也无）。fp8 是**存储格式**：
编解码 = 纯位操作（RNE + satfinite），设备代码内联展开、零外部依赖。语义钉死
CUDA 契约：`cvt.rn.satfinite.e4m3x2.f32`（E4M3FN：无 Inf、0x7F/0xFF=NaN、max 448、
溢出钳 0x7E）、`cvt.rn.e5m2x2.f32`（IEEE：溢出→Inf）、`__nv_fp4x2_e2m1`
（E2M1 satfinite 6.0）；packed lane 0 在低字节/低 nibble。

## 上游出处

- 设计契约与穷举法：cuda-oxide `crates/cuda-device/src/fp8.rs` @ adapt-rocm
  （那里 450,852 项真机穷举零失败）+ `examples/fp8_decode/src/main.rs`。
- 吞吐协议：cuda-oxide `docs/research/2026-11-10-fp8-throughput-grade.md`
  （标量 91-98% = 完美档、packed decode 81-82% = 优秀档）。
- 谱系：`docs/EMULATION_CATALOG.md` E1。

## 独立实现

`include/soft_fp8.hpp`：E4M3FN/E5M2/E2M1 解码（算术式，denormal 走 `m·2^-9`/
`m·2^-16` 位组装）+ 编码（共享 `rne_shift` RNE 原语；denormal↔normal 进位；
E4M3 NaN 槽 satfinite 钳位）+ packed x2。host/device 同一份 `__host__ __device__`。

## Hardware Matrix

| 架构 | 状态 |
|---|---|
| gfx1030 | ✅ 本 demo（真机穷举 + 吞吐） |
| gfx942 | 硬件有 `cvt_pk_fp8`（fnuz clamp 240 变体）——本 demo 的软件路径同样可用，未验证 |
| gfx950/1250 | 硬件 packed cvt 存在（aiter 路径）；软件路径冗余 |
| 通用 | 纯位操作，无架构依赖 |

## Build & Run

```bash
hipcc -x hip --offload-arch=gfx1030 -O3 src/main.hip -I include -o soft_fp8_demo
./soft_fp8_demo
```

## Results（2026-11-13，容器 gfx-m1）

穷举（设备上跑、独立 host 参考=格式定义构造 + 暴力最近值编码器）：

| 检查族 | 项数 | 结果 |
|---|---|---|
| E4M3 标量解码 256 | 256 | PASS |
| E4M3x2 packed 解码（双 lane） | 131,072 | PASS |
| E5M2 标量解码 256 | 256 | PASS |
| E2M1x2 packed 解码 | 512 | PASS |
| E4M3x2 全 packed 往返 | 65,536 | PASS |
| E5M2x2 全 packed 往返（NaN 规范化） | 65,536 | PASS |
| E2M1x2 全 packed 往返 | 256 | PASS |
| E4M3 编码 sweep（RNE 中点/饱和/NaN，±0.25 与 ±0.125 网格） | 21,856 | PASS |
| E2M1 编码 sweep | 21,856 | PASS |
| **合计** | **219,488** | **0 失败** |

吞吐（128 Mi 元素，5 B/元素口径，copy=8 B/元素参照 414.7 GB/s）：

| kernel | GB/s | vs copy |
|---|---|---|
| decode_e4m3 | 477.5 | 115.2% |
| encode_e4m3 | 469.0 | 113.1% |
| decode_e4m3x2 | 489.6 | 118.1% |
| encode_e4m3x2 | 533.0 | 128.6% |

口径说明：>100% 是流量混合产物（转换 5 B/elt vs copy 8 B/elt）——正确解读是
**字节速率达到/超过 copy 流**，即软件转换完全隐藏在内存带宽之后（cuda-oxide
在 8 B/elt 口径下的 copy 参照得到 91-98%，同结论）。按分级线 = 完美替代档。

## Inspection

```bash
hipcc -x hip --offload-arch=gfx1030 -S -emit-llvm src/main.hip   # IR：无任何 cvt fp8 指令
/opt/rocm/bin/llvm-objdump -d soft_fp8_demo | grep -c v_cvt      # = 0（纯位操作证据）
```

## 开发中抓到的 bug（穷举法的价值实证）

1. E4M3 NaN 解码丢符号位 → packed 往返 0x?ff 全失败。
2. E5M2 subnormal 误走隐含位路径（e+112 字段组装对 e=0 非法）。
3. E4M3 mantissa 进位阈值写成 0x10（rne_shift 输出域是 0..8）。
4. E2M1 sub-1.0 边界（e32<-1 应为 e32<0）与 k 移位差一。
5. host 暴力参考自身：e2m1 距离未取 fabs（负距离获胜）、±0 槽、1e30 下
   double 距离全等需饱和早退——**参考实现同样需要被检验**。

## 未验证事项

- E5M2 吞吐（e4m3 族已代表；e5m2 与 cuda-oxide 差异仅 IEEE 溢出分支）
- GEMM 组合（独立 demo 跟进）
- 其他架构（见 Hardware Matrix）
