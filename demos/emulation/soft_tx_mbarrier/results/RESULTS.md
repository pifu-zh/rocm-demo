# RESULTS — soft_tx_mbarrier

## 执行记录

- 日期：2026-11-14
- 环境：容器 gfx-m1（rocm10-dev:10.1.0，HIP 7.16.26385 / clang-24），GPU RX 6950 XT（gfx1030）
- 命令：`scripts/build_run.sh`
- 结果：**5 组全 PASS**（连续 3 次运行 exit=0，延迟数字逐次一致）

```
1. single-shot 2x256B (consumer verifies payload): PASS
2. byte gating (arrivals done + 0B -> gated; 3/4B -> gated; 4/4B -> flip; payload ok): PASS
3. multi-round 100 (consumer re-arm, no re-init): PASS
4. split completion 32 producers (staggered tx, payload ok): PASS
5. latency per op: tx-mbarrier 496 cycles, plain 253, native 31
   -> tx/plain 1.96x, tx/native 15.82x
soft_tx_mbarrier: PASS
```

（注：测试 4 文案里 "64 producers" 是历史遗留——实际 32 producer × 64 B，
重排线程映射时改的，文案待下轮清理。）

## 延迟解读

tx 版 496 cycles/op vs plain 253：额外成本 = 每轮 arm 的原子 + credit 双重
义务的翻转检查 + 每操作三次原子（arm/arrive/tx）vs plain 的两次。1.96× 换
的是**字节门控语义**（消费者恰在数据体量落地时放行，线程数完成 ≠ 数据完
成）——这正是 plain mbarrier 无法表达的 Hopper TMA 流水线同步。

## 调试链摘要（详见 README §三）

七个发现：SIMT 波陷阱再现（consumer/producers 同波）、init/arm 跨波竞态、
**clang-24 用 llvm.assume 跨 workgroup barrier 删除 spin（IR 抓现行）**、
**clang-24 软件流水线把下一轮 stage copy 排到当前轮 tx 之后**（volatile 与
atomic 之间无顺序约束的实证）、T4 arrive 在改造中丢失、测试期望对 37-取模
源模式不成立、atomicAdd(0) acquire 无效（无别名则被上提，memory clobber
才有效）。

## 范围与声明

- PTX 锚点：mbarrier.arrive.expect_tx / complete_tx 的相位完成语义
  （arrivals == 0 且 tx == 0）；本 demo 是语义仿真，非硬件事务跟踪。
- credit 预算限制（≤ 2^28/相位）已文档化。
- cuda-oxide 的同缺口（barrier.rs arrive_expect_tx 只对 Hopper 硬件）
  由本 demo 提供了 gfx1030 的软替代路径。
