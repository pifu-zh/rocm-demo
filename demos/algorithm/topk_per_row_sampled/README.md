# topk_per_row_sampled — 三阶段采样式逐行 top-k 流水线的主机参考

**类目**: algorithm · **验证级别**: SOURCE_VERIFIED + REFERENCE_PASS（纯 CPU 主机参考，无 GPU 执行声明）
**上游**: `aiter/csrc/kernels/topk_per_row_sampled_kernels.cu` + `csrc/include/topk_sampled/*` + `csrc/include/topk_fp32_key.h` @ `1eab5ae12c93af3c8c660202d9a413f637c2f011`（MIT；设备端 gfx950-only）
**依赖**: C++20 编译器，无 ROCm / 无 GPU / 无第三方库
**结果**: 86,716 checks, 0 failures（`results/execution.log`，2026-11-18 容器 gfx-m1 / ROCm 10.1 内 g++；ASAN+UBSAN 零报告）

## 一、原理说明

### 设计 [1]：fp32 可排序键映射（`topk_fp32_key.h`，逐条提取）

```
sortable(u)  = u 高位为 1 ? ~u : u ^ 0x80000000     // -0.0 恰在 +0.0 之下
sortable_key<NAN_HIGH>(u) = sortable(u) − 0x007FFFFF // NAN_HIGH: 负 NaN 旋转到 +inf 之上
radix_key<NAN_HIGH>(u)    = sortable 的反序（基数按最小键先扫）
```

上游文件自带 `static_assert(keys_agree())` 的完整键代数：往返双射、单调序、
radix 与 sortable 同序反向、NAN_HIGH 只移动 NaN。本 demo 在主机复验同一
套性质（ specials 18 值 + 20,000 随机位型）。

### 设计 [2]：三阶段流水线

- **A phase_a_threshold**：每行采样 S 个元素（64/块、步长 `sample_chunk_stride`
  = (N/chunks) & ~3，对齐 dwordx4），3 遍**截断**基数选择取 rank-th 键为
  阈值（PHASE_A_PASSES=3——第 4 字节在 fp32 精度下从不移动桶，候选计数
  位级相同）；ragged 且 len ≤ K 或 len < S 时阈值路由 +inf。
- **B phase_b_filter_coop**：dwordx4 流式读行，**float 比较** `!(v < th)`
  收集候选（NaN < th 恒假 ⇒ 保留全部 NaN），打包 `(bits<<32)|idx`，
  wave 级 LDS 暂存 + 预约原子写回；超 cap 置 cand_bad。
- **C phase_c_select_contig**：对候选做精确 4 遍基数选择得第 k_out 大键，
  gather = 严格大于者先、恰 eq_needed 个平局者后；回退条件触发时整行
  精确选择；ragged len ≤ K 恒走 identity + (−1, −inf) 填充。

### 设计 [3]：正确性不变式（本 demo 的中心命题）

**采样只选路径，永不降级答案**：若阈值高于真第 k 大值，则 ≥ 阈值的元素
数 ≤ k−1 < k_out ⇒ 候选不足 ⇒ 回退整行精确选择。配合 bucket-0 下溢检查
（c − low < k_out，low = 负 NaN/−inf/≤−2^127 的键数——float 比较保留的
NaN 可能垫高 c），对**任意** (S, rank ≥ 1, cap ≥ K) 流水线都是精确的。
S 律 / margin / cap-σ 推导是性能几何，与正确性无关，不复刻。

### 设计 [4]：输出契约——值多重集而非槽位序

`block_gather_topk` 的槽位由各 wave 对共享计数器的 `atomicAdd` 到达序
决定，跨 wave 无序保证。aiter 自己的路由层（`aiter/ops/topk_select.py`）
把 `sampled` 列入 **`_NONDETERMINISTIC`**（"repeat-stability has NOT been
measured"）且三档 tie 契约里只出现在 **no-promise** 档；上游测试
`test_topk_row_prefill.py` 用 **set 比较**。因此本 demo 的 oracle 比较把
两侧按 (键降序, 索引升序) 规范化后逐位比——顺序不敏感、平局策略确定
（主机候选序 = 行序；设备候选序为波预约序，非确定性）。

