# fused_qk_norm_rope_cache_quant — 解码路径融合 kernel（QK norm + RoPE + fp8 量化 + 分页 KV 写入）主机参考

**类目**: algorithm · **验证级别**: SOURCE_VERIFIED + REFERENCE_PASS（纯 CPU 主机参考，无 GPU 执行声明）
**上游**: `aiter/csrc/kernels/fused_qk_norm_rope_cache_quant.cu` 的 `fusedQKNormRopeQuantCacheShuffleKernel` @ `1eab5ae12c93af3c8c660202d9a413f637c2f011`（MIT）
**依赖**: C++20 编译器，无 ROCm / 无 GPU / 无第三方库
**结果**: 110 checks, 0 failures（`results/execution.log`，2026-11-18 容器 gfx-m1 / ROCm 10.1 内 g++；ASAN+UBSAN 零报告）

## 一、原理说明

### 设计 [1]：一 warp 一 (token, head) 的融合调度

全局 warp 序号展平 q/k/v 头表（`globalWarpIdx = token·(nhq+nhk+nhv) + localHeadIdx`），
每 lane 拥有 head_dim/32 个连续维（head_dim 必须是 32 的倍数，dispatch 强制）。
Q/K 头走 RMSNorm → RoPE → **写回激活数组（就地）**；K 头追加 fp8 量化 + 分页
cache 写入；V 头跳过 norm/rope 直接量化写入。

### 设计 [2]：shfl_xor 伙伴 lane 半旋 RoPE（本 demo 的核心机制）

NeoX 式半旋通过 warp 交换完成：`partner_lane = laneId ^ (embed_dim / E)`
（E = head_dim/32）。正确性依据：参与交换的 lane 恰为 `[0, 2δ)`（dims <
rotary_dim），其中 δ = embed/E 是 2 的幂 ⇒ 对 L < δ，xor = L+δ（无进位借位）；
对 δ ≤ L < 2δ，bit log2(δ) 必置位 ⇒ xor = L−δ。前半 dims 拿到 partner 取负
（x·cos − x[d+embed]·sin），后半直接用（x·cos + x[d−embed]·sin）。

**约束**：`(rotary_dim/2) % E == 0` 只保证 δ 是整数，**δ 还必须是 2 的幂**——
rotary 96 / head_dim 128 时 δ=12（两位），lane 8 的 xor(12)=4 ≠ 8+12：静默
错旋。demo 用构造案例证实此形状下 xor 仿真与 ±embed 索引参考**发散**，而
rotary 64（δ=8）位级一致——dispatch 的守卫并不充分，调用方形状须自守。

cos/sin cache 行布局 = [cos(embed) | sin(embed)]；dims ≥ rotary_dim 不动；
interleave（GPT-J 配对）分支为纯本地运算无交换。

### 设计 [3]：每 (token, head) fp8 量化 + 双 cache 布局

- amax：K 头取**后 norm-rope** 元素、V 头取原始元素的 |max|（蝴蝶归约）；
  下限 kAmaxFloor = 1e-10（与 ATOM 的 AMAX_FLOOR 同源，保证全零组有限非零
  scale）；scale = amax / dtype_max（fp8 e4m3 OCP host 分支 = 448；e5m2 =
  57344 参数化验证）；store = v / scale。
- scale 数组布局 [block][head][block_offset]（head 步长 page_size）。
- K cache `[nb, nhk, head_dim/x, page, x]`（dim 主 x 因子化）；V cache
  `[nb, nhv, page/x, head_dim, x]`（token 按 x 打包——"not contiguous on
  head_dim"故无向量化 store）。两个实现用加法偏移 vs 混合基数二维化两套
  独立索引算术对撞。
- kAuto 模式存原值不写 scale；slot < 0（padding）跳过 cache/scale 写但
  **保留 Q/K 写回**。

### 设计 [4]：双实现对撞（同浮点序、异机器结构）

run_emul（per-lane 数组 + 每步显式快照 + 加法偏移）vs run_reference（单一
flat 数组即快照 + 平坦伙伴索引 + 混合基数偏移）。两者每 token 每维执行完全
相同的浮点运算序列，位级相等 ⇒ 被验证的是 lane 所有权、xor 交换、cache 索
引这些"机器"，而非舍入。fp8 编解码用 lab 已穷举验证的原语；往返界检查
（|v − decode(cast(v/scale))·scale| ≤ 半 ulp）独立验证编码正确性。

