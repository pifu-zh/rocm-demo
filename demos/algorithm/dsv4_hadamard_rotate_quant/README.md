# dsv4_hadamard_rotate_quant — Hadamard 旋转 + FP4 量化流水线的主机参考

**类目**: algorithm · **验证级别**: SOURCE_VERIFIED + REFERENCE_PASS（纯 CPU 主机参考，无 GPU 执行声明）
**上游**: `aiter/csrc/kernels/dsv4_rotate_quant.cu`（hadamard_rotate_activation_fp4quant_kernel）@ `1eab5ae12c93af3c8c660202d9a413f637c2f011`（MIT）
**依赖**: C++20 编译器，无 ROCm / 无 GPU / 无第三方库
**结果**: 736 checks, 0 failures（`results/execution.log`，2026-11-14 容器 gfx-m1 / ROCm 10.1 内 g++）

## 一、原理说明

DeepSeek-V4 的 KV/Q 路径在量化前先做 **Hadamard 旋转**（把离群能量摊平到
各分量，让块量化无损效率）。kernel 用 O(n log n) 蝴蝶实现（非 O(n²) 矩阵
乘），分两个阶段：

### 设计 [1]：两阶段蝴蝶
- **intra-thread**（log2(vec_size) = 4 轮）：每 lane 的寄存器块内
  `(x0+x1, x0-x1)` 对，步长倍增；
- **inter-thread**（log2(dim)-4 轮）：`swap_thread_data<gs>` = DPP lane^(gs/2)
  交换，低半 lane 做 `a += x`，高半做 `a = x - a`；
- 末尾 × dim_rsqrt。整体 = **y = H_dim · x / √dim**（H 为自然序
  Walsh-Hadamard 矩阵）——本 demo 用显式递归矩阵（O(n²) oracle）逐位验证。

### 设计 [2]：FP4 scale 契约
行内 absMax 跨 lane 归约 → `scale_e8m0 = ceil_pow2(absMax / fp4_max)`
（与 mxfp4_moe_aux 相同的 `(bits + 0x7FFFFF) >> 23` 无分支位技巧，泛化到
/fp4_max，含 eps_amax 下限）→ e8m0 字节由 `threadIdx % num_thread_per_group == 0`
的 lane 存储。量化值 = x / scale 的 E2M1（lab 的 RNE 编码器，soft_fp4 已验证）。

### 设计 [3]：scale 布局契约
`groups_per_row = dim / group_size`，Natural 与 Flydsl（shuffled）两种布局
选项——本 demo 钉死 Natural 行主索引。

## 二、测试清单（736 checks）

| # | 内容 | 判据 |
|---|---|---|
| 1 | 蝴蝶旋转 vs 显式 Hadamard 矩阵 oracle（dim 16/32/64，含跨 lane 阶段） | 每元素 \|got-want\| ≤ 1e-4 |
| 2 | FP4 scale 契约（256 行，log-uniform 幅值） | amax/scale ≤ fp4_max（永不 clip）；逐值 decode ≤ 1.3 LSB |
| 3 | 端到端 rotate→quant→decode | 误差 ≤ 1.05 LSB；**能量守恒**（‖rotated‖/‖x‖ = 1 ± 1e-5，Hadamard 正交性） |

## 三、章程对照（10 项）

| 章程项 | 本 demo |
|---|---|
| 原理说明 | README §一 + 源文件头注释 |
| 上游出处 + commit | dsv4_rotate_quant.cu @ 1eab5ae12，MIT |
| 独立实现 | 单 TU ~300 行：逻辑 lane 仿真 + 显式矩阵 oracle |
| 最小依赖 | C++20；CPU-only |
| Reference | E2M1 编解码归 soft_fp4/mxfp4_moe_aux；DPP 指令归 warp_sync 线 |
| Correctness Test | 3 组 736 checks |
| Build Script | `scripts/build_run.sh`；CMakeLists 亦可 ctest |
| Inspection | 显式矩阵 oracle（O(n²) vs O(n log n) 双路径对撞）+ 能量守恒不变量 |
| Hardware Matrix | 上游目标 gfx950 系（DSV4）；本 demo CPU 主机参考 |
| Execution Result | `results/execution.log`：736 checks, 0 failures |

## 四、复现

```bash
cd demos/algorithm/dsv4_hadamard_rotate_quant && ./scripts/build_run.sh
# 或 CMake + ctest
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build && ctest --test-dir build
```
