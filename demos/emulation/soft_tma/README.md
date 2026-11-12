# demo: soft_tma — 无 async-copy 硬件的 gmem→LDS 深流水（gfx1030）

## 验证等级

**HARDWARE_PASS + PERFORMANCE_MEASURED**（gfx1030 / RX 6950 XT，ROCm 7.2.4 容器，2026-11-13）
正确性 6/6 形状（三深度 × 对齐/三种尾形，位级）；吞吐同协议含手写 ISA 参照对照。

## 原理

RDNA2 没有 TMA / cp.async / TDM 这类异步搬运硬件。等价能力由**软件流水**合成：
寄存器组乒乓持有 2×BATCH 个在飞 float4 加载，`s_waitcnt vmcnt(BATCH)` 部分排空
（只保证最老一组落地，新组保持在飞）——这就是"异步"的本质；落地组经
`ds_write_b128` 进 LDS 双缓冲（相位 XOR 翻转），`lgkmcnt(0)` 后消费。

**承重指令**是 vmcnt(N) 部分排空：HIP 无内建，本 demo 用 inline asm
（`"n"` 约束——BATCH 是编译期立即数，s_waitcnt 编码器要求）。两个已实证事实：
hipcc 接受该 asm 且显式 vmcnt 后 LLVM 不插额外排空（cuda-oxide catalogue §3.4）。

深度规则：在飞 VM ≤ 63 → BATCH ≤ 21（上游验证 4/8/16）。

## 上游出处（aiter @ 1eab5ae12；旁证 cuda-oxide）

- aiter 的流水做法：`csrc/kernels/mhc_kernels.cu:51-65`（KEEP/DRAIN 计数器类）、
  `mega_mhc.cu:334,1099`（显式 vmcnt 释放点）；aiter 仅在 gfx942 用
  buffer_load→LDS 直通（opus.hpp:1881-1906），RDNA 退化为同步寄存器中转——
  本 demo 即该退化的最优先替代。
- 设计 spec：cuda-oxide `scripts/soft_tma_bench/gen_kernels.py` `lds_bN`
  （收线 553 GB/s = 96.1% 经验上限，2026-11-04 修正口径）。
- 原理谱系：`docs/EMULATION_CATALOG.md` E3、`docs/ARCH_MATRIX.md` [lab] 行。

## 独立实现

`include/soft_tma.hpp`：`soft_tma_reduce<BATCH>`（模板深度、单 wave32/block、
双体循环寄存器乒乓——**动态循环里的组拷贝会让编译器溢出到 local memory
（实测 ~1000× 减速），必须像 ISA 一样复制循环体**）；串行尾处理剩余 quads。

## Hardware Matrix

| 架构 | 状态 |
|---|---|
| gfx1030 | ✅ 本 demo（HARDWARE_PASS + 分级吞吐） |
| gfx942/950 | 理论同构（vmcnt 语义同族）未验证 |
| gfx1250 | 应改用 `global_load_async_to_lds` / TDM（aiter 路径），未验证 |
| 通用要求 | wave32（wave64 需改 mbcnt lane 计算与 BATCH 上限） |

## Build & Run

```bash
# 容器内（host 无 ROCm）
hipcc -x hip --offload-arch=gfx1030 -O3 src/main.hip -I include -o soft_tma_demo
./soft_tma_demo ../../gpu/soft_tma_pipeline.co   # 可选：ISA 参照同协议对照
# 或一键全套：
scripts/build_run.sh
```

## Results（2026-11-13，容器 gfx-m1，RX 6950 XT）

正确性：B=4/8/16 对齐形状 + 130(尾2)/1/3 尾形全 PASS（位级）。

吞吐（triad 协议：320 blocks、2048 quads/block、320 MiB 区域 × 8 轮转、
best-of-8 × median-of-3、2 s DVFS 预热）：

| kernel | GB/s | vs copy 上限 | vs ISA 参照 |
|---|---|---|---|
| soft_tma C++ B=4 | **507.6** | 101.9%* | **91.1%** |
| soft_tma C++ B=8 | 493.2 | 99.0% | 88.5% |
| soft_tma C++ B=16 | 387.0 | 77.7% | 69.5% |
| plain（无流水） | 529.7 | 106.4% | 95.1% |
| copy_f4 上限（own r+w 口径） | 498.0 | 100% | — |
| ISA st_tma1（手写参照） | **557.0** | — | 100% |

\* 口径注意：copy 计 2×区域字节（读+写），soft_tma 读区域 + 极小 out——跨混合
占比是指示性的；**同协议 ISA kernel 是标定参照**（其 557 复现原工程收线 553）。

诚实结论：
1. C++ 版达 ISA 的 91.1%（B=4）→ 按分级线=完美替代档（vs 手写 ISA 参照）。
2. **编译器自调度的 plain（529.7）在该纯读负载上胜过显式 C++ 流水线（493-507）**
   ——显式 vmcnt 流水的价值在 ISA 形态（557）与更复杂消费端（真实 kernel 的
   LDS 消费不是 4 条加法）才体现；单靠"部分排空"不足以超越 -O3 自身调度。
3. B=16 明显掉速（LDS 16KB → occupancy 4 block/CU）。

## Inspection

```bash
hipcc -x hip --offload-arch=gfx1030 -S -emit-llvm src/main.hip   # LLVM IR：查 s_waitcnt 存活与 load 提升
/opt/rocm/bin/llvm-objdump -d soft_tma_demo                      # 最终 ISA
```
关键观察点：`s_waitcnt vmcnt(8)` 编码（gfx10.3 vmcnt 分裂域 vmcnt=[3:0]+[15:14]）、
`global_load_dwordx4`（float4 提升为 128-bit）、`ds_write_b128/ds_read_b128`。

## 未验证事项

- 其他架构（gfx942/950/1250）与 wave64 形态
- 与 aiter 真实消费端（attention/GEMM）组合时的收益——本 demo 消费端是极简加法
- RDNA3 dlds / RDNA4 TDM 硬件出现后需同基准复跑（升级条件，同原工程）
