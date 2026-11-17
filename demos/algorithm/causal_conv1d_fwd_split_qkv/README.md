# causal_conv1d_fwd_split_qkv — prefill 因果卷积 + 融合 split q/k/v 输出的主机参考

**类目**: algorithm · **验证级别**: SOURCE_VERIFIED + REFERENCE_PASS（纯 CPU 主机参考，无 GPU 执行声明）
**上游**: `aiter/csrc/kernels/causal_conv1d_fwd_split_qkv.cu` @ `1eab5ae12c93af3c8c660202d9a413f637c2f011`（MIT）
**依赖**: C++20 编译器，无 ROCm / 无 GPU / 无第三方库
**结果**: 9 checks, 0 failures（`results/execution.log`，2026-11-18 容器 gfx-m1 / ROCm 10.1 内 g++）

## 一、原理说明

### 设计 [1]：(sequence, chunk) 展平调度解码

grid.x 索引一个展平的 (序列, 块) 调度：`batch_ptr[pid]` 给序列号，
`token_chunk_offset_ptr[pid]` 给块号；块长 TM（设备模板 {8,16,32,64}，此处
32），`tok_start = chunk * TM`，块内 token 数 `count = min(TM, seqlen -
tok_start)`。每个 `(pid, gfeat)` 对完全独立——深度逐通道因果卷积，无跨
feature 通信。

### 设计 [2]：深度因果卷积 + SiLU（宽度 4）

```
acc = bias + w0·x[t-3] + w1·x[t-2] + w2·x[t-1] + w3·x[t]
out = silu(acc)，bf16 写出
```

w 与 bias 在上游均为 **bf16**（两个 bf16 打包进一个 uint 读出再逐个解码）。
滑窗以寄存器轮转 x0←x1←x2←x3 完成，每 token 一次乘加链。

### 设计 [3]：初始状态窗口与无冒险性（本 demo 的关键发现）

token 起始 < 3 的窗口来自 `conv_states[slot][gfeat][0..2]`
（slot = cache_indices[seq]，has_initial_state 门控；无初始状态则窗口为
零）。**tok_start ≥ 3 的块直接从 x 读窗口——块 ≥ 1 从不触碰状态**，因此
多块序列的各 CTA 之间不存在对 conv_states 的读写冒险，无需任何块间同步。
这是展平 (seq, chunk) 调度能成立的结构前提。

### 设计 [4]：split 输出路由

全局 feature gfeat 按三分段路由到三个独立张量，每个 `[T, k_dim]`
token 主序：

| gfeat 范围 | 张量 | 局部 feature |
|---|---|---|
| `< k_dim` | q_out | gfeat |
| `< 2·k_dim` | k_out | gfeat − k_dim |
| 其余 | v_out | gfeat − 2·k_dim |

（输出张量带运行时 stride，本参考取连续布局。）

### 设计 [5]：尾状态契约——恰一个 CTA 更新，且读的是全序列

**只有 chunk 0** 的 CTA 更新 conv_states，且写的是**整个序列**的最后
min(3, …) 个 token（跨出自己的块范围读 x）：

- `seqlen ≥ 3`：x 的末 3 个 token **原样 bf16 透传**（不经过卷积/量化）；
- `seqlen == 1`：状态 = [旧1, 旧2, x[seq_start]]（旧状态滑移一格）；
- `seqlen == 2`：状态 = [旧2, x[seq_start], x[seq_start+1]]（滑移两格）；
- `has_initial_state == 0` 时滑移前先把旧状态清零。

短序列分支里 kernel 读了 old0 却从不使用（死变量），参考实现照实省略并
注释。语义：prefill 结束后 conv_states 恰好是喂给下一轮 decode
causal_conv1d_update 的"序列末 3 个输入 token"。

### 设计 [6]：pad 序列跳过

`cache_indices[seq] == pad_slot_id` 的 CTA 在任何读写之前返回——pad 序列
的输出张量与状态槽完全不被触碰。

## 二、测试清单（9 checks）

| # | 测试 | 验证内容 | 结果 |
|---|---|---|---|
| 0a | 调度解码有序性 | 每个 (seq, chunk) 恰出现一次、块号 0,1,2… 有序 | PASS |
| 0b | 调度全覆盖 | Σ min(TM, seqlen−c·TM) = T（170 token） | PASS |
| 1a | **双计划位级对撞** | run_chunked（kernel 的块调度）vs run_flat（单遍滑窗）在 T=170、dim=48 的 q/k/v 全部 **u16 位级相等**（两计划同序同 float 运算，容差比较反而更弱） | PASS |
| 1b | 尾状态契约 | conv_states = 每序列末 3 个 x token（原样透传） | PASS |
| 2a | pad 跳过 | pad 序列输出保持哨兵值 0xDEAD | PASS |
| 2b | pad 不误伤 | 非 pad 槽 0 的状态仍正确更新 | PASS |
| 3a | seqlen 1 滑移 | 状态 = [旧1, 旧2, x0] | PASS |
| 3b | seqlen 2 滑移 | 状态 = [旧2, x0, x1] | PASS |
| 3c | 短序列双计划对撞 | 恢复初始状态快照后 flat 与 chunked 位级相等 | PASS |

## 三、发现与教训

1. **"恰一个 CTA 写状态"的非对称设计**：尾更新不在最后一个块（那需要
   块间顺序假设），而是固定由 chunk 0 承担并跨块读全序列——调度表里
   chunk 0 的存在性与状态正确性绑定。参考实现最初假设"每块写自己的尾、
   后者覆盖"，被源码证伪。
2. **块 ≥ 1 不读状态** ⇒ 展平调度天然无状态冒险。任何把窗口统一改为
   "从状态读前 3 token"的"简化"都会引入块间顺序依赖——上游的窗口来源
   二分（x vs 状态）是性能与正确性的联合设计。
3. **测试顺序即正确性**：run_chunked 的尾契约会变更 conv_states；随后
   跑 run_flat 必须恢复初始快照，否则两组输出初窗不同、全量位级失配
   （曾以 144/144 失配呈现——失配率 100% 本身就是"初窗不同"的诊断信号，
   而非数值 bug）。
4. **位级 oracle 的适用条件**：两计划对每个 token 执行完全相同的浮点
   运算序列（同窗口、同乘加顺序、同激活），位级相等可作硬断言；容差
   比较在这里是更弱的 oracle。

## 四、规格表

| 项 | 值 |
|---|---|
| Build Script | `scripts/build_run.sh`；CMakeLists 亦可 ctest |
| Inspection | 双计划位级对撞 + 尾状态契约（seqlen ≥3/==1/==2 三分支）+ pad 跳过 |
| Hardware Matrix | 上游目标 gfx10/9 系；本 demo CPU 主机参考 |
| Execution Result | `results/execution.log`：9 checks, 0 failures |

## 五、复现

```bash
cd demos/algorithm/causal_conv1d_fwd_split_qkv && ./scripts/build_run.sh
# 或 CMake + ctest
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build && ctest --test-dir build
```
