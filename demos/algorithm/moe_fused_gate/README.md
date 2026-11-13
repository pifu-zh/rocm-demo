# demo: moe_fused_gate — 分组偏置 MoE 路由（算法优化技术）

## 验证等级

**REFERENCE_PASS**（host C++20 确定性参考 + 排序式独立对拍 + 手推例；2026-11-13 落位）

## 原理与上游出处

DeepSeek 式分组偏置路由单 kernel 化（aiter @ 1eab5ae12）：
sigmoid+偏置 → 组内 top-2 和为组分 → 组间 ArgMin 淘汰 → 全局 ArgMax top-k
→ renorm → 融合共享专家。核心可移植技术：

1. **DPP 树序无关性**：ArgMax/ArgMin 平局取更小 key（hip_reduce.h:122-141），
   使设备 DPP 归约树与顺序归约结果恒等——host 参考得以逐位对拍。
2. **排除哨兵**：被淘汰组的 element 0 写 FLT_MAX，同时静默该线程的局部扫描
   （一个哨兵两个用途）。
3. **上流 quirk**：pad 行 routed 槽写 -1/0.0 但 shared 槽照写（无 pad guard）。

实现：`../../include/aiter_ref/moe_fused_gate.hpp` +
`../../src/moe_fused_gate.cpp`（确定性单线程 host 参考）；测试
`../../tests/test_moe_fused_gate.cpp`（2343 checks：排序式独立参考、
手推组选择例、VPT=1 退化、NaN→0、共享专家轮转、pad 行 quirk）。

## 谱系

docs/TECHNIQUE_CATALOG.md A1；docs/EMULATION_CATALOG.md（非 emu，纯算法线）。
上游：csrc/kernels/moe_fused_gate.cu:91-404（Apache-2.0，源自 sglang）+
csrc/include/hip_reduce.h ArgMin/ArgMax。

## Build

顶层 CMake（ctest: moe_fused_gate）；无 GPU 依赖。
