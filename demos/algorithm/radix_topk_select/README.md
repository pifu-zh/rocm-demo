# radix_topk_select — fp32 多轮基数选择的主机参考

**类目**: algorithm · **验证级别**: SOURCE_VERIFIED + REFERENCE_PASS（纯 CPU 主机参考，无 GPU 执行声明）
**上游**: `aiter/csrc/kernels/topk_per_row_kernels.cu`（radix_kernel_persistent，fp32 largest-first 基数路径）@ `1eab5ae12c93af3c8c660202d9a413f637c2f011`（MIT）
**依赖**: C++20 编译器，无 ROCm / 无 GPU / 无第三方库
**结果**: 149 checks, 0 failures（`results/execution.log`，2026-11-14 容器 gfx-m1 / ROCm 10.1 内 g++）

## 一、原理说明

### 设计 [1]：radix_key_bits（fp32 序保持但**反序**的 twiddle）

正数：`key = u ^ 0x7fffffff`（低 31 位翻转，符号位清零）；负数：`key = u`
原样。**key 升序 = 值降序**——低桶端向上扫描恰从最大值往下走，这正是
largest-first 选择需要的方向（测试 1 按值升序排布断言 key 单调降序验证；
位序 ≠ 值序跨符号边界，第一版测试按位排序被自己抓出）。NaN-high 模式把
任意 NaN 折叠到 `~magnitude` = 小 key = **排名高于 +inf**（与 torch.topk
一致——方向是"key 更小"而非"更大"，测试 1 的方向修正实测）。

### 设计 [2]：多轮基数选择（BitsPerPass=8，4 轮）

每轮：候选按当前 bucket 直方图计数（pass 0 全量；后续轮只数"累计前缀 ==
kth 前缀"的幸存者）→ 低端前缀和 → 累计跨过剩余 k 的桶 = kth 值桶 →
扩展 kth 前缀、剩余 k/长度更新。早停（剩余候选 == 剩余 k → 全写出）。
末轮：前缀 < kth 的**确定 top-k** 从前填；前缀 == kth 的从**后**填
（位置 k−1 递减，只填需要的量）——**平局中最低输入索引胜**（宿主按输入序
迭代是确定性的；设备原子序非确定，上游测试按排序后比较——同一纪律）。
`row_len ≤ k` 快路径：输出按 −inf / 索引 −1 填充（与 one-block kernel
共享的契约——分批跨界的调用语义不得改变）。

### 设计 [3]：调度决策（should_use_mulblocks）

按 CU 数分档的 seq_len 阈值表（128-CU：b≤2→65536、b≤32→98304、b≤64→
131072、b≤128→b·2048；64-CU：16384/60000/98304；回退：batch·8 ≤ CU），
TOPK_FORCE_PATH / TOPK_DISPATCH_FACTOR 环境覆盖——作为数据钉死。

## 二、测试清单（149 checks）

| # | 内容 | 判据 |
|---|---|---|
| 1 | radix key：边界类（±0/±inf/min-normal/subnormal/max-finite/NaN 载荷）单调性 + 对合 + NaN 方向 | 值升序 ⇒ key 降序；NaN-high 的 key < +inf 的 key |
| 2 | 多轮选择 vs 朴素参考（64 行：随机/重平局/len≤k 快路径） | 索引集合相等（顺序自由）；padding 正确 |
| 3 | NaN 行为（默认模式集合匹配） | 集合相等 |
| 4 | 调度决策 | 14 个精确点（含边界 ±1） |

## 三、章程对照（10 项）

| 章程项 | 本 demo |
|---|---|
| 原理说明 | README §一 + 源文件头注释 |
| 上游出处 + commit | topk_per_row_kernels.cu @ 1eab5ae12，MIT |
| 独立实现 | 单 TU ~380 行：算法仿真 + 朴素排序第三实现 |
| 最小依赖 | C++20；CPU-only |
| Reference | topk_plain_strategies（策略阶梯与调度公式族）；设备跨块 barrier 归硬件线 |
| Correctness Test | 4 组 149 checks |
| Build Script | `scripts/build_run.sh`；CMakeLists 亦可 ctest |
| Inspection | 14 个调度精确点 + 边界类 key 单调性 + 平局集合纪律 |
| Hardware Matrix | 上游目标 gfx10/9 系；本 demo CPU 主机参考 |
| Execution Result | `results/execution.log`：149 checks, 0 failures |

## 四、复现

```bash
cd demos/algorithm/radix_topk_select && ./scripts/build_run.sh
# 或 CMake + ctest
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build && ctest --test-dir build
```
