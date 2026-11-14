# causal_conv1d_update — Mamba 式因果一维卷积 decode 更新的主机参考

**类目**: algorithm · **验证级别**: SOURCE_VERIFIED + REFERENCE_PASS（纯 CPU 主机参考，无 GPU 执行声明）
**上游**: `aiter/csrc/kernels/causal_conv1d_update.cu` @ `1eab5ae12c93af3c8c660202d9a413f637c2f011`（MIT；Tri Dao causal-conv1d 的 AMD 适配）
**依赖**: C++20 编译器，无 ROCm / 无 GPU / 无第三方库
**结果**: 377 checks, 0 failures（`results/execution.log`，2026-11-14 容器 gfx-m1 / ROCm 10.1 内 g++）

## 一、原理说明

Mamba 式模型的 decode 路径每次只喂 1~几个新 token，但因果卷积需要
width-1 个历史值——`conv_state` 滑窗缓冲就是为此存在的。kernel 每
(batch, dim) 通道一个 CTA，维护 `conv_state[batch][dim][state_len]`，
一次调用完成"读历史 → 卷积 → 写新 token 入状态"三件事。

### 设计 [1]：非循环模式的**两遍守卫式搬移**

```
pass 1: state[i] = state[i + seqlen]        (i < len - seqlen - (width-1))
pass 2: { read state[len-(width-1)+i];      ← x_vals 窗口种子在此捕获
          if (guard) state[len-seqlen-(width-1)+i] = 同值; }
token loop: state[len-seqlen+i] = x_i（尾部写入） + 滑窗卷积
```

- **x_vals 种子必须在 pass 2 循环内部**（读写在同一循环、写前读）——拆出
  来的独立种子循环会读到搬移后的值，把最后一个 token 复制进卷积窗口，
  call-1 输出全错（本 demo 调试链的根因，见 RESULTS.md）。
- 守卫条件 `i < seqlen + (width-1) && position >= 0` 把 pass-2 的写位置
  钳制在合法几何内——**对任意 seqlen（含 > state_len）都能正确落位**
  （本 demo 最初假设"seqlen > width-1 时中段腐坏"被自己的检查证伪并撤回）。

### 设计 [2]：循环（ring）模式

`cache_seqlens[batch]` 是运行长度，写游标 = `cache_seqlens % state_len`；
新 token 直接写游标处并推进，无搬移；卷积读游标**后方** width-1 个历史值
（环绕取模）。游标由调用方逐次维护。

### 设计 [3]：连续批处理（continuous batching）间接

`conv_state_indices[batch] → 状态槽`；映射到 `pad_slot_id` 的行其 CTA
**早退**（状态与输出都不触碰——输出由调用方预填）。两行可共享同一槽
（宿主确定性下"最后写者胜"，上游只保证状态 RMW 的槽内唯一性）。

## 二、测试清单（377 checks）

| # | 内容 | 判据 |
|---|---|---|
| 1 | 非循环：12 次 decode 调用流 × 宽度 2/3/4 × 两种状态几何 × SiLU 开关 | 输出与状态 vs 朴素参考（朴素 = 无界历史 deque + 直接卷积） |
| 2 | 循环 ring：宽度 2/3/4 × 16 次调用，环绕游标 | 输出 vs 朴素 |
| 3 | 连续批处理：槽间接 + pad 跳过 + 共享槽 | 输出 vs 每槽朴素 |
| 4 | 大 seqlen（3/4/6 > width-1）状态卫生 | 输出与状态均 vs 朴素（"中段腐坏"假设被此检查证伪并撤回） |

## 三、调试链（两个真实 bug + 一个被证伪的假设）

1. **emu 的 x_vals 种子拆出了 pass-2 循环**——读到搬移后的状态，末 token
   重复进窗（call-1 输出错）。kernel 的三合一循环（读→写→记录）是承重
   结构，重构时不可拆。
2. **校验表达式对 37-取模源模式不成立**：`src[i%32]` vs 实际拷贝的
   `src[i]`——sm2 最小复现 PASS 是其源模式恰为 32 周期的巧合。
3. **"seqlen > width-1 中段腐坏"假设被证伪**：大 seqlen 下输出与状态均
   与朴素一致——两遍守卫式搬移完全健全，假设撤回（检查本身保留为回归
   钉子）。

## 四、章程对照（10 项）

| 章程项 | 本 demo |
|---|---|
| 原理说明 | README §一 + 源文件头注释 |
| 上游出处 + commit | causal_conv1d_update.cu @ 1eab5ae12，MIT |
| 独立实现 | kernel 忠实仿真 + 朴素第三实现，单 TU ~330 行 |
| 最小依赖 | C++20；CPU-only |
| Reference | GDN decode 链（同族 Mamba 式状态机制）、cud-oxide 无对应 |
| Correctness Test | 4 组 377 checks |
| Build Script | `scripts/build_run.sh`；CMakeLists 亦可 ctest |
| Inspection | 双变体互证（状态缓冲机制 vs 无界历史）+ 守卫几何边界（大 seqlen） |
| Hardware Matrix | 上游目标 gfx10/9 系；本 demo CPU 主机参考，未声明任何 HIP 执行 |
| Execution Result | `results/execution.log`：377 checks, 0 failures |

## 五、复现

```bash
cd demos/algorithm/causal_conv1d_update && ./scripts/build_run.sh
# 或 CMake + ctest
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build && ctest --test-dir build
```
