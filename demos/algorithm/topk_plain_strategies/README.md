# topk_plain_strategies — aiter top-k 自适应策略阶梯的主机参考

**类目**: algorithm · **验证级别**: SOURCE_VERIFIED + REFERENCE_PASS（纯 CPU 主机参考，无 GPU 执行声明）
**上游**: `aiter/csrc/kernels/topk_plain_kernels.cu` @ `1eab5ae12c93af3c8c660202d9a413f637c2f011`（MIT, © AMD）
**依赖**: C++20 编译器，无 ROCm / 无 GPU / 无第三方库
**结果**: 116 checks, 0 failures（`results/execution.log`，2026-11-14 容器 gfx-m1 内 g++）
**范围排除（NOT_EXTRACTED）**: `radix_topk_dispatch` 多块 radix kernel 本体与 buffer_load 寻址——只提取其决策函数。

## 一、原理说明

topk_plain 用**三级策略阶梯**覆盖输入密度谱（MOE 路由的 top-k 门控场景）：

### 设计 [1]：WaveTopkFilter — ballot 门控流式过滤（稀疏域）

每个 wave 维护一个**分布式 top-capacity 缓冲**：rank r（第 r 大）住在
`(lane r&63, slot r/64)`——这个映射是承重结构：lane (k−1)&63 的
slot (k−1)/64 **就是**第 k 大 = 过滤阈值；每 lane 的最后一个 slot 恰是
它的最弱元素（integrate 的被替换者）。每个 64-lane tile：

```
passes  = candidate > threshold          # 严格；-inf 哨兵永不过 -inf
ballot  = 64-bit 通过掩码                 # __ballot
offset  = popcount(ballot & ((1<<lane)-1))  # __popcll 前缀和 = 压缩偏移
slot    = staging_count + offset          # 紧凑追加进 LDS staging
```

staging 满 64 → integrate（排序 64 个候选 → 逐 lane 替换最弱 slot →
缓冲重排 → 刷新阈值）。**溢出处理**：slot ≥ 64 的候选在 integrate 消费
前 64 个之后**回绕写入 slot−64**——设备上靠程序顺序（fits 写 → barrier →
integrate → count−=64 → 溢出写）无锁安全。finalize 把剩余 staging 用
哨兵补满到 64 再 integrate。

稀疏正确性论证（本 demo 测试 4 钉死的契约）：候选 x 在过滤时若 ≤ 阈值，
则缓冲已有 ≥ k 个更好的元素 → x 永远进不了最终 top-k。阈值单调不减，
且**合法地滞后**于原始前缀（staging 里有未 integrate 的候选）。

### 设计 [2]：WaveTopkSort — 分块排序归并（稠密域）

首 capacity 块排序入缓冲；后续每块排序后与缓冲逐元素择优合并。上游用
bitonic 网络的"bitonic 序列"技巧（升序缓冲 vs 降序新块逐位比较形成
bitonic 序列，再一次 merge 归位）。本 demo 以 order-free 缓冲模型仿真
（语义 = 缓冲∪新块的 top-capacity）；**跨 lane bitonic 网络本身是设备
性能细节**，归 hardware/compiler 线。

### 设计 [3]：块内归约 — 对折合并树

Sort 策略给每个 wave 分**不相交**区间（len_per_wave 向上取整到 64 的
倍数）；Filter 策略则所有 wave **跨步共享**同一区间（每候选恰被见一次）。
reduce() 反复合并 wave 结果（对折：[half, num) 存 LDS，[0, num/2) 合并）。

### 设计 [4]：调度启发式（精确提取的纯函数）

- `should_use_topk_radix`：radix 路径当且仅当
  `K·log₂²K ≥ 4.8n/(log₂n − 9.5)`（由 `n + K·log²K ≥ 3·Factor(n)·n`、
  `Factor(n) = 1/3 + 1.6/(log₂n − 9.5)` 化简）；K ≤ 1 永不。
- `calc_capacity(k) = max(64, ceil_pow2(k))`。
- LaunchThreshold：Filter {multi 2, single 256}、Sort {multi 2, single 4}。

## 二、输出契约：SET 而非顺序

**上游自己的测试**（`op_tests/test_topk_plain.py:52,71`）对参考与实现
都先 `torch.sort` 再比较——**输出顺序不是契约，选出的集合才是**。
相等值的索引选择由设备压缩顺序决定（select_idx 保留 lane 自侧）。
本 demo：distinct 值输入钉索引集合相等；专门的 tie 用例只钉值多重集
+ "选中索引的值 ≥ 第 k 大"。

## 三、文件与验证对照（章程 10 项）

| 章程项 | 本 demo |
|---|---|
| 原理说明 | 本 README §一 + 源文件头注释 |
| 上游出处 + commit | topk_plain_kernels.cu @ 1eab5ae12，MIT |
| 独立实现 | 单 TU ~530 行：机制忠实仿真（ballot/staging/溢出/阈值）+ 朴素第三实现 |
| 最小依赖 | C++20；CPU-only |
| Reference | DPP/bitonic 网络归 warp_sync 与硬件探针线；radix kernel 未提取 |
| Correctness Test | 6 组 116 checks（见 §五） |
| Build Script | `scripts/build_run.sh`；CMakeLists 亦可 ctest |
| Inspection | 阈值单调性追踪（每 tile 检查）+ 策略行为差异（稀疏 vs 稠密的 integrate/溢出计数） |
| Hardware Matrix | 上游目标 gfx950 系（wave64）；本 demo CPU 主机参考，未声明任何 HIP 执行 |
| Execution Result | `results/execution.log`：116 checks, 0 failures |

## 四、测试清单

| # | 内容 | 判据 |
|---|---|---|
| 1 | Filter 策略 6 配置（k=64/32/128，n=100..100000，稠密/稀疏） | 索引集合 == 朴素；值/索引一致；稠密域溢出路径被 exercising |
| 2 | Sort 策略 4 尺寸 × 3 k | 集合相等 |
| 3 | 块内归约（2/4/8 waves） | 最终集合 == 全局 naive |
| 4 | 阈值契约 | 单调不减；finalize 后 == 真实第 k 大 |
| 5 | 调度启发式 | K≤1 反例、6 个公式精确点、k 单调性、capacity 最小性/pow2 |
| 6 | tie 行为 | 值多重集相等；选中索引 ≥ 第 k 大 |

## 五、复现

```bash
cd demos/algorithm/topk_plain_strategies && ./scripts/build_run.sh
# 或 CMake + ctest
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build && ctest --test-dir build
```
