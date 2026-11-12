# BACKEND_MATRIX — AITER 后端实现关系

对象：aiter @ `1eab5ae12`。回答"同一个 op 有几条实现路、谁在什么条件下选谁"。

## 1. 后端清单

| Backend | 载体 | 编译方式 | 适用域 | 证据 |
|---|---|---|---|---|
| **pure HIP** | csrc/kernels/*.cu（49+ TU） | jit/core.py torch-extension（--offload-arch） | 全架构通用路径 | 考古①全表 |
| **opus DSL** | 单头 opus.hpp + 实例 hpp（mla/mqa_logits 等） | `--genco -D__HIPCC_RTC__` 或预编译 .co（csrc/opus_gemm/gen_co/<arch>） | gfx942/950/1250 | opus README |
| **CK (Composable Kernel)** | ck_* 目录 + submodule | **JIT**：gen_instances.py 代码生成 → blob_gen_cmd → core.py 编译 | gfx9 系 | ck_gemm_a8w8 |
| **ck_tile** | cktile_gemm_*、deepgemm | 同上 + 专用 clang（FLATMM_HIP_CLANG_PATH） | gfx9 系 | deepgemm_common.cuh:16-20 |
| **asm 预编译** | csrc/hsa/<gfx>/、gen_co/ | 上游构建期生成，wheel 携带 | gfx942/950/1250 | core.py:917-919 |
| **FlyDSL** | aiter/ops/flydsl/（~80 py） | 第三方 MLIR JIT + 安装期 AOT（setup.py:414-429） | gfx942/950/1250 | flydsl README |
| **Triton** | aiter/ops/triton/（206 文件） | triton JIT（+HSACO 桥供 C++ 调） | RDNA/gfx1250 主力兜底 | 考古③§6 |
| **hipBLASLt** | gradlib rocsolgemm/hipbsolgemm | 独立 extension（hipb） | 未 tune 形状的默认 | tuned_gemm.py:797-805 |
| **rocBLAS** | 同上（rocb） | 同上 | solver 等组件 | solver/sytrd |
| **torch** | python 直调 | — | 最终兜底 | tuned_gemm.py:313-315 |

## 2. 选路逻辑（以 GEMM 为最完整样本）

```
tuned-CSV 行存在？
  → libtype 列决定: torch|hipblaslt|skinny|asm|triton|flydsl|opus (tuned_gemm.py:448-464,797-805)
  → 行校验失败（未知 flydsl/opus kernel 名、kid 不可解析）→ 弃行降级 (tuned_gemm.py:160-243)
未 tune：
  gfx942 bpreshuffle → hipblaslt；bf16 N,K%64==0 → asm；
  skinny 形状(gfx90a/942/950) → wvSplitK；gfx1250 bf16/fp16 → Triton(gluon)；
  其余 → torch (tuned_gemm.py:264-319)
运行时故障：
  torch._scaled_mm 拒绝 → fp32 matmul 模拟 (:573-599)
  opus import 失败 → torch_gemm (:33-36,724-753)
  FlyDSL launch 拒绝(M>K 等) → CK 回退，除非输出超 CK 2GiB 寻址 (gemm_op_a8w8.py:148-151,209-229)
反回退契约：tuned FlyDSL 行必须走 FlyDSL，ImportError → AssertionError (:250-293)
```

## 3. 非 GEMM op 的后端选择点（file:line）

| op 族 | 选择点 | 分支 |
|---|---|---|
| FMHA | mha.py:2200-2500 资格链 | gfx942/950→asm fmha_v3；else→ck-tile；gfx1250+asm_guard→asm；D64 split-K gfx942 专属；OPUS gfx950 |
| MLA | mla.py 多点 gate | asm 模块按 gfx942/950/1250 变体；FlyDSL reduce；require_gfx1250_asm 硬门 |
| PA | attention.py:35-41,183-207 | asm 支持 gfx942/950；shape/CU 启发式 `_should_use_asm_kernel`；gluon gfx1250 |
| layer_norm | norm.py:149-152 | CK-free 或 gfx1250 → Triton |
| fp8 dtype | utility/dtypes.py:10-41 | gfx942=fnuz，其余=fn，未知→uint8 |
| moe_sum | moe_op.py:153-160 | topk∈{2,4,5}→C kernel；else torch.sum |
| topk (gfx1250) | ops/topk.py:28-107 | HIP 契约不匹配 → Triton exact sigmoid |
| custom AR | custom_all_reduce.py | gfx1250 → 独立模块（无 hipIpc） |
| mega_mhc | mega_mhc.py:36-106 | gfx950/1250 tuned 流；gfx942 → generic 变体 |

## 4. 分发实现机制（三层）

1. **python-dispatch**（主体）：`compile_ops` 装饰器 import-or-build + if 链 + tuned-CSV；
2. **C++ dispatch**：aiter_dispatch.h 的 `_rmTorch` 宏（dtype/vec-size 编译期展开）+ rocm_ops.hpp 109 PYBIND 块；
3. **设备内分支**：`get_gpu_arch()` host 检查（fused_qk_rmsnorm_group_quant:1045）与 `#if defined(__gfx950__)` 编译期 guard。

## 5. 对 lab 的意义

- 每个"后端"都是一个可拆解对象：CK 实例化代码生成、flydsl MLIR 流、opus --genco、Triton→HSACO 桥都各自可做独立 demo。
- gfx1030 上 aiter 的后端矩阵几乎全空（只有 pure HIP 源码可读 + Triton 理论可用）→ 我们 lab 的 soft-* 实现正是把"pure HIP 源码里读到的技术"在 gfx1030 上落地的过程。
