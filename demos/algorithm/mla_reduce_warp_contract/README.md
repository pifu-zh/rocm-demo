# mla_reduce_warp_contract — MLA split-KV reduce 的 warp 级契约（M6-#3 扩展）

**类目**: algorithm · **验证级别**: SOURCE_VERIFIED + REFERENCE_PASS（纯 CPU 主机参考，无 GPU 执行声明）
**上游**: `aiter/csrc/include/mla_reduce_kernels.cuh`（MlaReduceKernelV1Traits / reduce_lse_massive / reduce_output_massive / LocalLse）+ `csrc/kernels/mla/reduce.cu` 的 `get_num_work_group_per_bh` @ `1eab5ae12c93af3c8c660202d9a413f637c2f011`（MIT）
**依赖**: C++20 编译器，无 ROCm / 无 GPU / 无第三方库
**结果**: 126 checks, 0 failures（`results/execution.log`，2026-11-22 容器 gfx-m1 / ROCm 10.1 内 g++；ASAN+UBSAN 零报告）
**关联**: M6-#3 opus_mla_decode_splitkv 的 warp 级内部拆解——本 demo 钉 reduce kernel 的实现层（lane 分布/混合存储/软件流水线/host 分割），M6-#3 钉流水线层（调度/解码数学/合并代数）

## 一、原理说明

### 设计 [1]：Traits 常量与问题规模路由

kOccupancy = 8、kMassiveThreshold = 4（splits ≥ 4 走 massive 管线，否则
up-to-wave 路径）、kNumWarps = (SizeDV < 128) ? 1 : 2、kVecWidth =
SizeDV/kNumThreads（static_assert 整除）——DV=512/wave64 ⇒ 2 warp、128 线
程、每线程 4 float。线程 t 累积输出元素 [t·kVecWidth, (t+1)·kVecWidth)，
per-thread 切片拼接即整行（位级）。

### 设计 [2]：host 分割 get_num_work_group_per_bh

workloads = num_reduce_tile·num_heads；hw_capacity = num_cu·kOccupancy；
经验系数 1.3 门控（`cap·1.3 > workloads` 才分割）；wg =
min(ceil(cap·1.3/workloads), max_seqlen_q) → next_power_of_two（1 保持 1）
→ clamp 256 → **向上**归入 dispatch 表 {1,2,4,8,16,64,256}；门外恒 1。
手算案例钉死表舍入方向（11→16、5→8）、q 上限（3161→16 因 q=16）、clamp
（4096→256）、严格大于门界（3161 开 / 3162 关——cap·1.3 浮点值 3161.6）。

### 设计 [3]：LSE lane 分布与混合存储（reduce_lse_massive，仅 warp 0）

split s 由 lane s % 64 在本地第 s/64 槽持有（split_idx = local_idx·64 +
lane）；越界 tile 读 −∞。LocalLse 前 4 槽走寄存器 value_[idx]、其余溢出
到 (idx−4)·group_size + idx_in_group——寄存器/内存混合视图。合并数学与
M6-#3 相同（max → sum → global_lse 的 INFINITY 守卫 → lse_scale =
exp(lse−global)），此处钉 lane 分布层。全 −∞ 场景：local − max =
−∞−(−∞) = NaN ⇒ sum 为 NaN ⇒ NaN 守卫把 global 归 INFINITY；lse_scale =
exp(−∞−∞) = 0（守卫项的精确职责分工）。

### 设计 [4]：massive 输出管线是"只重叠加载"（本 demo 的核心钉子）

reduce_output_massive 的 2 级软件流水线（双倍率主循环 + 两个 epilogue 块）
**只重叠 tile 加载与 LDS 映射预取**；每次累加严格按 tile 序左到右——
`reg_out += scale_t·o_t`，t = 0,1,2,…。因此 massive 管线与串行求和**位级
相等**（demo 对 S ∈ {1..200 含奇偶} 逐位对撞 8 种子 + 12 档全过）。流水线
隐藏的是延迟，不改变任何算术。

## 二、测试清单（126 checks）

| 组 | 内容 | 结果 |
|---|---|---|
| 0 | Traits 常量（8/4/2 warp/128 线程/vec4）+ 小 DV 分支 | PASS |
| 1 | host 分割：cap=3161 手算、表上舍入（11→16、5→8）、q 上限、clamp 256、门界严格大于（3161/3162）、批+头组合 | PASS |
| 2 | 路由边界（num_lse_per_thr 1/2/3 档）+ LocalLse 混合索引解码 | PASS |
| 3 | 12 档 split 数（1..200 含 63/64/65/128/129 边界）：权重和=1（ulp 量级）、**massive == 管线控制流 == 串行 三方位级**、global_lse ∈ [max, max+log S]、全 −∞ → INFINITY + 零权重 | PASS |
| 4 | 随机 sweep：8 种子任意 S 位级对撞 | PASS |

## 三、发现与教训

1. **移植陷阱：`kLastSupported` 的语义**——上游写
   `kLastSupported = sizeof(kSupportedNum)/sizeof(int32_t) − 1`（=6，尾索
   引），demo 初版误抄成 7 → 越界读使 clamp 值为垃圾、门内所有形状返回 1，
   且**部分断言因垃圾值恰好 ≥ 期望而假绿**。这是"复制常量时把派生表达式
   当字面值"的典型：一切 sizeof 派生常量移植时必须重算。
2. **门界是严格大于且带浮点尾数**：`cap·1.3 > workloads` 中 304·8·1.3f =
   3161.6——workloads = 3161 时门开（wg=ceil(3161/3161)=1，恰无分割），
   3162 时门关。int 截断（3161）与浮点比较（3161.6）之间隔着一个不可忽
   略的 0.6。
3. **global_lse 的合法上界是 max + log(S)**：初次断言用 mx + 1e-4 在大 S
   下系统性失败——log(sum) 项随 split 数增长（log 200 ≈ 5.3），不是误差。
4. **全 −∞ 的守卫分工**：sum 路径产生 NaN（−∞−(−∞)），NaN 守卫归
   INFINITY；scale 路径 exp(−∞−(+∞)) = 0。两个守卫条件（sum==0 与
   sum≠sum）分别覆盖"无有限 LSE"与"NaN 传播"，缺一不可。
5. **位级可断言的性能结构**：与 M6-#2 的 seg512 同型——软件流水线只动加
   载时序不动算术序时，"位级等于串行"是可断言契约，性能重构不会破坏数值
   可复现性。这是 lab 反复验证的流水线安全模式。

## 四、规格表

| 项 | 值 |
|---|---|
| Build Script | `scripts/build_run.sh`；CMakeLists 亦可 ctest |
| Inspection | 三方位级对撞（massive/管线控制流/串行）+ 分割手算案例 + 路由边界 |
| Hardware Matrix | 上游 wave64（gfx9xx）常量钉入；本 demo CPU 主机参考 |
| Execution Result | `results/execution.log`：126 checks, 0 failures |

## 五、复现

```bash
cd demos/algorithm/mla_reduce_warp_contract && ./scripts/build_run.sh
# 或 CMake + ctest
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build && ctest --test-dir build
```
