# gdn_prefill_fwd_h — 分块门控 Delta-Rule 前向状态 kernel 的主机参考

**类目**: algorithm · **验证级别**: SOURCE_VERIFIED + REFERENCE_PASS（纯 CPU 主机参考，无 GPU 执行声明）
**上游**: `aiter/csrc/kernels/chunk_gated_delta_rule_fwd_h.cu`（chunk_gated_delta_rule_fwd_h_hip_kernel）@ `1eab5ae12c93af3c8c660202d9a413f637c2f011`（MIT）
**依赖**: C++20 编译器，无 ROCm / 无 GPU / 无第三方库
**结果**: 49,157 checks, 0 failures（`results/execution.log`，2026-11-14 容器 gfx-m1 / ROCm 10.1 内 g++）
**范围**: 提取的是**数学**（分块递推 + 快照语义 + 尾部钳制 + 槽间接）；设备的 MFMA 16×16 tile / 面板 swizzle / .buffer 寻址是 hardware 线细节，不在本 demo。

## 一、原理说明

Gated DeltaNet 的 prefill 路径：把 T 个 token 按 BT=64 分块，逐块维护
跨 token 的状态 H[V][K]（fp32 寄存器驻留，快照 bf16 落盘）。本 kernel
消费上游预处理产物 k/w/u/g（w/u 含分块内修正），执行**分块递推**：

```
H_pred[t][v] = Σ_kk W[t][kk] · H[kk][v]              # 状态对 token t 的预测
gated[t][v]  = (U[t][v] − H_pred[t][v]) · exp(g_last − g[t])
H[v][k]      = H[v][k] · exp(g_last) · gk_last[k]     # 旧状态衰减（gk 可选 per-key）
             + Σ_t K[t][k] · gated[t][v]              # delta 写入
```

- `g` 为**chunk 内累计**的 log-decay（chunk 边界重置）——kernel 的
  `exp(g_last)` 衰减只有在该契约下才是 chunk 相对的（测试 1 的生成器按此
  构造并钉死）。
- `exp(g_last − g_t)` = token t 到 chunk 末尾的衰减；gated 已含之，故旧
  状态衰减 `full` **只乘旧状态**，不再乘写入项（测试 3 的手工参考曾把
  衰减乘错侧——被值比对抓出）。

### 设计 [2]：快照语义（从存店顺序测得）

`store_chunk_hstate` 在**更新前**存店——`h[c]` = 进入 chunk c 的状态
（h[0] = 初始态 h0；h[c] = chunk 0..c-1 之后的态）；**终态单独存 ht**。
测试 2 钉死快照链。

### 设计 [3]：尾部 chunk

末 chunk 的 actual_bt < BT：W/K/U 的行 ≥ actual_bt 被零填充（load 零填）、
g_scale ≥ actual_bt 为 0——零行对 Kᵀ·gated 无贡献（测试 3 手工逐项验证）。

### 设计 [4]：状态槽间接

`initial_state_indices[batch] → 槽`（h0 载入）；负/哨兵索引 = 零初始态
（测试 4）——与 decode kernel 的槽语义同族。

## 二、测试清单（49,157 checks）

| # | 内容 | 判据 |
|---|---|---|
| 1 | 分块递推：矩阵路径 emu vs 逐对标量 naive（130 token = 2 整块 + 尾 2，双 head） | 末态 H 逐元素 ≤ 1e-3 rel |
| 2 | 快照链 | h[c] == 进入 chunk c 的状态（bf16 逐位） |
| 3 | 尾 chunk（actual_bt=2） | emu vs 手工逐项（含衰减侧修正） |
| 4 | 状态槽 | h0 快照逐位；哨兵槽零态 |

## 三、章程对照（10 项）

| 章程项 | 本 demo |
|---|---|
| 原理说明 | README §一 + 源文件头注释 |
| 上游出处 + commit | chunk_gated_delta_rule_fwd_h.cu @ 1eab5ae12，MIT |
| 独立实现 | 单 TU ~330 行：矩阵路径 emu + 逐对 naive，双计划互证 |
| 最小依赖 | C++20；CPU-only |
| Reference | gdr_decode_chain（decode 侧同族递推）；MFMA tile/swizzle 归 hardware 线 |
| Correctness Test | 4 组 49,157 checks |
| Build Script | `scripts/build_run.sh`；CMakeLists 亦可 ctest |
| Inspection | 双计划互证（矩阵 vs 逐对）+ 快照链逐位 + 手工逐项对照 |
| Hardware Matrix | 上游目标 gfx950 系（MFMA）；本 demo CPU 主机参考 |
| Execution Result | `results/execution.log`：49,157 checks, 0 failures |

## 四、复现

```bash
cd demos/algorithm/gdn_prefill_fwd_h && ./scripts/build_run.sh
# 或 CMake + ctest
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build && ctest --test-dir build
```
