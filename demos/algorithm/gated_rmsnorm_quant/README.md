# gated_rmsnorm_quant — 门控 RMSNorm + FP8 组量化的主机参考

**类目**: algorithm · **验证级别**: SOURCE_VERIFIED + REFERENCE_PASS（纯 CPU 主机参考，无 GPU 执行声明）
**上游**: `aiter/csrc/kernels/gated_rmsnorm_quant_kernels.cu` @ `1eab5ae12c93af3c8c660202d9a413f637c2f011`（MIT）
**依赖**: C++20 编译器，无 ROCm / 无 GPU / 无第三方库
**结果**: 484 checks, 0 failures（`results/execution.log`，2026-11-14 容器 gfx-m1 / ROCm 10.1 内 g++）

## 一、原理说明

### 设计 [1]：门控 RMSNorm 数学（每 head，head_dim = GROUP_SIZE = 128）

```
var   = mean(x²)（head 维内）
norm  = x · weight · rsqrt(var + eps)
gated = norm · silu(z)（或 norm · sigmoid(z)——USE_SIGMOID 变体）
```

lane 分解：threads_per_group = 128/THREAD_DATA_SIZE 个 lane 协作一个
head；sum-sq 与 amax 经 **shfl_xor 蝴蝶**（mask tpg/2..1）归约——宿主以
逻辑 lane 数组仿真。

### 设计 [2]：两种量化范围
- **per-HEAD 组量化**（group kernel）：scale[head][token]，TRANSPOSE_SCALE
  布局选项（head 主 vs token 主索引）；
- **per-TOKEN 量化**（per_token kernel）：整个展平行
  [num_heads·head_dim] 一个 scale——匹配 per-token 激活 × per-channel
  权重的 a8w8 GEMM 方案（下游 GEMM 不变，只有激活生产被融合）。
- scale = amax / FP8_MAX（fp8 e4m3 max = 448），amax ≤ 1e-10 时钳到
  1e-10（全零 gated 行量化为零、永不 NaN）。

### 设计 [3]：clamp + cast 契约
out = cast(clamp(gated / scale, ±FP8_MAX))——显式饱和。fp8 的位级编码
归 soft_fp8（已穷举验证）；本 demo 把量化值建模为钳位浮点。

## 二、测试清单（484 checks）

| # | 内容 | 判据 |
|---|---|---|
| 1 | per-head 组量化：tds 2/8/16 × silu/sigmoid × eps 变体 × 32 试验 | scale ≤ 1e-5 rel；逐元素 ≤ 1e-4 rel |
| 2 | per-token 量化（amax 跨 head）+ scale 布局一致性 | 量化行 ≤ FP8_MAX；amax 恰达 FP8_MAX（scale 契约） |
| 3 | 零守卫 | 全零 gated → scale 恰为 1e-10、输出全零、永不 NaN |
| 4 | clamp 饱和 | 异常值 → ±FP8_MAX（不回绕） |

## 三、调试链（一个结构性 bug，方法论价值高）

**shfl_xor 蝴蝶被嵌进了每 lane 的填充循环**——64 个 lane 各跑一遍蝴蝶，
sum_sq 被累计 64×（scale 偏大 8-10×）。kernel 的真实结构是**分阶段**的：
全 lane 填充 → 一次归约 → 归一化/门控 → amax → 一次归约。宿主仿真必须
按 kernel 的**阶段结构**重排，不能按 lane 循环把所有阶段串起来。
另：**shfl_xor 是同时交换**——emu 每步必须先快照再更新（顺序就地累加
双重计数）；**门控语义**——silu(0) = 0 会把 x 异常值清零，饱和测试的
gate 必须给大正 z（silu(z) ≈ z 才能通过门）。

## 四、章程对照（10 项）

| 章程项 | 本 demo |
|---|---|
| 原理说明 | README §一 + 源文件头注释 |
| 上游出处 + commit | gated_rmsnorm_quant_kernels.cu @ 1eab5ae12，MIT |
| 独立实现 | 单 TU ~230 行：lane 分解仿真 + 朴素标量参考 |
| 最小依赖 | C++20；CPU-only |
| Reference | fp8 编码归 soft_fp8；RMSNorm 数学归 aiter_ref 组 |
| Correctness Test | 4 组 484 checks |
| Build Script | `scripts/build_run.sh`；CMakeLists 亦可 ctest |
| Inspection | 蝴蝶归约的双计划对撞 + scale 契约（amax 恰达 FP8_MAX） |
| Hardware Matrix | 上游目标 gfx10/9 系（warp64/warp32 分支）；本 demo CPU 主机参考 |
| Execution Result | `results/execution.log`：484 checks, 0 failures |

## 五、复现

```bash
cd demos/algorithm/gated_rmsnorm_quant && ./scripts/build_run.sh
# 或 CMake + ctest
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build && ctest --test-dir build
```
