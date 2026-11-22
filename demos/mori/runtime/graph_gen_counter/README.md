# graph_gen_counter — 设备侧世代计数器 vs host 冻结 token（hipGraph 重放陷阱）

**类目**: runtime ｜ **验证等级**: `HARDWARE_PASS`（gfx1030 + hipGraph 实测，`results/run_gfx1030.log`）

## 1. 原理说明

mori 的集合通信/EP 内核大量使用"flag 世代 token"协议：consumer 自旋等
`flag >= gen` 才读数据。当 kernel 被 **hipGraph/CUDA Graph 捕获**后，kernel 参数
在捕获期冻结——如果 gen 是 host 算好传进去的立即数，重放时它永远是捕获那一刻的值：

```
重放 1: producer 写 flag=1；consumer 等 flag>=1 ✓
重放 2: producer 还没写（或正在写）；consumer 等 flag>=1 —— flag 仍是上一轮的 1
        → wait 恒真 → 读到旧世代/在途数据 ← 陷阱
```

mori 的修法（`ccl_kernel_args.hpp:74-81` 注释 + `oneshot_sdma_kernel.hpp:131-137`）：
`genCounter` 改为**设备侧世代计数器指针**——kernel 每次重放运行时
`atomicAdd(counter,1)` 取得本世代号，等够了再写回。定值冻不进图，协议在重放下
自持。JIT v2 设计文档 §4 对跨设备 barrier epoch 给出同一结论
（`dispatch 结尾 atomicAdd(xdbFlag, 1)`），并指出第二个坑：op 里混入 host 同步
（`.item()/.cpu()`）会让捕获直接失败。

**实测**（单 gfx1030，双 stream，producer 自旋拉宽竞争窗口，200 次重放统计）：

| 变体 | 踩坑重放数 | 结论 |
|---|---|---|
| A: gen 为捕获期冻结的 host token | **113 / 200** | 陷阱以 ~57% 的重放率复现——不是理论问题 |
| B: genCounter 设备指针（mori 修法） | **0 / 200** | 修法完全有效 |

变体 A 的失败形态经数据校验确认为"读到旧世代 payload"（与期望 epoch*1000+i
不符），与上游注释描述的失败模式一致。

## 2. 上游出处

- `include/mori/collective/ccl_kernel_args.hpp:74-81`（genCounter 设备指针的动机注释）
- `include/mori/collective/allgather/oneshot_sdma_kernel.hpp:131-137`（kernel 自增+写回）
- `include/mori/collective/allreduce/twoshot_sdma_kernel.hpp:60-63`（同款 genCounter 注释）
- `docs/MORI_JIT_V2_DESIGN.md` §4（设备侧 epoch + graph capture 三时序约束）
- 考古报告：`docs/EMULATION_CATALOG.md` E-15、`docs/archaeology/03-collective-ops.md` §5.5

## 3. 独立实现说明

单文件 HIP C++。producer 与 consumer 分属两个 stream；consumer 图各捕获一次，
producer 常规发射。producer 用 `clock64()` 自旋拉宽竞争窗口（~8µs），使陷阱窗口
可观测；发布序沿用 Demo 3 的 `__threadfence_system` + RELAXED flag。

## 4. Reference / Correctness Test

consumer 读出的 64 word 必须与该轮 epoch 的期望值逐字相等——错误重放计数即为
陷阱率。变体 B 的正确性判据是 0 陷阱（mori 语义）；变体 A 的"失败"本身就是
实验目标，只记录不判失败。

## 5. 构建

```bash
demos/runtime/graph_gen_counter/scripts/build_run.sh   # 容器内
```

## 6. Inspection

`results/run_gfx1030.log`（陷阱率统计）。如需看图结构：
`hipGraphGetNodes` 枚举（未归档）。flag 的单调递增设计使变体 B 无需清零
（"Flags are monotonic generation tokens (AMO_SET), so no reset is needed"——
`twoshot_sdma_kernel.hpp:511` 的同一思想）。

## 7. Hardware Matrix

gfx1030 + HIP 7.16 图捕获/重放实测。陷阱率是时序敏感数字（随 producer 自旋
长度、CU 数、驱动调度变化），57% 只代表本机当前配置；变体 B 的 0/200 是
结构性结论，与速率无关。

## 8. Execution Result

ALL PASS（2026-11-18）：trapA=113/200，trapB=0/200。

未验证事项：多 consumer 并发（mori 的"全员 flag 到齐"聚合）；跨设备 epoch
（单卡无第二设备）；`hipStreamCaptureModeRelaxed` 下的差异。
