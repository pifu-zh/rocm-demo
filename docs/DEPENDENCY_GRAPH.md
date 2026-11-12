# DEPENDENCY_GRAPH — AITER 重要模块依赖关系

对象：aiter @ `1eab5ae12`。目的：记录技术间依赖，lab 复现时避免重复实现基础机制，并标明哪些依赖必须切断才能独立。

## 1. 构建/运行主干

```
setup.py
  ├─ PREBUILD_KERNELS 0-3 ──→ aiter/jit/core.py::build_module（142 模块表 optCompilerConfig.json）
  │                              ├─ blob_gen_cmd（CK gen_instances.py / ck generate.py / hsa codegen.py）
  │                              ├─ blob 事务缓存（jit_cache.py: stage→publish→restore；file_baton.py mp 锁）
  │                              ├─ hipify（torch CUDA→HIP，cpp_extension.py:1011-1029）
  │                              └─ --offload-arch per GPU_ARCHS（build_targets.py GFX_MAP/CU 表/gfx1250-strict 规则）
  └─ FlyDSL AOT（setup.py:414-429 → aiter/jit/flydsl_cache）

运行期：
python op（aiter/ops/*.py @compile_ops）
  ├─ import-or-build（core.py:2349-2405；ctypes 或 pybind FFI）
  ├─ torch_compile_guard（torch_guard.py:231-407 → torch.ops.aiter.* custom op + FakeTensor）
  └─ tuned-CSV（AITER_CONFIG_* env → configs/*.csv 合并去重 → libtype 列 → solMap 后端）
```

## 2. 设备侧依赖链

```
csrc/include/opus/opus.hpp（一切 opus 后端的根）
  ├─ hip_minimal.hpp（host dim3 shim）/ dtypes.hpp（__fp16 拼写）
  ├─ aiter_opus_plus.h（packed cvt / scaled_cast / hazard 绕过）← opus.hpp（单向）
  ├─ hip_reduce.h（KeyValuePair/ArgMax/DPP 归约）← moe_fused_gate / topk_softmax / sample
  ├─ quant_amax_floor.h（UE8M0 尺度下限）← quant_kernels / dsv4_rotate / hadamard 线
  └─ aiter_hip_common.h（BUFFER_RESOURCE_3RD_DWORD、AiterAsmKernelFast）
        ├─ aiter_dispatch.h（_rmTorch 分发宏）← 全部 torch-free TU
        ├─ aiter_stream.h / aiter_tensor.h（pybind tensor 面）← pybind 模块
        └─ topk_pad_rows.h（pad 行判定）← moe_fused_gate / sample

CK 线：ck_* → 3rdparty/composable_kernel（submodule 96afae1d）→ ck_tile_shim.h（ENABLE_CK=0 伪命名空间）
cpp_itfs：jinja 模板 → utils.py compile_lib（hipcc+make）→ ctypes；lru_cache.h；Triton→HSACO 桥
```

## 3. 算法族内依赖（复现顺序建议）

- **量化族**：fp8 codec → group quant（amax_floor）→ MX（e8m0+E2M1）→ 量化+pack（GEMM operand 布局）→ fused quant+sort
- **norm 族**：rmsnorm → +residual → +quant → +gate → +group quant（同一模板逐级叠加）
- **rope 族**：rope_core（1c/2c）→ cached/positions → (m)rope → 融合进 qk_norm_rope_cache_quant
- **MoE 族**：moe_align → topk_softmax → grouped/biased topk（DPP tie 表）→ moe_fused_gate → ck_moe_2stages（GEMM）→ mxfp4_moe_aux（sort+quant）
- **attention 族**：mha_native split-KV（最简）→ ck-tile fmha → opus MLA → HK（钉 VGPR）
- **GDN 族**：fused_split_gdr_update（token 内）→ gdr_decode_packed_bf16（decode）→ chunk_gated_delta_rule_fwd_h（块间）
- **通信族**：custom_all_reduce（IPC 基元）→ +rmsnorm/quant 融合 → quick_all_reduce（量化压缩）→ mhc 融合 orchestration

## 4. lab 复现的切断点（demo 独立化所需）

| aiter 依赖 | lab 替代 | 已落地于 |
|---|---|---|
| torch tensor/AT_DISPATCH | torch-free `aiter_tensor_t`→ 普通指针 API | core/*（vector 入参）|
| opus DSL | 直接 builtin/内联汇编/纯 C++ | gpu/soft_* |
| hiprand | 位级复刻 philox4x32_10 | core/sample |
| CK/FlyDSL/hipBLASLt | 不复现（记录于 BACKEND_MATRIX） | — |
| rocminfo 架构探测 | 编译期 `__gfx1030__` + hipDeviceProp | gpu/* |
| aiter jit 缓存系统 | design/jit_cache 最小版（内容寻址+FileBaton） | design/jit_cache |

## 5. 外部依赖风险表

| 依赖 | 版本敏感点 | 证据 |
|---|---|---|
| clang/ROCm | ≤22 的 b128 buffer_store miscompile（gfx1250）；7.2 fp6 asm 结果重叠；7.14 修复 | opus.hpp:1917-1924、mha_v4_quant:98 |
| CK submodule | pin 96afae1d；deepgemm 实例需更新 clang（FLATMM_HIP_CLANG_PATH） | deepgemm_common.cuh |
| flydsl | pin 0.3.4.1，≥0.2.4 硬检查 | flydsl/__init__.py:15-23 |
| gfx1250 硅片 | A0(strict)/B0 ELF mach 0xeb vs 0x149 不兼容 | build_targets.py:47-56 |
