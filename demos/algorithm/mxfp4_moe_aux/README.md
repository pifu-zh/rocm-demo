# mxfp4_moe_aux — aiter MXFP4 MoE 辅助调度流水线的主机参考

**类目**: algorithm · **验证级别**: SOURCE_VERIFIED + REFERENCE_PASS（纯 CPU 主机参考，无 GPU 执行声明）
**上游**: `aiter/csrc/kernels/mxfp4_moe/moe_aux/*.cuh` @ `1eab5ae12c93af3c8c660202d9a413f637c2f011`（MIT, © AMD）
**依赖**: C++20 编译器，无 ROCm / 无 GPU / 无第三方库
**结果**: 8237 checks, 0 failures（`results/execution.log`，2026-11-14 容器 gfx-m1 / ROCm 7.2.4 镜像内 g++）

## 一、原理说明

MoE 推理的"算子主体"（专家 GEMM）之前/之后有一圈辅助调度：把 token 按
expert 分桶（排序）、量化激活（MXFP4）、把专家输出散射回 token（scatter）。
aiter 把这三件事做成 mx 大小的 HIP kernel（几百行 .cuh），但它们的设计
本质是**调度契约**而非硬件技巧——恰好适合提取为确定性主机参考，用来钉死
上游 kernel 之间隐含的二进制约定。

三个独立可提取的设计 + 一个尾声：

1. **3-stage 多 CTA 排序**（`moe_3stage_sort.cuh`）
   - N_CTAS 个 CTA 各写一张部分直方图 `block_offsets[e][cta]`；
   - 单 CTA 阶段折叠成 per-(expert, cta) 起始偏移，并把每个 expert 段
     MB-pad 到块边界（`ceil(count/MB)*MB`）；
   - place+pad 阶段用 atomicAdd 游标把 pair 放进槽位，尾部填 sentinel。
   - 确定性来自"两阶段前缀和 + 段内游标"，而非单线程全局排序。

2. **单 CTA 排序**（`moe_sort_quant.cuh` 的 `sort_subkernel`）
   - int4 向量化计数（一 lane 读 4 个 id）、两级 DPP 包容扫描（本 demo
     语义仿真；DPP 指令本体是 `demos/emulation/warp_sync` 的领域）、
     atomicAdd 游标放置、gap 填充；
   - EP（专家并行）支持：`num_local_tokens` 之后的 pair 在
     `reverse_sorted` 写 -1（un-routed）。
   - 与设计 1 在确定性主机上产生**逐位相同**输出——同一契约的两个独立
     实现，比"实现 vs 参考"更强的互证。

3. **融合量化**（`quant_impl`，gfx950 路径）
   - bf16 amax 用**位模式取最大**（`bits & 0x7FFF` 后当无符号整数比）：
     对同号 bf16，位序=数值序，一次整数 max 完成_abs+max_；
   - 4-lane DPP max 归约（本 demo 语义仿真）；
   - **无分支 ceil 比例**：`scale = ((bits(amax * f32(1/6)) + 0x7FFFFF) >> 23) & 0xFF`。
     原理：f32 位模式对同号数单调；乘 f32(1/6)（≥ 真 1/6，不会低估）后，
     给尾数加 `2^23-1` 再右移 23 位 = 只要尾数非零就进位到下一个指数边界
     ——一次整数加法算出 `ceil(log2(amax/6))` 的指数域字节（e8m0）。
   - E2M1 nibble 编码：本 demo 用实验室 RNE 编码器作为 gfx950 硬件 cvt
     （`__builtin_amdgcn_cvt_scalef32_pk_fp4_bf16`）的文档化替代——上游在
     非 gfx950 上直接 `__builtin_trap()`，即**该算子没有 CPU 回退**，
     契约只能靠这种参考钉死。

4. **scatter_reduce 尾声**（`moe_scatter_reduce.cuh`）
   - `out[t] = Σ_i w[reverse[t,i]] · flat_out[reverse[t,i]]`，跳过 -1；
   - bf16 路径：`(bits & 0xFFFF) << 16` 解码 + fmaf；
   - mxfp4 路径：e8m0 比例按 **4-per-u32** 打包（块 `blk` 的字节在
     `u32 @ (blk & ~3)` 的第 `blk & 3` 字节），nibble 按 8-per-u32 解码。

## 二、被测试钉死的二进制约定（含一个上游未文档化约束）

- `sorted_token_ids` 打包 `(token & 0xFFFFFF) | (topk & 0xFF) << 24`。
- `m_indices`：真槽位 = token，PAD 槽位 = **M 本身**当 sentinel——下游
  GEMM 用 buffer_load 且 voff 超界后硬件丢弃该 load（上游
  `moe_3stage_sort.cuh:150-152` 与 `fill_padding_gaps` 依赖此行为）。
