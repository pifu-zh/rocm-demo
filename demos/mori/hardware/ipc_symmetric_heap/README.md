# ipc_symmetric_heap — 单卡双进程的 IPC 对称堆最小闭环

**类目**: hardware ｜ **验证等级**: `HARDWARE_PASS`（2026-11-18 实测，`results/run_gfx1030.log`）
**实验地位**: 把 `docs/ARCH_MATRIX.md` 中 4 个 ⚠️"待实测" 项转为实测结论——这是
mori shmem P2P 路径、CAS 原子真实介质、LSA barrier 协议在本 Lab 的介质可行性判决。

## 1. 原理说明

mori 的对称内存（SHMEM 对称堆、CCO window）都建立在"每个 rank 看得到所有 rank
的堆"之上：同 host 用 hipIpc handle 交换，同进程直接用指针。上游明确记载两个坑
（`symmetric_memory.cpp:143-168` 注释）：
- `hipIpcOpenMemHandle` **同进程内会失败**（所以同进程 peer 直接用指针）；
- IPC handle 记录导出时的 device ordinal，importer 可见数不含该 ordinal 时拒绝
  （`xgmi/backend_impl.cpp:852-866` 的 ordinal-0 规避）。

**单卡双进程**是最小的"多 rank"形态：一张 GPU、两个 HIP 上下文、一段物理显存、
两个 VA。mori P2P put/get、CAS 原子、LSA barrier 的介质语义全部可以在上面实测。

实测矩阵（全部一次通过）：

| 测试 | 内容 | 结果 |
|---|---|---|
| T1 | `hipIpcGetMemHandle`/`hipIpcOpenMemHandle(lazy peer access)` 同卡跨进程 | **可用**，remote VA ≠ 本地 VA（同一物理页两个映射） |
| T2 | 经 IPC 映射的"远端显存" kernel 直写 4096 word + `__threadfence_system` release 信号 → 对端全量校验 | **撕裂 0**（shmem P2P put+signal 语义成立） |
| T3 | CAS-loop 原子打在 IPC 内存上（Demo C-04 的真实介质）跨进程 0→1 单发 | **value=1 精确** |
| T4 | CCO epoch 回绕 barrier（RELAXED arrive + ACQUIRE 轮询 + `(got-(epoch+1))<=INT_MAX` 免清零）双向完成 | 双侧 arrive/wait 闭环 |

## 2. 上游出处

- `src/application/memory/symmetric_memory.cpp:109-363`（RegisterSymmMemObj 三段集合交换）
- `src/io/xgmi/backend_impl.cpp:829-943`（基址解析 + ipcOffset + ordinal-0 规避）
- `include/mori/shmem/shmem_device_api.hpp:482-563`（PutSignal 的 release 信号）
- `include/mori/cco/cco.hpp:649-816`（LSA barrier epoch 协议）
- `include/mori/ras/ras.hpp:48-53`（"不跟随 fork"——本 demo 踩坑后同款结论）
- 考古报告：`docs/archaeology/02-shmem-cco-kiwi.md` §3/§8

## 3. 独立实现说明

单文件 HIP C++；两进程 = fork（**fork 必须先于任何 HIP 调用**——fork 进已初始化的
runtime 是 UB，第一次运行挂死验证了这一点）；进程间同步 = flock-free 标志文件
（mori `local_bootstrap.cpp` 文件 barrier 的极简版），文件在 fork 前创建（第二次踩坑：
child 的 open 落空导致 set/wait 全部失效）。

## 4. Reference / Correctness Test

期望值独立推导：payload 每 word = seed 派生 XOR 序列；CAS 终值唯一；epoch 槽回绕
比较。child 全程无缓冲 stdout（`_exit` 会丢缓冲——第三次踩坑）。

## 5. 构建

```bash
demos/hardware/ipc_symmetric_heap/scripts/build_run.sh   # 容器内
```

## 6. Inspection

`results/run_gfx1030.log` 含双方进程完整输出与两个不同 VA 的记录。
如需 IPC 路径的内核级观察：`strace -f -e trace=ioctl` 观察 KFD 对
`AMDGPU_KFD_IOCTL_IPC_HANDLE` 类调用（未归档）。

## 7. Hardware Matrix

| 架构 | 结论 |
|---|---|
| **gfx1030 + ROCm 7.16（本机）** | ✅ 同卡双进程 IPC 全链路可用（T1-T4 全过） |
| gfx942/950/1250 | 上游生产路径（ mori CI 覆盖），未在本机验证 |
| 限制 | 单 GPU 无跨设备 P2P 拓扑；IPC 映射仅同卡——与 mori "sameHost → P2P" 决策链一致 |

## 8. Execution Result

`results/run_gfx1030.log`：ALL PASS（child_rc=0 parent_rc=0）。
**ARCH_MATRIX 回填**：`hipIpcOpenMemHandle 双进程单卡` ⚠️→✅；
`VMM hipMemCreate/Map` 仍待测（本 demo 未用 VMM，平坦 VA 槽位是另一条路）；
`__builtin_nontemporal_*` 已在 Demo 2 顺带实测（slc 位生效）。

未验证事项：VMM flat-VA（hipMemAddressReserve/Map/SetAccess）跨进程；IPC handle 的
ordinal-0 规避场景（本机单卡 ordinal 固定 0 天然成立）；高轮次 epoch 回绕溢出。
