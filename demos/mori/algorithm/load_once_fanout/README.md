# load_once_fanout — Load-once-write-many 扇出 + 寄存器 dedup（EPv1 IntraNodeLL 核心）

**类目**: algorithm ｜ **验证等级**: `HARDWARE_PASS`（gfx1030 实测，`results/run_gfx1030.log`）

## 1. 原理说明

EPv1 IntraNodeLL（token 中心的低延迟 dispatch）标注了三条优化
（`intranode_ll.hpp:234-247` 注释），本 demo 复刻其中两条半：

1. **Load-once-write-many**（:83-132）：payload 只从 HBM 读**一次**进寄存器，
   然后写 N 个目的——省 (N-1)/N 的 HBM 读。关键支撑是
2. **readlane 指针广播**（:61-67）：两次 32 位 `v_readlane_b32` 拼回 64 位指针，
   让 wave 内所有 lane 拿到**同一个 SGPR-uniform 指针**（否则每个 lane 各自算指针
   会产生 N 份地址计算与更宽的寻址占用）。本机 HIP 用 `__shfl_sync` 两个 32 位半段
   复现同一语义（gfx1030 无裸 readlane builtin 暴露，wave 内 shfl 读寄存器等价）。
3. **寄存器 dedup**（:151-206 ComputeTokenRoute 的最小化）：一个 wave 的 lane
   0..topk-1 各持一个目的，PE-lane 用 readlane 扫全部槽位、ballot 压缩活动表——
   **零内存**完成 topk 去重。

**实测结果**（8192 token × topk 8，随机路由）：

| 检验 | 结果 |
|---|---|
| 寄存器 dedup 目的集合 == host 参考 | **8192/8192 全对**（初版 8109 失败 → 收敛性修复） |
| load-once 扇出与 naive 逐 dest 重读 byte-wise 一致 | MATCH |
| 计时（信息性） | 两者相当（0.0072 vs 0.0074ms）——payload 段小到全进 L2，load-once 的 HBM 省读优势在更大的 payload / 远端内存（真实 EP 场景 payload 在对端显存）才显性化 |

**本 demo 的核心教学点是收敛性陷阱**：dedup 循环初版写成 `for (j < lane)`——每个
lane 的 trip count 不同，`__shfl_sync` 的 mask 内 lane 在循环迭代处不收敛 → 乱值
（8109/8192 mismatch）。修复为"所有 lane 统一 `j < kTopK`、循环内 `j < lane` 守卫"
后 100% 通过。**这正是 mori 源码用"PE-lane 扫全部 topk 槽"统一 trip count 的原因**
——从失败里读出的上游设计动机，比直接抄代码学得更深。

## 2. 上游出处

- `src/ops/dispatch_combine/intranode_ll.hpp:61-67`（ReadLanePtr）
- `src/ops/dispatch_combine/intranode_ll.hpp:83-132`（WarpLoadBroadcastStore）
- `src/ops/dispatch_combine/intranode_ll.hpp:151-206`（ComputeTokenRoute 寄存器 dedup）
- 考古报告：`docs/archaeology/03-collective-ops.md` §2.2（E3 条目）

## 3. 独立实现说明

单文件 HIP C++。HIP 7.16 的 `__shfl_sync`/`__ballot_sync` 要求 **64 位 mask**
（32 位触发 static_assert——HIP 版本差异实证，AMD warp sync functions 头文件
:277）。块-每-token 布局（block-per-token，mori 第三条优化的结构前提）。

## 4. Reference / Correctness Test

dedup 期望集合 = host 独立 `std::set` 折叠；扇出正确性 = 与 naive kernel 的
byte-wise 全等（两条独立 kernel 路径互证）。

## 5. 构建

```bash
demos/algorithm/load_once_fanout/scripts/build_run.sh   # 容器内
```

## 6. Inspection

`results/run_gfx1030.log`。ISA 观察（v_readlane 是否生成）：
`hipcc -c --offload-arch=gfx1030` 后 unbundling + objdump 查 `v_readlane_b32`/
`v_mov_b32`（本 demo 未归档 ISA，留待交叉验证轮）。

## 7. Hardware Matrix

gfx1030（wave32）实测。mori 上游假定 wave64（EPv1 wave64-only）；本 demo 把
wave 结构映射到 wave32 的 8-lane 活跃子集——协议（shfl 收敛/ballot 压缩）与
wave 宽度无关。gfx942 等未测。

## 8. Execution Result

ALL PASS（2026-11-18）。dedup 初版失败→收敛性修复的全过程记录在源码注释与
本 README——失败模式本身就是该 demo 的核心交付物之一。

未验证事项：大 payload / 对端显存上的 load-once 带宽优势量化；控制面/数据面
ping-pong 流水（mori 第三条优化）。
