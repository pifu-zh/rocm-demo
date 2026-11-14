# Results — soft_tma (2026-11-13)

环境：容器 gfx-m1（rocm10-dev:10.1.0；7.2.4 首测），GPU RX 6950 XT
（gfx1030/Navi 21，40 CU，256-bit @ 18 Gbps，经验上限 575.5 GB/s），
hipcc ROCm 7.2.4，-O3。

## 正确性（位级，整数填充模式）

| 形状 | B=4 | B=8 | B=16 |
|---|---|---|---|
| 64 blocks × 128 quads（对齐） | PASS | PASS | PASS |
| 64 × 130（尾 2） | PASS | — | — |
| 8 × 1（partial prologue 后单 quad） | PASS | — | — |
| 8 × 3（partial prologue） | PASS | — | — |

## 吞吐（triad 协议：320 blocks × 2048 quads，320 MiB × 8 rotations，median-of-3 best-of-8）

| kernel | ms/launch | GB/s | vs copy* | vs ISA |
|---|---|---|---|---|
| soft_tma C++ B=4 | 0.661 | 507.6 | 101.9% | 91.1% |
| soft_tma C++ B=8 | 0.679 | 493.2 | 99.0% | 88.5% |
| soft_tma C++ B=16 | 0.867 | 387.0 | 77.7% | 69.5% |
| plain（无流水） | 0.634 | 529.7 | 106.4% | 95.1% |
| copy_f4（own r+w 口径） | 1.348 | 498.0 | 100% | — |
| ISA st_tma1（手写参照） | 0.603 | **557.0** | — | 100% |

*copy 口径 = 2×区域字节（读+写）；soft_tma 读区域 + 极小 out——跨混合比是指示性的。

## 结论

1. GO 前提实证：hipcc 接受 `asm volatile("s_waitcnt vmcnt(%0)" :: "n"(N))`，
   C++ 流水线位级正确。
2. C++ B=4 = ISA 参照的 91.1% → 完美替代档（分级线 90%）。
3. 诚实负结果：该极简消费端下，编译器自调度的 plain（529.7，无显式流水）
   胜过显式 C++ 流水线 B=8/16；显式流水的完整价值在 ISA 形态（557）与
   真实消费端。B=16 掉速 = LDS 16KB 占用损失。
4. ISA 参照 557.0 复现原工程收线 553 GB/s（口径同族）。

## 已知坑（对复现者）

- 动态循环里的寄存器组拷贝（`gA = gB`）→ 编译器溢出 local memory（~1000× 减速）；
  必须复制循环体（ISA 同款）。
- GB/s 打印注意 ms→s 换算（本 demo 曾因此假性 0.5 GB/s）。
- copy 基线需专用同尺寸缓冲（复用小 out 缓冲会 OOB fault）。
