# opus_dsl_host — opus 单头 DSL 设备无关半的宿主单元测试

**类目**: compiler/DSL · **验证级别**: SOURCE_VERIFIED + REFERENCE_PASS（纯 CPU 宿主单元测试，无 GPU 执行声明）
**上游**: `aiter/csrc/include/opus/opus.hpp` @ `1eab5ae12c93af3c8c660202d9a413f637c2f011`（MIT，© 2025-2026 carlus.huang@amd.com）——**首次作为一等实验对象剥离**（此前 opus 只在各 demo 中被内联仿真过片段，见 M3/M4 各 demo）。
**依赖**: clang++（**clang-only**：opus.hpp 使用 `__make_integer_seq` / `__type_pack_element` 编译器内建，g++ 无法解析）；无 ROCm / 无 GPU
**结果**: 52 checks, 0 failures（`results/execution.log`，2026-11-14 容器 gfx-m1 / ROCm 10.1 clang-24）

## 一、提取内容（vendor/opus_host_slice.hpp）

**切片 = 上游头文件 1..1190 行**（设备无关半）+ 宿主 shim + namespace 收尾：

| 抽象 | 内容 | 测试 |
|---|---|---|
| type traits | remove_cvref/is_any_of/underscore | 编译期（static_assert 链） |
| constants | `number<I>`/`bool_constant` + `operator +−×÷`（number×number → number）+ `_I` 字面量 + is_constant | 四则运算的类型精确性 |
| seq 代数 | make_index_seq 三形态（N / Start,End / Start,End,Step）、at/get/pop_front/concat_seq/reduce_seq_sum/mul、size | 每形态逐元素 |
| static_ford / static_for | **seq = 形状维度**（N 维大小空间的全迭代 + ford_at 坐标分解）——seq 是维度不是索引列表 | 1-D 与 2-D 形状的和分解 |
| sub-byte packs | dpacks（storage/bits 载体）+ array 的代理存储 | 4-bit pack 代理写读 round trip（16 × 4-bit = 8 B 精确） |
| tuple 代数 | make/get/size、transform_tuple(_with_idx)、make_repeated_tuple、concat_tuple、嵌套 flatten、空 tuple 契约（NOTE：空 make_tuple 返回实例非引用） | 各变换逐元素 |
| layout | make_layout + coord_to_linear + packed_shape_to_stride（后缀积） | 行主/列主/3-D 逐项 vs 手算 |
| finfo | fp16/bf16/fp8/bf8/i8 的 eps/max/min/tiny 表（宿主编译分支 = OCP 值） | 位模式逐项 |

**切掉的（设备半区，1191 行起）**：GCN inline-asm 类型转换（fp32_to_bf16_rtn_asm）及以下——MFMA 包装、DPP 操作、.buffer 寻址。其中三件已由其他 demo **独立验证过**（med3/mov_dpp/upd_dpp → warp_sync；make_gmem/V# → lds_passthrough；fp4/e8m0 finfo 数值 → soft_fp4）——交叉验证素材。

**shim**（提取件的一部分）：`#undef __HIPCC__` 强制宿主路径 + `__host__`/`__device__` 置空（头内唯一裸用 = 421 行 tuple 推导指南）。

## 二、消费者映射（opus.hpp 的 12+ 个消费 kernel）

moe_fused_gate、mega_mhc(_gfx1250)、mla 全家（hk/opus/gfx950）、topk_plain_kernels、iq2r_gemm、opus_mqa_logits、gated_rmsnorm_quant、inverse_rope_group_quant、fused_qknorm_idxrqknorm——**剥离这份 DSL = 理解这批 kernel 的公共抽象层**。

## 三、测试清单（52 checks）

| # | 内容 |
|---|---|
| 1 | number 四则类型精确性 + _I 字面量 + is_constant |
| 2 | seq 三形态构造 + at/get/pop_front/concat/reduce |
| 3 | static_ford 1-D/2-D 形状分解 |
| 4 | array + 4-bit pack 代理 round trip + packed_bytes 契约 |
| 5 | tuple make/get/transform(_with_idx)/repeated/concat/flatten |
| 6 | layout 行主/列主/3-D coord_to_linear + packed_shape_to_stride |
| 7 | finfo 表（位模式逐项，OCP 宿主分支） |
| 8 | 空 tuple 契约 |

## 四、复现

```bash
cd demos/compiler/opus_dsl_host && ./scripts/build_run.sh   # 容器内（clang-only）
# 或 CMake + ctest（clang++ 缺席时自动跳过并说明）
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build && ctest --test-dir build
```

## 五、范围声明

- `--genco`（opus DSL → clang offload bundle 的编译模式，build_co.py）需要完整 opus 工具链，仍归 compiler 线待办。
- 设备半区（MFMA/DPP/buffer）的指令级验证归 hardware 线（lds_passthrough/warp_sync 已覆盖三件）。
- 切片边界 = 上游 1190 行（GCN asm 节之前）；上游演进时切片需重对齐。
