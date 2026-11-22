# vmm_flat_va_probe — CCO LSA 的物理层前提探测（VMM 平坦 VA + 跨进程互映射）

**类目**: hardware ｜ **验证等级**: `HARDWARE_PASS`（probe 级，2026-11-18 实测）
**实验地位**: 判决 `docs/ARCH_MATRIX.md` 的最后一个 ⚠️——CCO LSA（Local Symmetric
Access，flat-VA 槽位寻址）在 gfx1030 上的物理前提**成立**。

## 1. 原理说明

CCO 与 SHMEM 的本质区别（考古 02 §3）：SHMEM 对称堆是"各自分配 + IPC handle 交换 +
查表寻址"，CCO 是 `hipMemAddressReserve` 一段**平坦 VA**、每个 rank 的窗口在所有
进程的同一槽位互为镜像，device 代码一个公式即可寻到任意 peer：

```
peer_va = winBase + (peerLsaRank * stride4G) << 32 + offset     （cco.hpp:288-305）
```

这条公式成立的前提是三层物理能力。本探测逐层验证（HIP 7.16 API 形态）：

| 层 | API | 结果 |
|---|---|---|
| P1 平坦 VA 多槽位 | `hipMemAddressReserve(4GB, align 2GB)` | ✅ base=0x7828cbc00000 |
| P2 物理块+映射 | `hipMemCreate(Pinned, FD-exportable)` + `hipMemMap` + `hipMemSetAccess` | ✅ |
| P3 槽位语义 | H2D→D2H roundtrip 经设备路径 | ✅ 逐位一致 |
| P4 跨进程互映射 | `hipMemExportToShareableHandle(POSIX FD)` → fork（fd 直接继承）→ 子进程把**同一物理块** map 到自己的槽位 → 读 parent 写的数据 | ✅ 0/64 mismatch |

对上游实现的关键校准（版本差异实证）：
- HIP 7.16 的枚举是 `hipMemHandleTypePosixFileDescriptor/Fabric`——考古 01 引用的
  `hipMemAllocationTypeUncached`/Generic 名在本版本不存在/不同名；mori 自己就有
  ROCm 版本分支（`cco_init.cpp:194-222`）。
- **host 不能直接写 VMM 映射页**（P3 初版裸指针写 = SIGSEGV）——mori 的 LSA 访问
  全部经 kernel/memcpy 设备路径，这正是设计约束而非巧合。
- fork 场景 POSIX FD 由子进程直接继承，无需 SCM_RIGHTS（mori 的 FD 回退路径在
  多进程场景的简化形态）。

## 2. 上游出处

- `src/cco/cco_init.cpp:726-744`（flat VA reserve）、`:826-963`（ccoMemAlloc）、
  `:1373-1420`（fabric token / FD 回退互映射）
- `include/mori/cco/cco.hpp:288-305,695-701`（peer_va 公式）、`:649-816`（LSA barrier）
- 考古报告：`docs/archaeology/02-shmem-cco-kiwi.md` §3、`docs/archaeology/01-framework-core.md` §5.8

## 3. 独立实现说明

单文件 C++（hip::host），不依赖 mori。API 序列对照 cco_init.cpp；探测窗口缩小为
2GB×2 槽（上游 perRank 4GB）。

## 4. Reference / Correctness Test

P3/P4 期望值独立构造（0xDEADBEEFCAFE0000+i 序列），memcmp 全量比对。

## 5. 构建

```bash
demos/hardware/vmm_flat_va_probe/scripts/build_run.sh   # 容器内
```

## 6. Inspection

`results/run_gfx1030.log`。P3 初版 host 写 SEGV 的教训记录于源码注释——
"VMM 页只对设备路径可见"是 LSA 使用纪律的物理依据。

## 7. Hardware Matrix

gfx1030 + HIP 7.16：P1-P4 全过。与 Demo 6（IPC 路径）互补——**两条对称内存路径
（IPC handle 与 VMM flat-VA）在本机都成立**，shmem 查表寻址与 CCO 公式寻址的
介质前提同时具备。

## 8. Execution Result

ALL PASS（2026-11-18）。未验证事项：Fabric handle（需 fabric 硬件支持探测）；
dma-buf 路径（`hsa_amd_portable_export_dmabuf`）；大槽数/槽耗尽行为；hipMemUnmap
后的 VA 复用。
