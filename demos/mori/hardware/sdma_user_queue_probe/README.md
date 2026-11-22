# sdma_user_queue_probe — anvil 用户态 SDMA 队列在 gfx1030 上的可行性探测

**类目**: hardware ｜ **验证等级**: `HARDWARE_PASS`（probe 级，2026-11-18 实测）
**实验地位**: 判决 `docs/ARCH_MATRIX.md` 的关键 ⚠️——"anvil 的 gfx9 SDMA 包布局，
gfx1030 能否被驱动"的前半问（队列基础设施）答案为**可行**。

## 1. 原理说明

mori 的 SDMA 线（anvil，源自 David Sidler 的 shader_sdma）让 **GPU kernel 直接构造
SDMA 包写入 KFD 用户态队列环，写 MMIO 门铃唤醒 copy engine**——CU 只发描述符，
带宽由专用 copy engine 提供。其基础设施依赖三层：

1. KFD 用户态接口（libhsakmt）：打开 KFD、枚举 GPU 节点的 SDMA 引擎数；
2. 队列环缓冲：`hsaKmtAllocMemory(NonPaged|HostAccess|PageSize4K|NoNUMABind|
   ExecuteAccess|Uncached, 256KB)` + `hsaKmtMapMemoryToGPU`（CPU 与 SDMA 引擎共见）；
3. 用户态队列：`hsaKmtCreateQueueExt(nodeId, HSA_QUEUE_SDMA_BY_ENG_ID, 100,
   HSA_QUEUE_PRIORITY_MAXIMUM, engineId, queueBuf, size, NULL, &queue)` ——拿到
   `Queue_write_ptr_aql / Queue_read_ptr_aql / Queue_DoorBell_aql` 三个用户态句柄。

**实测结论（gfx1030 + ROCm 7.16 容器）**：

| 层 | 结果 |
|---|---|
| P1 KFD 打开 + GPU 节点枚举 | node 1（KFDGpuID=61356）：**4 SDMA 引擎 × 8 队列/引擎**，XGMI 引擎 0（单卡无 XGMI——与拓扑一致） |
| P2 队列环分配 + 映射 | 256KB uncached+execute 成功 |
| P2 SDMA 用户队列创建 | **4 个引擎全部 SUCCESS**（HSA_QUEUE_SDMA_BY_ENG_ID, engine 0..3） |
| P3 用户态指针可访问 | wptr/rptr/doorbell 全部非空且可解引用 |

对上游结论的修正：考古报告 01/02 曾按"anvil 是 gfx9 packet 布局"推断 gfx1030
不可用（02 §6/#11、ARCH_MATRIX ⚠️）。**本探测证明推断过保守**：队列基础设施层
完全 arch 无关（KFD ABI），不可用的只是包格式层（SDMA4 的 COPY_LINEAR 布局 vs
gfx1030 的 SDMA5）——把"不可行"的范围从整条 anvil 线缩小到包编码一层。
这正是"探测优先于推断"的价值。

**下一步（记录为后续实验）**：写一个 SDMA5 COPY_LINEAR 包验证 D2D 拷贝 +
`SDMA_PKT_ATOMIC(ADD64)` signal 闭环（anvil_device.hpp 的 put/quiet 协议移植）。
风险点：SDMA5 的 32B-unit 包格式与 gfx9 的差异（mori `sdma_pkt_struct.h` 是
gfx9 vendored 版）。

## 2. 上游出处

- `src/application/transport/sdma/anvil.cpp:106-110`（SetUpKFD）、`:235-286`（SdmaQueue
  构造——本探测 P2 的直接母本）、`:61-62`（hsakmt 版本坑注释）、`:199-212`（engine 掩码）
- `include/mori/core/transport/sdma/anvil_device.hpp:194-345`（设备侧包协议）
- `src/application/transport/sdma/sdma_pkt_struct.h`（gfx9 包格式 vendored）
- 考古报告：`docs/archaeology/01-framework-core.md` §3.4、`docs/EMULATION_CATALOG.md` E-04

## 3. 独立实现说明

单文件 C（libhsakmt 静态链接），不依赖 mori 代码。API 序列逐一对照 anvil.cpp。
链接链（容器内静态库的闭包）：`libhsakmt.a + libdrm_amdgpu.so + librocm_sysdeps_drm.so.2
+ libnuma.so.1 + pthread + rt`——与 mori 的 CMake FindHsakmt 面对同一组依赖。

## 4. Reference / Correctness Test

探测型 demo：正确性判据是 hsaKmt 返回码与指针非空；不写包（包格式属后续实验）。

## 5. 构建

```bash
demos/hardware/sdma_user_queue_probe/scripts/build_run.sh   # 容器内
```

## 6. Inspection

`results/run_gfx1030.log`（完整探测输出）。对照物：上游
`examples/sdma/sdma_self_copy_test.cpp`（gfx9 单机 SDMA 测试——需要 mori 全库）。

## 7. Hardware Matrix

| 架构 | P1-P3 结果 |
|---|---|
| gfx1030 + ROCm 7.16（本机） | **全部通过**（4 引擎可建用户队列） |
| gfx942/950/1250 | mori 生产路径，未在本机验证 |
| 已知边界 | 包格式层未验证（SDMA5 ≠ SDMA4）；XGMI 引擎数=0 |

## 8. Execution Result

P1/P2/P3 全过（2026-11-18）。destroy 干净，无残留队列。
未验证事项：写包并执行拷贝、门铃 MMIO 写、signal+quiet 闭环、多队列并发。
