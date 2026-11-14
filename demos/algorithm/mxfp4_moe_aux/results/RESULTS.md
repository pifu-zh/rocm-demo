# RESULTS — mxfp4_moe_aux

## 执行记录

- 日期：2026-11-14
- 环境：容器 gfx-m1（ROCm 7.2.4 镜像，g++ -std=c++20 -O2；纯 CPU，未触碰 GPU）
- 命令：`scripts/build_run.sh`
- 结果：`execution.log` — **8237 checks, 0 failures**（6 组全 PASS）

```
1. 3-stage vs single-CTA identical: PASS
2a. reverse_sorted inverse permutation: PASS
2b. segment multiset + pad sentinel + block consistency: PASS
3. quant scale/round-trip contract (worst err/3qs = 0.323): PASS
4a. scatter_reduce bf16 vs oracle: PASS
4b. scatter_reduce mxfp4 (quantized-domain exact, D=128): PASS
mxfp4_moe_aux: 8237 checks, 0 failures -> PASS
```

## 量化误差的物理核对

worst err/3qs = 0.323。理论上限 1/3：E2M1 相邻码最大间隙是 4→6（宽 2），
半间隙 1·qs；`err ≤ 3qs` 是测试用的保守界。0.323 贴着 0.333 且不超过
——随机数据逼近但极少正好落在最坏中点上，数值物理一致。

## 调试史（编号对应测试）

**初始失败**：测试 3 报 `quant err col=0: 1.27606e+38 > 3*qs=6.38029e+37`
——err 恰好 = 6·qs，即存储 nibble 为 0xF（饱和 -6），而该元素 |x| ≈ 3.7e14
远小于 amax/qs·6 的饱和阈。矛盾持续多轮。

**决定性实验**：给 dbg 打印加 `x/qs` 字段。输出显示**每个 nibble 只跟随
输入符号**（正→0x7，负→0xF），与幅值完全无关（x=-824→f，x=+1.6e-24→7，
x/qs=-1.75776e-23→f，x/qs=-0→f）。这一"只看符号"指纹立即锁定饱和分支
等价行为 → 检查 RNE 循环 → 发现 `d = mag - vals[c]` 是**有符号**距离，
且 `d` 随 c 严格递减，`d < best_d` 每轮必胜 → best 恒为 7（最远码！）。

**为何 4b 不报警**：4b 的 oracle 在量化域逐位精确——它消费同一个坏编码器
的输出再对比 scatter 路径，验证的是"散射不破坏字节"，不是编码正确性。
独立契约测试（3）是唯一能抓住它的关卡。→ 方法学结论已写入 README §三。

**修复**：比较改为 `fabs(mag - vals[c])`，tie-break 保留"偶数码"语义。
**次生发现**：修复后的 11 个定向 RNE 钉子一度报 3 个 FAIL——根因是
**测试表自己**把 nibble 与解码值搞混（0x7 = 6.0 而非 4.0；5.0 中点的
偶数码是 code 6 = 4.0）。修正期望后全 PASS。编码器与测试双向出错的
调试链完整记录于此，供后续跨验证（aiter `even_round_e2m1` /
cuda-oxide `rne_shift` / 实验室编码器三方对比）引用。

## 已钉死的上游隐含约束

- mxfp4 比例 u32 读跨 4 个连续 32 列块（`blk & ~3`）→
  **`d_hidden % 128 == 0`** 才不越界；上游仅 assert `D % 8 == 0`。
- PAD 槽 sentinel = M（依赖下游 buffer_load 越界丢弃）。
- 段内顺序设备端非确定 → 上机对比必须按段 multiset。


## 跨验证（2026-11-14 追加）：三方 E2M1 编码器

`tests/e2m1_crosscheck.cpp` 把三方编码器移植到同一输入网格上对撞：

| 实现 | 来源 | NaN/Inf 策略 |
|---|---|---|
| T1 aiter | `emit_f32_to_e2m1`（FlyDSL bit-trick，2^22 bias 非正规路径 + 0xC11FFFFF+mant_odd 正规路径） | satfinite 带符号（NaN → ±7） |
| T2 cuda-oxide | `f32_to_e2m1_rne_satfinite`（rne_shift 两段式） | satfinite 带符号 |
| T3 lab | `e2m1_encode_rne`（最近码 + ties-to-even） | **NaN → 正 0x7（丢符号）**，Inf → ±7 |

**结果（results/crosscheck.log）**：

- **271,844 个有限输入三方逐位一致**——含 f16 全格点（65,536 位型）、
  8 个 E2M1 舍入边界 ±512 ulp 扫描、f32 非正规、±0、随机 f32。RNE 语义
  三方钉死。
- NaN：aiter == oxide（带符号 satfinite，2060/2060）；lab 只在**负 NaN**
  上分歧（1030/2060），即唯一预期的策略性分歧。

结论：三个独立实现的 RNE 语义完全一致；NaN 策略是实现自由度（E2M1FN 无
NaN 编码），三方各选其一，跨验证的价值在于**把分歧从"疑似 bug"降级为
"已记录的策略差异"**。此前 lab 编码器的 signed-distance bug（见上文调试
史）正是这种跨验证设计当初要拦的目标——现在它有了常备关卡。