## 二、测试清单（110 checks）

| 组 | 内容 | 结果 |
|---|---|---|
| 0 | xor 伙伴代数：参与 lane [0,2δ) 内 xor=±δ ⟺ δ 为 2 的幂（3 head_dim × 3 rotary 组合）；δ=12 反例 | PASS |
| 1 | RoPE 机器：interleave vs half-rotate × 全/部分 rotary（部分 rope dims ≥ rotary 不动），仿真 vs 参考位级 | PASS |
| 2 | 量化与布局：全零行 floor scale（=1e-10/448 位级）、slot<0 跳过但写回保留、kAuto 原始 store、e5m2 dtype_max 参数化 | PASS |
| 3 | 融合 vs 模块化：rotary 96（δ=12）构造**发散**（约束实证）+ rotary 64 位级一致 | PASS |
| 4 | 随机主 sweep：12 配置（hd 64/128/256、rot 全/半/半半、两种 rope、nhv≠nhk、quant/kAuto、page 4-16、x 4-8）× 3 种子 = 36 行位级对撞 + 最终写入者往返界 | PASS |

## 三、发现与教训

1. **oracle 一致性 ≠ 正确性的活例（M3 教训再现）**：e4m3 encode 的
   subnormal 阈值写错（2^-9，应为 2^-6——[2^-9, 2^-6) 落入负 e8 的 UB 路
   径）且 e4m3**FN** 饱和规则搞错（e8=15 是合法指数、m3 ≤ 6 合法，448 =
   1.110₂·2^8；只有 m3=7 才是 NaN 槽）——**位级对撞全绿**（两实现共享同一
   encode），只有独立 decode 往返界检查抓到（q=−287 被饱和成 −448）。
2. **e4m3FN ≠ e4m3 的 inf 处理**：无 inf 槽，inf 走 satfinite 448；448/480
   边界的 RNE 平局（464）舍向 448。
3. **IEEE −0 的可见后果**：全零行经 half-rotate RoPE，(−0)·sin 项使 IEEE 和
   产生 −0，fp8 编码保留符号 → cache 字节 0x80——"全零行写全零 cache"的
   直觉预期不成立（设备行为一致，是忠实而非 bug）。
4. **kernel 的 isQ 提前返回是契约**：`if(isQ) return;` 在写回后、slot 读取
   前——漏掉它使 Q head 以 head=localHeadIdx 落入 V 分支产生野偏移
   （ASAN 抓 heap-buffer-overflow，两实现对撞抓不到，因为两者一起错）。
5. **butterfly 快照必须在每个 offset 步内**（M5-#2 教训再现）：单次外置
   快照让每步都折叠原始值 → norm 总和双重计数（q_act[0] ≈ 2× 参考值）。
6. **slot 碰撞语义**：随机 slot_mapping 下多 token 写同槽，cache 归最后写
   入者——往返检查只能针对每槽的最终写入者；outputs_equal 不受影响（两
   实现写序一致）。
7. **几何守卫**：page_size % x == 0 是调用方义务（V 布局 [.., page/x, hd, x]
   在 page<x 时 d·x 越过自身 (block,head) 跨度）；cos_sin cache 行数必须覆
   盖全部 position id（pos_ids 越界读堆是 UB，两实现各读到不同垃圾）。
8. **死代码**：`inverted_kscale`/`inverted_vscale`（上游 221-222 行）定义后
   无任何使用。

## 四、规格表

| 项 | 值 |
|---|---|
| Build Script | `scripts/build_run.sh`；CMakeLists 亦可 ctest |
| Inspection | 双实现对撞（lane 机器 vs flat 索引）+ xor 伙伴代数 + 独立 fp8 往返界 |
| Hardware Matrix | 上游目标 gfx9 系（dispatch 强制 head_dim%32==0、(rot/2)%E==0）；本 demo CPU 主机参考；dtype_max 按 finfo host 分支（OCP 448），gfx942 FNUZ 分支为 240 |
| Execution Result | `results/execution.log`：110 checks, 0 failures |

## 五、复现

```bash
cd demos/algorithm/fused_qk_norm_rope_cache_quant && ./scripts/build_run.sh
# 或 CMake + ctest
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build && ctest --test-dir build
```
