# io_sim_model — MORI-IO sim 后端的独立复现（纯 CPU）

**类目**: emulation ｜ **验证等级**: `REFERENCE_PASS`（10/10 语义测试；无 HIP 参与，
模型参数取自上游实测标定目录）

## 1. 原理说明

MORI-IO sim backend 是 mori 官方的"无硬件验证通信语义"路径
（`sim/backend_impl.hpp:46-49`）：

> Hardware-free stand-ins for the RDMA / TCP / XGMI backends.
> Registration, routing, sessions, the TCP control plane and notifications run
> **for real**; only the data movement is replaced by a modelled delay.

**架构精髓：控制面与数据面解耦**——注册/寻址/会话/故障上报全部真实运行，
只有字节搬运被延迟模型替换。因此真实引擎（sglang PD 分离）可以不改一行代码
跑在 GPU-free 模拟器上。本 demo 把这个架构还原为独立 C++ 库：

- **延迟模型**（`ReserveLink` :631-642 逐项复刻）：
  `busy = bytes/BW + segments·perSeg + perOp`；每方向一条 FIFO 链路
  （`freeAt = max(now, freeAt) + busy`）；完成时刻 = 占用结束 + 传播延迟。
- **失败语义**：AskMemory 远端内存校验失败 → op failed + 本端对 peer 的 dead 视图 +
  PeerFailureEvent（`MarkPeerDead` :562-573 / `PopPeerFailure`）——模拟"真实
  QP/MR 建立失败"的可观测行为。
- **子区视图**：一次大分配（paged KV-cache）的 per-layer 子区通过基址+尺寸检查
  （上游 `desc.ipcOffset` 思想的简化）。
- **标定目录数值**：`sim_catalog.yaml` 的实测数字直接生效——
  mi355x XGMI 61.4 GB/s / 9µs / 19.5µs-per-seg；pollara400 RDMA 47.4 GB/s / 20µs / 255ns-per-seg。

**测试矩阵**（10/10 PASS，`results/run_cpu.log`）：

| 测试 | 验证点 |
|---|---|
| T1 ×2 | 延迟模型公式（大流量与多段小流量两形态） |
| T2 | 每方向 FIFO 排队（第二个 1GB 完成时刻 = 第一个 + busy₂） |
| T3 | TIME_SCALE 加速（10× 下完成时刻按比例缩短） |
| T4 ×2 | 上游标定目录数值代入后公式闭合（±2%） |
| T5 ×2 | 越界 → op failed + dead 视图 + PeerFailureEvent 消费 |
| T6 | 16MB 大分配的 4MB 偏移子区通过 / 20MB 越界拒绝 |

**顺带钉死的两个工程坑**（复现过程中实测）：
1. `MarkPeerDead` 的语义是**本端对 peer 的死亡视图**（peer 失联 → 本端记录并可消费
   事件），不是把对端标死——初版断言写反。
2. 测试宏 `CHECK(cond)` 把条件求值两次，`ConsumeFailureEvent` 有副作用 → 第二次
   求值永远 false → 幽灵失败。单次求值的宏写法是测试基建的必修课。

## 2. 上游出处

- `src/io/sim/backend_impl.hpp:46-49`（定位声明）
- `src/io/sim/backend_impl.cpp:575-664`（Submit/ReserveLink/TimerLoop/Complete）
- `src/io/sim/backend_impl.cpp:562-573,666-691`（MarkPeerDead/失败复查）
- `python/mori/io/sim_catalog.yaml`（标定目录实测数字）
- `tests/python/io/test_sim_backend.py`（上游官方测试——本 demo 测试矩阵的对应物）
- `docs/MORI-IO-GUIDE.md:195-202,256-258`（GPU-free 推理引擎模拟；模型已知缺口）
- 考古报告：`docs/archaeology/04-io-umbp-ras.md` §2、`docs/EMULATION_CATALOG.md` E-13

## 3. 独立实现说明

头文件库 + 测试（C++20，无 HIP、无 msgpack/TCP 依赖）。TCP 控制面以"本地回调总线"
替位——协议语义（校验→排队→完成/故障）保留，传输介质省略；上游已知缺口
（模型不封顶单 transfer 带宽）未复刻，如实记录。

## 4. Reference / Correctness Test

全部期望值由公式独立计算（非被测代码自证）；上游 YAML 数值作为外部真值锚点。

## 5. 构建

```bash
demos/emulation/io_sim_model/scripts/build_run.sh   # 容器内（宿主无编译器）
```

## 6. Inspection

`results/run_cpu.log`（10 测试输出）。上游对照物：`tests/python/io/test_sim_backend.py`
（420 行，可在装了 mori Python 包的机器上直接跑——本 Lab 未安装 mori 包，属构建层排除项）。

## 7. Hardware Matrix

**纯 CPU**——设计即 hardware-free（这正是它的复现价值：任何机器可跑）。
XGMI/RDMA 介质参数来自上游对 MI355X/Pollara 400 的实测标定（2026-10-28）。

## 8. Execution Result

ALL PASS（2026-11-18）。未验证事项：真实 TCP 控制面（AskMemory/Notif 的网络传输）、
TimerLoop 的 prctl(PR_SET_TIMERSLACK) 精度优化、故障注入规则引擎（RDMA backend 侧）。
