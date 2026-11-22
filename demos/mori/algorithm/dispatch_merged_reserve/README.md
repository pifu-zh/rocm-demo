# dispatch_merged_reserve — EP dispatch 的合并远端原子预留

**类目**: algorithm ｜ **验证等级**: `HARDWARE_PASS`（gfx1030 容器实测，见 `results/run_gfx1030.log`）

## 1. 原理说明

MoE expert-parallel dispatch 中，每个 token 的 topk 个目的 expert 分散在不同 GPU peer 上。
接收侧用"槽位分配器"（per-peer 递增 offset）给每个到达的 (token, expert) 分配接收槽。

**朴素做法**：每条路由一次 `atomicAdd(&offsets[p], 1)` —— 远端 RMW 次数 = 路由数
（真实场景 4k token × topk 8 = ~32k 次跨设备原子，每次都是一条网络/互联事务）。

**mori 的做法**（Phase 1→2→3 三相）：
1. Phase 1：block 内先在 **SMEM** 里数出本 block 给每个 peer 的 token 数 `s_N[p]`
   （顺带做 topk dedup：同一 token 的更早 expert 槽已选同 peer 则丢弃）；
2. Phase 2：每个 (block, peer) **只发一次** `atomicAdd(&offsets[p], s_N[p])`，
   一次性预留 `s_N[p]` 个**连续**槽位；
3. Phase 3：用 SMEM base + 本地游标写入槽位，不再有任何远端原子。

效果：远端 RMW 从 O(tokens×topk) 压到 O(blocks×npes)。本 demo 实测（65536 token、
topk 8、去重后 344,149 条路由、128 blocks × 8 peers）：

| 路径 | 远端 atomicAdd 次数 | 用时（信息性） |
|---|---|---|
| per-pair naive | 344,149 | 0.277 ms |
| mori merged | **1,024**（336× 压缩） | 0.082 ms（3.4×） |

**可迁移的普遍思想**：把"每元素一次远端 RMW"改为"分块聚合 → 每块每目的地一次
批量 RMW + 本地游标填写"。适用于任何槽位分配型协议（消息队列、接收表、种子填充）。

## 2. 上游出处

- 上游 pin：ROCm/mori @ `c5bdc3913660f6b663ae09ba7c7176291d6f5343`
- `src/ops/dispatch_combine/intranode.hpp:117-150`（Phase 1 计数 + dedup）
- `src/ops/dispatch_combine/intranode.hpp:153-161`（Phase 2 单次预留 —— 本 demo 核心）
- `src/ops/dispatch_combine/intranode.hpp:163-212`（Phase 3 槽位填写，含循环边界逐字一致的警告注释）
- 考古报告：`docs/archaeology/03-collective-ops.md` §2.1（E1 条目）

## 3. 独立实现说明

- 不依赖 mori 源码/工具：纯 HIP C++ 单文件。
- "对端"退化为同一 GPU 上 per-peer 的连续槽位数组；协议结构（SMEM 计数→单次预留→
  游标填写）与上游逐相一致。
- 保留了上游的 topk dedup 语义（`laneId < k` 更早槽位同 dest 则丢弃），这是槽位
  总数 ≠ tokens×topk 的原因（344,149 < 524,288）。

## 4. Reference 与 Correctness Test

- Host 参考实现 `RefRoute()`：独立计算每 peer 应收到的 (token,k) **多重集合**。
- 每世代每路径校验：① offsets 终值总和 == 期望总数；② 每 peer 收到的多重集合与
  参考完全一致（顺序无关，槽位写入顺序依赖 block 调度，这正是"槽位是集合不是序列"
  的契约）；③ 每 peer 槽区间无洞（哨兵 -1 检查）；④ 远端 RMW 计数器精确等于
  理论值（naive=路由数；merged=host 按 block 划分精确计算的 Σ(块,peer,sN>0)）。
- 3 个世代重复（offsets 复用，覆盖 reset 语义）。

## 5. 构建

```bash
# 容器内（gfx1030）：
demos/algorithm/dispatch_merged_reserve/scripts/build_run.sh
```
CMake + HIP，`-O2`，无第三方依赖。

## 6. Inspection

- 设备代码经 `hipcc` 默认全管线编译；如需 ISA 观察：
  `hipcc --genco --offload-arch=gfx1030 src/dispatch_merged_reserve.hip -o /dev/null`。
- Phase 2 的远端原子在 ISA 上表现为一条 `s_atomic_add`/`v_atomic` + 后续等待，
  Phase 3 的 SMEM 游标是 `ds_*` 指令族 —— 与 naive 的逐条原子形成对照。

## 7. Hardware Matrix

| 架构 | 适用性 | 依据 |
|---|---|---|
| gfx942/950/1250（mori 官方） | 上游原样适用 | intranode.hpp |
| gfx1030（本实验） | ✅ 实测通过（warpSize=32 下 SMEM 相协议成立） | results/run_gfx1030.log |
| 注意 | 上游假定 wave64 组织（kBlockThreads=512）；本 demo 在 wave32 亦正确，因为协议只用 SMEM+block 级原子，不依赖 wavefront 宽度 | — |

## 8. Execution Result

见 `results/run_gfx1030.log`（2026-11-18，容器 rocm10-dev:10.1.0，HIP 7.16，RX 6950 XT）：
3 世代 × 2 路径全部 PASS，RMW 计数精确匹配，merged 336× 原子压缩。

未验证事项：真实跨设备（XGMI/IPC 跨进程）场景未测——本机单卡；上游实测数字
（811-826 行注释的 +8.7% 完成协议优化等）与本 demo 的完成协议部分未复刻。
