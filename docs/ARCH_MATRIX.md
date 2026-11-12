# ARCH_MATRIX — 架构 × 能力支持矩阵（aiter 证据 + 本实验室实测）

对象：aiter @ `1eab5ae12` 源码证据 + rocm-demo 实验室（RX 6950 XT / gfx1030）实测。
纪律（charter §五）：架构支持必须以源码 guards、编译器能力、实测、可靠资料为据；不凭架构名推断。

## 图例
✅=aiter 使用且有源码证据　🔶=使用但带条件/回退　✗=不支持/硬检查拒绝　? =标注未验证
`[lab]` = 本实验室在 gfx1030 实测的补充行

## aiter 的架构分层（源码证据）

| 架构 | aiter 定位 | 关键证据 |
|---|---|---|
| gfx90a/gfx940/941/942 (CDNA3) | 主力 MFMA 路径 | buffer SRD 编码 `__GFX9__`（chunk_gdr:42-53）、v_pk_mul_f32 家族 |
| gfx950 (CDNA4/MI350) | MX 量化主战场 | `cvt_scalef32_pk_fp4_*`、`2xpk16_fp6`、scaled MFMA f8f6f4、fp4 MFMA 32x32x64、wave32 MI350 分支（custom_kernels:667/#else 对） |
| gfx1250 (MI450) | 新一代：WMMA+TDM | `wmma_f32_16x16x32_bf16`、TDM ring、`pk8` 批量 cvt、无 hipIpc 指针式 AR；**A0(strict)/B0 硅片二进制不兼容**（build_targets.py:47-56） |
| gfx110x/1151/1200/1201 (RDNA3/4) | Triton/flydsl 兜底 | CK a8w8 仅 gfx9 代码对象 → 静默 Triton（gemm_op_a8w8.py:61-67,731-738） |
| gfx1030 (RDNA2) | **aiter 不支持**（无任何 dispatch 分支） | 本实验室对象：soft-TMA/soft-fp8/fp4 全为软件替代 |

## 能力矩阵（aiter 源码证据）

| 能力 | gfx90a | gfx942 | gfx950 | gfx1030 | gfx12xx | 证据 |
|---|---|---|---|---|---|---|
| MFMA bf16 32x32x8/16x16x16 | ✅ | ✅ | ✅ | ✗ 无 mai-insts | ✗(WMMA 替代) | opus.hpp:3106-3131；lab PROFILE |
| MFMA scaled f8f6f4 | ✗ | ✗ | ✅ | ✗ | ✗(WMMA scale16) | opus.hpp:3146-3151 |
| MFMA fp4 32x32x64 | ✗ | ✗ | ✅ | ✗ | ✗ | opus.hpp:3186 |
| WMMA gfx12 wave32 | ✗ | ✗ | ✗ | ✗ | ✅ | opus.hpp:3196-3238 |
| `v_pk_mul_f32` packed | ✅ | ✅ | ✅ | ✗ → 标量回退 | ✗(?) | activation:101-108 |
| fp8 cvt（pk） | ✗ | ✅(fnuz clamp240) | ✅(fn clamp448) | ✗ | ✅(pk8) | aiter_opus_plus.h:43-88 |
| fp4 cvt pk | ✗ | ✗ | ✅ | ✗ | ✅ | aiter_opus_plus.h:143-168 |
| fp6 2xpk16 | ✗ | ✗ | ✅ | ✗ | ✗ | mha_v4_quant:101-110 |
| buffer_load→LDS 直通 | gfx942 用 | ✅(aiter 唯一使用点) | ? | 硬件有+builtin 错位[lab] | ?（global_load_async） | opus.hpp:1881-1906；toolchain 实证 |
| gfx1250 global_load_async_to_lds | ✗ | ✗ | ✗ | ✗ | ✅ | opus.hpp:1866-1880 |
| TDM tensor DMA | ✗ | ✗ | ✗ | ✗ | ✅(clang≥22) | opus.hpp:2411,2896-2943 |
| wave64 | ✅ | ✅ | ✅ | ✗(wave32) | ✗ | get_warp_size opus.hpp:1573 |
| hipIpc AR | ✅ | ✅ | ✅ | ✅(单卡无意义) | ✗ 指针式 | custom_all_reduce_gfx1250:15-16 |
| hipBLASLt 兜底 | ✅ | ✅ | ✅ | ?（aiter 不构建） | 🔶 慢→Triton | tuned_gemm.py:301-311 |
| CK a8w8 代码对象 | ✅ | ✅ | ✅ | ✗ | ✗→Triton | gemm_op_a8w8.py:61-67 |
| Triton 层兜底 | ✗ | 🔶 | 🔶 | ✗ | ✅ 主力 | aiter/ops/triton/ 206 文件 |
| LDS 容量表 | ✅ | ✅(64K) | ✅ | ✗(未知→ValueError) | ✅ | chip_info.py:98-120 |

## [lab] gfx1030 实测补充（aiter 不覆盖，本实验室自证）

| 能力 | gfx1030 状态 | 证据 |
|---|---|---|
| ds_write/read_b128（16B LDS 向量） | ✅ 真机正确（推翻旧 b32 负探针） | substitution-catalogue §2.5 + soft_tma demo |
| buffer_load→LDS 直通（b32） | ✅ 硬件有；**builtin miscompile +32dword**（m0 折叠 vs 数组 LDS 128） | toolchain.hip 实证 |
| 直通 LDS 单波约束 | ⚠ 双波共用 m0 → launch fault | toolchain 实证 |
| s_waitcnt vmcnt 分裂域 | ✅ vmcnt=[3:0]+[15:14]（llvm-mc 30+ 探针） | lab gfx1030.md L3 |
| 手写 ISA 深流水 gmem→LDS | ✅ 553 GB/s = 96.1% 经验上限（原工程收线值） | catalogue §3（2026-11-04 修正口径） |
| soft fp8 转换流 | ✅（cuda-oxide 侧）标量 91-98% of copy | fp8-throughput-grade |
| MFMA/WMMA | ✗ 硬缺失（fail-loud） | PROFILE：无 mai/wmma-256b-insts |
| fp8/fp4/fp6 转换硬件 | ✗ 全部软件位操作替代 | 本 lab soft_fp8/fp4 |

## aiter 的架构适配手法（三种，均 file:line 实证）

1. **编译期 guard**：`#if defined(__gfx950__)` 内核体分支（iq2r 每kernel、mha_v4_quant）；同源多 TU 按模块拆分（custom_all_reduce_gfx1250 整 TU）。
2. **运行期分支**：`get_gpu_arch()=="gfx950"` host 检查选 tuned 路径（fused_qk_rmsnorm_group_quant:1045）；`opus::get_warp_size()` 设备期波长探测。
3. **Python 层兜底链**：tuned-CSV libtype → 架构 if 链 → Triton/flydsl/torch 兜底（BACKEND_MATRIX.md）；未知架构 fail-closed（KeyError/raise/asm_guard）。
