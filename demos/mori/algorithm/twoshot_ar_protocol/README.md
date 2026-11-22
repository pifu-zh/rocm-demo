# twoshot_ar_protocol — mori twoshot AllReduce 协议模拟（2-rank IPC 介质，A-06/A-07）

**类目**: algorithm ｜ **验证等级**: `HARDWARE_PASS`（双进程 gfx1030 实测，2 轮稳定，
`results/run_gfx1030.log` + `rank{0,1}.log`）
**覆盖条目**: A-06（twoshot AR 协议：scatter→世代 flag→本地 reduce→AG）、
A-07（世代 token 纪律 + 槽位零复位复用）

## 1. 原理说明

mori twoshot SDMA AllReduce 的协议结构（`twoshot_sdma_kernel.hpp:177-512`）：
scatter（每 rank 把对端要 reduce 的输入分片推到对端 gather 槽）→ 世代 flag（AMO_SET
单调 token，"no reset is needed"）+ 自旋 → 纯本地 reduce → AG（推 reduced 分片到
所有 rank 的槽）。本 demo 把 SDMA 数据面替换为 **IPC 对称堆上的 SM store**
（介质差异如实标注：mori 的槽位复用握手防的是 SDMA 绕过 L2 的写与 CU 写在 L2 的
alias；IPC+SM 介质共享 L2 天然一致——世代 token 语义逐件保留，握手防御对象消失）。

**实测矩阵（2-rank × 3 世代，每世代新输入、槽位零复位复用）**：
全部 PASS——每 rank 的 result 双分片逐元素等于双输入之和（位级 memcmp，输入
0.5 步长 + 和 < 2^24 保证浮点逐位精确），gotSum = 2× 单 rank 输入和 ✓（AR 的
本征语义：结果 = 双 rank 贡献之和）。

### 调试全程钉死的四个纪律（每个都有失败形态，是本 demo 的核心教学价值）

1. **位型整数加 ≠ 浮点加**：首版 reduce 写 `unsigned int v = own[i] + gathered[i]`
   （位型相加）→ 结果 0x844E0000 ≈ -0.0、int 和溢出产生 NaN 模式——"sum=-0.0"的
   真正来源。mori WarpAccum 用 float 加的原因即此。修复：bit-cast 后 float 加。
2. **IPC alias VA（回写缓存）与本地 VA 的 D2H 读不一致**：reduce 的 SM store 经
   L2 脏行，hipMemcpy D2H（不 snoop）读到陈旧值——NT store（写穿）修复
   （mori SdmaVisibleStore 同款）。**NT load 同样不可用**（IPC alias 内存上实测
   返回 -0.0 垃圾）——数据面读写最终全部 plain（同 GPU 共享 L2 一致），
   仅 D2H 可见性路径的写用 NT。
3. **多 block 无 grid 同步 → 信号竞态**（与 dispatch_merged_reserve 同款教训）：
   单 block 协同式 + `__syncthreads` + thread0 fence+signal。
4. **hipMalloc(缓存) vs hipDeviceMallocUncached**：IPC alias 写入的缓存策略与
   本地 VA 策略的组合决定一致性方向——本 demo 最终用普通缓存分配 + 全 plain
   访问（标准 HIP 模型）。

## 2. 上游出处

- `include/mori/collective/allreduce/twoshot_sdma_kernel.hpp:177-512`（三相协议 +
  单调世代 token）
- `include/mori/collective/allreduce/twoshot_sdma_common.hpp:37-43`（CrossPeBarrier
  槽位复用握手——本介质下防御对象消失，如实记录）
- `include/mori/collective/ccl_kernel_args.hpp:74-81`（设备侧世代号）
- 考古报告：`docs/archaeology/03-collective-ops.md` §1.2（C3 条目）

## 3. 独立实现说明

单文件 HIP C++，双进程由脚本分别启动（rank0 监听/rank1 连接）。堆 16MB 普通
缓存分配（mori 4GB Uncached 的介质适配替代——Uncached+IPC alias 组合在本机被
实证不连贯，见纪律 2/4）。协议相位由 socket 栅栏分隔（'s'/'1'/'2'/'3'/'e'），
设备侧依赖由世代 flag 自旋保证。

## 4. Reference / Correctness Test

期望值 host 独立推导：`expected[i] = my_input[i] + other_input[i]`（other 输入
由对称公式 + 共享 delta 独立重构），**位级精确** memcmp（浮点可精确表示性由
构造保证）。3 世代 × 双 rank = 6 次全量校验全过。

## 5. 构建

```bash
demos/algorithm/twoshot_ar_protocol/scripts/build_run.sh   # 容器内（自动起双进程）
```

## 6. Inspection

`results/{rank0,rank1}.log`（双进程 trace：每世代 sum/mism）。
`src/twoshot_ar_protocol.hip` 内含取证块（kernel 视角 gather/own 头部 dump）。

## 7. Hardware Matrix

| 架构 | 结论 |
|---|---|
| gfx1030 + HIP 7.16（本机） | 协议全链 ✅；介质=IPC+SM plain 访问 + NT store（仅 D2H 可见性） |
| gfx942/950（mori 官方） | SDMA 引擎面 + Uncached 堆策略（本机不可复现，ARCH_MATRIX 已记） |

## 8. Execution Result

ALL PASS（2026-11-18/23，多轮稳定）。调试历程（四个失败形态→修复）全部保留在
源码注释与本 README——协议正确性之外，内存一致性的介质适配是本 demo 的第二交付物。

未验证事项：SDMA 引擎真数据面（介质不兼容，见 sdma5_copy_experiment）；>2 rank
scatter 广播形态；graph 捕获下的世代计数器（见 graph_gen_counter 单独 demo）。
