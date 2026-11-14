# RESULTS — dsv4_hadamard_rotate_quant

## 执行记录

- 日期：2026-11-14
- 环境：容器 gfx-m1（rocm10-dev:10.1.0，g++ -std=c++20 -O2；纯 CPU）
- 命令：`scripts/build_run.sh`
- 结果：**736 checks, 0 failures**（3 组全 PASS，一次通过）

```
1. butterfly rotation == explicit Hadamard matrix oracle (dim 16/32/64): PASS
2. FP4 scale contract (ceil_pow2(amax/6), no clip, decode bound): PASS
3. end-to-end rotate->FP4 quant (err <= 1.05 LSB; energy preserved): PASS
dsv4_hadamard_rotate_quant: 736 checks, 0 failures -> PASS
```

## 提炼记录

- 蝴蝶的两阶段拆分（intra-thread 4 轮 + inter-thread 跨 lane 轮）与
  swap_thread_data<gs> = lane^(gs/2) 的 DPP 映射已从上游逐条对齐；
  逻辑 lane 仿真与显式 Hadamard 矩阵 oracle 一致到 1e-4。
- FP4 scale 的 ceil_pow2 位技巧与 mxfp4_moe_aux 的实现同源（/6 → /fp4_max
  泛化 + eps_amax 下限 = fp4_max × 2^-126），契约（永不 clip）256 行验证。
- 能量守恒（Hadamard 正交 × dim_rsqrt）作为旋转正确性的独立不变量，
  与逐元素矩阵比对互证。
- 上游的 MFMA/.buffer 指令细节不在本 demo 范围（hardware 线）；
  scale 的 Flydsl shuffled 布局未提取（Natural 已钉，Flydsl 记录待做）。
