# gdr_decode_chain — aiter Gated Delta Rule（GDR/GDN）decode 链的主机参考

**类目**: algorithm · **验证级别**: SOURCE_VERIFIED + REFERENCE_PASS（纯 CPU 主机参考，无 GPU 执行声明）
**上游**: `aiter/csrc/kernels/gdr_decode_packed_bf16.cu` + `csrc/kernels/fused_split_gdr_update.cu` @ `1eab5ae12c93af3c8c660202d9a413f637c2f011`（MIT, © AMD）
**依赖**: C++20 编译器，无 ROCm / 无 GPU / 无第三方库
**结果**: 8,470,774 checks, 0 failures（`results/execution.log`，2026-11-14 容器 gfx-m1 内 g++）

## 一、原理说明

Gated DeltaNet 的 decode 路径在 aiter 里有**两个互补 kernel**：
`gdr_decode_packed_bf16`（单 token，bf16 state 池，nontemporal 访问）和
`fused_split_gdr_update`（T 步链，fp32 state 常驻寄存器，swizzled state 池）。
两者实现**同一条 delta-rule 递推**，但调度与布局完全不同——本 demo 把它们
提取为两个结构忠实的主机仿真 + 一个朴素第三实现，三方互证。

### 递推（每 value-head，K=key 维，V=value 维）

```
decay    = exp(-exp(A_log) · softplus(a + dt_bias))
beta     = sigmoid(b)
k_n      = k / rsqrt(k·k + 1e-6)          （q 另乘 scale）
S_dec    = S · decay
residual = (v − S_dec·k_n) · beta
S_new    = S_dec + residual ⊗ k_n
out      = S_new · q_n
```

### 两条 schedule，一个恒等式

- **decode kernel**（代数拆分）：`out = sum_hq + residual·(k_n·q_n)`，
  其中 sum_hq = S_dec·q_n——**从不为输出重新推导 S_new**，省一次
  更新后的 state 读；
- **split kernel**（直读）：Phase 2 先更新寄存器里的 h_vec，Phase 3 直接
  `out = (S_new)·q_n`——state 全程住在 float4 寄存器里跨 T 步。

### 设计 [1]：XOR-butterfly 波内归约（ds_swizzle BITMASK_PERM）

decode kernel 的 `reduce_k` 用三步 `ds_swizzle`（xor 掩码 1/2/4，编码常量
`(N << 10) | 0x1f` 原样抄录）把 (v_idx) 组的 8 个 k-lane 在 log₂8 步内求和，
零 bank conflict、零 LDS 流量；split kernel 用 `__shfl_xor(16/32)` 在 64-lane
波内折叠 4 个 K-split（`lane>>4`）。本 demo 结构仿真其语义
（step m 后 lane i 持有 p[i] + p[i^m]）；**指令本身的编码/语义上卡验证归
M3 硬件探针 demo（ds_swizzle probe，待做）**。

### 设计 [3]：state 池布局

- decode：bf16 `[slot][HV][V][K]` 行主，`__builtin_nontemporal` load/store
  （streaming：每 decode 步触碰一次）；
- split：fp32 **swizzled** `[slot][HV][K/4][V][4]`——float4 片元把
  k = kg·4+f 打包，使每个 lane 的寄存器 tile 恰好是连续 float4。codec 的
  round-trip 测试钉死这个布局。

### 设计 [4]：sentinel/索引策略**不对称**（两 kernel 各自的观察契约）

- decode kernel：无效索引（负数**或** ≥ pool，unsigned cast 技巧）→
  输出写 0、**不碰 state**（batch padding 语义）。上游同时注释：有效
  slot 必须在 batch 内唯一，否则 workgroup 在 RMW 上竞争。
- split kernel：`idx >= 0` 只 gate state load/store；负索引 = "新序列起点"
  ——零初始 state、输出照算、slot 不动。

## 二、被测试钉死的约定

- mixed_qkv 打包 `[B][H·K q | H·K k | HV·V v]`；value head hv 的 q/k head
  = `hv / (HV/H)`（此处 4 个 v-head 共享一个 qk head）。
