# concat_and_cache_mla_seg — DSR1 MLA 分段分页 KV cache 写入家族主机参考

**类目**: algorithm · **验证级别**: SOURCE_VERIFIED + REFERENCE_PASS（纯 CPU 主机参考，无 GPU 执行声明）
**上游**: `aiter/csrc/kernels/cache_kernels.cu` 的 `concat_and_cache_mla_kernel` / `concat_and_cache_mla_seg_kernel` / `concat_and_cache_mla_seg_512_kernel` @ `1eab5ae12c93af3c8c660202d9a413f637c2f011`（MIT）
**依赖**: C++20 编译器，无 ROCm / 无 GPU / 无第三方库
**结果**: 70 checks, 0 failures（`results/execution.log`，2026-11-18 容器 gfx-m1 / ROCm 10.1 内 g++；ASAN+UBSAN 零报告）
**关联**: 与 dsv4_dequant_gather_k（DSV4 读侧，448+128 记录）不同栈——本 demo 是 **DSR1 MLA** 线（512 NoPE + 64 RoPE）；其读侧 = MLA attention（未做，见队列）

## 一、原理说明

### 设计 [1]：两种物理布局，同一逻辑内容

MLA token 的 KV 由两段组成：`kv_c`（NoPE 压缩 KV，kv_lora_rank=512）与
`k_pe`（解耦 RoPE，pe_dim=64）。写入分页 slot 时：

- **entry 交错布局**（`concat_and_cache_mla_kernel`）：`[block][entry][rank+pe]`
  每 token 一条拼接记录，偏移走运行时 block_stride/entry_stride；
- **分段布局**（seg 家族）：`block = [page×rank 区][page×pe 区]`，区**内**
  token 主序——nope 在 `block_idx·block_stride + block_offset·rank + i`，
  pe 在 `block_idx·block_stride + page·rank + block_offset·pe + i`。
  两布局逻辑内容相同、物理地址不同——分段布局是 MLA attention 读侧消费的
  形状（nope 区与 pe 区分别连续，利于读侧分区加载）。

### 设计 [2]：静态 scale 的"乘倒数"语义

量化是**每张量静态 scale**（单 float 指针），且 kernel 乘**倒数**：
`store = cast(v · (1/scale))`——不是 `v / scale`。1/scale 先舍入一次，
之后所有元素共享同一精确因子，与逐元素除法位级不同（demo 钉了乘法形式并
给出 `v·(1/49) ≠ v/49` 的具体位级差例）。kAuto 实例化存原值（cache_t =
bf16）不碰 scale。

### 设计 [3]：seg_512 的"先发射后寻址"负载调度（本 demo 的核心机制）

`concat_and_cache_mla_seg_512_kernel`（kv_lora 512 / pe 64 / page 64 编译期
常量、TPB tokens/block）与朴素 seg 写同一布局，差别只在**加载何时发射**：

- 朴素版一块一 token：lane 的单个 16B 加载排在 `slot_mapping[tok]` 读与
  **运行时 page_size 的 64 位除法**之后——源地址明明不依赖 slot；
- seg_512：所有源加载**先**发射（只依赖 token_idx），slot 查找（page 编译期
  64 ⇒ 除法变移位）与之重叠；一块 TPB 个 token，lane 携带 TPB 个 nope 向量
  （lane = 向量号，NUM_VEC = blockDim = 512/8 = 64）；
- **pe 按块摊开**：`pe_tok = tid/PE_CHUNKS, pe_chunk = tid%PE_CHUNKS`——
  每个 token 的 pe 由自己的 PE_CHUNKS 个 lane 持有，而非堆在 lane
  0..PE_CHUNKS−1，TPB 多大都不压栈。`TPB ≤ NUM_VEC/PE_CHUNKS`（=8）是
  static_assert（每 token 的 pe 需要专属 lane 组）。

