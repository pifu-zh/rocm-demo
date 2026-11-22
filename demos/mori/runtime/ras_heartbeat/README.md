# ras_heartbeat — MORI RAS 心跳与退出检测复现（纯 CPU）

**类目**: runtime ｜ **验证等级**: `REFERENCE_PASS`（6/6 协议语义测试；纯 CPU 无 GPU 参与）
**上游对应**: 该 Demo 的上游模块正是研究对象 commit `c5bdc391` 的主体（"feat(ras): heartbeat links between MORI-IO peers, with exit detection (RAS 2/5) #909"）。

## 1. 原理说明

MORI RAS 是 per-process 运行时：用自己的 **out-of-band TCP 链路**（与 IOEngine 控制面
分立）监视 peer 健康，供上层做退出检测。核心三件事：

1. **心跳协议 v1**（36B 定头 + msgpack 体）：HELLO / HEARTBEAT / HEARTBEAT_ACK / LEAVE
   严格解码。时序参数（`ras/config.hpp:43-61`）：
   `heartbeat=1000ms`；`HeartbeatTimeout = max(20s, 3×heartbeat)`；`PeerGone=60s`；
   `Handshake=5s`。
2. **心跳时钟数学**（`heartbeat.hpp:24-31`——全模块最有教学价值的一段）：
   ACK **回显**发送方发送时刻 + 携带对端持有时长 + 对端发送时刻 → 发送方据此算
   **RTT 与两机钟差**，"nothing compares two machines' monotonic clocks"——单调钟
   永不跨机比较，全靠 ACK 回显对齐。
   本 demo 实测：peer 注入已知 **+5.000s** 发送时刻偏差，observer 从 ACK 中算出
   **offset=5.000s**（容差 ±1s，实际精确到毫秒级）。
3. **退出检测状态机**（`link.cpp:387-405,1065-1084`）：
   LEAVE=干净退出；LINK_CLOSED/RST=崩溃（立即）；HEARTBEAT_TIMEOUT=静默；
   被拒重连持续 60s → kGaveUp。

**实测矩阵（6/6 PASS，`results/run_cpu.log`）**：

| 测试 | 注入方式 | 结果 |
|---|---|---|
| T1 握手 + 3 轮心跳 + 双向 LEAVE | 正常路径 | PASS |
| T2 时钟数学 | peer 注入 +5.000s 偏差 | **offset=5.000s** 精确恢复，rtt<0.5ms |
| T3 对端 LEAVE | peer 主动退出 | CLEAN_EXIT（不等待超时） |
| T4 SIGKILL 崩溃 | fork 子进程被 kill -9 | LINK_CLOSED → PEER_CRASHED（内核 FIN/RST 即时） |
| T5 静默死亡 | 连接保持、心跳不回不关 | HEARTBEAT_TIMEOUT → SILENT_TIMEOUT |
| T6 重连被拒持续 | listener 关闭后重连 | 67 次 refused → GAVE_UP |

T4 与 T5 的区分正是 RAS 的核心价值：**崩溃（内核可见）秒级判定，静默（内核不可见）
靠超时判定**——前者不占超时预算，后者按 max(20s, 3×hb) 判。

## 2. 上游出处

- `include/mori/ras/ras.hpp:24-53`（定位/out-of-band/atexit LEAVE/不跟随 fork）
- `src/ras/config.hpp:43-61`（时序参数与下限）
- `src/ras/link.cpp:296`（epoll 主循环）、`:387-405`（超时判定）、`:1065-1084`（giveUp）
- `src/ras/heartbeat.hpp:24-31`（时钟数学）
- 考古报告：`docs/archaeology/04-io-umbp-ras.md` §5

## 3. 独立实现说明

- 单文件 C++20，纯 TCP/POSIX，零第三方依赖（msgpack 体省略——四类消息体为空，
  36B 定头语义字段与上游一一对齐）。
- 常规测试用单线程双 socket 状态机（TCP loopback 是真实内核路径）；T4 用 fork+SIGKILL
  保留**内核级连接中断**的真实语义（线程模式无法产生真 RST/FIN）。
- 时序可缩放：`MORI_LAB_RAS_HEARTBEAT_MS/TIMEOUT_MS/PEER_GONE_MS`（上游 20s/60s
  下限对测试过长；覆盖下限的旋钮在 config 结构里，与上游"env 覆盖"精神一致）。

## 4. 复现过程中的两个工程教训（已沉淀）

1. **协议 wire 格式用显式序列化，不依赖 pack 布局**：初版用 `#pragma pack(1)` 结构体
   聚合初始化直发，出现了无法完全根因定位的字段错位（栈内容进了 wire、帧错位）；
   改为**显式偏移序列化**（putU16/putU32/putU64 到固定 offset）后 6/6 全过。
   上游 mori 用 msgpack 正是同一动机——**wire 格式与内存布局解耦**。
2. **测试进程清理纪律**：`pkill -f ras_heartbeat` 会匹配调用 shell 自身的命令行
   （自自杀）；超时被杀的运行会留下持有 listening socket 副本的孤儿子进程，
   **偷走后续运行的连接**（表现为"收到神秘外来字节"）。修复：端口随机化
   （bind port 0 + getsockname）+ 精确 pkill 模式 + 每轮运行前清理。

## 5. 构建

```bash
demos/runtime/ras_heartbeat/scripts/build_run.sh   # 容器内（纯 CPU 部分）
```

## 6. Inspection

`results/run_cpu.log`（6 测试输出）。协议头布局见源码 `RasHeader` 注释（36B 字段表
与上游语义字段一一对应）。RTT/钟差公式见 `processAck()`。

## 7. Hardware Matrix

纯 CPU——任何机器可跑（这正是 RAS 的定位：out-of-band 监控不依赖 GPU/NIC）。
两机场景的钟差恢复数学已由注入偏差验证；真实两机（跨机墙钟）未测（单机环境）。

## 8. Execution Result

ALL PASS（2026-11-18，容器 g++ 13.3）。未验证事项：msgpack 体编码、多 peer 星型
拓扑（本 demo 单对链路）、epoll 主循环（select 替位）、LEAVE 的 atexit 路径、
跨机真实钟差。
