# SOURCE_INDEX — AITER 源码与技术条目索引

研究对象：ROCm/aiter @ `1eab5ae12c93af3c8c660202d9a413f637c2f011`（浅克隆于 `~/workspace/src/aiter`，2026-11-09）。
考古方法：三路串行系统扫描（kernels 算法线 / backends+编译器线 / python 运行时线），全部条目带 file:line 证据。
本文是索引；条目详情见 TECHNIQUE_CATALOG.md / EMULATION_CATALOG.md；架构适配见 ARCH_MATRIX.md；后端关系见 BACKEND_MATRIX.md；依赖见 DEPENDENCY_GRAPH.md。

## 1. 仓库布局速览

| 路径 | 内容 | 规模 |
|---|---|---|
| `csrc/kernels/*.cu` | 49+ 算法 kernel TU（含 rope/ rmsnorm/ mha_native/ mla/ topk_gating/ iq2r/ solver/ mxfp4_moe/ opus_mqa_logits/ sparse_attn/ 子目录） | 见 §2 |
| `csrc/include/` | opus DSL（4099 行 opus.hpp）、aiter_opus_plus.h（965 行）、aiter_dispatch.h、rocm_ops.hpp（2979 行）、ck_tile shim 等 | — |
| `csrc/ck_*/`, `csrc/py_itfs_ck/` | Composable Kernel GEMM 实例化层（submodule `3rdparty/composable_kernel` @ 96afae1d） | 10+ 目录 |
| `csrc/cpp_itfs/` | 运行时 hipcc+make+ctypes 编译的 C++ ITF（mha/mla/moe/pa/sampling） | — |
| `csrc/opus_gemm/gen_co/<arch>/` | 预编译 opus 代码对象（wheel 内置） | — |
| `aiter/jit/` | JIT 系统（core.py 2635 行、optCompilerConfig.json 142 模块、file_baton/jit_cache/chip_info/asm_guard） | — |
| `aiter/ops/` | op 面（含 flydsl/ ~80 文件、triton/ 206 文件带 @triton.jit） | — |
| `aiter/dist/`, `aiter/plugin/` | 分布式层 / 外置 kernel-provider 注册 | — |
| `aiter/quantization/iq2r/` | IQ2R 量化包（compile/calibrate gfx950） | — |

## 2. csrc/kernels 技术条目索引（算法线）

完整 schema 条目（name/path/entry/math/hw_deps/arch_guards/emu_path/backend/notes/python 映射）见考古报告原文沉淀于本文件末尾附录 A（要点已转录进 TECHNIQUE_CATALOG.md）。总表：

| 文件 | 算法类 | 硬件依赖 | emu 路径 |
|---|---|---|---|
| activation_kernels.cu | 融合激活(+量化) | v_pk_mul_f32（RDNA 标量回退 :106） | ✓ |
| cache_kernels.cu | KV cache 管理+融合 rope/quant（5980 行） | gfx1250 TDM :2835 | ✓ 非 TDM 通用路径 |
| chunk_gated_delta_rule_fwd_h.cu | 块间 GDN 状态递归 | MFMA 16x16x16 bf16 :333、wave64 | 部分：gfx12 WMMA 双路 |
| custom_all_reduce*.cu | IPC all-reduce 族 | shfl_xor、IPC 原子 | CodecFP 全精度 |
| dsv4_rotate_quant.cu | Hadamard 旋转+MX 量化 | DPP 蝶形、gfx950 cvt fp4 | ✓ 标量 E2M1 编码器 :45-79 |
| fused_qk_norm_rope_cache_quant.cu | 巨融合 norm/rope/quant/cache（7187 行） | gfx1250 TDM :5107 | ✓ 非 TDM store 路径 |
| gdr_decode_packed_bf16.cu | GDR decode 收缩 | LDS DS-swizzle :41-43、wave64 | — |
| mega_mhc.cu / mega_mhc_gfx1250.cu | MHC 混合 GEMM | MFMA 16x16x32 bf16 / WMMA+TDM ring | ✓ H=0 generic 变体 |
| mhc_kernels.cu | MHC pre/post/fused | MFMA wave64 / WMMA wave32、TDM s_wait_tensorcnt | ✓ fp32 GEMM 回退 :40-45 |
| moe_align / moe_fused_gate / topk_* | MoE 路由/topk 族 | DPP tie 优先级（group.cu:313）、hipcub radix | ✓ smem 回退（cuh:103） |
| quant_kernels.cu | fp8/int8/MX 量化族（3363 行） | gfx1250 pk8 cvt :152 | ✓ 按架构回退 :364 |
| quant_mxfp4.cu | MXFP4 量化 | gfx950 pk_fp4 :36 | ✓ 标量 even_round_e2m1 |
| quant_mxfp4_gemm / mxfp6_gemm | 量化+pack | gfx950 硬检查 | ✗（硬检查 :318/:402） |
| sample_kernels.cu | 采样族（philox/外置指数） | — | — |
| topk_per_row_kernels.cu | radix top-k 族（5871 行） | DPP scan :1408、gfx1250 s_wait_storecnt :503 | ✓ gfx950 特化外通用 |
| topk_plain_kernels.cu | 自适应 ballot/sort/merge/radix | ballot、DPP :1340 | ✓ 策略阶梯本身 |
| custom_kernels.cu | wave GEMV/split-K | MFMA fp8 32x32x16 :1892 | ✓ 非 MI350 #else 变体 |
| rope/ 16 TU | RoPE 布局族 | gfx94 RNE 10 指令 vs gfx95 1 指令（rope_common.h:7515） | ✓ |
| rmsnorm/ 5 TU | C-ABI RMSNorm(+quant) | — | ✓ fp32 dtype 路径 |
| mha_native/ | FMHA d64 split-KV | MFMA 32x32x8 bf16（op_gemm.hpp:181） | ✗ |
| mla/opus_* | MLA decode/prefill（opus 实例） | MFMA f8f6f4 16x16x128 / WMMA+TDM | ✗ |
| mla/hk_* | HipKittens MLA（钉 VGPR） | `amdgpu_num_vgpr(72)`、buffer_load_lds | ✗ 严格 arch dispatch |
| iq2r/ | IQ2R 码本 GEMM（GLM-5.3） | scaled MFMA fp8 16x16x128 :391 | ✗ gfx950 host check |
| solver/ | sytrd 三对角化 | __shfl、rocBLAS（未接入 jit） | fp32/fp64 模板 |
| mxfp4_moe/ | MoE sort/quant/scatter | gfx950 fp4 | 形状不支持→报错 |
| opus_mqa_logits/ | 分页 MQA logits MXFP4 | MFMA fp4 32x32x64 / WMMA+TDM | ✗ |
| sparse_attn/msa/ | 稀疏块 attention | MFMA scale f8f6f4 16x16x128 | ✗ 硬检查 |

