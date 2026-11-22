# lsa_flat_va — CCO LSA 完整 demo：平坦 VA 对称窗口 + peer_va 公式寻址 + epoch barrier

**类目**: hardware ｜ **验证等级**: `HARDWARE_PASS`（双进程 gfx1030 实测，2 轮稳定复现，`results/run_gfx1030.log`）
**实验地位**: CCO（MORI 下一代集合通信对象）最核心的可移植思想——**对称平坦 VA
窗口**——在 gfx1030 双进程上的完整端到端验证。`vmm_flat_va_probe` 只验证了物理层
（reserve/create/map/互映射可行）；本 demo 把它组装成 CCO 的实际窗口拓扑并跑通
LSA put + epoch barrier 协议。

## 1. 原理说明

SHMEM 对称堆是"各自分配 + IPC handle 交换 + **查表**寻址"（`peerPtrs[pe]`）；
CCO 的 LSA（Local Symmetric Access）是"**地址可计算**"：每个 rank 的窗口在所有
进程的同一平坦 VA 槽位互为镜像，device 代码一个公式寻到任意 peer（`cco.hpp:288-305`）：

```
peer_va = winBase + peerLsaRank * stride + offset     （stride=4GB 对齐，demo 缩小为 256MB）
```

本 demo 构建完整拓扑并实测：

| 测试 | 内容 | 结果 |
|---|---|---|
| L1 | parent kernel 直写 peer_va（child 的窗口 B）→ child kernel 校验自己窗口 | **mism=0/4096** |
| L2 | child kernel 直写 peer_va（parent 的窗口 A）→ parent kernel 校验 | **mism=0/4096** |
| L3 | epoch barrier 双向 4 轮：fence→RELAXED arrive→ACQUIRE wait + 回绕比较免清零 | **双进程 rendezvous 全对** |

LSA put 在两端都是**普通 global store**（`lsaPutKernel`），没有任何传输层介入——
这正是 LSA 的本质：同节点窗口互映射后，"通信"退化为访存。

## 2. 上游出处

- `src/cco/cco_init.cpp:726-744`（平坦 VA reserve）、`:826-963`（窗口物理块）、
  `:1399-1420`（FD 路径互映射——本 demo 的 SCM_RIGHTS 即此路径）
- `include/mori/cco/cco.hpp:288-305,695-701`（peer_va 公式）、`:649-816`（LSA barrier）
- 考古报告：`docs/archaeology/02-shmem-cco-kiwi.md` §3、`docs/archaeology/01-framework-core.md` §5.8

## 3. 独立实现说明

- 单文件 HIP C++，双进程：**fork 先于任何 HIP 调用**（Demo 6 教训），两进程各自
  独立初始化 HIP。
- FD 传递用 SCM_RIGHTS（Unix socketpair）——mori 的 FD 回退路径的传输机制；
  **收到的 FD 必须经 `hipMemImportFromShareableHandle` 显式 import** 后才能
  `hipMemMap`（直接强转 int→handle 会段错误——本 demo 实测教训；vmm probe 里
  fork 继承的 FD 能直接用，是因为 fork 保持 FD 编号与 open-file-description 同一）。
- VMM 装配两阶段串行化（socket 握手）：**两进程并发调 hipMemAddressReserve/
  hipMemCreate 有竞态段错误**（实测），parent 完成自建装配后 child 才开始。

## 4. Reference / Correctness Test

期望模式独立构造（1000000+i / 7000000+i）；校验用 SM 内核全量比对（4096 word）；
barrier 正确性 = 双进程各 4 轮全部 rendezvous 完成（任一方 wait 不返回则超时挂死）。

## 5. 构建

```bash
demos/hardware/lsa_flat_va/scripts/build_run.sh   # 容器内
```

## 6. Inspection

`results/run_gfx1030.log`（双进程完整 trace）。LSA put 的 ISA 形态就是普通
`global_store_dword`（可用 Demo 2 的解包管线验证）——这正是"通信退化为访存"的
可观察证据。

## 7. Hardware Matrix

gfx1030 + HIP 7.16 双进程实测。与 `ipc_symmetric_heap`（IPC handle 路径）互补：
**两条对称内存路径在本机都端到端可用**。真实 CCO 的 4GB stride/多 rank 星型
拓扑未测（单机单卡缩小版）。

## 8. Execution Result

ALL PASS（2026-11-18，两轮稳定）。未验证事项：4GB stride 全尺寸、>2 rank、
Fabric handle 路径、LSA 上的 atomic（上游 ccoLsaBarrierSession 用的 RELAXED
store 本身已覆盖）、hipMemUnmap 后 VA 复用。
