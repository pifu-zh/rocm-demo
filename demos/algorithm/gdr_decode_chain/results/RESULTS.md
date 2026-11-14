# RESULTS — gdr_decode_chain

## 执行记录

- 日期：2026-11-14
- 环境：容器 gfx-m1（rocm10-dev:10.1.0，g++ -std=c++20 -O2；纯 CPU；7.2.4 首测结果一致）
- 命令：`scripts/build_run.sh`
- 结果：`execution.log` — **8,470,774 checks, 0 failures**（5 组全 PASS）

```
1. xor-butterfly reduce (ds_swizzle xor 1/2/4; shfl_xor 16/32): PASS
2. decode step (lane decomposition + butterflies vs naive): PASS
3. fp32 state-pool swizzle codec [slot][HV][K/4][V][4] round trip: PASS
4. T-step split chain (register state + swizzled pool vs naive): PASS
5. LDS bank padding (idx + idx/CHUNK, stride 33): PASS
gdr_decode_chain: 8470774 checks, 0 failures -> PASS
```

## 检查数说明

8.47M 的绝大部分来自测试 2/4 的 pool/word 级零填充与位级不变检查
（pool·VH·VD·KD ≈ 2M 词 × 两实现 × 两类检查）。核心数值检查（out/state
三方针）约 6 万项。

## 排错链（5 个真实 bug，全部由测试组定位）

1. `slot_words` 布局公式把 v 重复乘 VD（`(slot·VH + v)·VD·KD`）→ segfault。
   修复：`(slot·VH·VD + v)·KD + k`。
2. swizzle codec 的 row-major 地址漏 `v·KD` → pack 用 127 个 v 反复覆盖
   同一地址，round trip 失败。修复：pack/unpack 都补 `+ v·KD`。
3. split 打包维 `2·KD + VD = 384` ≠ 上游 `2·key_dim + value_dim = 4352`
   （value_dim = HV·V）→ hv≥1 的 v 读越界（vector operator[] 无检查），
   堆垃圾进归一化 → 1e16/NaN。修复：DIM = 2·KD + VH·VD。
4. split 仿真 final-state writeback 漏 `v_col·KD` → slot 内所有 v 折叠进
   首行，测试 4 的 final state 对比抓出。修复。
5. decode 仿真首循环用未归一化 k 累加 sum_hk，归一化后又累加 → 双计。
   上游 kernel 的顺序是"先归一化，再累加 recurrent dot"——仿真必须忠实
   上游的操作顺序，不能"数学上等价"地重排。修复：首循环只做 raw 平方和。

## 方法学记录

- **三方互证结构**：结构仿真（忠实 lane 分解 + butterfly + LDS 布局）×2
  + 朴素参考 ×1。测试 2/4 的失败模式直接指出哪一个仿真层出错（布局类
  bug 在 state 对比暴露，数值类在 out 对比暴露）。
- **负对照**（测试 1）：故意漏掉 xor2 步，断言 butterfly **不**折叠该位
  ——防止"测试恒真"。这是本 demo 从 mxfp4_moe_aux 的 oracle 教训
  （README §三）继承来的纪律：测试本身也要有失效能力。
- **未验证声明**：`ds_swizzle` 的 BITMASK_PERM 编码常量
  `(N<<10)|0x1f` 是从上游逐字抄录的，其**指令级语义**（以及 gfx1030 上
  该 builtin 的可用性）归 M3 硬件探针 demo 验证；本 demo 只钉 XOR
  butterfly 的语义行为。
- 上游 host 侧 `AITER_CHECK(dim == 2*key_dim + value_dim)` 是布局契约的
  一部分——排错 3 证明绕过它会静默越界。提取布局契约时必须连 host 校验
  一起读。