## 3. Backend/编译器层索引（详情 BACKEND_MATRIX.md）

| 区域 | 路径 | 要点 |
|---|---|---|
| opus DSL | `csrc/include/opus/opus.hpp` | 单头 C++ DSL：typed vector/gmem 描述符/MFMA/WMMA/DPP/TDM/cast；`--genco -D__HIPCC_RTC__` 免 HIP runtime 编译（README:186-265） |
| aiter_opus_plus | `csrc/include/aiter_opus_plus.h` | gfx950/gfx1250 packed cvt 层 + ROCm 7.2 早熔 hazard 绕过（opus.hpp:1917-1924）+ s_nop WAR hazard（:862-865） |
| CK 集成 | `csrc/ck_*/` + `blob_gen_cmd` | **JIT**：`gen_instances.py` 代码生成 → jit/core.py `--offload-arch` 编译；hipBLASLt 默认兜底 |
| FlyDSL | `aiter/ops/flydsl/`（~80 py） | 第三方 Python DSL→MLIR→HSACO；安装期 AOT（setup.py:414-429）；csrc 侧只有数据布局契约 |
| cpp_itfs | `csrc/cpp_itfs/` | jinja 模板 → hipcc+Makefile → ctypes.CDLL（utils.py:256-380）；lru_cache.h；Triton→HSACO 桥（utils.py:439-486） |
| 分发注册 | `aiter_dispatch.h`（torch-free _rmTorch 宏）+ `rocm_ops.hpp`（109 个 PYBIND 块）+ torch_guard.py（custom op 注册） | — |
| 构建系统 | `setup.py` + `aiter/jit/optCompilerConfig.json`（142 模块） | PREBUILD_KERNELS 0-3 级；per-file `-mllvm` 旗标；gfx1250-strict 二进制不兼容规则 |

## 4. Python 运行时层索引（详情 EMULATION_CATALOG.md §fallback）

| 机制 | 位置 | 层 |
|---|---|---|
| compile_ops import-or-build | `aiter/jit/core.py:2309-2405` | python-jit |
| blob 代码生成事务（stage/publish/restore） | `jit_cache.py:271-513` | python-jit |
| FileBaton 多进程构建安全 | `file_baton.py:26+`、`core.py:61-92` | python-jit |
| arch 探测（rocminfo/GPU_ARCHS，未知→KeyError） | `chip_info.py:47-163` | python-dispatch |
| gfx1250 A0/B0 硅片 fail-closed 门 | `asm_guard.py:12-64` | python-dispatch |
| fp8 fnuz(gfx942)/fn(其余)+uint8 兜底 | `aiter/utility/dtypes.py:10-41` | python-dispatch |
| tuned-CSV libtype 分发（solMap） | `aiter/tuned_gemm.py:797-805` | python-dispatch |
| torch._scaled_mm→fp32 模拟 | `tuned_gemm.py:573-599` | runtime-fallback |
| Windows 无 ROCm → AITER_TRITON_ONLY | `aiter/__init__.py:78-100` | package 级回退 |
| opus warn+stub（import 存活、调用抛错） | `aiter/ops/opus/_arch.py:51-146` | python-dispatch |

## 5. Python 映射

kernel 文件 → jit 模块 → python 函数映射完整表见附录 A（`aiter/jit/optCompilerConfig.json` + `aiter/ops/*.py` 交叉验证）。例外：`fused_kernels.cu`（休眠，无模块引用）、`solver/`（独立 Makefile 基准，rocBLAS 依赖）。

## 附录 A：完整 kernel 条目

（三路考古报告原文已转录，条目 schema：name/path/entry/math/hw_deps/arch_guards/emu_path/backend/notes/python。为控制体量，此处收录索引；完整逐文件条目存于考古会话记录，关键条目已并入 TECHNIQUE_CATALOG.md。）