- `reverse_sorted` 是逆置换；un-routed pair 为 -1。
- expert 段 MB-pad；设备上段内顺序来自 atomicAdd 游标（非确定），主机
  参考是升序确定——因此**上机对比必须按段 multiset，不能逐元素**
  （与 moe_align 同纪律）。
- **隐式上游约束（violation 发现，非文档）**：mxfp4 比例的 u32 读横跨
  4 个连续 32 列块（`blk & ~3`），故 `d_hidden/32` 必须是 4 的倍数，
  即 **`d_hidden % 128 == 0`**；上游只 static_assert `D % 8 == 0`——
  `D_HIDDEN = 32` 时会读到下一行的比例 / 越界。

## 三、方法学发现：oracle 一致性 ≠ 正确性

本 demo 的 E2M1 编码器初版有真实 bug：RNE 循环比较**有符号**距离
`d = mag - vals[c]` 而非绝对距离。因 `vals` 单调递增、`d` 严格递减，
`d < best_d` 每轮必胜——循环永远停在最远的 c=7。编码器把一切未饱和
输入映射成 `sign(x)·6`。

能抓住它的只有测试 3（契约检验：`err ≤ 3·qs`）；测试 4b 反而 PASS，
因为它的 oracle 在**量化域逐位精确**——消费同一个编码器的输出。教训
（已写入实验室方法）：

> 由同一实现构造的 oracle 只验证一致性；跨实现的独立契约测试才验证
> 正确性。量化域 oracle 必须与独立契约测试配对存在。

修复后 11 个定向 RNE 钉子（中点 tie→偶数码、-0 保号、satfinite 边界）
补上随机数据几乎不会命中的语义角。worst err/3qs = 0.323，贴着理论上限
1/3（4 与 6 之间半间隙 = 1·qs）——物理一致。

## 四、文件与验证对照（章程 10 项）

| 章程项 | 本 demo |
|---|---|
| 原理说明 | 本 README §一 + `src/mxfp4_moe_aux.cpp` 头注释（49 行） |
| 上游出处 + commit | `moe_aux/{moe_3stage_sort,moe_sort_quant,moe_scatter_reduce}.cuh` @ 1eab5ae12，MIT |
| 独立实现 | 单 TU 640 行，不链接 aiter_ref（独立性 = 特性） |
| 最小依赖 | C++20；CPU-only |
| Reference | 上游头文件逐条对应；DPP 归 `warp_sync`、硬件 cvt 归 `soft_fp4` |
| Correctness Test | 6 组 8237 checks + 跨验证 e2m1_crosscheck（三方 271,844 有限值逐位一致，见下） |
| Build Script | `scripts/build_run.sh`（g++ 直编 + 日志落 results/；CMakeLists 亦可 ctest） |
| Inspection | 变体互证（1）+ 逆置换/multiset（2）+ 契约/钉子（3）；ISA 层归 compiler/hardware 类 demo |
| Hardware Matrix | 上游目标 gfx950（MI300）cvt + ROCm 7.x；本 demo CPU 主机参考，未声明任何 HIP 执行 |
| Execution Result | `results/execution.log`：8237 checks, 0 failures |

## 五、测试清单

| # | 内容 | 判据 |
|---|---|---|
| 1 | 3-stage vs 单 CTA 逐位一致 | 两种实现同一契约 |
| 2a | `reverse_sorted` 是逆置换 | `sorted[reverse[p]] == p` |
| 2b | 段 multiset + PAD sentinel + 块一致 | 按 expert 段配对集合相等；PAD 槽 m_indices == M |
| 3 | 量化契约：scale ∈ [0,254]、`err ≤ 3qs`、11 个 RNE 钉子 | 独立契约测试 |
| 4a | scatter_reduce bf16 vs 独立 oracle | bf16 域逐位 |
| 4b | scatter_reduce mxfp4 vs 量化域 oracle | 逐位精确（配对 3 使用） |
| cross | 三方 E2M1 编码器（aiter FlyDSL / cuda-oxide / lab）在 f16 全格点 + 8 边界 ±512 ulp + 非正规 + NaN 上对撞 | 有限值三方逐位一致；NaN 策略分歧已记录（lab 负 NaN → 正 0x7） |

## 六、复现

```bash
# 容器内（或任何有 g++ 的机器）
cd demos/algorithm/mxfp4_moe_aux && ./scripts/build_run.sh
# 或 CMake + ctest
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build && ctest --test-dir build
```