- decode kernel 把 beta **舍入到 bf16**（sigmoid → bf16 → f32）——刻意的
  精度钉；split kernel 不舍入。两边不对称，各自钉在对应参考里。
- softplus 两种表达式在调用方默认参数（beta=1, threshold=20）下数值一致。
- split kernel 的 use_vec2 LDS 装载 + `lds_padded_idx`（见下）。

## 三、调试史（本 demo 真实排错记录）

1. **segfault**：`DecodeState::slot_words` 把布局算成
   `(slot·VH + v)·VD·KD`——v 已含 VD 因子，被重复乘 → 越界 70M 字。
   正确：`(slot·VH·VD + v)·KD + k`。
2. **swizzle codec 环回失败**：pack/unpack 的 row-major 地址漏了 `+ v·KD`
   ——所有 v 折叠进首行，pack 用 127 个 v 反复覆盖同一地址。
3. **chain 输出爆炸（1e16/NaN）**：split 打包维写成 `2·KD + VD = 384`，
   而上游 `dim == 2·key_dim + value_dim` 中 value_dim = **HV·V = 4096**
   （共 4352）——hv ≥ 1 的 v 读取越界（std::vector operator[] 无检查，
   读到堆垃圾 → 归一化后爆炸）。教训：上游 host 校验
   `AITER_CHECK(dim == 2*key_dim + value_dim)` 本身就是布局契约的一部分。
4. **writeback 丢 v**：split 仿真的最终 state 写回同样漏 `v·KD`。
5. **仿真先写后加 double-count**：decode 仿真的首循环用未归一化 k 累加
   sum_hk，归一化后又累加一次——上游 kernel 是先归一化再累加，仿真必须
   忠实于这个顺序。

## 四、文件与验证对照（章程 10 项）

| 章程项 | 本 demo |
|---|---|
| 原理说明 | 本 README §一 + `src/gdr_decode_chain.cpp` 头注释 |
| 上游出处 + commit | 两个 .cu @ 1eab5ae12，MIT |
| 独立实现 | 单 TU ~980 行：结构仿真 ×2 + 朴素参考 ×1（三方互证），不链接 aiter_ref |
| 最小依赖 | C++20；CPU-only |
| Reference | DPP/shuffle 硬件语义归 `warp_sync`；ds_swizzle 指令探针归 M3 硬件队列 |
| Correctness Test | 5 组 8,470,774 checks（见 §五） |
| Build Script | `scripts/build_run.sh`（g++ 直编 + 日志落 results/；CMakeLists 亦可 ctest） |
| Inspection | XOR butterfly 负对照（漏 xor2 必须不折叠）+ 结构分解 vs 朴素参考差分定位 |
| Hardware Matrix | 上游目标 MI300 级（gfx950 系）；本 demo CPU 主机参考，未声明任何 HIP 执行 |
| Execution Result | `results/execution.log`：8,470,774 checks, 0 failures |

## 五、测试清单

| # | 内容 | 判据 |
|---|---|---|
| 1 | XOR butterfly：8-lane（xor1/2/4）与 64-lane k-split（xor16/32） | 每 lane == 组和；**负对照**：漏 xor2 不折叠 |
| 2 | decode 单步：lane 分解仿真 vs 朴素参考 | out + next-state 相对 1e-5；sentinel 行输出恒 0；未引用 pool slot 零填充 |
| 3 | fp32 swizzled state 池 codec round trip | 逐字 memcmp |
| 4 | T=4 步链：寄存器 state + swizzled pool vs 朴素链 | out + final state 相对 1e-4；sentinel 行非零输出（零初始 state）；未写 slot 位级不变 |
| 5 | LDS bank padding `idx + idx/CHUNK`（stride 33） | 单调有界；行 r 起点 bank ≡ r；固定列跨 32 行触达全部 32 bank |

## 六、复现

```bash
cd demos/algorithm/gdr_decode_chain && ./scripts/build_run.sh
# 或 CMake + ctest
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build && ctest --test-dir build
```
