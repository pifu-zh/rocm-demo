# reshape_and_cache_block_quant — vLLM 式 KV 块量化写入（重缩放回写契约）主机参考

**类目**: algorithm · **验证级别**: SOURCE_VERIFIED + REFERENCE_PASS（纯 CPU 主机参考，无 GPU 执行声明）
**上游**: `aiter/csrc/kernels/cache_kernels.cu` 的 `reshape_and_cache_with_block_quant_kernel`（522-768 行）+ host 入口（4815 行）@ `1eab5ae12c93af3c8c660202d9a413f637c2f011`（MIT）
**依赖**: C++20 编译器，无 ROCm / 无 GPU / 无第三方库
**结果**: 39 checks, 0 failures（`results/execution.log`，2026-11-22 容器 gfx-m1 / ROCm 10.1 内 g++；ASAN+UBSAN 零报告）

## 一、原理说明

### 设计 [1]：CTA 拥有物理块（而非窗口）

grid = (batch, ceil(seq/bs) **+ 1**, heads)——多出的第 windows 个 grid.y 是
**尾守卫**：瞄准批末 token 的物理块，若最后一个完整窗口的首 token 已在该
块（preTg == block_idx）则直接返回。连续 slot 机制下窗口首 token 恰差 bs
个 slot ⇒ 窗内不可能重复；守卫跳过是 kernel 唯一的去重。

一个 CTA 处理**一个物理块**：窗口首 token 的 slot 落在块中段（block_offset
> 0）时，向前扫 slot_mapping（threads < bs，token = first − tid − 1）找进
块边界，把 first_token_idx 重定到块的首个 call token。**回扫在公共路径**
（守卫 CTA 也做；窗口 0 不会需要——批首 token 天然是其块的首 call token）。

### 设计 [2]：重缩放回写契约（本 demo 的核心）

`numtokens_in_block` = 本次调用中 slot 落入本块的 token 数；amax **只覆盖
本次调用的 token**（种子 kAmaxFloor = 1e-10，与 a8w8 融合 kernel 同常数）；
s_new = amax/dtypeMax（fp8 = 448）。block_offset > 0（前次调用的条目已在
块内）时：

- **s_old < s_new**：旧区 [0, block_offset) 原位重写为
  `cast(cast_f32(old)·s_old/s_new)` 并采纳 s_new——旧条目带上**复合的双重
  量化误差**，块 scale 单调上升；
- **s_old ≥ s_new**：保留更细的 s_old，新 token 用它量化——scale 跨调用
  **永不下降**；
- **block_offset == 0**：无条件写 s_new（新块；陈旧 scale 弃用）。

旧条目的真实值**不参与 amax**——块 scale 是"本调用 token + 旧 scale"的
函数。存储 = v·(1/scale)（又是倒数乘法，M6-#2 同款）后 RNE satfinite。

### 设计 [3]：三套布局 + 两种 scale 索引

- K `[nb, nh, hs/x, bs, x]`：((blk·nh+h)·(hs/x)+d/x)·bs·x + bol·x + d%x；
- V plain `[nb, nh, hs, bs]`：((blk·nh+h)·hs+d)·bs + bol；
- V asmLayout `[nb, nh, bs/x, hs, x]`：((blk·nh+h)·(bs/x)+bol/x)·hs·x +
  d·x + bol%x（token 按 x 因子化——与 M6-#1 fused kernel 的 V 布局同族）；
- scale 索引：plain h·nb+blk，asmLayout blk·nh+h。

### 设计 [4]：count-vs-iterate 假设（caller 契约）

计数循环按 slot 逐个判断块归属，amax/store 循环却按**连续 token** 迭代
（id/head_size + fti）——两者一致的前提是块内 call token 恰为从块首开始
的连续段（vLLM prefill 按序列连续追加 slot 的模式）。任意 slot 置换是该
契约的静默违反。padding 语义见发现 [1]。

## 二、测试清单（39 checks）

| 组 | 内容 | 结果 |
|---|---|---|
| 0 | 布局算术：K/V-plain/V-asm 偏移手算、双 scale 索引、blockDimx 上取整、窗口数 | PASS |
| 1 | 重缩放契约：全零组 floor scale（=1e-10/448）+ 零条目；**增长场景**（旧区重量化，decode(after)·s₂ ≈ decode(before)·s₁ 界内）+ scale 上升；**收缩场景**（scale 保持、旧字节位级不动、新条目用旧细 scale）；四次调用单调性 | PASS |
| 2 | 窗口 vs 平坦位级对撞：seq 13 跨块+跨批+中段起始（offset 5）、seq 5 ≤ bs 单窗口守卫跳过（恰一块带 scale）、**asmLayout 变体**、**中段 padding 语义钉死**、整窗 padding 全零 | PASS |
| 3 | 随机主 sweep：6 配置（bs 4-12、seq 3-14、双批、asm 交替、中段起始）windowed vs flat 位级 + 每条目 decode 界 | PASS |

## 三、发现与教训

1. **中段 padding 不被跳过（真发现）**：slot < 0 只在**窗口首 token**（CTA
   级）检查；窗口中间的 pad 经 C++ 向零截断 `(-1)/bs == 0` 被算进 block 0，
   **pad token 的数据照常写入 cache**——与 concat_and_cache_mla 家族的
   per-token `if(slot_idx < 0) return` 截然不同。上游调用方约定块量化
   prefill 窗口内无 pad；任何把两家族 padding 语义互相类推的复用都会错。
2. **连续 slot 机制下的窗口不相交性**：相邻窗口首 token 恰差 bs 个 slot ⇒
   必属不同物理块，窗内重复不可能；守卫的 preTg 比较是唯一需要的去重——
   kernel 的并发正确性论证依赖这一数据布局性质，而非锁或原子。
3. **scale 单调性是复合误差的代价上界**：旧条目经第二次量化（decode→乘比
   →RNE），误差 ≤ 半新 ulp；永不下降的 scale 保证重量化比值 ≤ 1（不溢出）。
   "块 scale 是时间单调函数"使任意读侧反量化（M5-#1 的 decode gather、
   M6-#3 的 split-KV 解码）只需存里的 scale 而无需写序知识。
4. **amax 不含旧条目**：重缩放路径不重评旧值——极端场景（旧块曾有近满幅
   值、本次 amax 更大）下旧条目重量化后信息损失不变（比值 ≤1 不截顶），
   但旧条目的量化细度永久绑定在其写入时的 scale 上。
5. **测试教训**：flat schedule 的目标推导初版试图复用窗口机器（绕且错），
   重构为"共享量化主体 + 两条独立的目标/参数推导路径"——对撞的意义在推
   导路径不同，而非主体抄两遍。

## 四、规格表

| 项 | 值 |
|---|---|
| Build Script | `scripts/build_run.sh`；CMakeLists 亦可 ctest |
| Inspection | 双调度位级对撞（窗口机器含守卫/回扫 vs 平坦直接推导）+ 重缩放双向场景 + decode 界 |
| Hardware Matrix | 上游目标 gfx9 系；本 demo CPU 主机参考 |
| Execution Result | `results/execution.log`：39 checks, 0 failures |

## 五、复现

```bash
cd demos/algorithm/reshape_and_cache_block_quant && ./scripts/build_run.sh
# 或 CMake + ctest
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build && ctest --test-dir build
```