宿主仿真忠实重演 issue→slot→emit 三相（发射相明确先于 slot 查找），与
朴素 seg 逐位对撞——**调度不同、输出必须相同**。

### 设计 [4]：编译期 page=64 的移位等价

`(slot/64 == slot>>6) && (slot%64 == slot&63)` 仅对 2 的幂 page 成立
（demo 给了 page=48 的反例）；seg_512 把 page 钉成 64 换取消除运行时除法
——朴素 seg 家族接受任意 page，两者靠 dispatch 配对。

## 二、测试清单（70 checks）

| 组 | 内容 | 结果 |
|---|---|---|
| 0 | 布局算术：block_stride=64·576、nope/pe 基址手算（slot 130 → block 2）、区不重叠有序、移位等价成立与反例、entry 偏移手算 | PASS |
| 1 | 量化语义：乘倒数形式钉死、`v·(1/49) ≠ v/49` 位级差例、kAuto 透传 | PASS |
| 2 | 跨调度位级：seg vs seg512（TPB 1/4/8）在含 pad/碰撞的 13-token job 上逐位相等；**去 pad 重跑 ⇒ cache 逐位不变**（pad 零贡献）；kAuto 跨调度相等 | PASS |
| 3 | 逻辑等价：entry 交错 vs 分段布局按 (slot, dim) 反量化逐位相同 + 段内值恰为量化源 | PASS |
| 4 | 随机主 sweep：8 配置（rank 64-512、pe 16-64、page 8-128 含非 2 幂 48、nb 2-4、tokens 7-33）× 3 种子 = 24 行 seg vs seg512 位级 + 每槽最终写入者的段首/段尾/pe 首值点检 | PASS |

## 三、发现与教训

1. **调度正确性与加载发射顺序解耦**：seg_512 的先发射后寻址是纯性能结构
   ——三 schedules（flat / issue-emit TPB 1/4/8）输出逐位相同是可断言的
   契约，与 M3 topk_plain 的"多策略同输出"同型。
2. **pe 摊开 vs 堆叠**：pe_lane 由 `tid/PE_CHUNKS` 决定，TPB ≤
   NUM_VEC/PE_CHUNKS 是"每 token 的 pe 需要专属 lane 组"的 static_assert
   ——摊开让发射相的 pe 加载与 nope 加载同相完成，堆叠会让大 TPB 的 pe
   加载串行。
3. **乘倒数 vs 除法的位级差**：`1/scale` 一次舍入 + 全体共享，是生产量化
   kernel 的普遍形态（与 M5-#2 的 scale=amax/FP8_MAX 后除法形态对照——
   两处取舍相反，各自成立）。
4. **slot 碰撞语义第三次出现**（M6-#1 后再次）：随机 slot_mapping 下值检
   查只对每槽最终写入者有效；pad token（slot=−1）全体同值，"pad 槽不被
   任何 token 写"的正确检查是**去 pad 重跑 ⇒ cache 不变**，而非同值扫描。
5. **关联地图**：DSV4 576B 记录（448 fp8 + 128 bf16，写侧 = hadamard_rotate
   quant，读侧 = dequant_gather_k）与 DSR1 MLA 576B（512 fp8 + 128 bf16，
   写侧 = 本 demo，读侧 = MLA attention，未做）是同字节数、不同分段的两代
   设计——读侧排进队列。

## 四、规格表

| 项 | 值 |
|---|---|
| Build Script | `scripts/build_run.sh`；CMakeLists 亦可 ctest |
| Inspection | 三调度对撞（flat / issue-emit×3）+ 双布局逻辑等价 + 乘倒数位级差例 |
| Hardware Matrix | 上游目标 gfx9 系；本 demo CPU 主机参考 |
| Execution Result | `results/execution.log`：70 checks, 0 failures |

## 五、复现

```bash
cd demos/algorithm/concat_and_cache_mla_seg && ./scripts/build_run.sh
# 或 CMake + ctest
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build && ctest --test-dir build
```
