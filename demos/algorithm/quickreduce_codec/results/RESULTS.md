# RESULTS — quickreduce_codec

## 执行记录

- 日期：2026-11-14
- 环境：容器 gfx-m1（rocm10-dev:10.1.0，g++ -std=c++20 -O2；纯 CPU；7.2.4 首测结果一致）
- 命令：`scripts/build_run.sh`
- 结果：`execution.log` — **56,855 checks, 0 failures**（全部 PASS）

```
0. packed-hex constant table -> bf16 scalar cross-check: PASS
── Q4 ──  A/B/C/D 全 PASS
── Q3 ──  A/B/C/D 全 PASS
── Q6 ──  A/B/C/D 全 PASS
6. transmitted-tile compression (4096B raw): Q4 3.556x Q3 4.571x Q6 2.462x: PASS
quickreduce_codec: 56855 checks, 0 failures -> PASS
```

## 调试史（3 个测试侧发现，codec 本体一次通过）

1. **"宽端码点"公式错**：初版测试断言 absmax → `-(1<<bits)`（Q3 期望
   −8）。实际上游 signed 域是 [−2^(b−1), 2^(b−1)−1]（bias = 2^(b−1)），
   Q3 宽端是 −4，且无符号宽端码恒为 0。同时暴露设计点理解：**只有正
   absmax 才落宽端**（负 scale 翻转正数到受保护端）；负 absmax 落 clip
   端、损失 ≤1 LSB——这是上游的刻意设计（保证出现的极值分给保证精确的
   一端），不是 bug。测试改为按 absmax 符号分支断言。
2. **tile_send 逐线程编码**：初版把每个线程当独立组编码，recv 却按
   thread/8 读组 leader 的 scale → 码与 scale 错配（Q3/Q6 大偏差）。
   Q4 侥幸通过（随机数据下 per-thread 界恰好覆盖）。修复：按真实
   8 线程组编码。教训：**组归约的结构（谁和谁共享 scale）是 codec 契约
   的一部分**，tile 级测试正是为抓这类错而存在。
3. **误差界的两层结构**：
   - 初版统一 1.05 LSB → Q6 clip 端实测 1.066 LSB 越界。根因：scale 链
     双重 bf16 舍入（amax→bf16 → ÷32→bf16 时 7.515625 RNE-tie 舍到 7.5，
     欠估 0.206%）叠加 clip 的 1 LSB。
   - 初版 tile 界用**线程** amax → 组内小线程在大值组上被粗 scale 量化，
     误差由**组** amax 决定 → 界必须按组。
   - 最终：内部元素 ≤ 1.05 LSB；clip 端 ≤ 1.3 LSB（1 LSB + 双重舍入
     ≤ ~0.42% + 余量）；tile 界按组 amax。三者都有实测数据支撑。

## 方法学记录

- **常量表交叉核对**（测试 0）值得固化：上游 packed hex 常量
  （0xBE00BE00 等）是位级契约，抄录时一个 nibble 错就是静默的精度损失。
  hex → 标量逐值核对 + 标量 → hex 自洽双向钉死。
- codec 本体（encode/decode/pack/unpack/tile 布局）在测试 A/B/C/D 就位后
  一次通过——上游这段代码质量很高；所有失败都在**测试侧**（对契约的
  理解偏差），这正是三方互证结构的价值：把"理解偏差"逼到显式断言上。
- 范围排除重申：IPC communicator（flag sync、PullQ4 布局、buffer 注册）
  未提取，本 demo 对其不做任何正确性声明。
