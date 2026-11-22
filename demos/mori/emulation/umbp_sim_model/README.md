# umbp_sim_model — UMBP sim 模式核心复现（纯 CPU）

**类目**: emulation ｜ **验证等级**: `REFERENCE_PASS`（13/13 公式语义测试，纯 CPU）
**上游对应**: `src/umbp/sim/sim.h`（SimTransferEngine）+ `docs/umbp-simulation.md:106-114`
官方公式。与 `io_sim_model`（MORI-IO sim）互补：本 demo 覆盖 UMBP 模型独有的
**多线程拷贝曲线、size_term 对数项、channel_capacity 排队、SSD 半服务语义**。

## 1. 原理说明

UMBP（统一内存带宽池）的 sim 模式保留全部控制面（分配/放置/LRU/tier policy/控制
RPC），把 payload 传输替换为**按路径标定的排队模型**。核心公式
（docs/umbp-simulation.md:106-114）：

```
size_term = log2(max(1, bytes / copies / 4096))
overhead  = latency_ns[p] + copies*copy_latency_ns[p]
          + size_term*(copies*log_size_latency_ns + batch_log_size_latency_ns)
private_ns = overhead + bytes*1e9/bandwidth[p]
service_ns = overhead + bytes*1e9/channel_capacity
channel_available = max(submitted, channel_available) + service_ns
finish = max(submitted + private_ns, channel_available)
```

两个容易误读的语义（本 demo 的测试重点）：
1. **channel_capacity ≠ bandwidth**：单调用带宽（bandwidth，受线程数限制）与通道
   共享容量（capacity，多调用方共享的实测上限）是两个系数；通道服务 FIFO 串行，
   但 **private 执行可与通道排队 overlap**（T2 验证：fin₂ = max(priv₂, serv₁+serv₂)，
   而不是 fin₁+serv₂）。
2. **bandwidth/capacity 的单位是 bytes/秒**（公式 bytes*1e9/bw 的约定）——实现时
   按 B/ns 理解会错一百万倍（本 demo 调试时踩过并记录）。
3. **SSD 读半服务**（serialize_latency=false）：service 只含字节成本，使独立请求的
   延迟可 overlap；写/混合保留全服务（overhead 计入通道）。

**实测矩阵（13/13 PASS）**：T1×5 公式逐项（16MB 单拷贝：size_term=12、overhead/
private/service/finish 精确）；T2 通道 FIFO 串行+private overlap；T3 空闲通道
finish=private only；T4×2 copies 缩放（size_term 用 bytes/copies：÷4 → -2 log2；
overhead copies 项线性）；T5×2 SSD 读半服务/写全服务；T6×2 零字节无字节成本/
共享路径服务求和。

## 2. 上游出处

- `src/umbp/sim/sim.h:60-146`（SimTransferEngine、Path 结构、kModelCount=16）
- `docs/umbp-simulation.md:106-114`（公式原文）、`:41-58`（serialize_latency 语义）、
  `:166-173`（模型已知限制清单）
- 考古报告：`docs/archaeology/04-io-umbp-ras.md` §4、`docs/EMULATION_CATALOG.md` E-14

## 3. 独立实现说明

头文件库 + 测试（C++20，无 HIP/依赖）。Path 用标量字段近似上游的线程曲线
（cpu_cpu 型曲线按线程数索引——如实标注简化）。Channel 为 per-direction FIFO
（mutex 保护的 available 时间点）。

## 4. Reference / Correctness Test

期望值全部由 docs 公式独立推导（系数代入手算），非被测代码自证。T2/T3 的断言
直接对应文档语义（"通道串行、private overlap" / "独立 SSD 读延迟 overlap"）。

## 5. 构建

```bash
demos/emulation/umbp_sim_model/scripts/build_run.sh   # 容器内（宿主无编译器）
```

## 6. Inspection

`results/run_cpu.log`。模型已知限制（上游自述，未复刻）：无单 transfer 带宽封顶、
无拥塞/公平共享建模、控制 RPC 开销未计入。

## 7. Hardware Matrix

纯 CPU——任何机器可跑（上游 `ctest -R '^umbp_sim$'` 同为 GPU-free）。
系数为演示值；平台实测标定需上游 calibrate 工作流（docs:67-70）。

## 8. Execution Result

ALL PASS（2026-11-18）。**单位教训**：公式 `bytes*1e9/bandwidth` 的 bandwidth 是
bytes/秒——按 B/ns 理解错 1e6 倍，表现为 T2/T3/T5 全挂，数值打印定位后修正。
未验证事项：16 条路径全量、SSD 分片/CRC 语义、JSONL trace、跨 peer 共享。
