# binary_op_dispatch — 二元算子形状模式分类器 + 实例化矩阵的主机参考

**类目**: compiler/DSL · **验证级别**: SOURCE_VERIFIED + REFERENCE_PASS（纯 CPU 主机参考，无 GPU 执行声明；GPU kernel 本体未提取）
**上游**: `aiter/csrc/kernels/generate_binaryop.py`（实例化矩阵生成器）+ `binary_operator.cu`（binary_op_impl 的形状分类级联）@ `1eab5ae12c93af3c8c660202d9a413f637c2f011`（MIT）
**依赖**: C++20 编译器，无 ROCm / 无 GPU
**结果**: 19 checks, 0 failures（`results/execution.log`，2026-11-14 容器 gfx-m1 内 g++）

## 一、原理说明

### 设计 [1]：形状模式分类器（binary_op_impl 的级联）

一对 (input, other) 张量被分类为 7 个**预实例化**的内存访问模式之一，
不匹配则调用方回退到通用路径——分类器就是 aiter 快路径的门：

| 模式 | 条件 |
|---|---|
| CONTIGUOUS | 维/尺寸全等，双连续（1-D 要求 numel%128==0） |
| TRANSPOSE | 3-D、尺寸全等、连续性不同、非连续者 stride(1)==1 |
| BROADCAST_0/1/2 | 3-D 对，恰一维尺寸为 1（order_flag = input 是否为全尺寸侧） |
| BROADCAST_4 | 3-D、首维相等、一侧后两维全 1 |
| BROADCAST_3 | (m,n,k) + (n,1)（2-D 权重；input 为 3-D 时 order=true） |
| 1-D 广播 | (m,n,k)+(k)，size % (128/element_size) 且 numel % (32768/element_size) |
| BROADCAST_1 回退 | 非 3-D 同维中维广播（**仅 ≥4-D 可触发**——2-D 的中维即边界维） |

`order_flag` 钉死 broadcast 侧永远是"非 primary"（input 为广播侧时 false）。

### 设计 [2]：实例化矩阵生成器

generate_binaryop.py 按 (op, dtype-pair) 配置发射：**调度梯子**
（if/else 链 per dtype 对 → binary_op_impl<Op,X,Y>）+ **显式实例化声明**
——把 (dtype × pattern × op) 的编译成本从运行时 JIT 前移到构建期。
本 demo 重实现发射器并结构验证：分支数、首 if/后续 else-if 链、每分支
的精确调用名、末端 return false。

## 二、测试清单（19 checks）

| # | 内容 |
|---|---|
| 1 | CONTIGUOUS：2-D、1-D mod-128 对齐（含 fp32 变体） |
| 2 | 广播族：b0/1/2/3/4 正例 + 不支持形状（维不匹配 / 连续性不同但非转置条件） |
| 3 | 非 3-D 中维广播回退：2-D 中维**不被支持**（边界维）；4-D 中维触发 |
| 4 | 梯子发射器：分支数/首 if 链/调用名/末尾 false |

## 三、调试链（测试期望三次修正，均为对上游级联的精读收益）

1. **BROADCAST_3 的 order 方向**：input 为 3-D 时 order=true（上游
   `input.dim()==2 ? false : true`）——首版期望写反。
2. **BROADCAST_1/2 的 order**：`order_flag = input.size(bd) != 1`——广播
   侧在 input 时 order=false。
3. **2-D (m,n)+(1,n) 实际不被支持**：BROADCAST_1 回退要求
   `bcast_dims[0] != 0 && != dim-1`——2-D 的中维即边界维，永不触发；
   **≥4-D 中维广播才走此回退**（改为 4-D 测试点）。
4. **1-D 对齐是元素计数**（numel % 128），fp32 的 32 元素不满足——
   element_size 只影响 1-D 广播的尺寸对齐（128/element_size）。

## 四、章程对照（10 项）

| 章程项 | 本 demo |
|---|---|
| 原理说明 | README §一 + 源文件头注释 |
| 上游出处 + commit | generate_binaryop.py + binary_operator.cu @ 1eab5ae12，MIT |
| 独立实现 | 单 TU ~330 行：分类器忠实移植 + 梯子发射器重实现 |
| 最小依赖 | C++20；CPU-only |
| Reference | jit_cache（JIT 编译成本前移的同族设计）|
| Correctness Test | 4 组 19 checks |
| Build Script | `scripts/build_run.sh`；CMakeLists 亦可 ctest |
| Inspection | 广播族全模式精确点 + 梯子结构验证 |
| Hardware Matrix | GPU kernel 本体未提取（本 demo 是 dispatch/编译设计层） |
| Execution Result | `results/execution.log`：19 checks, 0 failures |

## 五、复现

```bash
cd demos/compiler/binary_op_dispatch && ./scripts/build_run.sh
# 或 CMake + ctest
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build && ctest --test-dir build
```
