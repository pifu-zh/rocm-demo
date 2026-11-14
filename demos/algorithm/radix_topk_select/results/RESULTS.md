# RESULTS — radix_topk_select

## 执行记录

- 日期：2026-11-14
- 环境：容器 gfx-m1（rocm10-dev:10.1.0，g++ -std=c++20 -O2；纯 CPU）
- 命令：`scripts/build_run.sh`
- 结果：**149 checks, 0 failures**（4 组全 PASS，连续 3 次）

```
1. radix_key_bits (monotone, involution, NaN classes): PASS
2. multi-pass radix select vs naive (64 rows, ties + distinct + fast path): PASS
3. NaN handling (default mode set match; NaN-high key pinned in test 1): PASS
4. dispatch decision (tiered thresholds, exact points): PASS
radix_topk_select: 149 checks, 0 failures -> PASS
```

## 提炼记录

- **key 方向是这个算法最容易踩的反直觉点**：twiddle 使 key 升序 = 值降序
  （正数低 31 位翻转、负数原样），低桶端扫描 = 从最大值下探。两处测试
  断言先后把方向写反（NaN-high "key 更小 = 排名更高"；单调性必须按值
  排序而非按位排序——位序 ≠ 值序跨符号边界），都被值比对抓出。
- 平局纪律：kth 桶内的等值候选从后往前填（back_pos < needed）→ 宿主
  确定序下"最低输入索引胜"——与上游测试的排序比较纪律一致。
- 调度阈值表按 CU 分档钉死（14 精确点含边界 ±1）；env 覆盖路径记录。
- 设备侧跨块 barrier（atomicInc + pass_done 轮转）与自复位工作区是
  硬件线细节，未提取。
