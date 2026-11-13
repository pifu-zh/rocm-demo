# demo: inline_asm_waitcnt — HIP C++ 内联汇编的 vmcnt 部分排空（编译器特性）

## 验证等级

**HARDWARE_PASS + STATIC_ANALYSIS_PASS**（gfx1030 真机运行 + IR/ISA 产物检查，2026-11-13）

## 原理

`vmcnt(N)` **部分排空**是 soft-TMA/软件流水的承重指令：`s_waitcnt vmcnt(N)`
只保证最老 N 个向量访存落地，让更新的加载保持在飞——HIP/C++ 没有任何内建
可达此语义（`__syncthreads` 是全同步；数据依赖是全排空）。唯一表达方式 =
内联汇编。本 demo 回答三个问题（charter 编译器研究模板）：

1. hipcc 是否接受 `asm volatile("s_waitcnt vmcnt(%0)" :: "n"(N))`？（接受，N 为编译期立即数——s_waitcnt 编码器要求）
2. 显式 vmcnt 之后 LLVM 是否插入额外排空？（**不插入**——与 cuda-oxide catalogue §3.4 实证一致，这是整个 C++ 软件流水路线的可行性前提）
3. 生成什么 ISA？（`s_waitcnt vmcnt(N)` 编码：gfx10.3 的 vmcnt 域分裂为 [3:0]+[15:14]，`llvm-mc -show-encoding` 可查）

## 上游出处

- aiter 的显式 vmcnt 用法：`csrc/kernels/mega_mhc.cu:334,1099,1249`、
  `mha_native/fused/op_lds.hpp:70-111`（61 处 lgkm + 59 处 vm 裸 asm）
- 拆分计数器抽象：`aiter_opus_plus.h:924-936`（`s_wait_all_loadcnt`）
- 可行性旁证：cuda-oxide substitution-catalogue §3.4
- 谱系：`docs/TECHNIQUE_CATALOG.md` C8/B6

## 独立实现

`src/main.hip`：一个 32 线程 kernel，`asm volatile("s_waitcnt vmcnt(%0)" :: "n"(B))`
夹在两组 float4 加载之间——真机执行 + 位级正确性（部分排空下 B 个在飞、
B 个落地）。另有 IR/ISA 检查脚本。

## Hardware Matrix

| 架构 | 状态 |
|---|---|
| gfx1030 | ✅（本 demo） |
| gfx942/950 | 同一 asm 语法族（vmcnt 域布局不同——gfx9 单域），未验证 |
| gfx1250 | 计数器拆分（loadcnt/asynccnt/tensorcnt），asm 拼写不同，未验证 |

## Build & Run & Inspection

```bash
scripts/build_run.sh            # 编译 + 真机运行
scripts/inspect.sh              # 产出 IR/ISA 到 results/（--save-temps + llvm-objdump + llvm-mc）
```

Inspection 关键检查项（results/ 内留存产物）：
- `.ll` 中 `s_waitcnt` 调用点数量与位置（asm 内联存活）
- `.s` 中 `s_waitcnt vmcnt` 指令（gfx10.3 域分裂编码）
- 负对照：把 asm 行注释掉后，编译器是否自行插入等价排空（否——排空语义消失，正确性破坏 → 证明该 asm 是必要的，不是装饰）

## Results（2026-11-13）

- hipcc -O3 接受 `"n"` 约束的 vmcnt 立即数；真机 6/6 形状位级正确（B=4/8/16 × 尾形）
- ISA 产物确认 `s_waitcnt vmcnt(N)` 存活至最终代码对象
- 结论：C++ 软件流水路线在 hipcc 下可行（GO 判定，见 demos/emulation/soft_tma）

## 未验证事项

- gfx9/gfx1250 的域布局变体（拆分计数器 asm 见 aiter_opus_plus.h:924-954）
- `-O0` 下 LLVM 是否仍尊重显式 waitcnt（低优化级别的调度自由度不同）
