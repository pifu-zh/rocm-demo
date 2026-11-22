# p2p_cas_atomic — P2P 原子的 CAS-loop 软件仿真（mori 软件原子层母本）

**类目**: emulation ｜ **验证等级**: `HARDWARE_PASS`（gfx1030 实测，见 `results/run_gfx1030.log`）

## 1. 原理说明

mori 的 P2P 传输（hipIpc 映射的对端显存直读直写）**不保证有原生原子**——对端显存
经由 IPC 映射后，硬件原子能否跨映射可见是 arch 相关的。mori 的解法是把整套原子
语义**用 CAS 循环仿真**（`p2p/device_primitives.hpp:286-503`）：

```
fetch_add(p, v):
  old = load_relaxed(p)
  loop: if compare_exchange(p, old, old+v) return old;   // 失败则 old 已被刷新，重试
```

AMO_ADD/AND/OR/XOR/SWAP/COMPARE_SWAP（fetch 与 non-fetch 两种）全部由这一个
循环模式实现。这是"介质缺原生原子 → 用本地 CAS 表达远端原子语义"的软件模拟层
（EMULATION_CATALOG E-11），与 E-02 的"对端 CPU 代执行原子"是同一问题的两种解法：
CAS-loop 在**本地**表达语义，SEND_WITH_IMM 把原子**搬运**到有原子的地方执行。

本 demo 在 gfx1030 上验证 CAS-loop 仿真的两个维度：

**Q1 语义等价**（262,144 线程 × 4 轮的高争用压力）：

| 检验 | 结果 |
|---|---|
| fetch_add 票据唯一性（返回值多重集合 == {0..N-1}，终值 == N） | PASS |
| 硬件原子 fetch_add 同检验（独立实现对照） | PASS |
| fetch_and / fetch_or / fetch_xor 终值 == host 独立折叠参考 | PASS ×3 |
| compare_swap 单发重置协议（262k 线程争抢，恰 1 个赢家） | PASS |

and/or/xor 的终值与操作顺序无关（可交换可结合），因此 host 参考折叠是**确定性**
期望——这不是弱校验。

**Q2 代价**（信息性）：全线程争用**单条 cacheline** 的最坏情形下
cas=1154ms vs hw=0.014ms（**~85,000×**）。诚实记录并解释：这是最坏情形基准——
真实 mori P2P 原子用于跨进程 IPC 内存的低频控制面（槽位预留/信号），争用分散在
per-peer 地址上；85,000× 的比例说明该仿真层只能用于控制面而非数据面，与上游
"原子只出现在元数据路径" 的用法一致。

## 2. 上游出处

- `include/mori/core/transport/p2p/device_primitives.hpp:286-503`（NonFetch 原子族）
- `include/mori/core/transport/p2p/device_primitives.hpp:417-503`（Fetch 型，返回值广播
  契约见 02 报告 §2.2——非 leader 返回 T{}）
- 考古报告：`docs/archaeology/02-shmem-cco-kiwi.md` §2（p2p 原子条目）、`docs/EMULATION_CATALOG.md` E-11

## 3. 独立实现说明

单文件 HIP C++。CAS 循环用 C11 原子内建（`__atomic_compare_exchange_n`）直接表达，
acq_rel 成功序 + relaxed 失败序（mori 用 AtomicCompareExchangeSystem，语义等价）。
硬件原子对照用 HIP `atomicAdd`——两条独立实现，不允许互相拷贝代码结构。

## 4. Reference / Correctness Test

期望值全部由 host 独立推导：票据集合 {0..N-1}、折叠初值+操作数序列的顺序无关折叠、
单发协议的 winners==1。GPU 结果只与 host 参考比对，绝不用 GPU 结果自证。

## 5. 构建

```bash
demos/emulation/p2p_cas_atomic/scripts/build_run.sh   # 容器内
```

## 6. Inspection

CAS 循环经编译器可展开为 `s_load/s_cmp/v_cmp/s_cbranch` + `buffer_atomic_cmpswap`；
如需 ISA 对照：`hipcc --genco --offload-arch=gfx1030 src/p2p_cas_atomic.hip`。
（本 demo 以行为证据为主，ISA 未归档。）

## 7. Hardware Matrix

gfx1030 实测。上游 P2P CAS 目标介质是 gfx942/gfx950 的 IPC/LSA 映射；gfx1030 的
IPC 映射可见性（hipIpcOpenMemHandle 跨进程同卡）尚未实测——本 demo 只验证
CAS-loop **在本地内存上的语义等价性**，介质行为属于 Demo 7（IPC 对称堆）的范围。

## 8. Execution Result

`results/run_gfx1030.log`（2026-11-18）：6/6 检验 PASS，全部一次通过。
争用吞吐 85,000× 差距已记录（最坏情形单行争用，控制面定位）。

未验证事项：跨进程 IPC 内存上的 CAS 可见性；compare_swap 高轮次多代协议
（本 demo 用单代验证单发语义）；ABA 场景（mori 用 wrap-safe 序号处理，属 C-07 条目）。
