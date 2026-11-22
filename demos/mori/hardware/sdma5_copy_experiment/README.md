# sdma5_copy_experiment — SDMA5 COPY_LINEAR 包适配实验（gfx1030 用户态队列）

**类目**: hardware ｜ **验证等级**: `HARDWARE_PASS`（COPY 线性拷贝，10/10 NT 校验全过）+
**实验性结论**（ATOMIC 不可执行，两种编码已试；NOP 会卡死引擎）
**实验地位**: 判决 mori anvil（shader_sdma）路径在 gfx1030 上的可行性——
队列基础设施（probe）+ **包执行（本实验）** 都成立，atril 线在 RDNA2 上对 COPY 有效。

## 1. 原理说明与实验结论

在 `sdma_user_queue_probe` 验证"用户态 SDMA 队列可创建"的基础上，本实验从 **host
侧**直接构造包写入 KFD 用户态队列环（hsaKmtAllocMemory 的 HostAccess 内存），
写门铃 MMIO 触发引擎，逐项验证：

| 实验 | 结果 |
|---|---|
| E1 单包 COPY_LINEAR（28B 包，D2D） | ✅ **执行正确**（rptr 精确推进 + NT-load 校验和精确一致） |
| E1b 尺寸扫描 64KB..2MB | ✅ 全部执行（gfx9 包布局跨 SDMA4/5 兼容——与 mori 注释"gfx1250 仍用 gfx9 布局"一致） |
| E1c 10 包连发量化 | ✅ **10/10 NT 校验全过**（NTsum(dst)==NTsum(src) 位级精确） |
| E2 ATOMIC ADD64 signal | ❌ 包被消费（rptr 推进）但效果不可见——两种编码（operation[31:25]=47 与 sub_op[15:8]=47）都不执行 |
| warmup NOP | ⚠️ **4B NOP 包把引擎卡死**（进程退出/队列销毁后引擎自愈）——gfx1030 该路径不接受此 NOP |

### 两个核心发现

**发现 1：gfx1030 的 KFD 用户态 SDMA 队列接受 gfx9 布局包并正确执行 COPY。**
考古阶段按"anvil 是 gfx9 包布局"推断 gfx1030 不可用（02 §6/#11）——本实验
把该推断的范围进一步缩小到：COPY 族全兼容；ATOMIC 不可执行（两编码已试）；
NOP 不可用。mori 的 anvil 设备代码（SdmaPutThread/Warp + CopyPacket）在
gfx1030 上**编译后即可用**（前提：host 侧队列创建/门铃发布协议按本实验路径）。

**发现 2：SDMA 写绕过 L2，读取方必须用 nontemporal load（gfx1030 的一致性手段）。**
这是本实验最曲折也最有价值的发现，因果链：
1. 包执行后 `hipMemcpy D2H`/普通 load 读 dst 全零（多次"失败"）
2. 排除 L2 脏行写回覆盖（把 scrub 移到拷贝前）→ 仍零 → **读路径问题**
3. `hipMemcpy D2D` 做 L2 驱逐无效——**D2D 本身走 SDMA，SDMA 访问绕过 L2**
4. **SM kernel + `__builtin_nontemporal_load`（glc/slc 直读内存）→ 读到 SDMA 写入的正确数据** ✅

这就是 mori 在 `p2p/device_primitives.hpp:130-220` 让 WarpCopy 全用
`__builtin_nontemporal_*` 的原因；也是 mori 在 gfx940/950 用 `buffer_wbl2`/
`buffer_inv`（SDMA-L2 一致性，考古 03 §5.6）的问题本质——**gfx1030 两条指令
都不存在，NT load/store 是唯一可行的一致性手段**。任何在 gfx1030 上做
SDMA-写后读的代码都必须遵守此纪律。

### 调试过程否定掉的假设（供后续实验参考）
- ~~count 尺寸上限~~（64KB..2MB 全过）
- ~~L2 脏行写回覆盖~~（scrub 前移后仍零 → 读路径问题）
- ~~hipMemset 跨流竞态~~（加 hipDeviceSynchronize 后依旧——竞态真实存在但非主因）
- ~~CPU cache/WC 可见性~~（CLFLUSHOPT 版本曾使引擎卡死，已移除；读回+mfence 保留）
- ~~原子编码位置~~（operation[31:25] 与 sub_op[15:8] 两变体都不执行）

## 2. 上游出处

- `include/mori/core/transport/sdma/sdma_pkt_struct.h`（包布局：COPY 28B/ATOMIC 32B）
- `include/mori/core/transport/sdma/anvil_device.hpp:64-82`（CreateCopyPacket）、
  `:160-172`（CreateAtomicIncPacket）、`:194-345`（队列协议：wptr/门铃=字节偏移）
- `src/application/transport/sdma/anvil.cpp:235-286`（队列创建）
- 考古报告：`docs/archaeology/01-framework-core.md` §3.4、`docs/ARCH_MATRIX.md`

## 3. 独立实现说明

单文件 HIP C++。host 侧直接构造包（显式序列化 putU32——RAS demo 教训），
写入队列环，门铃 MMIO 触发；NT-load 内核做验证（checksumNT/signalNTKernel）。
发布序：memcpy → 读回同页（WC flush）→ wptr → mfence → 门铃。

## 4. Reference / Correctness Test

E1c 的参考 = host 对同一 int 位型视图求和（NTsum(src)）；NTsum(dst) 与之位级
比较。E1/E1b 同法。无"GPU 自证"：src 的参考值完全由 host 独立计算。

## 5. 构建

```bash
demos/hardware/sdma5_copy_experiment/scripts/build_run.sh   # 容器内
```

## 6. Inspection

`results/run_gfx1030.log`（完整 trace：每包 rptr 推进 + NT 校验和）。
链接闭包（容器内）：`libhsakmt.a + libdrm_amdgpu + librocm_sysdeps_drm + libnuma`。

## 7. Hardware Matrix

| 架构 | 结论 |
|---|---|
| **gfx1030 + ROCm 7.16（本机）** | COPY 族 ✅ 全过（含 2MB）；ATOMIC ❌ 两种编码不执行；NOP ⚠️ 卡死引擎 |
| gfx942/950（mori 官方） | anvil 全功能（含 ATOMIC signal 闭环） |
| gfx1250 | mori 注释：仍用 gfx9 布局（无 npd/scope 位） |

## 8. Execution Result

`results/run_gfx1030.log`（2026-11-18）：E1c 10/10 NT 全过；
E2 ATOMIC FAIL（记录两种编码）；诊断中间态见 git 历史。

**未验证/待续**：ATOMIC 的正确 gfx10 编码（需 SDMA5 固件级文档或内核驱动
源码对照）；FENCE/POLL_REGMEM 包（mori 用于 quiet 的替代，未试）；
多引擎并发；性能测量。
