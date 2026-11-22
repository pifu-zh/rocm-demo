# ll128_wire_format — NCCL LL128 线缆格式数学复现（E-11/D-11，纯计算）

**类目**: algorithm ｜ **验证等级**: `REFERENCE_PASS`（T1-T5 全过，纯 CPU）
**上游对应**: `include/mori/ops/dispatch_combine_v2/ep_cfg.hpp:550-556`
`EpLl128LandRowBytes`（EPv2 ll128 cfg 的 land 区定量公式）@ `c5bdc391`

## 1. 原理说明

LL128（NCCL 低延迟协议血统）的线缆形态：**每条 128B 线缆行承载 120B 数据 +
8B flag/控制**，8 行为一组（1024B 线缆 / 960B 数据 → 理论效率 93.75%）。mori 的
EPv2 用 `EpLl128LandRowBytes = ((data+119)/120 + 7)/8 × 1024` 给 land 区定量。

本 demo 纯计算验证三层：
1. **mori 公式逐点复算**（边界 1/119/120/121/960/961/9600B）——公式与独立推导
   逐点一致；测试表自身曾算错 121→2048（实际 ceil(121/120)=2 行仍在 1 组内
   →1024），修正过程记录。
2. **pack/unpack round-trip**：8 行交错放置（每行 [0..7]B flag 槽 + [8..127]B
   数据），960B 满组逐字节一致 + flag 槽不被数据污染不变量 + 1..9300B fuzz
   （含越界哨兵）。
3. **线缆放大率表**：效率随尺寸爬升（1KB:50% → 256KB:93.4%）——组粒度
   （8 行/1024B）的阶梯效应；对照 naive pad-128（数据即 100%，但无 flag 通道）。

**LL128 的工程动机**（对照解释）：naive pad-128 省带宽但没给 flag 留位置——
LL128 用 6.25% 带宽税换来**每行内嵌 flag 通道**（低延迟协议的 flag-guarded
数据形态），这正是 EPv2 ll128 cfg 的存在理由。

## 2. 上游出处

- `include/mori/ops/dispatch_combine_v2/ep_cfg.hpp:550-556`（EpLl128LandRowBytes）
- `ep_cfg.hpp:262-268,572-575`（ll128 cfg 字段与 land 区定量）
- 血统：NCCL LL128 协议（120/128 = 93.75%）
- 考古报告：`docs/archaeology/03-collective-ops.md` §2.6（E11 条目）

## 3. 独立实现说明

单文件 C++20 纯计算。pack/unpack 为 NCCL 简化形态（数据按行序填各行数据区，
每 lane 独占一行的轮转读等效）；未复刻 NCCL 完整的 8-rank 单行内 8×16B 旋转
放置（那需要多 rank 语义，如实标注）。

## 4. Reference / Correctness Test

T1 判定基准 = mori 公式逐字复算 + 独立推导双对照；T2/T5 = 逐字节 memcmp +
越界哨兵（unpack 不得写超出 n）；曾抓到测试表自身 121 的期望算错——修的是
测试不是公式。

## 5. 构建

```bash
demos/algorithm/ll128_wire_format/scripts/build_run.sh   # 容器内（纯 CPU）
```

## 6. Inspection

`results/run_cpu.log`（放大率表 + 全测试）。

## 7. Hardware Matrix

纯计算——任何机器可跑。mori ll128 cfg 只在 gfx942/950/1250 的 EPv2 路径启用
（ll128 桶边界随 topk 移动、专家数不动的调优结论见 mori JIT v2 设计文档 §5.1）。

## 8. Execution Result

ALL PASS（2026-11-23）。未验证事项：真实 kernel 的 LL128 打包/解包（本 demo 只
验证公式与布局数学）、NCCL 完整 8×16B 旋转放置、8-rank 语义。