## 二、测试清单（86,716 checks）

| 组 | 内容 | 结果 |
|---|---|---|
| 0 | 键代数：往返双射、单调序、−0.0/+0.0、双符号 NaN 两种策略、radix 反序一致、NAN_HIGH 只动 NaN、20k 随机位型 | PASS |
| 1 | 几何：sample_chunk_stride 掩码（131328/131327/65600）、末块入行界、common_prefix_passes 手算案例、截断选键 = 精确选键掩码 | PASS |
| 2 | 路由：len ≤ K identity（绝对索引 + −1/−inf 填充）、len == K、len < S +inf 路由零候选回退、+inf 路由遇负 NaN 经 undershoot 兜底 | PASS |
| 3 | 构造边角：全等行、平局密集边界（16/24 个 7.0）、cap 溢出回退、bucket-0 两个子案例（1048 finite 无回退 / 仅 2 finite 回退且答案合法含 6 个 −NaN）、+NaN 排在 +inf 之上、ragged 尾列拾取（行最大值住在第 100 列）、dense ≡ ragged | PASS |
| 4 | 随机主不变式 sweep：10 配置 × 8 分布 × 3 行 = 240 行，逐行 pipeline vs oracle 规范化逐位等 + 索引有效 + 值自洽 + 回退行候选数越界检查（160 行回退得到演练） | PASS |

## 三、发现与教训

1. **"恰一个阈值只选路径"的证明结构**：c ≥ k_out ∧ c − low ≥ k_out ⟹
   top-k_out ⊆ 候选（反证：若真第 k 大元素 < th，则 ≥ th 的元素全在
   真前 k−1 内 ⇒ c − low ≤ k−1 矛盾）。bucket-0 检查不是可选项——
   float 比较保留的负 NaN 会把 c 垫过 k_out 而不进入键序前缀。
2. **设备输出顺序是波到达序竞争**：`block_gather_topk` 的槽位基址来自
   每 (wave, i0块) 一次的共享计数器 atomicAdd，跨 wave 顺序非确定。
   上游以 set 契约 + `_NONDETERMINISTIC` 声明自洽。任何"槽 p = 第 p 大"
   的主机假设都会被"pipe(122,−0.539) vs exact(1953,−0.018)"这类失配
   误导成数值 bug——实际值多重集完全一致。
3. **测试窗口越界读堆元数据不是稳定 oracle**：窗口 [168, 268) 越过
   256 元素缓冲区后，pipeline 与 oracle 各自的内部 vector 分配改变了堆
   布局，同一索引在两次运行读到不同垃圾值——表现为"oracle 自身失配"
   的假象。OOB 读是 UB，不是契约。
4. ** crafted 案例的阈值统计直觉常错**：rank=4/1024 的采样阈值落在行
   最大值附近（uniform 行的 4th-largest 采样 ≈ max），保留集趋近空——
   构造"中位阈值"要用 rank ≈ S/2；rank = S 才是"保留全行"。
5. **`!(v < th)` 的 float 比较与键序的有意分歧**：NaN 全保留是 Phase B
   的刻意行为（负 NaN 由 bucket-0 检查兜底、正 NaN 键序本就高于 +inf，
   属 topk_select 语义的合法返回值）。

## 四、规格表

| 项 | 值 |
|---|---|
| Build Script | `scripts/build_run.sh`；CMakeLists 亦可 ctest |
| Inspection | 双实现（三阶段仿真 vs 稳定排序 oracle）规范化逐位对撞 + 不变式断言 |
| Hardware Matrix | 上游目标 gfx950（其他架构 __builtin_trap）；本 demo CPU 主机参考 |
| Execution Result | `results/execution.log`：86,716 checks, 0 failures |

## 五、复现

```bash
cd demos/algorithm/topk_per_row_sampled && ./scripts/build_run.sh
# 或 CMake + ctest
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build && ctest --test-dir build
```
