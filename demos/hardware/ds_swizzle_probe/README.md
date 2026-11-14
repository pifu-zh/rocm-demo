# ds_swizzle_probe — BITMASK_PERM 语义与 wave 大小的实测探针（gfx1030）

**类目**: hardware · **验证级别**: HARDWARE_PASS（RX 6950 XT / gfx1030，ROCm 7.2.4 首测 + 10.1 重测均通过，2026-11-14）
**动机**: aiter 的 `gdr_decode_packed_bf16.cu` / `quick_all_reduce.cuh` 使用 swizzle 码
`(N << 10) | 0x1f`（kDsSwizzleXor1/2/4）做 XOR-butterfly 归约，但编码的字段语义
在上游与 ISA 文档层面都未被 aiter 记录。主机参考
（`demos/algorithm/gdr_decode_chain`）只仿真了 XOR-butterfly **语义**并把
指令级真相推迟到这里——本探针用**测量**而非假设闭合这个悬案。

## 一、测量结论（四条硬事实）

1. **`(N<<10)|0x1f` = XOR-butterfly `src(lane) = lane ^ N`**（N ∈ {1,2,4}，全
   64 映射逐 lane 验证： feeding x = lane_id 并读回）。候选假设中的
   broadcast（`((lane&0)|7)^N`）与 identity 被否证。
2. **掩码 {1,2,4} 折叠的是连续 8-lane 块**（lane i 的组 = {i&~7 .. i&~7+7}），
   与上游 `reduce_k`（kKThreads=8）的用法精确一致。
3. **gfx1030 编译为 wave32**（RDNA2 原生；全部 kernel 的
   `.amdhsa_metadata` 实测 `wavefront_size: 32`，且行为一致；**10.1/clang-24
   重测仍为 wave32**——这是硬件/驱动事实而非工具链伪象）：
   - 掩码 {1..16} 折叠整个 32-lane compiled wave；
   - **xor32 不可达**：clang 静默丢弃该步（ISA 中无 SWAP,32）；
   - `__shfl_xor(v, 32)` 在此宽度下退化为段内自身交换（累加器翻倍）——
     上游 `fused_split_gdr_update` 给 `__shfl_xor` 显式传 width=64 正是
     为了 wave64 CDNA 目标。
4. **builtin 吃 INT 位**：把 float 直接传给 `__builtin_amdgcn_ds_swizzle`
   会插入 `v_cvt_i32_f32` **值**转换（ISA 实测），非整数值的位型被破坏；
   正确调用必须 union 位 punning——与上游 `ds_swizzle_xor_f32` 的写法
   一致，这解释了那个 union 不是风格而是必需品。

## 二、归约闭环

- 3 步（xor1+2+4）== 连续 8-lane 块和：PASS
- 5 步（xor1..16）== compiled wave（32 lane）和：PASS
- 全 64 线程折叠：不可用 ds_swizzle（xor32 越界 + wave32）——需要 LDS 或
  分段 shfl，与上游跨 wave 设计（BlockTopkFilter::reduce 用 LDS、split
  kernel 用 shfl_xor(16/32, width=64)）互证。

## 三、调试链（本探针自身的三次假阳性，全部值得记录）

1. 把 float 直接传给 builtin → ISA 出现 `v_cvt_i32_f32` 值转换 → 归约错。
   修复：union 位 punning（结论 4）。
2. 期望"3 步折满 64 lane"——错，{1,2,4} 只折 8-lane 组（结论 2）。
3. 期望"组 = i&7 相同的 strided lane"——错，是**连续块**；"want 84 got 84
   仍 FAIL"（越界读显存垃圾）暴露了检查范围错。

## 四、文件

| 文件 | 内容 |
|---|---|
| `src/main.hip` | 映射测量 kernel（模板化立即数）+ 8-lane 组 / 32-lane wave 归约 kernel |
| `results/execution.log` | 真机运行日志（PASS） |
| `results/group_kernel.s` | -O3 ISA 留档（SWAP 指令 ×11、`wavefront_size: 32`） |
| `scripts/build_run.sh` | hipcc 构建 + 运行 + 日志落盘 |

## 五、复现

```bash
cd demos/hardware/ds_swizzle_probe && ./scripts/build_run.sh   # 容器内，需真机
```
