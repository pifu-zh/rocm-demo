# RESULTS — gated_rmsnorm_quant

## 执行记录

- 日期：2026-11-14
- 环境：容器 gfx-m1（rocm10-dev:10.1.0，g++ -std=c++20 -O2；纯 CPU）
- 命令：`scripts/build_run.sh`
- 结果：**484 checks, 0 failures**（4 组全 PASS）

```
1. per-head group quant (tds 2/8/16, silu vs sigmoid, eps variants): PASS
2. per-token quant (amax across heads) + scale layouts: PASS
3. zero guard (all-zero gated -> scale 1e-10, out 0, never NaN): PASS
4. clamp saturation (outliers -> ±FP8_MAX, no wrap): PASS
gated_rmsnorm_quant: 484 checks, 0 failures -> PASS
```

## 调试链（一个结构性 bug + 两个语义点）

1. **蝴蝶嵌进 lane 循环**：宿主仿真把 shfl_xor 蝴蝶放进每 lane 的填充
   循环——64 lane × 1 次归约 = sum_sq 累计 64×（scale 偏大 8-10×）。
   kernel 的真实结构是**分阶段**的：填充 → 一次蝴蝶归约 → 归一化/门控 →
   amax → 一次归约。宿主仿真必须按阶段重排。
   **方法论：shfl_xor 蝴蝶的宿主仿真 = 每步快照 + 全 lane 同步更新，
   且整个归约只跑一次、在所有 lane 部分值就位之后。**
2. **shfl_xor 是同时交换**：emu 每步快照再更新（顺序就地累加双重计数，
   即使蝴蝶只跑一次）。
3. **门控语义**：gated = normed · silu(z)——silu(0) = 0 会把 x 异常值
   清零；饱和测试的 gate 必须给大正 z。

## 钉死的契约

- per-token 量化范围（amax 跨全行 [num_heads·head_dim]）匹配 a8w8 方案
  （per-token 激活 scale × per-channel 权重 scale，下游 GEMM 不变）。
- scale 契约：amax 恰映射到 FP8_MAX（量化行 amax == 448 ± 1e-4）。
- 零守卫：amax ≤ 1e-10 → scale 恰为 1e-10（不是 0——避免除零 NaN）。
- clamp 饱和：异常值 → ±FP8_MAX 精确（opus::cast 的饱和语义）。
- TRANSPOSE_SCALE 与自然布局在同一 scale 值下互换。
