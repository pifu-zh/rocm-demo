# sched_group_barrier_probe — 调度屏障内联函数的实测探针（gfx1030）

**类目**: hardware · **验证级别**: HARDWARE_PASS + STATIC_ANALYSIS_PASS（RX 6950 XT / gfx1030 / ROCm 7.2.4 真机执行，2026-11-14）
**动机**: aiter 在 gfx950/gfx1250 的 opus kernel 里用
`__builtin_amdgcn_sched_group_barrier(mask, count, group_id)` 做 IGLP
共执行调度（如 `pa_mqa_logits_mxfp4_gfx950_common.cuh:476-477`、
`mla_decode_a8w8_32nx1.hpp`）。gfx1030 上这个内联函数的行为（可编译性、
功能等价性、工具链稳定性）未被记录——本探针测量。

## 一、测量结论（三条硬事实）

1. **功能等价**：上游风格注解（多个指令类掩码共享**同一 group id**）的
   kernel 与未注解 kernel 输出**逐位一致**（256/256），注解是纯调度提示，
   只影响指令排序。
2. **gfx1030 可用的指令类 id**（实测编译）：`0x8`（VMEM）、`0x11`
   （VALU/ALU）、`0x18`（TRANS）、`0x28`（SALU）。aiter 在 gfx950/gfx1250
   用的 MFMA/WMMA 掩码在 RDNA2 上无对应单元。
3. **工具链雷区（实测）**：某些混合类型双 group 模式会**段错误** LLVM
   机器调度器（`ScheduleDAGMI::schedule`，clang-22）。崩溃集不规则：
   `{0x11 gid0 → 0x8 gid1}` 崩、`{0x11 gid5 → 0x8 gid10}` 不崩、逆序不崩、
   同类型双 group 不崩——这是 LLVM bug 面，不是使用规则。
   **安全模式（实测 + 与上游一致）**：一个调度区域内所有
   sched_group_barrier 共享同一个 group id。

## 二、文件

| 文件 | 内容 |
|---|---|
| `src/main.hip` | 注解/未注解对偶 kernel（逐位比较） |
| `results/execution.log` | 真机日志（F1 PASS） |
| `results/annotated.s` | -O3 ISA 留档 |
| `scripts/build_run.sh` | hipcc 构建 + 运行 |

## 三、复现

```bash
cd demos/hardware/sched_group_barrier_probe && ./scripts/build_run.sh  # 容器内，需真机
```
