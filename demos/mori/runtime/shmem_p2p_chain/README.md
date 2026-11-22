# shmem_p2p_chain — mori SHMEM P2P 全链路复现（双进程单卡，IPC 对称堆介质）

**类目**: runtime ｜ **验证等级**: `HARDWARE_PASS`（协议链 T1/T2/T3/T5 全过）
**+ 硬件发现 T4**（负结果，已取证）: **gfx1030 的 IPC alias VA 上原子操作静默失效**
**覆盖条目**: D-01（P2P 传输决策落地）、D-03（Socket bootstrap 迷你版）、
D-06（GpuStates 装配）、02 报告 §2 的全套 P2P 设备语义（put/get/atomic/quiet/barrier）

## 1. 原理说明

mori SHMEM 的 P2P 通道语义链：对称堆 + 对端指针查表 + 纯 load/store 数据面 +
release 信号完成语义 + CAS-loop 原子仿真 + PE0-coordinator barrier。本 demo 在
**双进程单 gfx1030**（介质由 `ipc_symmetric_heap` 验证）上按上游结构逐件组装：

```
bootstrap(rank0 监听/rank1 连接)          ← ShmemGetUniqueId 迷你版（TCP 端口 rendezvous）
  → 交换 hipIpcMemHandle + 堆基址（TCP）   ← symmetric_memory.cpp 的 handle 交换语义
  → hipIpcOpenMemHandle(peer)             ← lazy peer access
  → GpuStates{heapBase, peerHeap, myPe, nPes} host 构造 → hipMemcpy 灌设备   ← D-06
  → 设备内核全部经 GpuStates 取址          ← mori kernel 的取址模式
```

**实测矩阵**：

| 测试 | 内容 | 结果 |
|---|---|---|
| T1 | put+signal 0→1，2 世代单调 token（免清零）: rank0 SM store + release signal → rank1 设备侧 `WaitUntilGreaterThan` 自旋 + 全量校验 | ✅ 0/4096 |
| T2 | put+signal 1→0 反向同构（信号槽复用，token 3/4） | ✅ 0/4096 |
| T3 | get: rank1 SM 铺数据 → rank0 GetMemNbi → NT store 落本地 → host 校验 | ✅ 0/4096 |
| T5 | barrier: PE0-coordinator 两阶段（arrive pSync → coordinator 感知后分发 done），2 轮不同 epoch | ✅ 双轮 |
| T4 | 原子: rank1 远端 CAS ×1000 / plain atomicAdd ×1000 | ⚠️ **负结果（硬件发现）** |

### 硬件发现（本 demo 最重要的交付物之一）

**gfx1030 的 IPC alias VA：普通 load/store 完全可用，原子操作静默失效。**

| 子实验 | 观测 |
|---|---|
| T4a rank1-only CAS ×1000 | 发起方视角"成功"走完 tickets [0..938]（顺序 fetch 语义自洽），但**远端计数器只到 32**——CAS 写未正确到达共享物理内存 |
| T4b 叠加本地 atomicAdd ×1000 | counter=1939 ≠ 2000——CAS 路径部分丢失 |
| T4c 对照: plain atomicAdd via alias ×1000 | counter=**0**——完全未落地 |

而**同一 alias 的普通 store 在 T1/T2 完美工作**（4096 word × 4 世代全对）。结论：
RDNA2 的 IPC peer 映射上，**数据面（load/store）可用、原子面静默失效**（疑似 PTE
原子权限位未设置，原子被丢弃且发起方 CAS 仍"成功"）。直接推论：**mori 的 P2P
原子仿真（`device_primitives.hpp` CAS-loop）在 gfx1030 上会静默破坏数据**——这是
mori 官方仅支持 gfx942/950/1250 的又一个深层原因（此前已知构建层排除，本 demo
给出了介质层的实证）。对单卡双进程用 P2P 通道的实践约束：数据用 put/get，**同步
用 signal（release store）而非远端原子**。

### 调试过程钉死的三个纪律（每个都有失败形态）

1. **多 block 无 grid 同步 → signal 竞态**：首版 put/verify 各 17 block，signal 由
   block0 发出，其余 block 未完成 → 接收端 mism=3840/4096（恰 256=block0 词数对）。
   修复：单 block 协同式拷贝 + `__syncthreads` + thread0 fence+signal（mori Thread
   语义的信号纪律）。
2. **H2D 写源数据 → 对端 SM 读 stale**：hipMemcpy H2D 走 SDMA 写 DRAM 绕过 L2，
   对端 SM 读撞 bootstrap memset 留下的 stale 行。修复：SM kernel 铺数据（同 GPU
   SM↔SM 经共享 L2 一致）。
3. **SM 写 → D2H 读不可见**：kernel 写经 L2 的脏行对 D2H（不 snoop L2）不可见。
   修复：落区用 `__builtin_nontemporal_store` 写穿（mori `SdmaVisibleStore` 同款纪律）。

## 2. 上游出处

- `include/mori/shmem/shmem_device_api.hpp:61-74`（DISPATCH_TRANSPORT_TYPE 结构）、
  `:1140-1189`（WaitUntil 轮询）、`:1207-1289`（PE0 coordinator barrier）
- `include/mori/shmem/shmem_p2p_kernels.hpp:39,222,286-404,1151-1158`（put/signal/
  CAS 原子/quiet=no-op）
- `src/shmem/init.cpp:594-671,956-1036`（GpuStateInit/UniqueId）、`runtime.cpp:93-114`
  （GpuStates 灌设备）、`internal.hpp:62`（静态堆）
- 考古报告：`docs/archaeology/02-shmem-cco-kiwi.md` §2/§8

## 3. 独立实现说明

单文件 HIP C++，双进程由脚本分别启动（rank0 监听/rank1 连接）。堆 16MB Uncached
（mori 4GB 缩小版），pSync 区在堆尾 4KB，信号用单调 token（mori twoshot AR 同款：
"Flags are monotonic generation tokens, so no reset is needed"）。

## 4. Reference / Correctness Test

期望模式独立构造（epoch*1e6+i）；校验在设备侧内核全量比对（含 release/wait 语义
的真实行使）；T4 三子实验交叉互证（CAS vs plain atomicAdd vs 本地）。

## 5. 构建

```bash
demos/runtime/shmem_p2p_chain/scripts/build_run.sh   # 容器内（自动起双进程）
```

## 6. Inspection

`results/{rank0,rank1}.log`（双进程完整 trace）。P2P put 的 ISA 即普通
`global_store`（可用 Demo 2 管线验证）；CAS 循环 ISA 见 p2p_cas_atomic 交叉验证。

## 7. Hardware Matrix

| 架构 | 结论 |
|---|---|
| **gfx1030 + HIP 7.16（本机）** | put/signal/get/barrier 全链路 ✅；**远端原子经 IPC alias 静默失效**（plain store ✓） |
| gfx942/950（mori 官方） | P2P 全功能含原子（上游 CI 覆盖） |
| 推论 | 单卡双进程实践约束：数据 put/get + signal 同步；避免远端原子 |

## 8. Execution Result

`results/run_gfx1030.log` + `rank{0,1}.log`（2026-11-18）：协议 4/4 PASS，
双进程 rc=0；T4 三项负结果已取证记录。

未验证事项：远端原子失效的机制定位（PTE 权限位假设未证）、多轮压力下的
T4 稳定性、CAS 失败后发起方"成功假象"的驱动层成因。
