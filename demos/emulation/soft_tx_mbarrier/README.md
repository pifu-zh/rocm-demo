# soft_tx_mbarrier — 软事务 mbarrier（expect_tx 字节级计数）实测闭环

**类目**: emulation · **验证级别**: HARDWARE_PASS（RX 6950 XT / gfx1030，ROCm 10.1 / HIP 7.16 / clang-24 真机执行，2026-11-14）
**动机**: 两个实验室共同记录的开放缺口——cuda-oxide 的 `arrive_expect_tx(bytes)` 只是 API 壳，warp_sync.hpp 明确写着"expect_tx byte-counting is NOT supported (open gap in cuda-oxide too)"。本 demo 在 gfx1030 上用 LDS 原子实现**字节级事务跟踪**并闭环验证。

## 一、原理说明

### PTX 契约（被仿真的语义）

CUDA PTX 的 mbarrier 相位携带**双重义务**：N 个 arrival + B 个事务字节：
- `arrive.expect_tx(b)`：注册 b 字节待落（消费侧武装相位）；
- `complete_tx(b)`：报告 b 字节已落（硬件 TMA 自动完成）；
- **相位完成 = arrival 归零 且 字节归零**——消费者不能只等线程数，必须等**数据体量**落地。

### 为什么这在 gfx1030 上有价值（替代故事）

没有 TMA、没有硬件 mbarrier。plain SoftMbarrier 只数线程：producer 若发完
load 不等自身 vmcnt 就 arrive，消费者会被提前放行（数据还在路上）。朴素补
丁——producer 等自己的 vmcnt 再 arrive——把每个 producer 串行化在自己的
load 上，破坏**分片完成**模式（多个 producer 各自异步完成份额）。expect_tx
跟踪字节体量：每个 producer 异步完成自己的份额，消费者恰好在总体量落地时
放行 ✓——这正是 Hopper TMA 流水线的核心同步原语的软替代。

### 状态设计（单 64 位 LDS 字，atomicAdd-only）

```
bit  32    : 相位 parity
bits 31:0  : credit = 待决 arrival 数 + 待决字节数
bits 63:33 : 轮次（每次翻转的进位）
```

- `arm(n, b)`（等待方，相位入口）：`+= (n + b)`
- `arrive()`（生产方）：`-= 1`；**credit 归零者翻转 parity**（PTX：计数归零即相位完成——纯 arrival 相位（b=0）在最后一个 arrive 完成）
- `tx_complete(b)`（生产方，自身 load 落地 + threadfence 后）：`-= b`；credit 归零者翻转
- credit 在字节待决时不可能经 arrive 归零（credit ≥ 待决字节 > 0）→ 两个翻转点互斥安全
- LDS 原子串行化 → 恰有一个完成者观测 `old == 自身消费量` → 每相位恰一次翻转，无 CAS（CAS 挂死规避）
- credit 预算：arrival ≤ 2^28、字节 ≤ 2^28/相位（API 限制）

## 二、测试与结果（results/execution.log，2026-11-14）

| # | 内容 | 结果 |
|---|---|---|
| 1 | 单发 2×256B，消费者验证 512B 全落 | PASS |
| 2 | **字节门控**：全 arrival 完成且 0 字节完成 → try_wait 必须假；3/4 字节 → 假；4/4 → 翻转 + payload 验证 | PASS |
| 3 | 100 轮消费者重武装（无重初始化），parity 推进 + 末轮 payload | PASS |
| 4 | 32 producer 分片完成（错峰 tx），全 payload 验证 | PASS |
| 5 | 延迟：tx 版 496 cycles vs plain 253（1.96×——arm 的额外原子 + credit 语义成本）vs native 31 | 报告 |

## 三、调试链（五个真实发现，含两个工具链级）

1. **SIMT 波陷阱再现**（warp_sync 教训第二次命中）：阻塞 wait 与 producers
   同波 → 整波钉死在 spin PC。修复：consumer 移到 wave 1（tid 32）。
2. **init/arm 跨波竞态**：init 在 tid0（wave 0）、arm 在 tid32（wave 1），
   两波间无序——arm 被 init 的写 0 覆盖丢失。修复：init/arm 同线程。
3. **plain-load spin 被编译器删除**（**clang-24 工具链级发现**）：编译器追踪
   "等待线程自己的 arm 使 parity==0"，**把该知识跨过 workgroup barrier 携带**，
   在 wait 处发射 `llvm.assume(parity == 0)` 并**整体删除 spin**（IR 抓到现
   行）——wait 在 producers 翻转前就返回。修复：spin 体加 memory clobber。
4. **软件流水线跨原子重排**（**clang-24 工具级发现**）：producer 循环被流水
   化后，**下一轮的 stage copy 发射在当前轮 tx_complete 之后**（消费者读到
   "从未完成的轮"的页；r=100 与 r=93 同页 %7，双缓冲诊断设计过但未闭合）。
   修复：copy 与校验全 volatile + `#pragma clang loop pipeline(disable)`。
   **volatile 与 atomic 之间无顺序约束**是这一发现的本质：volatile ≠ 原子。
5. **T4 arrive 丢失**：token 改造来回中 arrive 调用被删（txs 无 arrives 的
   credit 不守恒，word 停在 0x20 诊断锁定）。
6. **测试期望错**：校验表达式 `src[i%32]` 对 37-取模回绕的 src 模式不成立
   （stage[i] == src[i] 才是拷贝契约）；sm2 最小版 PASS 是其 src 恰好 32 周
   期的巧合。
7. `llvm.assume` 后的 `atomicAdd(word, 0)` acquire 无效——与数据无别名，
   照样上提；memory clobber 才有效。

## 四、复现

```bash
cd demos/emulation/soft_tx_mbarrier && ./scripts/build_run.sh   # 容器内，需真机
```
