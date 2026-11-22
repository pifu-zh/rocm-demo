# proxy_ring_publish_order — GPU→CPU 发布协议（mori ProxyRing 的内存序核心）

**类目**: hardware ｜ **验证等级**: `HARDWARE_PASS` + `STATIC_ANALYSIS_PASS`
（200 轮 × 4096 命令压力实测；ISA 证据见 `results/isa/`）

## 1. 原理说明

mori 的 CPU host-proxy（IBGDA 不可用时的 fallback，E-01/E-02）依赖一个精确的
**GPU→CPU 发布协议**：

```
设备端（proxy_device_primitives.hpp:58-77）:
  填 128B ProxyCmd payload
  __threadfence_system()            ← release 屏障，payload 必须先于 status 可见
  __atomic_store_n(&status, PENDING, RELAXED)

宿主端（proxy_thread.cpp:290-410）:
  acquire 读 status == PENDING      ← 此刻 payload 必然完整
  消费命令 → 回写 COMPLETED
```

关键点：**status 一个字的翻转是"门铃"**，payload 的完整性靠发布序保证，而不是靠
更大的原子单位。这正是 doorbell/status 协议族的通用模式（mori ProxyRing、CCO
notify、kiwi LL8 队列的信号即数据保护，全都依赖同一硬件序原语）。

本 demo 在单 gfx1030 上复刻最小闭环：

| 实验 | 结果 |
|---|---|
| 正确协议（fence）200×4096=819,200 命令 | **撕裂 0**，acquire 读到 PENDING 时 payload 100% 完整 |
| 违规协议（去 fence）同规模 | **撕裂 0（本机实测）**——见下"诚实记录" |
| `__threadfence_system` 的 ISA 形态 | RDNA2 上 = `s_waitcnt_vscnt null, 0x0`（等全部 vector store 完成）+ `s_waitcnt vmcnt(0)/lgkmcnt(0)` |
| 设备自旋卫生（信息性） | s_sleep 背压 vs 纯自旋在本机往返延迟上不可区分（~5µs，受 flag 写入路径主导） |

**诚实记录（认识论卫生）**：违规变体在本机（gfx1030 + x86 宿主 + PCIe posted-write
顺序）未观测到撕裂——PCIe 对同一线程的 posted write 保持顺序，加上 -O2 下编译器
没有重排 payload/store，UB "看起来能用"。这**不构成正确性证据**：内存模型层面该
顺序无保证（其他 GPU/编译器/IO 路径可能重排；mori 源码在 fence 处的注释本身就是
对这个问题的回答）。demo 输出如实打印两条路径的数字，不把违规变体的"通过"计入
判据（failures 只统计正确协议的撕裂）。

## 2. 上游出处

- `include/mori/core/transport/rdma/proxy/proxy_device_primitives.hpp:58-77`（发布序）
- `include/mori/core/transport/rdma/proxy/proxy_types.hpp:31-99`（ProxyRing/状态机）
- `src/application/transport/rdma/proxy/proxy_thread.cpp:39-47`（s_sleep 背压）、`:290-410`（消费循环）
- `src/shmem/init.cpp:618-637`（hipHostRegister(Mapped|Portable) 装配同款）
- 考古报告：`docs/archaeology/01-framework-core.md` §3.1、§3.2（内存序总表）

## 3. 独立实现说明

单文件 HIP C++。ring 缩小为 4096 cmd；CPU proxy 退化为宿主线程自旋消费；
hipHostMalloc(Mapped|Portable) 复刻 mori 的 host-mapped 共享内存装配。
校验 payload = 每 word 等于 seq 派生的期望值（64B 全字比对）。

## 4. Reference / Correctness Test

正确性判据 = fence 变体零撕裂（819,200 命令全字校验）；违规变体仅记录实测撕裂数。
设备侧 seq/payload 生成与宿主期望值独立推导，无共享实现。

## 5. 构建

```bash
demos/hardware/proxy_ring_publish_order/scripts/build_run.sh   # 容器内
```

## 6. Inspection

- `results/isa/proto.full.s`：完整反汇编；fence 处的 `s_waitcnt_vscnt null, 0x0`
  是 RDNA2 system-scope fence 的落点（mori anvil_device.hpp:60-66 对 gfx9 用
  `s_waitcnt(0)`、gfx1250 用 release fence——三代的 fence 形态各不相同，本机
  实测给出了 RDNA2 这一代的实证）。
- `results/run_gfx1030.log`：压力数字与自旋对照。

## 7. Hardware Matrix

| 架构 | fence 落点 | 依据 |
|---|---|---|
| gfx9（mori 官方） | `__builtin_amdgcn_s_waitcnt(0)` | anvil_device.hpp:60-66 |
| **gfx1030（本实验）** | `s_waitcnt_vscnt null, 0x0`（实测） | results/isa/proto.full.s |
| gfx1250（mori 官方） | release fence（无 s_waitcnt） | anvil_device.hpp:60-66、cco_scale_out.hpp:679-685 |

## 8. Execution Result

`results/run_gfx1030.log`（2026-11-18，HIP 7.16，RX 6950 XT）：ALL PASS
（fence 协议 0 撕裂；racy=0 记录在案并附解释）。

未验证事项：多 NIC 消费者并发（ProxyThread 批量 post/ENOMEM 重试路径）；
rdma 数据面本身（无硬件）；跨 NUMA 主机撕裂率差异。
