# 考古①：csrc/kernels 算法线全扫（原文转录）

aiter @ `1eab5ae12c93af3c8c660202d9a413f637c2f011`。约定期 schema：name/path/entry/math/hw_deps/arch_guards/emu_path/backend/notes/python。约定："opus" = `csrc/include/opus/opus.hpp` DSL；"rmTorch dispatch" = `AITER_DISPATCH_*_rmTorch` torch-free 分发宏。标 **[not built]** = 存在但未被任何 jit 模块引用。构建/入口映射依据 `aiter/jit/optCompilerConfig.json`（module → srcs）交叉核对 `aiter/ops/*.py`。

## A. 顶层 `csrc/kernels/*.cu`

### 1. activation_kernels.cu
- **name**: Fused activation + (optional) mul/bias/quant (SiLU/SwiGLU/GeLU/GELU-tanh/situV2) with fp8/fp4 MX quant epilogues
- **path**: `csrc/kernels/activation_kernels.cu` (2283 lines)
- **entry**: host `silu_and_mul`:1446, `swiglu_and_mul`:1461, `silu_and_mul_bias`:1467, `swiglu_and_mul_bias`:1544, `gelu_and_mul_bias`:1634, `scaled_silu_and_mul`:1711, `silu_and_mul_quant`:1766, `gelu_and_mul`:2054, `gelu_tanh_and_mul`:2060, `gelu_fast`:2248; kernels `act_and_mul_kernel`:33, `swiglu_act_and_mul_kernel`:124, `act_and_mul_bias_kernel`:187, `swiglu_act_and_mul_bias_kernel`:301, `scaled_act_and_mul_kernel`:397, `act_and_mul_quant_kernel`:516, `situv2_and_mul_quant_kernel`:859, `activation_kernel_vec`:2092, `activation_kernel_vec_safe`:2137
- **math**: out[..., :d] = act(x[..., :d]) * x[..., d:] (optionally +bias, scale, mx/fp8 quantize) elementwise per token
- **hw_deps**: none (pure VALU; packed-fp32 `v_pk_mul_f32` inline asm at 102, 279, 469, 597); opus vector load/store helpers
- **arch_guards**: `#if defined(__gfx906__)||__gfx908__||__gfx90a__||__gfx940/941/942__||__gfx950__` at 101-103, 278-280, 468-470, 596-598 (select `v_pk_mul_f32`); `#if defined(__gfx1250__)||__gfx1250_strict__` at 684, 697 (fp8 convert variant)
- **emu_path**: yes — RDNA portable fallback "RDNA archs lack `v_pk_mul_f32`; portable fallback" → two scalar multiplies (106-108, 283-285, 476-478, 601-603); `activation_kernel_vec_safe` (2137) is a numerically-safe non-vector path
- **backend**: pure HIP + opus vector helpers (`store_vector_nbytes`), torch-free (`AITER_NO_TORCH_TYPES` line 4)
- **notes**: `AITER_NO_TORCH_TYPES` build isolation (4-9); vectorized loads with per-arch packed-math; activation+quant fusion in one pass; `__launch_bounds__` on quant kernel (859)
- **python**: `aiter/ops/activation.py` (`module_activation`)

### 2. binary_operator.cu
- **name**: Elementwise binary ops (add/sub/mul/div) via code-generated dispatch
- **path**: `csrc/kernels/binary_operator.cu` (42 lines)
- **entry**: host `aiter_add`:6, `aiter_sub`:10, `aiter_mul`:14, `aiter_div`:18 (each → `binary_op_dispatch`); device kernels live in generated `csrc/include/binary_operator.cuh`
- **math**: out = a op b elementwise for tensor pairs
- **hw_deps**: none visible in this TU (kernels generated)
- **arch_guards**: none in this file
- **emu_path**: none visible (dispatch target is generated)
- **backend**: pure HIP (codegen: `csrc/kernels/generate_binaryop.py` "generate kernel instances to speed up compilation", line 5-7)
- **notes**: instance generation for compile-time parallelism; torch-free tensors
- **python**: `aiter/ops/aiter_operator.py` (`module_aiter_operator`, MD_NAME line 12)

### 3. cache_kernels.cu
- **name**: KV-cache management family: swap/copy blocks, reshape-and-cache (plain/flash/per-token-quant/per-block-quant/ASMPA), concat-MLA (+segmented, +opt, +fused qk-rope), indexer K/QK-rope quant caches, gather
- **path**: `csrc/kernels/cache_kernels.cu` (5980 lines)
- **entry**: host `swap_blocks`:67, `copy_blocks`:152, `reshape_and_cache`:4228, `reshape_and_cache_flash`:4288, `reshape_and_cache_with_pertoken_quant`:4736, `reshape_and_cache_with_block_quant`:4815, `reshape_and_cache_with_block_quant_for_asm_pa`:4898, `concat_and_cache_mla`:4988, `concat_and_cache_mla_seg`:5026, `indexer_k_quant_and_cache`:5084, `indexer_qk_rope_quant_and_cache`:5125, `cp_gather_indexer_k_quant_cache`:5343, `fused_qk_rope_concat_and_cache_mla`:5545, `fused_qk_rope_concat_and_cache_mla_seg`:5857; kernels `copy_blocks_kernel`:119, `swap_blocks kernel`:211, `reshape_and_cache_flash_kernel`:289, `reshape_and_cache_with_per_token_quant_kernel`:366, `reshape_and_cache_with_block_quant_kernel`:522, `..._for_asmpa`:769, `concat_and_cache_mla_kernel`:1026, `concat_and_cache_mla_opt_kernel`:1079, `concat_and_cache_mla_seg_kernel`:1199, `concat_and_cache_mla_seg_opt_kernel`:1252, `concat_and_cache_mla_seg_512_kernel`:1319, `indexer_k_quant_and_cache_kernel`:1413, `indexer_qk_rope_quant_and_cache_kernel`:1674, `cp_gather_indexer_k_quant_cache_kernel`:2075, `fuse_qk_rope_concat_and_cache_mla_kernel`:3441 (+prefill:4100, general:4144), `fused_qk_rope_concat_and_cache_mla_seg_kernel`:2528
- **math**: writes/transforms q/kv (with fp8/UE8M0 quant and RoPE) into paged KV cache slots, copies/gathers blocks between caches
- **hw_deps**: none MFMA; vectorized 16B stores; gfx1250 TDM tensor-engine staging (2835-2841 "stage Q through the tensor engine… three tensor ops in flight"); fp8 `v_cvt` paths
- **arch_guards**: `#if defined(__gfx1250__)||__gfx1250_strict__` at 2835 (TDM Q staging); host `tdm_arch = get_gpu_arch()=="gfx1250"` at 5429 sizing dynamic LDS
- **emu_path**: yes — non-TDM default (per-thread 16B head loads, comment 2825-2834) is the portable path; TDM variant gated to gfx1250
- **backend**: pure HIP + opus; torch-free
- **notes**: quantization fused into cache writes (per-token, per-block UE8M0); segmented MLA cache write; ASMPA variant; head-index-scalar optimization noted at 2826-2834
- **python**: `aiter/ops/cache.py` — `swap_blocks`:13, `copy_blocks`:17, `reshape_and_cache`:23, `reshape_and_cache_flash`:37, `reshape_and_cache_with_pertoken_quant`:50, `reshape_and_cache_with_block_quant`:63, `reshape_and_cache_with_block_quant_for_asm_pa`:76, `concat_and_cache_mla`:90, `concat_and_cache_mla_seg`:101, `indexer_k_quant_and_cache`:112, `indexer_qk_rope_quant_and_cache`:123 (`module_cache`)

### 4. causal_conv1d_fwd_split_qkv.cu
- **name**: Prefill causal conv1d with fused split of q/k/v outputs
- **path**: `csrc/kernels/causal_conv1d_fwd_split_qkv.cu` (698 lines)
- **entry**: kernels `conv1d_split_qkv_channel_last_t`:46, `conv1d_split_qkv_t`:215 (both `__launch_bounds__(256)`); host `causal_conv1d_fwd_split_qkv_hip_impl`:525, `causal_conv1d_fwd_split_qkv_hip`:656
- **math**: y[t,c] = sum_{k} w[c,k]·x[t-k,c] (+bias) for a flattened (sequence,chunk) schedule, writing q/k/v to separate outputs
- **hw_deps**: none (bf16→f32 via union bit-cast, 14-19); coalesced bf16 loads
- **arch_guards**: none
- **emu_path**: none visible
- **backend**: pure HIP
- **notes**: grid.x = flattened (seq, chunk) decoded through `batch_ptr`/`token_chunk_offset_ptr`, grid.y = feature block (header 5-7); channel-last and interleaved variants
- **python**: `aiter/ops/causal_conv1d_fwd_split_qkv.py` (`module_causal_conv1d_fwd_split_qkv`)

### 5. causal_conv1d_update.cu
- **name**: Decode-time causal conv1d state update (Mamba-style) with SiLU, circular buffers, continuous batching
- **path**: `csrc/kernels/causal_conv1d_update.cu` (412 lines; Tri Dao copyright 2023)
- **entry**: kernel `causal_conv1d_update_kernel`:107 (`__launch_bounds__(kNThreads)`); launch `causal_conv1d_update_launch`:232, `causal_conv1d_update_dispatch`:249 (widths 2/3/4 at 253-257); host `causal_conv1d_update`:267
- **math**: y[t] = act(sum_k w[k]·x[t-k]) for one/few new tokens, updating sliding window state buffers
- **hw_deps**: none (plain VALU; templated conv width)
- **arch_guards**: none
- **emu_path**: none visible (dtype dispatch only, 366-388)
- **backend**: pure HIP (vLLM/Tri Dao port)
- **notes**: width templated {2,3,4}; fp16/bf16/fp32; circular & non-circular modes; SiLU option (header 9-17)
- **python**: `aiter/ops/causal_conv1d_update.py` (`module_causal_conv1d_update`)

### 6. chunk_gated_delta_rule_fwd_h.cu
- **name**: Chunked gated delta rule forward recurrence for state H (GDN/Kimi linear attention)
- **path**: `csrc/kernels/chunk_gated_delta_rule_fwd_h.cu` (1541 lines)
- **entry**: kernel `chunk_gated_delta_rule_fwd_h_hip_kernel`:1066 (`__launch_bounds__(256)`); impl `chunk_gated_delta_rule_fwd_h_hip_impl`:1335; host `chunk_gated_delta_rule_fwd_h_hip`:1516
- **math**: H[i_n, chunk+1] = diag(exp(g))·H[chunk]·(I − kᵀw) + uᵀv_new per chunk (BT=64, K=V=128, BV=16), i.e. chunked rank-16 state updates with input gates
- **hw_deps**: MFMA — `mfma16x16x16_bf16` helper at 333-339: `__builtin_amdgcn_mfma_f32_16x16x16bf16_1k` (CDNA) or `__builtin_amdgcn_wmma_f32_16x16x16_bf16_w64_gfx12` (gfx12); wave64 (`WAVE_SIZE=64`, line 44); LDS panels (`__shared__` state tiles); raw buffer descriptors via `BUFFER_RESOURCE_3RD_DWORD` (42-53)
- **arch_guards**: `#if defined(__gfx803__)…__gfx950__||__gfx9_4_generic__||__GFX9__` / `__gfx103__` / `__gfx11xx__||__gfx1200/1201__||__GFX12__` at 42-53 (buffer-SRD encoding); `#if defined(__gfx1200__)||defined(__gfx1201__)` at 324 (WMMA row-group permutation), 335 (WMMA builtin), 689 and 980 (`__syncthreads()` ordering for gfx12)
- **emu_path**: none visible (single code path for both CDNA MFMA and RDNA WMMA)
- **backend**: pure HIP with raw `__builtin_amdgcn_*` builtins
- **notes**: software pipelining of gated state panels ("gated_v_panel aliases h_state_panel1… all waves must finish reading before overwrite", 686-688); exp2 fast gate (`USE_EXP2`, 344-350); BV=16 column chunking so each wave owns an MFMA fragment
- **python**: `aiter/ops/chunk_gated_delta_rule_fwd_h.py` — `chunk_gated_delta_rule_fwd_h_hip`:95 (`module_chunk_gdr_fwd_h`)

### 7. custom_all_reduce.cu
- **name**: Multi-GPU IPC custom all-reduce family: one/two-stage reduce, reduce-scatter, all-gather, fused AR+RMSNorm(+quant/per-group), fused QK-norm(+RoPE) AR, Lamport, fp4-Hadamard AR
- **path**: `csrc/kernels/custom_all_reduce.cu` (1227 lines) + `csrc/include/custom_all_reduce.cuh` (kernels)
- **entry**: host `dispose`:64, `initLamport`:79, `lamportAllReduce`:105, `register_input_buffer`:413, `register_output_buffer`:428, `get_graph_buffer_ipc_meta`:450, `register_graph_buffers`:460, `all_reduce`:525, `reduce_scatter`:562, `all_gather_reg`:593, `all_gather_unreg`:604, `all_gatherv`:627, `fused_allreduce_rmsnorm`:730, `fused_allreduce_rmsnorm_pad`:823, `fused_allreduce_rmsnorm_quant`:872, `fused_allreduce_rmsnorm_quant_per_group`:921, `fused_qknorm_allreduce`:1070, `fused_qknorm_allreduce_rope`:1143; kernels in .cuh: `cross_device_reduce_1stage_naive` (cuh:283), `cross_device_reduce_1stage` (cuh:323), 2-stage variants (cuh:391/517/625), `allgather_naive`:755, `allgather_vec`:781, `allgather_lastdim`:869, `reduce_scatter_split_first_dim`:920, `reduce_scatter_split_lastdim(_naive)`:954/990, `reduce_scatter_split_middim(_naive)`:1025/1062, `allReduceQuantFp8`:1311, `reduce_scatter_cross_device_store`:1384, `local_device_load_rmsnorm`:1612
- **math**: peer-to-peer all-reduce/all-gather/reduce-scatter over registered IPC buffers with peer signal flags; optional fused RMSNorm/quant epilogue
- **hw_deps**: none MFMA; `shfl_xor` wave reduction (cuh:1200), 512-thread `__launch_bounds__(512,1)` kernels; gfx950 fp4 packed-conversion for Hadamard-rotate quant AR (1009-1011)
- **arch_guards**: host check `get_gpu_arch()=="gfx950"` for hadamard_rotate at 1009-1011 (file-local); kernels in .cuh are arch-agnostic
- **emu_path**: none (naive kernels are layout/size fallbacks, not arch fallbacks)
- **backend**: pure HIP (IPC + atomics + spin-wait flags)
- **notes**: multi-variant split-dim reduce-scatter; graph-capture buffer registration; Lamport 3-buffer scheme; fp4/quant fused epilogues; residual all-reduce and RMSNorm instances split into custom_all_reduce_ext for parallel compile
- **python**: `aiter/ops/custom_all_reduce.py` (`module_custom_all_reduce`)

### 8. custom_all_reduce_ext.cu
- **name**: Instance TU: residual all-reduce (HAS_RESIDUAL) + row-option RMSNorm + single-kernel 2-stage fused AR+RMSNorm instantiations
- **path**: `csrc/kernels/custom_all_reduce_ext.cu` (95 lines)
- **entry**: none of its own — provides extern instances declared by `custom_all_reduce.cuh` (`AITER_CUSTOM_AR_EXT_INSTANCES`, comment 18-21)
- **math**: same ops as custom_all_reduce.cu; split out only so instances compile in parallel
- **hw_deps**: inherits from .cuh (shfl_xor, launch_bounds 512)
- **arch_guards**: none
- **emu_path**: none
- **backend**: pure HIP
- **notes**: pure compile-time-parallelization refactor (comment 17-21)
- **python**: same `module_custom_all_reduce` (compiled with custom_all_reduce.cu)

### 9. custom_all_reduce_gfx1250.cu
- **name**: gfx1250 (MI450) pointer-based custom all-reduce (no hipIpc)
- **path**: `csrc/kernels/custom_all_reduce_gfx1250.cu` (712 lines)
- **entry**: host `dispose`:84, `reduce_scatter`:180, `register_input_buffer`:213/`register_input_buffer_ipc`:231, `register_output_buffer`:221/`..._ipc`:246, `get_graph_buffer_ptrs`:268, `register_graph_buffers`:275, `get_graph_buffer_ipc_meta`:293, `register_graph_buffers_ipc`:301, `all_gather`:444, `all_reduce`:496, `fused_allreduce_rmsnorm`:621, `fused_allreduce_rmsnorm_quant`:642, `start_sync_latency`:673, `end_sync_latency`:686, `two_sync_latency`:699
- **math**: same AR/RS/AG semantics as gfx9 version but addressed by raw pointers (gfx1250 has no IPC handles)
- **hw_deps**: gfx1250-specific kernels in `custom_all_reduce_gfx1250.cuh` (TDM/pointer-based transport); no MFMA in this TU
- **arch_guards**: whole-TU gfx1250 target (module built only for gfx1250; header comment 15-16 "hipIpc is not available on gfx1250")
- **emu_path**: none visible
- **backend**: pure HIP
- **notes**: pointer-based API; graph buffer registration; separate latency-sync micro-kernels
- **python**: `aiter/ops/custom_all_reduce.py` (`module_custom_all_reduce_gfx1250`)

### 10. dsv4_dequant_gather_k.cu
- **name**: DeepSeek-V4 paged-K gather + dequantize (fp8 NoPE dims + bf16 RoPE tail with UE8M0 scales)
- **path**: `csrc/kernels/dsv4_dequant_gather_k.cu` (220 lines)
- **entry**: kernel `dsv4_dequant_gather_k_kernel`:62 (`__launch_bounds__(kBlockThreads)`); host `dsv4_dequantize_and_gather_k`:146
- **math**: out[448 fp8 dims→f32/bf16, 64 bf16 RoPE dims] gathered per token from paged records, applying UE8M0 per-64-dim scales
- **hw_deps**: wave64 (`kWave=64`, 32); one wavefront per token, lane L owns 8 output elements → single fully-coalesced 1024 B dwordx4 store (header 13-18)
- **arch_guards**: none
- **emu_path**: none visible
- **backend**: pure HIP
- **notes**: bit-exact record layout documented (576 B/token: 448 fp8 + 128 B bf16 + 8 B scales, 20-27); lanes 56-63 pass bf16 tail through unchanged (17-18)
- **python**: `aiter/ops/cache.py` — `dsv4_dequantize_and_gather_k`:206 (`module_dsv4_dequant_gather_k`)

### 11. dsv4_rotate_quant.cu
- **name**: Hadamard-rotate + (RoPE) + MXFP4/FP8 quant activation transforms for DeepSeek-V4
- **path**: `csrc/kernels/dsv4_rotate_quant.cu` (1571 lines)
- **entry**: kernels `hadamard_rotate_activation_fp4quant_kernel`:279, `rope_hadamard_rotate_activation_fp4quant_kernel`:534, `rope_hadamard_rotate_activation_fp8quant_kernel`:930, `norm_rope_hadamard_rotate_activation_fp4quant_kvcache_kernel`:1168; host `rotate_activation`:493, `rope_rotate_activation`:849
- **math**: applies random-Hadamard rotation to activations (optionally after RMSNorm/RoPE) and quantizes to MXFP4 (E2M1+E8M0) or fp8
- **hw_deps**: none MFMA; DPP `opus::mov_dpp` butterfly permutations for Hadamard (dsv4-style thread_data swaps); gfx950 `__builtin_amdgcn_cvt_scalef32_pk_fp4_*` converts; rocprim
- **arch_guards**: fp4-convert `#if defined(__gfx950__)` sites (ported from quant_mxfp4 helpers); runtime `WARP_SIZE` "not const: a const init would take the host fallback of 64" at 445, 507, 791, 889, 1143, 1520 (wave32/64 adaptive block sizing)
- **emu_path**: yes — non-gfx950 builds take the even-round-e2m1 scalar FP4 encoder (shared with quant_mxfp4.cu 45-79); host-side `WARP_SIZE` fallback comment (445)
- **backend**: pure HIP + opus (torch-free)
- **notes**: fusion of norm+rope+rotate+quant in one kernel (1168); rotate_dim_rsqrt compile-time Hadamard scaling (18-19); quant-amax-floor scale rounding
- **python**: `aiter/ops/quant.py` — `rotate_activation`:1361 (fc `rotate_activation_fp4quant`, `module_dsv4_rotate_quant`)

### 12. fused_ar_mhc_post.cu
- **name**: Fused custom all-reduce + MHC (manifold hyper-connection) post-processing
- **path**: `csrc/kernels/fused_ar_mhc_post.cu` (378 lines)
- **entry**: host `fused_allreduce_mhc_post_only`:181, `fused_allreduce_mhc_post_one_stage`:246, `fused_allreduce_mhc_post_split`:311; helpers `run_ar_mhc_post_split`:41/108, `run_ar_mhc_post_large_m`:57, `copy_input_to_registered_buffer`:15
- **math**: performs the AR pass then chains MHC post-combining of AR output with residual stream without a host round-trip
- **hw_deps**: inherits both `custom_all_reduce.cuh` kernels and `mhc.h` post kernels (includes at 4-9); no new device code
- **arch_guards**: none in this TU
- **emu_path**: none
- **backend**: mixed — orchestrates custom_all_reduce (pure HIP) + mhc_kernels (opus) device code
- **notes**: split (small-m) vs large-m orchestration paths; registered-buffer reuse for graph capture
- **python**: `aiter/ops/custom_all_reduce.py` (`module_fused_ar_mhc`)

### 13. fused_kernels.cu **[not built]**
- **name**: LLGemm_Silu — fused SILU-activation GEMM epilogue (vLLM legacy)
- **path**: `csrc/kernels/fused_kernels.cu` (234 lines)
- **entry**: kernel `LLGemm_Silu_kernel`:55 (`float4`/`__half2` operands); host `LLGemm_Silu`:195
- **math**: c = silu(b)·(a·x) fused GEMV/GEMM epilogue per row block
- **hw_deps**: none (float4 vectorized VALU; vLLM-derived)
- **arch_guards**: none
- **emu_path**: none
- **backend**: pure HIP
- **notes**: **dormant** — no jit module lists this TU; only a commented-out caller in `csrc/py_itfs_cu/custom.cu`:26-35. Kept for reference.
- **python**: none found

### 14. fused_norm_quant_gemm.cu
- **name**: Fused RMSNorm+FP8-quant into preallocated workspace followed by hipBLASLt GEMM
- **path**: `csrc/kernels/fused_norm_quant_gemm.cu` (45 lines)
- **entry**: host `aiter::fused_rmsnorm_quant_gemm`:10 — "Phase 1: fused RMSNorm + FP8 quantization into pre-allocated workspace" (38) then `hipb_mm(fp8_workspace, weight_t, solution_index, …)` (35-43)
- **math**: y = (rmsnorm(x)·scale_a) · (fp8 W)ᵀ·scale_w in bf16 out, quant staged in `fp8_workspace`
- **hw_deps**: device kernels from `rmsnorm_quant.h` (VALU); GEMM from hipBLASLt (`hipbsolgemm.cuh` → `aiter/gradlib/csrc/hipbsolgemm.cu`, `module_hipbsolgemm` in jit config)
- **arch_guards**: none
- **emu_path**: Python side has explicit C++-unavailable fallback (`aiter/ops/fused_norm_quant_gemm.py`:32 "C++ JIT module not available … using Python fallback", :79)
- **backend**: mixed — HIP kernels + hipBLASLt host call; torch-facing (torch/extension.h, line 4)
- **notes**: preallocated fp8 workspace avoids allocation inside graph capture; `solution_index` selects a pre-tuned hipBLASLt solution
- **python**: `aiter/ops/fused_norm_quant_gemm.py` — `fused_rmsnorm_quant_gemm`:39 (module built via gradlib path)

### 15. fused_qk_norm.cu
- **name**: Fused Q/K RMSNorm, 2D-grid parallel (Q on blockIdx.y=0, K on y=1)
- **path**: `csrc/kernels/fused_qk_norm.cu` (255 lines)
- **entry**: kernel `fused_qk_rmsnorm_kernel`:26; host `fused_qk_rmsnorm`:184
- **math**: q ← q/rms(q)·w_q, k ← k/rms(k)·w_k with shared BlockSize/thread_data_size
- **hw_deps**: none MFMA; `v_pk_mul_f32` packed math; opus vector loads
- **arch_guards**: `#if defined(__gfx906__)…__gfx950__` at 117-119 and 134-136 (packed vs scalar multiply)
- **emu_path**: yes — else-branch scalar math for non-gfx9 arches (123-127 region, same pattern as activation_kernels 106-108)
- **backend**: pure HIP + opus (torch-free)
- **notes**: Q and K blocks execute fully in parallel on different CUs (header 15-17); shared header `fused_qk_norm_rope_cache_quant.h` with the bigger fusion file
- **python**: `aiter/ops/fused_qk_norm_rope_cache_quant.py` (module `module_fused_qk_norm_rope_cache_quant_shuffle` compiles both `fused_qk_norm.cu` and `fused_qk_norm_rope_cache_quant.cu`)

### 16. fused_qk_norm_mrope_cache_quant.cu
- **name**: Fused QK RMSNorm + multimodal (3-section) RoPE + K/V cache write + per-tensor K/V fp8 quant
- **path**: `csrc/kernels/fused_qk_norm_mrope_cache_quant.cu` (235 lines, host-only)
- **entry**: host `fused_qk_norm_mrope_3d_cache_pts_quant_shuffle`:13 → `mrope_utils::fused_mrope_rms_set_kv<T,3,…>` (line ~113/179 of body); device kernels + launcher live in `csrc/kernels/rope/rope_common.h` (`namespace mrope_utils` 7222-8556, `fused_mrope_rms_set_kv` 8204)
- **math**: normalizes q/k, applies mrope with 3-way section split, quantizes k/v per tensor, writes paged KV cache at slot_mapping
- **hw_deps**: none MFMA (wave-level shfl RMSNorm, vectorized stores); stride-generic block/token/head addressing
- **arch_guards**: none in this TU (dtype/`fp8e4m3fn` vs `fnuz` selection at body lines ~110/179)
- **emu_path**: none visible
- **backend**: pure HIP + opus (torch-free)
- **notes**: `has_unit_element_stride` validation (8-10); supports optional k_out/v_out passthrough; per-tensor (not per-token) scales
- **python**: `aiter/ops/fused_qk_norm_mrope_cache_quant.py` — `fused_qk_norm_mrope_3d_cache_pts_quant_shuffle`:10 (`module_fused_qk_norm_mrope_cache_quant_shuffle`)

### 17. fused_qk_norm_rope_cache_quant.cu
- **name**: Mega-fusion family: QK RMSNorm+RoPE(+cache+fp8 shuffle quant) variants — 1way/2way, amax per-head, block-quant, minimax, V-quant tiles, group-quant KV
- **path**: `csrc/kernels/fused_qk_norm_rope_cache_quant.cu` (7187 lines)
- **entry**: kernels `fusedQKNormRopeQuantCacheShuffleKernel`:163, `fusedQKNormRopeBlockQuantCacheShuffleKernel`:465, `fused_rope_rms_2way_kernel`:1408, `fused_rope_rms_1way_kernel`:1691, `fused_rope_rms_1way_quad_kernel`:1995, `fused_rope_rms_2way_amax_kernel`:2440, `qk_partial_amax_to_perhead_scale_kernel`:2656, `static_fp8_quant_perhead_kernel`:2707, `minimax_qk_norm_rope_kernel`:2803, `qk_1way_output_partial_amax_kernel`:3654, `v_amax_to_descale_kernel`:4087, `v_2way_per_head_amax_tiled_kernel`:4100, `v_2way_per_head_quant_tiled_kernel`:4153, `v_1way_per_head_amax_tiled_kernel`:4268, `v_1way_per_head_quant_tiled_kernel`:4306, `fused_kv_norm_rope_group_quant`-family at 6098/6163/6962 (`__launch_bounds__(TOKENS_PER_BLOCK*64, 512/…)`); host launchers `launchFusedQKNormRopeQuantCacheShuffle`:1028, `launchFusedQKNormRopeBlockQuantCacheShuffle`:1193, `minimax_qk_norm_rope`:2920, `fused_qk_norm_rope_cache_quant_shuffle`:3041, `fused_qk_norm_rope_cache_pts_quant_shuffle`:3257, `fused_qk_norm_rope_cache_block_quant_shuffle`:3855, `fused_qk_norm_rope_group_quant`:6291, `fused_kv_norm_rope_group_quant`:7037
- **math**: one-pass RMSNorm → (M)RoPE → optional fp8/UE8M0 per-token/per-head/per-group quantization → paged KV-cache store (and V tensor quant)
- **hw_deps**: none MFMA; gfx1250 TDM tensor-engine Q staging (5107+), gfx942-specific VALU sequences (114), wave-of-64 token blocks, fp8 `v_cvt_pk_fp8_f32` paths (6032)
- **arch_guards**: `#if defined(__gfx942__)` at 114 (and 7404 `(__gfx942__)||(__gfx950__)` in rope_common helper, 7528 `__gfx906__…`); `#if defined(__gfx1250__)||__gfx1250_strict__` at 5107, 5159, 5280, 5353 (TDM ring/merge-q-scale-store)
- **emu_path**: yes — non-TDM build keeps plain-store variant (`kMergeQScaleStoreOk = false` at 5119-5127 "…this is off wherever the ring is off"); host `AITER_CHECK(get_gpu_arch()=="gfx942")` gates for the v-quant paths (3761, 4346); per-arch float_2_bf16 RNE branch vs gfx95 single-instruction note (7488-7518)
- **backend**: pure HIP + opus (torch-free)
- **notes**: 2-way (Q+K separate tensors) vs 1way (QKV fused); per-head amax→scale two-phase; runtime vs host-side store-merge selection with measured tradeoffs (-3.9% xlarge, +6% small) documented at 5130-5140; minimax variant separate (2803)
- **python**: `aiter/ops/fused_qk_norm_rope_cache_quant.py` — `fused_qk_norm_rope_cache_quant_shuffle`:39, `minimax_qk_norm_rope`:123, `fused_qk_norm_rope_cache_block_quant_shuffle`:204, `fused_qk_norm_rope_2way`:262, `fused_qk_norm_rope_1way`:287, `fused_qk_norm_rope_group_quant`:362, `fused_qk_norm_rope_2way_fp8_perhead_quant`:547, `fused_qk_norm_rope_1way_fp8_perhead_quant`:691, `fused_kv_norm_rope_group_quant`:810, `v_2way_per_head_fp8_quant`:917, `v_1way_per_head_fp8_quant`:952 (`module_fused_qk_norm_rope_cache_quant_shuffle`)

### 18. fused_qk_rmsnorm_group_quant.cu
- **name**: Fused Q/K RMSNorm + per-group (MX) fp8 quantization (and per-token variant)
- **path**: `csrc/kernels/fused_qk_rmsnorm_group_quant.cu` (1097 lines)
- **entry**: kernel `fused_qk_rmsnorm_group_quant_kernel`:31; host `fused_qk_rmsnorm_group_quant`:605, `fused_qk_rmsnorm_per_token_quant`:1065
- **math**: rmsnorm then group-wise (group_size 32/64/128) fp8 quant with UE8M0/e4m3 scales
- **hw_deps**: none MFMA; rocprim; wave-level reductions; runtime arch branch at 1045
- **arch_guards**: runtime `if(get_gpu_arch()=="gfx950" && has_residual && group_size <= WARP_SIZE*8)` at 1045 (tuned path selection, not compile guard)
- **emu_path**: yes — the non-gfx950 / non-residual combinations fall through to the generic launcher path (1045 else branch)
- **backend**: pure HIP + opus (torch-free)
- **notes**: residual-fused input option; group-size templated dispatch; separate per-token quant entry (1065)
- **python**: `aiter/ops/fused_qk_rmsnorm_group_quant.py` — `fused_qk_rmsnorm_group_quant`:60, `fused_qk_rmsnorm_per_token_quant`:137, `fused_qk_rmsnorm`:179 (`module_fused_qk_rmsnorm_group_quant`)

### 19. fused_qknorm_idxrqknorm.cu
- **name**: Horizontally fused Q/K RMSNorm + partial NeoX RoPE + sparse-layer indexer Q/K norm with optional KV/index-cache insert (AME/vLLM port)
- **path**: `csrc/kernels/fused_qknorm_idxrqknorm.cu` (1700 lines)
- **entry**: kernel `fusedQKNormIdxrQKNormKernel`:322; launcher `launchFusedQKNormIdxrQKNorm`:717; host `fused_qknorm_idxrqknorm`:1644 (PYBIND11-style jit extension, header 7-9)
- **math**: applies RMSNorm to q/k and to indexer q/k (two weight sets), partial RoPE, optionally writes KV cache and index caches
- **hw_deps**: none MFMA; `quant_utils.cuh` fp8 converts; opus vector ops; per-element `fallback_ptr` store path (111-131)
- **arch_guards**: none visible in this TU
- **emu_path**: yes — scalar `fallback_ptr` store branch when vectorized path can't be used (111-131)
- **backend**: pure HIP + opus
- **notes**: two-norm fusion (main + indexer) in a single kernel launch; optional cache insert; vLLM "AME" operator port (header 7-9)
- **python**: `aiter/ops/fused_qknorm_idxrqknorm.py` (`module_fused_qknorm_idxrqknorm`)

### 20. fused_split_gdr_update.cu
- **name**: Fused split gated-delta-rule update: mixed QKV decode → q/k norm, dt/softplus/sigmoid gates, state update, gated output
- **path**: `csrc/kernels/fused_split_gdr_update.cu` (539 lines)
- **entry**: host `fused_split_gdr_update`:406; device helpers `hip_softplus`:20, `hip_sigmoid`:22, `load_bf16x2`:25
- **math**: for GDN decode: splits mixed_qkv into q/k/v, applies l2-norm, computes dt=softplus(A_log·a)+dt_bias and gate b=sigmoid(b_gate), updates recurrent state with decay, emits gated v output
- **hw_deps**: none (VALU, bf16x2 vector loads)
- **arch_guards**: none
- **emu_path**: none visible
- **backend**: pure HIP
- **notes**: softplus threshold short-circuit (20-22); state-slot indexing with sentinel indices; bf16 throughout with fp32 math
- **python**: `aiter/ops/fused_split_gdr_update.py` — `fused_split_gdr_update`:37 (`module_fused_split_gdr_update`)

### 21. gated_rmsnorm_quant_kernels.cu
- **name**: Fused gated RMSNorm + fp8 group quant (and per-token variant)
- **path**: `csrc/kernels/gated_rmsnorm_quant_kernels.cu` (636 lines)
- **entry**: kernels `gated_rmsnorm_fp8_group_quant_kernel`:43, `gated_rmsnorm_fp8_per_token_quant_kernel`:344; launchers `gated_rmsnorm_fp8_group_quant_launcher_impl`:199, `..._launcher`:248, host `gated_rmsnorm_fp8_group_quant`:291; per-token: impl:496, launcher:546, host `gated_rmsnorm_fp8_per_token_quant`:598
- **math**: y = rmsnorm(x)·w, gated by a sigmoid gate, then fp8-quantized per group / per token (ops documented at 16-25)
- **hw_deps**: none MFMA; opus core types only (header 6-8 deliberately avoids heavy includes for dual host/device pass); vectorized fp8 converts
- **arch_guards**: none
- **emu_path**: none visible
- **backend**: pure HIP + opus
- **notes**: gate computed inline (Qwen-Next/gated-norm style); group quant with amax-floor rounding; two granularity variants share the launcher pattern
- **python**: `aiter/ops/gated_rmsnorm_fp8_group_quant.py` — `gated_rmsnorm_fp8_group_quant`:24; `aiter/ops/gated_rmsnorm_fp8_per_token_quant.py` (`module_gated_rmsnorm_quant`)

### 22. gdr_decode_packed_bf16.cu
- **name**: GDR (gated delta rule) decode: packed bf16 mixed-QKV contraction with recurrent state read-modify-write
- **path**: `csrc/kernels/gdr_decode_packed_bf16.cu` (336 lines)
- **entry**: kernel `gdr_decode_packed_bf16_kernel`:96 (`__launch_bounds__(kWarps*kWaveSize,1)`); host `gdr_decode_packed_bf16`:271
- **math**: per (token, v-head): computes decayed state update out = a·state + b·v with qk-side scales from packed mixed_qkv (8 q-heads ×128, 32 v-heads ×128 constants at 11-14)
- **hw_deps**: none MFMA; wave64 (`kWaveSize=64`), LDS with explicit DS-swizzle XOR patterns (`kDsSwizzleXor1/2/4`, 41-43) for bank-conflict-free state tiles; `Floatx4` vector math (39)
- **arch_guards**: none
- **emu_path**: none visible
- **backend**: pure HIP
- **notes**: 4 warps/block, v-head split across 4 vBlocks; state pool with sentinel negative indices skipping state access (contract comment 126-129)
- **python**: `aiter/ops/gdr_decode_packed_bf16.py` — `gdr_decode_packed_bf16`:38 (`module_gdr_decode_packed_bf16`)

### 23. groupnorm.cu
- **name**: Group normalization (up/down-dispatch variants) with preallocated workspace
- **path**: `csrc/kernels/groupnorm.cu` (387 lines)
- **entry**: kernels `groupnorm_kernel_dispatch_up`:208, `groupnorm_kernel_dispatch_down`:236; launcher `launchGroupNormKernel`:281, host `groupnorm_run`:349
- **math**: per-group mean/variance normalization over (num_groups, channels) with per-channel affine
- **hw_deps**: none (fp32 accumulate via `dtype2acctype`, 17)
- **arch_guards**: none
- **emu_path**: none visible
- **backend**: pure HIP
- **notes**: separate up (few channels/lane) and down (many) shapes; workspace output tensor; env-driven tuning strings (sstream/cstdlib at 11-15)
- **python**: `aiter/ops/groupnorm.py` (`module_groupnorm`)

### 24. inverse_rope_group_quant.cu
- **name**: Inverse-RoPE (de-rotation) + group-quant producer for downstream MFMA/WMMA scaleB consumers
- **path**: `csrc/kernels/inverse_rope_group_quant.cu` (1841 lines)
- **entry**: kernel `inverse_rope_group_quant_kernel`:345; host `inverse_rope_group_quant`:1160
- **math**: de-rotates cached K/Q (inverse of RoPE) and re-quantizes to fp8 with per-group E8M0 scales laid out for CDNA `V_MFMA_SCALE` (mfma_tile) or RDNA WMMA scaleB (n32k4)
- **hw_deps**: none MFMA itself; gfx1250 TDM consumer kernels (154-207); gfx950 `v_cvt_scalef32_pk_fp8_f32` (184) and gfx1250 `v_cvt_scalef32_pk8_fp8_f32` (177, 293-299); TDM arch host check (71)
- **arch_guards**: `#if defined(__gfx90a__)||__gfx940/941/942/950__` at 37-38 (CDNA branch); `#if defined(__gfx942__)` at 74; `#if defined(__gfx1250__)…` / `#elif defined(__gfx950__)` at 154-156, 167-179, 207, 283, 605, 898
- **emu_path**: partial — scale layouts are strictly paired to consumers: `mfma_tile` AITER_CHECKs `is_cdna_arch()` ("has no consumer on … use n32k4", 1824-1826) and `n32k4` requires non-CDNA (1828-1830); within a build the other layout is compiled-out (`AITER_INVERSE_ROPE_MFMA_TILE`/`N32K4` build flags, 1817/1832)
- **backend**: pure HIP + opus (torch-free)
- **notes**: scale-layout dispatch (kScaleMfmaTile/kScaleN32K4) selected at runtime with per-layout kernel families; comment block 138-141 documents the per-arch fp8 convert instruction counts; group size templated 32/64/128 (1789-1810)
- **python**: `aiter/ops/inverse_rope_group_quant.py` — `inverse_rope_group_quant`:91 (`module_inverse_rope_group_quant`)

### 25. mega_mhc.cu
- **name**: Mega-MHC (hyper-connection mixing): fused RMSNorm + per-token small GEMMs (residual/sublayer × mixing matrices) + Sinkhorn-ish scaling + optional MXFP8, gfx950 tuned + gfx942 generic
- **path**: `csrc/kernels/mega_mhc.cu` (2733 lines)
- **entry**: kernel `mega_mhc_kernel`-family instantiation at 2107 (`__launch_bounds__(launch_threads<…>)`); host `launch_mega_mhc`:2380 (host-side arch dispatch: gfx1250 → `mega_mhc_gfx1250`, 2631-2650)
- **math**: streams residual/sublayer tiles and computes mixed outputs via bf16 MFMA (fn packed hi/lo), applies pre/post mixing vectors and per-token norms with split-K partials in `partials`/`counters` workspace
- **hw_deps**: MFMA — `opus::mfma_f32_16x16x32_bf16` at 973-977, 1692-1718, 2023-2025; wave64 (`readfirstlane(tid/64)`, 1835); LDS double-buffered old/new residual tiles (`__shared__ bf16 old_r[4][BM][BK*2]; new_r…`, 1867-1870); gfx950 UE8M0 scale math with DPP amax reduce and `__builtin_amdgcn_cvt_scalef32_pk_fp8_bf16` (1838-1870)
- **arch_guards**: `#if defined(__gfx950__)` at 141, 217, 654, 1370 (tuned stream kernels + fp8 convert); `#if defined(__gfx950__)||defined(__gfx942__)` at 1828 (kernel body), 2136; host `AITER_CHECK(arch=="gfx950"||"gfx942")` 2470, tuned-only-gfx950 2472, mxfp8-gfx950 2468; host dispatch `#if AITER_MHC_GFX1250` + runtime `get_gpu_arch()=="gfx1250"` at 2631-2635
- **emu_path**: yes — generic runtime-width variant (H=0 "runtime-width generic fallback", 22; variant 13 "generic", 86-93); gfx942 gets the generic path only (2472); fp32 accumulation with bf16 MFMA (fn hi/lo split, comment at mhc line pattern)
- **backend**: pure HIP + opus DSL intrinsics (no torch; `MHC_HIDDEN` set by module build recipe, 14-15)
- **notes**: tuned width modules h5120/h7168/generic (`module_mega_mhc_stream_*`); variant 12 with post-stream; split-K with device counters; identity-pre layout optimization (1849-1852 "both arrays optimized away")
- **python**: `aiter/ops/mega_mhc.py` — `launch` closure at :139 building `module_mega_mhc_stream_{suffix}` (:176)

### 26. mega_mhc_gfx1250.cu
- **name**: Mega-MHC gfx1250: TDM LDS-ring + wave32 WMMA packed bf16 hi/lo projection
- **path**: `csrc/kernels/mega_mhc_gfx1250.cu` (1728 lines)
- **entry**: kernel `mega_mhc_kernel`:1300 (`__launch_bounds__(C::THREADS,1)`); host `launch`:1433
- **math**: same MHC mixing as gfx950 but with TDM (tensor data mover) staging of residual/sublayer tiles into a per-wave LDS ring and WMMA compute (header 3-5)
- **hw_deps**: WMMA — `opus::wmma_f32_16x16x32_bf16` at 640-642, 878-880; TDM engine ops (header 3-4; TDM ring at 396+); wave32
- **arch_guards**: `#if defined(__gfx1250__)` at 206, 396, 1330 (device code); host `AITER_CHECK(variant==GENERIC_VARIANT…)` 1707, mxfp8 H%128 check 1492
- **emu_path**: none (gfx942/gfx950 have their own file)
- **backend**: pure HIP + opus
- **notes**: BM=16 tokens/WMMA-N, BK=32 WMMA-K (28-29); WMMA operand lane-mapping comments (411, 631); double-buffered ring with separate old/new tiles
- **python**: same `aiter/ops/mega_mhc.py` (`module_mega_mhc_stream_*` selects gfx1250 sources: both .cu listed in module srcs)

### 27. mha_common.cu
- **name**: Shared MHA philox RNG state unpacker
- **path**: `csrc/kernels/mha_common.cu` (19 lines)
- **entry**: kernel `ParsePhiloxCudaState` (line 8); used by all `module_mha_*`/`module_fmha_v3_*` modules (shared src)
- **math**: extracts (seed, offset) from captured or eager Philox state
- **hw_deps**: none
- **arch_guards**: none
- **emu_path**: none
- **backend**: pure HIP (at::PhiloxCudaState — the one torch-coupled TU)
- **python**: shared src of `module_mha_fwd/varlen/fmha_v3_*` in `aiter/ops/mha.py`

### 28. mha_v4_quant.cu
- **name**: MHAv4 pre-GEMM activation transforms: Hadamard rotate + MXFP8/MXFP6(fp6_p)/MXFP4 quant of Q, and V quantize kernels
- **path**: `csrc/kernels/mha_v4_quant.cu` (1261 lines)
- **entry**: kernels `hadamard_rotate_activation_hd128_kernel`:161, `hadamard_rotate_activation_mxfp8_quant_kernel`:250, `hadamard_rotate_activation_mxfp6_quant_kernel`:344, `hadamard_rotate_activation_mxfp4_quant_kernel`:507, `quantize_v_mxfp4_kernel`:643 (`__launch_bounds__(64)`), `quantize_v_mxfp6_fp6_p_kernel`:759; host `launch_quant`:873 (`check_inputs`:843)
- **math**: hd128 Hadamard rotation of Q (head_dim=128, 18) then MX-format quantization with E8M0 scales; V quantized to MXFP4/fp6-p
- **hw_deps**: none MFMA; gfx950 `v_cvt_scalef32_2xpk16_fp6_f32` inline asm wrapper at 101-110; `__builtin_amdgcn_cvt_scalef32_pk_fp4_f32` at 588, 735; DPP `opus::mov_dpp`/`upd_dpp` Hadamard butterflies (118-129)
- **arch_guards**: `#if defined(__gfx950__)` at 97 (fp6 convert), 436, 584, 734, 815; runtime `AITER_CHECK(get_gpu_arch()=="gfx950")` at 850, 1082, 1201; gfx942-or-gfx950 for hd128 rotate at 921
- **emu_path**: yes — hd128 rotate runs on gfx942 or gfx950 (921); MX quant paths are gfx950-only with hard host checks (no soft emu inside file)
- **backend**: pure HIP + opus (torch-free)
- **notes**: raw asm with early-clobber for ROCm 7.2 result-overlap hazard (98-101); separate K-only variants (`rotate_activation_mxfp6_quant_k` python side)
- **python**: `aiter/ops/mha_v4_quant.py` — `rotate_activation_hd128`:87, `rotate_activation_mxfp8_quant`:104, `rotate_activation_mxfp6_quant`:115 (+`_k`:125), `rotate_activation_mxfp4_quant`:149 (+`_k`:159) (`module_mha_v4_quant`)

### 29. mhc_kernels.cu
- **name**: MHC (manifold hyper-connection) kernel family: pre_gemm_sqrsum, pre_big_fuse(+rmsnorm), post, fused post+pre
- **path**: `csrc/kernels/mhc_kernels.cu` (3589 lines)
- **entry**: launchers `mhc_pre_gemm_sqrsum`:940, `mhc_pre_big_fuse`:1394, `mhc_post`:1877 (`launch_mhc_post_raw`:1841), `mhc_pre_big_fuse_rmsnorm`:2492, `mhc_fused_post_pre_gemm_sqrsum`:3487; kernels `mhc_pre_gemm_sqrsum_kernel`-family:204, `mhc_pre_big_fuse_kernel`:1001, `mhc_post_kernel`:1563, `mhc_pre_big_fuse_rmsnorm_kernel`:1910, `mhc_fused_post_pre_gemm_sqrsum_kernel`:2542
- **math**: MHC stream mixing: GEMM of hidden state against per-layer mixing matrices (fn), sum-of-squares for RMSNorm, post-combining and next-pre computation (see aiter/ops/mhc.py)
- **hw_deps**: MFMA/WMMA — wave64 CDNA bf16 MFMA (`MHC_BF16_MFMA`, gfx942 chained K16 / gfx950 native K32) at 40-44 and 556-641; gfx1250 wave32 `wmma_f32_16x16x32_bf16` (37, 642-839, marked "UNVERIFIED - no HW to validate"); gfx1250 TDM with `s_wait_tensorcnt` KEEP/DRAIN macros (45-81); `__launch_bounds__(num_warps*get_warp_size(), 1|2)` (204, 1001, 1910, 2542)
- **arch_guards**: `#if defined(__gfx1250__)…` at 28, 56, 81, 158, 235, 388, 642, 840, 2575, 2584, 2664, 2725, 2868, 2999, 3120, 3192, 3244; `#if defined(__gfx942__)` at 288, 1470, 1601, 1619, 1639, 2689, 2777; `#if defined(__gfx950__)||__gfx942__||__gfx9_4_generic__` at 40 (MHC_BF16_MFMA); occupancy dispatch `m <= cu_num*12 || arch != "gfx942"` at 1388-1392
- **emu_path**: yes — fp32 GEMM fallback path when bf16 MMA unavailable (`MHC_BF16_MFMA 0` → "other arches (host) fall back to fp32", 38-45; `GEMM_LOOP_BODY` generic path at 845-851); async_load vs TDM residual paths
- **backend**: pure HIP + opus DSL (torch-free)
- **notes**: 2-stage software pipelining with KEEP/DRAIN wait classes (48-80); bf16 fn hi/lo packed-weight scheme with LDS XOR-mask swizzle (556-575); fused post+pre single-kernel variant (2542); occupancy-driven kernel config table (1388-1392)
- **python**: `aiter/ops/mhc.py` (`module_mhc`; also `module_fused_ar_mhc` pulls this TU)

### 30. moe_align_block_size_kernels.cu
- **name**: MoE token-to-expert block alignment (sorted_token_ids/expert_ids/offsets)
- **path**: `csrc/kernels/moe_align_block_size_kernels.cu` (161 lines; vLLM-derived)
- **entry**: kernel `moe_align_block_size_kernel`:35; host `moe_align_block_size`:130
- **math**: builds expert-sorted token id lists padded to block_size with cumulative block offsets (O(num_experts) shared layout documented 46-50)
- **hw_deps**: none (LDS histogram + cumsum + atomic write positions, 46-58)
- **arch_guards**: none
- **emu_path**: none
- **backend**: pure HIP
- **notes**: single kernel computes counts, cumsum, and scatter positions with atomics
- **python**: `aiter/ops/moe_op.py` via `module_moe_asm` (srcs include this file)

### 31. moe_fused_gate.cu
- **name**: Fused MoE gating: softmax/sigmoid + bias + grouped top-k with tie-fixup, single kernel
- **path**: `csrc/kernels/moe_fused_gate.cu` (793 lines; adapted from sglang, header 4-6)
- **entry**: kernels `moe_fused_gate_kernel`:430, `moe_fused_gate_kernel_dynamic`:504; host `moe_fused_gate`:547
- **math**: computes gating scores, applies bias/e-pad correction, selects top-k experts per token with deterministic tie-breaking
- **hw_deps**: none (VALU; `AlignedArray` vector loads, 36)
- **arch_guards**: none
- **emu_path**: none visible
- **backend**: pure HIP
- **notes**: static (fixed num_experts/topk) and dynamic variants; bias correction path for DeepSeek-style routing
- **python**: `aiter/ops/topk.py` — `moe_fused_gate`:317 (`module_moe_asm`)

### 32. pos_encoding_kernels.cu
- **name**: Rotary position embedding (GPT-J/NeoX), plain and batched
- **path**: `csrc/kernels/pos_encoding_kernels.cu` (286 lines; vLLM-derived)
- **entry**: kernels `rotary_embedding_kernel`:100, `batched_rotary_embedding_kernel`:127; host `rotary_embedding`:160, `batched_rotary_embedding`:222
- **math**: x' = x·cos − rot(x)·sin per 2-element pair with rotate-half or GPT-J interleaving
- **hw_deps**: none
- **arch_guards**: none
- **emu_path**: none visible
- **backend**: pure HIP
- **notes**: batched variant takes per-row position ids 2-D; scalar_t templated fp16/bf16/fp32
- **python**: `aiter/ops/pos_encoding.py` (`module_pos_encoding`)

### 33. quant_kernels.cu
- **name**: Quantization family: dynamic per-tensor/per-token/per-group fp8/int8, smooth-quant, MoE smooth-quant v1/v2, fused MX-quant+MoE-sort, partial transpose
- **path**: `csrc/kernels/quant_kernels.cu` (3363 lines)
- **entry**: kernels `__launch_bounds__(block_size)` dynamic quant:96, `initializeScale`:711 (test util), amax kernels:821/833, `scaled_quant_kernel`:996, `scaled_quant_tail_kernel`:1005, smooth per-token:1014, `smooth_per_token_scaled_quant_kernel`:1098, MX grouped quant kernel:1551 (`__launch_bounds__(kWaves*32)`), `partial_transpose_kernel`:2137, `moe_smooth_per_token_scaled_quant_kernel_v1`:2268, `..._v2`:2485, `fused_mx_quant_moe_sort_kernel`:2755, `mxfp4_moe_sort_kernel`:3107; host `dynamic_per_tensor_quant`:1330, `dynamic_per_token_scaled_quant`:1402, `dynamic_per_group_scaled_quant`:1733, `smooth_per_token_scaled_quant`:2067, `partial_transpose`:2173, `fused_dynamic_mx_quant_moe_sort_hip`:3039, `..._bounded`:3063
- **math**: computes amax/scales then quantizes activations to fp8/int8/MX (E8M0+E2M3/E2M1) with optional smoothquant factors, and fuses MoE token sort for MX quant
- **hw_deps**: none MFMA; gfx1250 `v_cvt_scalef32_pk8_fp8_bf16` packed fp8 converts (152-222, 453); gfx942 specializations (394, 1580, 2798); DPP/`__shfl` reductions
- **arch_guards**: `#if defined(__gfx1250__)||__gfx1250_strict__` at 152, 187, 201, 222, 596, 1159, 1571, 2315; `#if defined(__gfx942__)` at 394, 1580, 2798; tuned host flag gfx1250 at 30; gfx950 mx-sort check 1749
- **emu_path**: yes — generic scalar quant path when packed convert guard absent; `v_cvt_scalef32_pk8_fp8_bf16` saturation workaround comment (364) implies non-packing fallback exists per arch
- **backend**: pure HIP + opus (torch-free)
- **notes**: amax-floor rounding for UE8M0 scales (`quant_amax_floor.h`); fused quant+sort (2755) eliminates a separate sort kernel; v1 vs v2 MoE smooth-quant (2268 vs 2485); partial transpose for weight layouts (2137)
- **python**: `aiter/ops/quant.py` (`module_quant`; also used from gemm ops e.g. `gemm_op_a6w4.py`)

### 34. quant_mxfp4.cu
- **name**: MXFP4 (E2M1+E8M0) activation quantization
- **path**: `csrc/kernels/quant_mxfp4.cu` (317 lines)
- **entry**: kernel `quant_mxfp4_kernel`:102 (`__launch_bounds__(kBlockThreads)`); host `quant_mxfp4`:245
- **math**: quantizes bf16/fp16 activations to packed MXFP4 with per-32-element E8M0 scales
- **hw_deps**: gfx950 `__builtin_amdgcn_cvt_scalef32_pk_fp4_bf16/_f16` (36-40)
- **arch_guards**: `#if defined(__gfx950__)` at 32, 125, 166
- **emu_path**: yes — scalar `even_round_e2m1` round-to-nearest-even E2M1 encoder with midpoint table for non-gfx950 (45-79, documented tie rules 50-58)
- **backend**: pure HIP + opus (torch-free)
- **notes**: hardware convert writes dst while reading src; two elements per convert with `sel` selects; host check "requires gfx950 hardware FP4 conversion" only on gemm-side sibling (quant_mxfp4_gemm:318) — the standalone quant path keeps the emu
- **python**: `aiter/ops/quant.py` (`module_quant`)

### 35. quant_mxfp4_gemm.cu
- **name**: Fused MXFP4 quant + (weight-layout aware) GEMM input preparation kernel
- **path**: `csrc/kernels/quant_mxfp4_gemm.cu` (425 lines)
- **entry**: kernel (quant+pack) at 236 (`__launch_bounds__(kBlockThreads)`); host `quant_mxfp4_gemm_hip_out`:306
- **math**: quantizes activations to MXFP4 and packs to the GEMM operand layout with E8M0 scales
- **hw_deps**: gfx950 `__builtin_amdgcn_cvt_scalef32_pk_fp4_f32` (206)
- **arch_guards**: `#if defined(__gfx950__)` at 201; host `AITER_CHECK(get_gpu_arch()=="gfx950", … "requires gfx950 hardware FP4 conversion")` at 318
- **emu_path**: no software fallback here — hard host check (318); the scalar encoder lives in quant_mxfp4.cu
- **backend**: pure HIP + opus (torch-free)
- **notes**: `RoundUp`/amax-floor scale rounding (146); output-tensor variant `_out` avoids allocation
- **python**: `aiter/ops/quant.py`/gemm ops (`module_quant`)

### 36. quant_mxfp6_gemm.cu
- **name**: MXFP6 (fp6 e2m3/e3m2, `fp6_p` packing) quant + pack for GEMM
- **path**: `csrc/kernels/quant_mxfp6_gemm.cu` (488 lines)
- **entry**: kernel `quant_mxfp6_gemm_kernel`:357 (`__launch_bounds__(kBlockThreads)`); host `quant_mxfp6_gemm_hip`:390
- **math**: quantizes 16-float vectors to two packed fp6 words with one E8M0 scale (`2xpk16`)
- **hw_deps**: gfx950 `__builtin_amdgcn_cvt_scalef32_2xpk16_fp6_f32` (229, 329)
- **arch_guards**: `#if defined(__gfx950__)` at 227, 326; host `is_gfx950` check 401-402
- **emu_path**: no software fallback in this file (hard check 402)
- **backend**: pure HIP + opus (torch-free)
- **notes**: kTileRows=256 block tiling (13); scales interleaved with packed data for direct MFMA consumption
- **python**: `aiter/ops/quant.py` (`module_quant`)

### 37. quick_all_reduce.cu
- **name**: QuickReduce quantized all-reduce (FP/Q4/Q3/Q6/FP8 codecs, optional fused RMSNorm)
- **path**: `csrc/kernels/quick_all_reduce.cu` (270 lines; kernels in `csrc/include/quick_all_reduce.cuh`)
- **entry**: host `init_custom_qr`:30, `qr_destroy`:41, `qr_uses_pull_q4`:47, `qr_get_handle`:54, `qr_open_handles`:61, `qr_all_reduce`:75, `qr_all_reduce_rmsnorm`:133, `qr_max_size`:218; codec instantiation table `INSTANTIATE_FOR_WORLDSIZE…` 239-268
- **math**: all-reduce where each rank quantizes its shard (int4/int3/int6/fp8/full-precision), peers dequantize and accumulate — communication bytes ≈ bits/element
- **hw_deps**: none MFMA; codec kernels in .cuh (`CodecFP`:28, `CodecQ4`:69, CodecQ3:248, `CodecQ6`:413, FP8:587); IPC peer buffers
- **arch_guards**: none in this TU
- **emu_path**: CodecFP is the no-quantization codec (cuh:26 "Default full precision codec")
- **backend**: pure HIP
- **notes**: Q3 TP2-only; rmsnorm-fused variant instantiated per dtype pair; pull-mode Q4 variant
- **python**: `aiter/ops/quick_all_reduce.py` (`module_quick_all_reduce`, MD_NAME :10)

### 38. quick_reduce_scatter.cu
- **name**: QuickReduce phase-1 reduce-scatter (contiguous rank shards, no all-gather)
- **path**: `csrc/kernels/quick_reduce_scatter.cu` (178 lines)
- **entry**: launcher `launch_quick_rs`:121; host `qr_reduce_scatter`:147
- **math**: reuses QuickReduce codec/accumulation but assigns each rank a contiguous shard and omits the all-gather + second quantization (header 8-12)
- **hw_deps**: same codec kernels as quick_all_reduce.cuh; IPC peer buffers consumption barrier (header 12-13)
- **arch_guards**: none in this TU
- **emu_path**: CodecFP full-precision codec available via shared header
- **backend**: pure HIP
- **notes**: two-phase design comment (8-13); barrier-protected IPC buffers for graph capture
- **python**: `aiter/ops/quick_reduce_scatter.py` (`module_quick_reduce_scatter`)

### 39. rmsnorm_quant_kernels.cu
- **name**: add-RMSNorm / RMSNorm + fp8-int8 quant (per-token/group/residual variants)
- **path**: `csrc/kernels/rmsnorm_quant_kernels.cu` (732 lines)
- **entry**: kernel `add_rmsnorm_quant_kernel`:24; host `add_rmsnorm_quant`:479, `rmsnorm_quant`:561, `add_rmsnorm`:637, `rmsnorm`:694
- **math**: fused residual add + RMSNorm + quantization (fp8/int8, per-token or grouped) emitting both normed-bf16 and quantized outputs
- **hw_deps**: none MFMA; `v_pk_mul_f32` (166-168, 205-207); gfx942 path (260); rocprim; vectorized stores
- **arch_guards**: `#if defined(__gfx906__)…__gfx950__` at 166-168, 205-207; `#if defined(__gfx942__)` at 260
- **emu_path**: yes — RDNA scalar fallback (213 "RDNA archs lack `v_pk_mul_f32`; portable fallback") and grouped-quant fallback path (536 "Same grouped-quant fallback as the residual dispatch above")
- **backend**: pure HIP + opus (torch-free)
- **notes**: dual-output (bf16 + fp8) single pass; residual in-place or out-of-place; group quant with amax-floor
- **python**: `aiter/ops/rmsnorm.py` (`module_rmsnorm_quant`)

### 40. sample_kernels.cu
- **name**: Sampling family: greedy, random (with Gumbel/outer-exponential trick), mixed (top-k/p?), exponential RNG
- **path**: `csrc/kernels/sample_kernels.cu` (825 lines)
- **entry**: kernels `greedy_sample_kernel`:376, `random_sample_outer_exponential_kernel`:386, `random_sample_kernel`:407, `mix_sample_outer_exponential_kernel`:439, `mix_sample_kernel`:475, `exponential_kernel`:727; host `greedy_sample`:510, `random_sample_outer_exponential`:537, `mixed_sample_outer_exponential`:577, `random_sample`:624, `mixed_sample`:673, `exponential`:781
- **math**: argmax (greedy) or sampling from softmax via outer-exponential (exp(-E)-key argmax) with philox (seed,offset) RNG; mixed top-k/typical variants
- **hw_deps**: none (wave reductions via `hip_reduce.h`); philox inline RNG (177-193, 413-428)
- **arch_guards**: none
- **emu_path**: none
- **backend**: pure HIP (torch-free; philox passed as plain pair, header 7-9)
- **notes**: outer-exponential sampling avoids full softmax; exponential RNG generation kernel separate (727)
- **python**: `aiter/ops/sample.py` (`module_sample`)

### 41. sp_head_exchange.cu
- **name**: SP (sequence-parallel) head exchange: allgather last-dim with token-major head layout write
- **path**: `csrc/kernels/sp_head_exchange.cu` (83 lines)
- **entry**: kernel `sp_head_exchange_kernel`:11 (`__launch_bounds__(512,1)`); host `sp_head_exchange`:34
- **math**: each rank reads only its token slice of peers' buffers and writes the final token-major head layout (comment 8-9)
- **hw_deps**: IPC `RankData`/`RankSignals` machinery from custom_all_reduce.cuh; uint4 (16 B) stores
- **arch_guards**: none
- **emu_path**: none
- **backend**: pure HIP (reuses custom_all_reduce sync protocol)
- **notes**: same multi-rank signal/flag sync as `allgather_lastdim` (cuh:869) but destination-side gather+repack
- **python**: `aiter/ops/sp_head_exchange.py` — `sp_head_exchange`:11 (`module_sp_head_exchange`)

### 42. topk_gating_kernels.cu
- **name**: Fused MoE topk gating dispatcher (score funcs: sqrtsoftplus/sigmoid/softmax)
- **path**: `csrc/kernels/topk_gating_kernels.cu` (154 lines) + `csrc/include/topk_gating_kernels.cuh` (kernels) + instantiation TUs `csrc/kernels/topk_gating/{topk_softmax,topk_sigmoid,topk_sqrtsoftplus}.cu`
- **entry**: host `topk_gating`:42 (resolves dtype+score_func string, header 9-13); kernels `topk_gating_kernel_opt` (cuh:304), `topk_gating_kernel_opt_multiwave` (cuh:425); instantiation macro `AITER_TOPK_GATING_INSTANTIATE(SCORE_*)` (each 8-line TU)
- **math**: scores experts (softmax / sigmoid / sqrt(softplus(x)) per header 9-13), top-k select with optional renorm
- **hw_deps**: none MFMA; register/shfl top-k, LDS tie handling; wave32 vs wave64 EPT tuning (cuh:120, 297)
- **arch_guards**: none compile-time; runtime arch gates in .cuh: `get_gpu_arch()=="gfx942"` E=128 opt_n gate (95-99), gfx942/gfx950 for E=512 prefill_n (103-109), wave32-only multiwave kernel (cuh:439-442)
- **emu_path**: yes — smem fallback path for non-benchmarked arches ("Other archs (gfx1201, gfx1250, …) stay on the smem fallback until benchmarked", cuh:103-104)
- **backend**: pure HIP + opus (torch-free)
- **notes**: score-function selected by string at runtime → 3 instantiation TUs for compile parallelism; multiwave register kernel for wave32 (cuh:415-451)
- **python**: `aiter/ops/topk.py` — `topk_gating_fwd`:20, `topk_gating`:165 (`module_moe_topk`)

### 43. topk_per_row_kernels.cu
- **name**: Radix-select top-k per row (multiblock persistent, one-block register, one-block LDS-tail families)
- **path**: `csrc/kernels/topk_per_row_kernels.cu` (5871 lines)
- **entry**: kernels `radix_kernel_persistent`:342, `last_filter_kernel`:1784, `radix_kernel`:1890, `radix_topk_one_block_reg_kernel`:2437, `radix_topk_one_block_lds_tail_kernel`:3853, `radix_topk_one_block_kernel`:4443; launchers `standalone_stable_radix_topk_multiblock_`:757, `standalone_stable_radix_topk`:837, `standalone_stable_radix_topk_`:4760, `standalone_stable_radix_topk_one_block_`:4907, `radix_topk_dispatch`:5598, host `top_k_per_row_prefill`:5676, `top_k_per_row_decode`:5785
- **math**: exact top-k indices per row via radix histogram/bin filtering passes (multiblock with cross-block arrival counter + spin-wait) or single-block register/LDS radix
- **hw_deps**: none MFMA; hipcub BlockScan/BlockLoad (279-281); DPP scan (`wave_inclusive_sum_dpp`/`row_inclusive_sum_dpp`, 1408-1418, 2677-2716); gfx1250 `s_wait_storecnt` vs gfx9 `s_waitcnt vmcnt(0)` memory-wait (503-507); LDS histograms; `__builtin_amdgcn_s_sleep`/`__builtin_amdgcn_fence` spin barrier (530-546)
- **arch_guards**: `#if defined(__gfx1250__)||__gfx1250_strict__` at 503; `#if defined(__HIP_DEVICE_COMPILE__) && !defined(__gfx950__)` at 5193 (excludes wave64 kernels needing >gfx942 LDS from gfx950 code object, 5194-5198)
- **emu_path**: yes — generic radix path serves rows outside the gfx950 specialized ranges (`dispatch_topk_plain_gfx950` returns false on other targets, 5192-5199)
- **backend**: pure HIP + hipcub + DPP
- **notes**: persistent multiblock radix with atomic histogram + cross-block barrier (508-546); one-block register family with per-length lane-count instantiation ladder (5207-5217); NaN-aware fp32 key ordering (`topk_fp32_key.h`); prefill/decode dispatch with mulblocks heuristic (5533-5590)
- **python**: `aiter/ops/topk.py` — `top_k_per_row_prefill`:759, decode path (`module_top_k_per_row`; also compiled into `module_topk_plain`)

### 44. topk_per_row_sampled_kernels.cu
- **name**: Sampled top-K for prefill: 3-phase threshold/filter/select with streamed-radix fallback
- **path**: `csrc/kernels/topk_per_row_sampled_kernels.cu` (1758 lines)
- **entry**: kernel phase A `PHASE_A_OCCUPANCY __launch_bounds__(1024)` kernel at 952 (`phase_a_threshold`); phases B/C via helpers; host `topk_sampled_supports`:1574, `top_k_per_row_prefill_sampled`:1594
- **math**: samples S contiguous chunks to get row threshold T, filters row with dwordx4 into per-wave LDS candidate staging, then selects exact K-th key and gathers winners; unusable rows re-run streamed radix over full row (header 5-11)
- **hw_deps**: none MFMA; 1024-thread blocks; LDS staging; dwordx4 vector loads (402 comment); hipcub in fallback
- **arch_guards**: none compile-time; runtime gfx950-only gate (1526-1547: "gfx950 only: elsewhere the kernels are traps (TOPK_SAMPLED_DEVICE)"; `gcnArchName` check 1547); LDS budget vs gfx942 documented (1528-1529)
- **emu_path**: yes — per-row streamed radix fallback inside phase C (header 10-11, 347-367 register-budget fusion notes); other arches unsupported at host (1547)
- **backend**: pure HIP
- **notes**: fallback inlined into phase_c to share register allocation (349-367, explicitly measured "no-fallback time within 1.4%"); 4 fallback slot contract (39)
- **python**: `aiter/ops/topk.py` — sampled workspace + prefill-sampled path (`module_top_k_per_row_sampled`)

### 45. topk_plain_kernels.cu
- **name**: AdaptiveTopK: ballot-filter / bitonic-sort / bitonic-merge strategies + radix path
- **path**: `csrc/kernels/topk_plain_kernels.cu` (2700 lines)
- **entry**: kernels `topk_per_row`:59, `gather_topk_values_kernel`:147, `gather_topk_values_strided_kernel`:174, filter/sort/merge instantiations at 1191/1201/1211, 1613, 2015/2236; launchers `topk_per_row_kernel_launcher`:101/2504, `topk_kernel_launcher`:2267, host `AdaptiveTopK`:2361/2429, `topk_plain`:2548, capability fns `topk_plain_uses_radix`:2694, `topk_plain_reads_pitch`:2696
- **math**: top-k values/indices per row choosing among ballot-filter (sparse), bitonic sort/merge (moderate), or radix (large) strategies per header 8-20
- **hw_deps**: none MFMA; `__ballot` compaction (10-12); LDS staging; hipcub BlockScan (270-281); DPP wave scan (1340-1345 "wave scan is DPP — row_shr plus row_bcast, pure VALU"); `ds_bpermute` (1345)
- **arch_guards**: none compile-time in this file (gfx950-specialized dispatch imported from topk_per_row_kernels.cu `dispatch_topk_plain_gfx950`)
- **emu_path**: yes — strategy ladder itself is adaptive; block-sort fallback checks pitch (2401) and unconditionally-written outputs fallback note (2601); radix vs plain selected by `should_use_topk_radix` (123, 2380, 2451)
- **backend**: pure HIP + hipcub + opus
- **notes**: occupancy-based launch-parameter calculation (1293-1399); ragged-row batching (`topk_plain_batches_ragged_rows` python :85); mulblocks heuristic exported to python
- **python**: `aiter/ops/topk_plain.py` — `topk_plain`:119, `topk_plain_uses_radix`:47, `topk_plain_reads_pitch`:51 (`module_topk_plain`)

### 46. topk_softmax_kernels.cu
- **name**: MoE top-k gating softmax (TensorRT-LLM-derived) + fused shared-expert gate + moe_sum
- **path**: `csrc/kernels/topk_softmax_kernels.cu` (1620 lines)
- **entry**: kernels `moeSoftmax`-family at 67 (`__launch_bounds__(TPB)`), `moeTopK`:130, fused gating kernel:249 (`__launch_bounds__(WARPS_PER_CTA*get_warp_size())`), secondary topk:659, `moe_sum_kernel`:772, fused shared gate:806; launchers `topkGatingSoftmaxLauncherHelper`:550, `topkGatingSoftmaxKernelLauncher`:685, `topkGatingSoftmaxFusedGateLauncherHelper`:1168, `topkGatingSoftmaxFusedGateKernelLauncher`:1300; host `topk_softmax`:1368, `topk_softmax_fused_shared_gate`:1439, `moe_sum`:1570
- **math**: softmax over experts then top-k (with renorm and optional shared-expert gate add)
- **hw_deps**: none MFMA; warp-level sorts; wave-size generic (`opus::get_warp_size()` 249, 806)
- **arch_guards**: none
- **emu_path**: yes — non-power-of-2 expert fallback rejected in favor of Python-side path (1353 "must be handled on the Python side (torch.sum fallback)" for moe_sum at 1615)
- **backend**: pure HIP + opus
- **notes**: TPB/warps-per-CTA templated; fused-shared-expert variant writes gated weights directly
- **python**: `aiter/ops/topk.py` — `topk_softmax` / shared-gate (`module_moe_asm`)

### 47. topk_softmax_kernels_group.cu
- **name**: Grouped top-k (biased sigmoid/softmax) with DPP tie-priority ranks, wave32 and wave64 variants
- **path**: `csrc/kernels/topk_softmax_kernels_group.cu` (2265 lines)
- **entry**: kernels grouped-topk at 432, `topk_reg_kernel`:752, group form at 1072, wave32 biased grouped at 1578 (`__launch_bounds__(32*TPB)`); host `biased_grouped_topk`:2096, `grouped_topk`:2210
- **math**: n-group partitioned top-k selection with bias correction (DeepSeek V3 style), sigmoid or softmax scores
- **hw_deps**: none MFMA; DPP tie-priority table (313-317 "Compact form of the legacy wave64 DPP tie-priority table… permlanex16 for row_bcast"); wave32 register kernel with 8 experts/lane (2127)
- **arch_guards**: `#if !defined(__GFX9__)` at 1592 (wave32-only kernel excluded on CDNA where wave is 64)
- **emu_path**: partial — wave64-only register path marked "wave32 untested" (1893); dispatch selects kernel by `get_warp_size_func()` (2127-2132, 2186)
- **backend**: pure HIP + opus (torch-free)
- **notes**: separate wave32 (1570-1615) and wave64 (register) implementations; biased and unbiased entries; renorm options
- **python**: `aiter/ops/topk.py` — `grouped_topk`:268, `biased_grouped_topk`:346 (`module_moe_asm`)

### 48. unary_operator.cu
- **name**: Elementwise unary ops (sigmoid, tanh, …) tile kernel
- **path**: `csrc/kernels/unary_operator.cu` (172 lines)
- **entry**: kernel `unary_operator_tile_kernel`:100; host wrappers for `aiter_sigmoid`/`aiter_tanh` etc. (declared `csrc/include/aiter_unary.h`:13-15)
- **math**: applies unary function elementwise on [M,N,K] tiles
- **hw_deps**: none (VALU; a commented-out `v_exp_f32` asm emulator block at 48-70 shows the previous tanh/sigmoid asm approach, now removed)
- **arch_guards**: none
- **emu_path**: yes — non-tile-friendly inputs are handled Python-side via torch (aiter_unary.h 9-11 "the non-tile-friendly fallback … now lives in the Python" wrapper)
- **backend**: pure HIP
- **notes**: torch-free output-into-caller-tensor design; ops generated/dispatched similar to binary_operator
- **python**: `aiter/ops/aiter_operator.py` (`module_aiter_unary`)

### 49. custom_kernels.cu
- **name**: Wave-quantized GEMV/split-K family: `wvSplitK_hf(_sml/_big)`, `wvSplitKQ_hf` (fp8 MFMA), HGEMV_WFPerRow, LLGemmZZ, matrixMultiplyShared
- **path**: `csrc/kernels/custom_kernels.cu` (2478 lines)
- **entry**: kernels `wvSplitK_hf_sml_`:686/934, `wvSplitK_hf_`:949/1241, `wvSplitK_hf_big_`:1256/1607, `wvSplitKQ_hf_sml_`:1781/1978, `wvSplitKQ_hf_`:2002/2195, `HGEMV_WFPerRow`:2265, `matrixMultiplyShared`:2407, fp8 gemv at 276/434; host `wvSplitK_`:1719, `wvSplitKQ_`:2210, `LLGemmZZ`:2346, `MMGPUKernel`:2456
- **math**: per-wave split-K GEMV/GEMM (bf16/fp16, quantized-Q fp8 variants) with workspace reduction
- **hw_deps**: MFMA — `__builtin_amdgcn_mfma_f32_32x32x16_fp8_fp8` at 1892 and 2107 (wvSplitKQ fp8 path); LDS staging for matrixMultiplyShared
- **arch_guards**: `#if defined(__HIPCC__) && (__gfx90a__||__gfx942__)` at 21, `__gfx942__` at 25, `(__gfx90a__||__gfx942__||__gfx950__)` at 29 (arch-selection prelude); `#if defined(__HIP__MI350_MI300_MI250__)` blocks at 430/667-681, 683/932-944, 946/1239-1251, 1253/1605-1617, 1772/1969-1991, 1993/2186-2208 (MI350-class wave32 vs generic wave64 kernel pairs)
- **emu_path**: yes — each kernel pair has a non-MI350 `#else` variant (e.g. 667-681 vs 683-944): the generic build compiles scalar/fewer-vector variants
- **backend**: pure HIP
- **notes**: reached via `module_custom` (pybind `custom_pybind.cu` + `py_itfs_cu/custom.cu` wrappers `wvSplitK`, `wvSplitKQ`, `LLGemmZZ`, `LLMM1`); python `aiter/ops/custom.py` — `wvSpltK`:12, `wv_splitk_small_fp16_bf16`:18, `LLMM1`:24, `wvSplitKQ`:28
- **python**: `aiter/ops/custom.py` (`module_custom`)

## B. `csrc/kernels/rope/`（16 kernel TU + rope_common.h）

rope 家族是共享 `rope_common.h`（内含 `mrope_utils` 7222-8556 与 arch 特化 helper 4476、7404、7488-7528）的生成/分发集。

- **name**: Rotary position embedding family — layouts: `1c/2c` × `{2d, cached, cached_positions, cached_positions_offsets, thd, uncached}` × `{fwd, bwd}`
- **path**: `csrc/kernels/rope/general_*.cu` (48-100 lines each; e.g. `general_1c_2d_fwd_kernels.cu` entry `rope_2d_fwd_impl`:8, `general_1c_cached_fwd_kernels.cu` `rope_cached_fwd_impl`:8, `general_1c_thd_fwd_kernels.cu` `rope_thd_fwd_impl`:8, `general_2c_cached_fwd_kernels.cu` `rope_cached_2c_fwd_impl`:8, `general_1c_cached_positions_offsets_fwd_kernels.cu` `rope_cached_positions_offsets_fwd_impl`:33 with doc 20-32)
- **math**: applies/backs-out RoPE (NEOX style=0 / GPT-J style=1) on [s,b,h,d] (or [t,h,d] varlen) tensors using cached cos/sin tables, optional positions(+offsets) indirection
- **hw_deps**: none MFMA (VALU trig-free cos/sin multiply-add; vectorized pair math); per-arch helpers in rope_common.h (`float_2_bf16_pair` gfx94 RNE branch 7404/7488-7518, gfx9 packed-math at 7528+)
- **arch_guards**: rope_common.h `#if defined(__HIP_DEVICE_COMPILE__) && (__gfx942__||__gfx950__)` at 7404; `#if defined(__gfx906__)||…` at 7528; kernels themselves arch-neutral
- **emu_path**: yes — generic scalar rotate paths; gfx95 single-instruction vs gfx94 10-instruction VALU sequence documented (7515-7518)
- **backend**: pure HIP + opus (rope_common.h torch-free with `AITER_NO_TORCH_TYPES` pattern)
- **notes**: each TU compiles standalone for parallelism (rope_common.h 1-3 "norm is the compile bottleneck" pattern reused); thd = varlen via cu_seqlens; 2d = image H/W freq split
- **python**: `aiter/ops/rope.py` — `rope_fwd_impl`:12, `rope_bwd_impl`:31, `rope_2c_fwd_impl`:50, `rope_cached_fwd_impl`:92, `rope_cached_positions_fwd_impl`:176, `rope_cached_positions_offsets_fwd_impl`:222, etc. (`module_rope_*` 16 modules)

## C. `csrc/kernels/rmsnorm/`（5 文件）

- **name**: OPUS RMSNorm C-ABI family: plain norm per dtype (bf16/fp16/fp32) + fused rmsnorm+quant(int8/fp8)
- **path**: `csrc/kernels/rmsnorm/` — `rmsnorm_opus_norm.hpp` (macro launcher `OPUS_NORM_DEFINE`, 14-19), `rmsnorm_opus_norm_entry.cu` (C ABI `rms_norm_opus`:29, `fused_add_rms_norm_opus`:50, `add_rms_norm_opus`:74; dtype dispatch macro 21-33), `rmsnorm_opus_norm_bf16/fp16/fp32.cu` (9-line TUs, `OPUS_NORM_DEFINE(opus_norm_bf16, bf16_t)` at bf16:11), `rmsnorm_opus_quant.cu` (`rms_norm_quant_opus`:17)
- **math**: RMSNorm with optional residual add (in-place or out-of-place), gemma/model_sensitive modes; optional int8/fp8 output quant
- **hw_deps**: none MFMA (VALU + opus vector ops; split "be + generic kernels" per dtype, hpp 3-5)
- **arch_guards**: none in these TUs (arch-neutral)
- **emu_path**: yes — fp32 dtype path is the highest-precision fallback (dtype code 2 → `opus_norm_fp32`, entry.cu 25-26); plain (no-add) vs residual variants
- **backend**: pure HIP + opus DSL, C-ABI via ctypes ("raw int64 pointers + dims, validated Python-side", entry.cu 6)
- **notes**: per-dtype TU split for compile parallelism (hpp 3-5); quant TU separate (`launch_quant`, quant.cu 7-9)
- **python**: `aiter/ops/rmsnorm.py` (`module_rmsnorm`, `module_rmsnorm_quant`)

## D. `csrc/kernels/mha_native/`（4 .cu + fused/*.hpp + headers）

- **name**: Native FMHA forward for head_dim=64 bf16: split-KV kernels (msk0/msk1), combine, torch entry
- **path**: `csrc/kernels/mha_native/` — `mha_fwd_native_splitkv.cu` (host `mha_fwd_native_splitkv`:27, base-2 softmax scale note 25-26), `fmha_fwd_d64_bf16_msk0_split.cu` (kernel:6 `__launch_bounds__(kBlockSize,4)`, launcher `launch_msk0_split`:18), `fmha_fwd_d64_bf16_msk1_split.cu` (kernel:6, `launch_msk1_split`:19), `fmha_fwd_d64_bf16_combine.cu` (kernel:6, `launch_combine`:11), design docs `fused/pipeline.hpp` (flow 20-27), `fused/op_gemm.hpp` (MFMA shape docs 11-40)
- **math**: standard scaled dot-product attention fwd (exp2 softmax, kLog2e conversion at mha_fwd_native_splitkv.cu:25) with split-KV partials (scratch_o fp32 [G,B,Hq,Sq,D], scratch_lse) combined in a second kernel
- **hw_deps**: MFMA — `v_mfma_f32_32x32x8_bf16` CDNA3 (`__builtin_amdgcn_mfma_f32_32x32x8bf16_1k` at op_gemm.hpp:181-189); raw buffer SRDs; LDS staging with async copy landing "K in MFMA-ready order" (op_lds.hpp:299); `kBlockSize,4` occupancy
- **arch_guards**: none found in the .cu/.hpp (CDNA3-targeted by construction; no `__gfx` guards)
- **emu_path**: none visible (no non-MFMA fallback)
- **backend**: pure HIP (raw builtins; torch-free entry `mha_native.h` 5-12)
- **notes**: msk0=causal-off / msk1=causal-on variants; per-block pipeline in pipeline.hpp orchestrating op_lds/op_gemm/op_softmax/op_epilog; MFMA output lane->column mapping tricks documented (op_gemm.hpp 26-40)
- **python**: `aiter/ops/mha.py` — `mha_fwd_native_splitkv`:304 (`module_mha_fwd_native_splitkv`)

## E. `csrc/kernels/mla/`

### E1. metadata.cu (+ metadata/*.cuh)
- **name**: MLA/PA/PS scheduling metadata (persistent grid work-splitting for varlen MLA)
- **path**: `csrc/kernels/mla/metadata.cu` (402 lines) + `metadata/v1_0_device.cuh`, `v1_1_device.cuh`, `v1_2_device.cuh`, `v1_2_pa_device.cuh`, `v1_2_host.cuh`, `v1_comm.cuh`
- **entry**: host `get_mla_metadata_v1`:43, `get_pa_metadata_v1`:292, `get_ps_metadata_v1`:351 (+ arch-string tuple fn:173); device kernels in v1_*_device.cuh (e.g. v1_2_device.cuh `__launch_bounds__(get_warp_size()*MLA_V12_FILL_WARPS,1)` at :157, :485, :879)
- **math**: schedules (batch, partial, q_start, q_end, kv start/end) work records over persistent CTAs for decode/prefill/ps (documented returns 19-31)
- **hw_deps**: none MFMA; LDS work queues; wave-size generic
- **arch_guards**: `__gfx` reference found in `metadata/v1_2_device.cuh` and `v1_2_pa_device.cuh` (gfx-conditional code paths)
- **emu_path**: v1_0/v1_1 vs v1_2 generations are alternative schedulers selectable per shape
- **backend**: pure HIP
- **python**: `aiter/ops/attention.py` — `get_pa_metadata_v1`:1065, `get_ps_metadata_v1`:1207, info fns 1024/1148 (`module_mla_metadata`, `module_pa_metadata`, `module_ps_metadata`)

### E2. reduce.cu (+ reduce_instances/*.cu, 24 instances)
- **name**: MLA split-KV combine (LSE-weighted reduce) per (num_heads, head_dim, workgroups) support-matrix row
- **path**: `csrc/kernels/mla/reduce.cu` (224 lines) + `reduce_instances/nh*_hd*.cu` (nh1..nh96 × hd64/128/512)
- **entry**: host `mla_reduce_v1`:161 routing via `MLA_REDUCE_CASE` macro 27-43; kernels/launchers in `mla_reduce_kernels.cuh` instantiated per instance file (header comment 3-5)
- **math**: out = softmax-combine of split partials with running max/LSE (NRFM variant without final map, 25)
- **hw_deps**: none MFMA; vectorized bf16/fp16 accumulation; per-instance compile specialization
- **arch_guards**: none in reduce.cu (instances arch-neutral)
- **emu_path**: none (instance table *is* the shape dispatch)
- **backend**: pure HIP + opus
- **python**: `aiter/ops/attention.py` (`module_mla_reduce`)

### E3. opus_mla_decode_fwd.cu (+ opus/gfx950/*.hpp, opus/mla_decode_kargs.h)
- **name**: OPUS MLA decode forward: bf16/a8w8/mxfp8 instances (16mx1/32mx1/32mxt tile variants)
- **path**: `csrc/kernels/mla/opus_mla_decode_fwd.cu` (500 lines) + `opus/gfx950/` traits/instance hpp + `mla_decode_kargs.h`
- **entry**: host `opus_mla_decode_bf16`:147, `opus_mla_decode_a8w8`:178, mxfp8 path ~450-477; kargs builder:341-363; instance launch via `impl.launch_kernel({&kargs,…})` (224) or hipLaunchKernelGGL-style 113-116; interface documented at 11 (merged d=576)
- **math**: MLA decode attention: nope (512) + rope (64) heads against paged KV, split-KV partials + reduce, optional causal/CP (context-parallel) sharding (221)
- **hw_deps**: MFMA — gfx950 16x16x128 f8f6f4 MFMA with scale for nope + plain fp8 16x16x32 for rope (mla_decode_traits.h 186-189); `buffer_load…lds` sized to dwordx4 limits (traits 209); wave64, `W_N`/`W_M` static asserts 496-502; descale strategies (139)
- **arch_guards**: directory-level: gfx950 instances only; runtime dispatch on q dtype (382-385); gfx950/gfx1250 split per traits dir
- **emu_path**: none visible (bf16 vs fp8 are dtype paths, both MFMA)
- **backend**: opus DSL instances + HIP host (mixed)
- **notes**: CPRR (context-parallel rank reduction) support; per-instance registry with host-side traits sizing (traits 1-20 host-safe section)
- **python**: `aiter/ops/opus/mla.py` — `opus_mla_decode_fwd`:46, `opus_mla_decode_mxfp8_fwd`:24, `opus_mla_decode_supported`:71 (`module_mla_decode_opus`)

### E4. opus_mla_prefill_fwd.cu (+ opus/gfx950 + opus/gfx1250 prefill instances)
- **name**: OPUS MLA prefill forward v4/v4.1: a16w16, a8w8, a8w4 tile families + split reduce
- **path**: `csrc/kernels/mla/opus_mla_prefill_fwd.cu` (1262 lines) + `opus/gfx950/mla_v4_*`, `mla_v41_*` hpp and `opus/gfx1250/mla_v41_*` hpp
- **entry**: host dispatchers `opus_mla_v4_prefill_a16w16_gfx950_fwd`:188, `opus_mla_v4_prefill_a8w8_gfx950_fwd`:278, gfx1250 `gfx1250_launch`:518, `gfx1250_launch_cluster`:553, `gfx1250_dispatch`:570, split-reduce `opus_mla_prefill_split_reduce`:68
- **math**: prefill MLA with causal masking, per-tile GEMM0 (QK) + PV, optional split output + separate reduce (mla_prefill_split.h)
- **hw_deps**: MFMA (gfx950: `make_mfma` v_mfma forms — decode sibling example mla_decode_a8w8_32mx2_32nx2.hpp:600-601,673-686) and WMMA/TDM on gfx1250 (`make_wmma` + `tdm<gather<32>>` with cache policy, mla_v41_prefill_a8w8_16mx1_16nx4.hpp:134-172)
- **arch_guards**: directory-level gfx950 vs gfx1250 instance sets; runtime gfx1250 dispatch cluster (508-570)
- **emu_path**: none visible
- **backend**: opus DSL + HIP host
- **notes**: a8w4 = fp8 activations × fp4 weights (gfx950 v4.1); cluster-launch variant for gfx1250 (553)
- **python**: `aiter/ops/opus/mla.py` — `opus_mla_v4_prefill_a16w16_gfx950_fwd`:81, `…_gfx1250_fwd`:100, `opus_mla_v4_prefill_a8w8_gfx950_fwd`:119, `…_gfx1250_fwd`:141, `opus_mla_v41_prefill_a8w8_gfx950_fwd`:163, `opus_mla_v41_prefill_a8w4_gfx950_fwd`:185, `opus_mla_v41_prefill_a8w8_gfx1250_fwd`:207 (`module_mla_prefill_opus`)

### E5. hk_v32_decode_fwd.cu / hk_v40_decode_fwd.cu (+ hk/*.cuh, hk/doc spec)
- **name**: "HipKittens" (HK) MLA decode: v32 fp8fp8 (gfx942 mi3xx) and v40 fp8bf16 gen1 (gfx950 mi35x)
- **path**: `csrc/kernels/mla/hk_v32_decode_fwd.cu` (104 lines), `hk_v40_decode_fwd.cu` (75 lines), `hk/mi3xx_v32_fwd_decode_m16x8_fp8_fp8.cuh` etc., spec `hk/doc/hk_mla_v40_gen1_spec.md`
- **entry**: host `hk_mla_v32_decode_fwd`:9 (dispatch by num_head*max_seqlen_q and gfx: gfx942→mi3xx m16x8, else mi35x variants), `hk_mla_v40_decode_fwd`:9 (gfx950, 64/128 q-token splits)
- **math**: paged MLA decode attention with split output/lse; fp8 nope + bf16 rope (v40) or fp8 both (v32)
- **hw_deps**: MFMA + pinned VGPR ART: `__attribute__((amdgpu_num_vgpr(72)))` (mi3xx_v32:16), `hkdart::split_many_t` VGPR range clobber planning (mi3xx_v32 94-105), `pack_4f32_to_fp8` (514), `buffer_load_lds`, `ds_read_b128/tr` (spec doc 5-7); wave64; gfx950-specific warp reduce strides (hk_mla_utils.cuh 362-371); s_waitcnt encodings (hk_mla_utils.cuh 300-311)
- **arch_guards**: `#if defined(__gfx942__)` wrapping the whole mi3xx kernel (mi3xx_v32:15); `#if defined(__gfx950__)`/`__gfx942__` branches in hk_mla_utils.cuh 371, 450-452; runtime gfx string checks (hk_v32:30-33, hk_v40:17)
- **emu_path**: none (strict arch dispatch; missing shape → no build, checked in v40 dispatch)
- **backend**: pure HIP with heavy inline-asm/pinned-VGPR "HipKittens" style
- **notes**: design spec doc (hk/doc/hk_mla_v40_gen1_spec.md) details LDS bank model, pinned VGPR hex maps, QManager phases; VGPR reuse overlays (`k_p_mfma` ranges) at mi3xx 42-53
- **python**: `aiter/ops/attention.py` (`module_hk_mla_v32_fwd_mi3xx`, `module_hk_mla_v40_fwd_mi3xx`)

### E6. build_co.sh
- Build helper for opus .co objects under `mla/opus` (not a kernel; lists per-arch instance builds)

## F. `csrc/kernels/topk_gating/`（3 instantiation TU）
- **name**: Topk-gating score-function instantiations: `AITER_TOPK_GATING_INSTANTIATE(aiter::SCORE_SOFTMAX|SCORE_SIGMOID|SCORE_SQRTSOFTPLUS)` (each file, last line)
- **path**: `csrc/kernels/topk_gating/topk_softmax.cu`, `topk_sigmoid.cu`, `topk_sqrtsoftplus.cu` (8 lines each)
- **entry**: none of their own — device kernels from `csrc/include/topk_gating_kernels.cuh` (`topk_gating_kernel_opt` cuh:304, `topk_gating_kernel_opt_multiwave` cuh:425; score enum cuh:32)
- **math**: see #42 (dispatch host in topk_gating_kernels.cu)
- **hw_deps / arch_guards / emu_path**: as #42 (smem fallback for unmeasured arches cuh:103-104)
- **backend**: pure HIP + opus, torch-free TUs
- **python**: via `module_moe_topk` → `aiter/ops/topk.py` `topk_gating_fwd`:20

## G. `csrc/kernels/iq2r/`

### G1. iq2r_gemm_gfx950.cu
- **name**: IQ2R codebook-quantized GEMM for GLM-5.3 MoE: encode (assign/base/pack), materialize, gate (m1/prefill/decode/nobarrier), down (tp4/tp8/route9/ordered), reduce-chunk kernels
- **path**: `csrc/kernels/iq2r/iq2r_gemm_gfx950.cu` (2748 lines)
- **entry**: host `iq2r_encode_out`:2269, `iq2r_materialize_out`:2374, `iq2r_glm53_gate_m1_out`:2484, `iq2r_glm53_gate_out`:2518, `iq2r_glm53_down_out`:2581, `iq2r_glm53_down_route9_out`:2633, `iq2r_glm53_down_reduce_out`:2674; kernels `iq2r_encode_assign_kernel`:83, `iq2r_encode_base_kernel`:201, `iq2r_encode_pack_kernel`:250, `iq2r_materialize_kernel`:316, `glm53_gate_m1_kernel`:551, `glm53_gate_prefill_kernel`:687, `glm53_down_tp4_kernel`:956, `glm53_down_prefill_tp4_kernel`:1097, `glm53_down_prefill_tp8_kernel`:1241, `glm53_reduce_chunk_kernel`:1477, `glm53_down_route9_kernel`:1512, `glm53_down_tp8_ordered_kernel`:1665, `glm53_gate_decode_kernel`:1947, `glm53_gate_decode_nobarrier_kernel`:2121
- **math**: GEMM where weights are IQ2R-codebook-quantized (4 KB codebook + 8 B/lane records + triplet metadata, constants 14-30): each wave decodes compressed quads via a scaled fp8 MFMA against the codebook, then accumulates
- **hw_deps**: MFMA — `opus::mfma<fp8_t,fp8_t,fp32_t,16,16,128>` (scaled) at 384-391 (`iq2r_triplet_mfma`), decode quad MFMA 545; codebook in LDS (`__shared__ Storage` 565-568); software-pipelined compressed-quad loads with `iq2r_scheduled_load_quad` (596-617); issue-all-MFMAs-before-add reordering note (920-921)
- **arch_guards**: `#if defined(__gfx950__)` in every kernel body (96, 208, 261, 322, 562, 694, 966, 1107, 1251, 1482, 1523, 1675, 1959, 2133); host `iq2r_check_gfx950`:2262
- **emu_path**: none (gfx950-only by host check; no scalar path)
- **backend**: pure HIP + opus
- **notes**: machine-sink workaround for gfx950 scaled-MFMA NaN under lane-dependent branches (855-858 "Fixed upstream"); persistent task-table scheduling with `tasks`/`task_count`; LDS `partial[8][4][64]` accumulators (566)
- **python**: `aiter/ops/iq2r.py` + `aiter/iq2r_glm53.py` (`module_iq2r_moe`)

### G2. iq2r_moe_aux_gfx950.cu
- **name**: GLM-5.3 routing aux: 3-stage route sort (histogram/prefix/scatter), route quant, m1 route quant, route reduce
- **path**: `csrc/kernels/iq2r/iq2r_moe_aux_gfx950.cu` (687 lines)
- **entry**: kernels `glm53_sort_histogram`:33, `glm53_sort_chunk_prefix`:72, `glm53_sort_expert_prefix`:84, `glm53_sort_scatter`:110, `glm53_quant_kernel`:182, `glm53_m1_route_quant_kernel`:194, `glm53_sort_quant_kernel`:369, `glm53_route_reduce_kernel`:386; host `iq2r_glm53_m1_route_quant_out`:493, `iq2r_glm53_sort_quant_out`:532, `iq2r_glm53_prefill_sort_quant_out`:579, `iq2r_glm53_route_reduce_out`:649
- **math**: sorts up to 257-expert × top-9 routes (kGlm53Experts=257, kGlm53TopK=9, 22-23) via per-256-chunk counting sort, then quantizes routed activations to MX groups
- **hw_deps**: none MFMA; LDS histogram (512 ints, 34-36); gfx950-only bodies
- **arch_guards**: `#if defined(__gfx950__)` at kernel bodies (e.g. 34)
- **emu_path**: none
- **backend**: pure HIP + opus
- **notes**: 3-pass sort with disjoint expert-range prefix assignment (header 26-28); fused sort+quant single-launch variant (369)
- **python**: `aiter/ops/iq2r.py` (`module_iq2r_moe`)

### G3. iq2r_glm53_tune.py
- Autotune script (no kernels)

## H. `csrc/kernels/solver/`
- **name**: Householder symmetric tridiagonalization (sytrd) — larfg, sytd2, blocked latrd, driver
- **path**: `csrc/kernels/solver/sytrd_kernels.cu` (761 lines)
- **entry**: kernels `larfg_kernel`:74, `fused_dot_scale_axpy`:171, `setup_tridiagonal`:233, `small_sytd2_kernel`:248, `accumulate_a_col_updates`:412, `compute_w_col_kernel`:441, `update_w_col_kernel`:516; C ABI `hip_ssytrd`:738, `hip_dsytrd`:751
- **math**: A = Q·T·Qᵀ tridiagonalization producing D/E/TAU (README "Algorithm overview" 4-11); blocked LATRD panel + rank-2k trailing update
- **hw_deps**: none (warp `__shfl_down` reduction 42-47, block reduce via LDS; rocBLAS gemm for trailing update — includes rocblas/rocblas.h line 2)
- **arch_guards**: none in code; Makefile pins `--offload-arch=gfx942` (line 8)
- **emu_path**: fp32 (ssytrd) and fp64 (dsytrd) templated; rocSOLVER comparison mode (`-v`)
- **backend**: pure HIP + rocBLAS calls
- **notes**: standalone benchmark TU (sytrd_benchmark.cu) + python LAPACK reference (lapack_sytrd.py); not wired into any jit module — an off-line component with MI300X benchmark table (README 29-46)
- **python**: none (lapack_sytrd.py is a reference implementation, not a launcher)

## I. `csrc/kernels/mxfp4_moe/`
- **name**: MoE MXFP4 aux pipeline: fused sort+quant, 3-stage sort, sort-only(+zi), quant-only, sort-scales, scatter-reduce(+q)
- **path**: `csrc/kernels/mxfp4_moe/moe_mxfp4_aux.cu` (345 lines) + `moe_aux/{moe_3stage_sort,moe_scatter_reduce,moe_sort_quant,moe_sort_scales}.cuh` + `moe_aux/codegen/{gen_instances.py, mxfp4_moe_aux_dispatch.h}` + `common/arithmetic.hpp`
- **entry**: host dispatch via codegen'd shape-key lookup tables (`sort_quant_lookup`:27, `sort3stage_lookup`:33, `sort_only_zi_lookup`:39, `sort_only_lookup`:45 over `mxfp4_moe_aux_lookup.h` extern "C" instances); public `mxfp4_moe_sort_quant_kernel`:98, `mxfp4_moe_sort_kernel`:138, `mxfp4_moe_quant_kernel`:231, `mxfp4_moe_sort_scales_kernel`:257, `mxfp4_moe_scatter_reduce_kernel`:287, `mxfp4_moe_scatter_reduce_q_kernel`:318
- **math**: permutes/zero-inits and scatters tokens by routed expert with MX scale propagation (moe_sort_quant.cuh `zero_init_bf16_out_impl` 12-30)
- **hw_deps**: `#if defined(__gfx950__)` in moe_sort_quant.cuh:282 (fp4 convert path); WARP_SIZE from opus (`opus::get_warp_size()`, moe_sort_quant.cuh:10)
- **arch_guards**: gfx950 sites in moe_aux headers (282); instance set generated per (NE, D_HIDDEN, D_INTER, TOPK) shape table (gen_instances.py SHAPES 11-27: Kimi-K2.5, DSR, minimax, qwen35, dsv4)
- **emu_path**: unsupported-shape reporting path (`mxfp4_moe_sort_internal_is_supported`:79, missing-instance error object python ops/moe_mxfp4_aux.py:118)
- **backend**: pure HIP + opus; codegen-driven instance registry
- **notes**: string-key → extern "C" instance lookup (comment 25); shapes tuned for specific model deployments; scatter-reduce with and without q output
- **python**: `aiter/ops/moe_mxfp4_aux.py` — `mxfp4_moe_sort_quant`:155, `mxfp4_moe_sort`:176, `mxfp4_moe_quant`:200, `mxfp4_moe_sort_scales`:213, `mxfp4_moe_scatter_reduce`:227, `mxfp4_moe_scatter_reduce_q`:240, `prepare_mxfp4_moe_aux`:135 (`module_moe_mxfp4_aux`)

## J. `csrc/kernels/opus_mqa_logits/pa_mqa_logits_mxfp4/`（7 文件）
- **name**: Paged MQA logits over MXFP4 KV: out[r,c] = Σ_h relu(q[r,h]·k[c])·w[r,h]·wscale (interface doc pa_mqa_logits_mxfp4.h 6-11)
- **path**: `csrc/kernels/opus_mqa_logits/pa_mqa_logits_mxfp4/` — `pa_mqa_logits_mxfp4.h` (contract + 3 schedule modes: Table/Free/Prefill, 15-21), `pa_mqa_logits_mxfp4.cu` (host `mqa_logits_mxfp4_instances`:522, `mqa_logits_mxfp4_build_schedule`:569, `mqa_logits_mxfp4_launch`:651), `pa_mqa_logits_mxfp4_pybind.cu` (PYBIND11_MODULE:7), gfx950: `pa_mqa_logits_mxfp4_gfx950.cu` (traits/registry, 1-30) + `_kv.cuh`/`_qshare.cuh`/`_rows.cuh` kernels; gfx1250: `pa_mqa_logits_mxfp4_gfx1250.cu` (traits, 1-30) + `_common.cuh`/`_h32.cuh`/`_h64.cuh`
- **math**: per query row, computes logits vs every cached key window with per-32-K-block E8M0 scales and relu+weight epilogue
- **hw_deps**: MFMA — gfx950 `opus::mfma<fp4,fp4,float,32,32,64>` 32x32x64 fp4 MFMA (gfx950_rows.cuh:37; VALU-bound design 8-13 with software-pipelined relu/fma around MFMA, 12-13, 173-179); gfx1250 WMMA — `opus::wmma<fp4_t,fp4_t,float,…>` (gfx1250_h64.cuh:31) with TDM LDS ring (h64 44-78, "block-table word through constant address space s_load" 78)
- **arch_guards**: directory-level gfx950 vs gfx1250 instance sets; runtime arch pick (`device_arch`:491); per-source compiler flags: `-mllvm -enable-post-misched=1` (gfx950.cu:13, gfx1250.cu:23-24) and `-fno-honor-nans` for gfx1250 (gfx1250.cu 8-10)
- **emu_path**: none visible (MXFP4-only operator)
- **backend**: opus DSL instances + HIP host + pybind
- **notes**: instance registry queried from python (`mqa_logits_mxfp4_instances`); V4 64-head vs V4.1 32-head plane layouts (gfx950.cu 5-9); 32-bit vs 64-bit cache addressing constraints documented (h 24-30)
- **python**: `aiter/ops/opus/pa_mqa_logits_mxfp4.py` — `_mqa_logits_mxfp4_launch`:221, `_instances_raw`:151 (`module_pa_mqa_logits_mxfp4_opus`)

## K. `csrc/kernels/sparse_attn/msa/`（4 文件）
- **name**: MSA sparse block attention passes: score (decode uniform-row / prefill), block top-k select, top-k (incl. context-parallel `pa_sparse_block_topk_cp`)
- **path**: `csrc/kernels/sparse_attn/msa/` — `pa_sparse_block_select_entry.cu` (433 lines; C-ABI entrypoints `pa_sparse_block_score_decode`:57, `pa_sparse_block_score_prefill`:127, `pa_sparse_block_topk`:207, `pa_sparse_block_topk_cp`:312 via `AITER_CTYPES_DEFINE_ENTRYPOINT_VOID`), instance TUs `pa_sparse_block_score_decode.cu` (11 lines, `SPARSE_DECODE_TABLE(SPARSE_DECODE_DEFINE)`), `pa_sparse_block_score_prefill.cu` (10), `pa_sparse_block_topk.cu` (11, `SPARSE_TOPK_TABLE`), kernels `pa_sparse_block_select.hpp` + `pa_sparse_block_select_kernels.cuh`
- **math**: scores index-head q against paged KV blocks with one MFMA covering the whole head dim (static_assert hpp:252, kernels.cuh 80-89), then selects top-k blocks
- **hw_deps**: MFMA — `__builtin_amdgcn_mfma_scale_f32_16x16x128_f8f6f4` (kernels.cuh:30, wrapped `mfma_scale` 27-30); gfx950-only guard kernels.cuh:29; LDS block tiles
- **arch_guards**: `#if defined(__gfx950__)` kernels.cuh:29; host `sparse_arch_supported()` = gfx950 (entry.cu 39-41); shape static-checks SPARSE_CHECK_SHAPE (24-36)
- **emu_path**: none (hard arch + shape checks raise python RuntimeError via TLS error storage, entry.cu 10-13)
- **backend**: pure HIP + raw builtins, C-ABI ctypes (`.so` per prebuilt variant table)
- **python**: `aiter/ops/msa_block_select.py` (`module_msa_sparse_attention`)

## Python 映射总表

（kernel file → jit module → python function，依据 `aiter/jit/optCompilerConfig.json` + `aiter/ops/*.py` 交叉验证）：

| kernel file | python-facing |
|---|---|
| activation_kernels.cu | yes — `aiter/ops/activation.py` (module_activation) |
| binary_operator.cu | yes — `aiter/ops/aiter_operator.py` (module_aiter_operator) |
| unary_operator.cu | yes — `aiter/ops/aiter_operator.py` (module_aiter_unary) |
| cache_kernels.cu | yes — `aiter/ops/cache.py` (module_cache) |
| dsv4_dequant_gather_k.cu | yes — `aiter/ops/cache.py:206 dsv4_dequantize_and_gather_k` |
| causal_conv1d_fwd_split_qkv.cu | yes — `aiter/ops/causal_conv1d_fwd_split_qkv.py` |
| causal_conv1d_update.cu | yes — `aiter/ops/causal_conv1d_update.py` |
| chunk_gated_delta_rule_fwd_h.cu | yes — `aiter/ops/chunk_gated_delta_rule_fwd_h.py:95 chunk_gated_delta_rule_fwd_h_hip` |
| custom_all_reduce.cu (+_ext) | yes — `aiter/ops/custom_all_reduce.py` (module_custom_all_reduce) |
| custom_all_reduce_gfx1250.cu | yes — `aiter/ops/custom_all_reduce.py` (module_custom_all_reduce_gfx1250) |
| fused_ar_mhc_post.cu | yes — `aiter/ops/custom_all_reduce.py` (module_fused_ar_mhc) |
| fused_kernels.cu | **no** — dormant, not in any jit module |
| fused_norm_quant_gemm.cu | yes — `aiter/ops/fused_norm_quant_gemm.py:39` (gradlib-built module; python fallback on failure) |
| fused_qk_norm.cu | yes — via `aiter/ops/fused_qk_norm_rope_cache_quant.py` (module_fused_qk_norm_rope_cache_quant_shuffle) |
| fused_qk_norm_mrope_cache_quant.cu | yes — `aiter/ops/fused_qk_norm_mrope_cache_quant.py:10` |
| fused_qk_norm_rope_cache_quant.cu | yes — `aiter/ops/fused_qk_norm_rope_cache_quant.py` (10 wrapper fns, 16-952) |
| fused_qk_rmsnorm_group_quant.cu | yes — `aiter/ops/fused_qk_rmsnorm_group_quant.py:60/:137` |
| fused_qknorm_idxrqknorm.cu | yes — `aiter/ops/fused_qknorm_idxrqknorm.py` |
| fused_split_gdr_update.cu | yes — `aiter/ops/fused_split_gdr_update.py:37` |
| gated_rmsnorm_quant_kernels.cu | yes — `aiter/ops/gated_rmsnorm_fp8_group_quant.py:24` + `_per_token_quant.py` |
| gdr_decode_packed_bf16.cu | yes — `aiter/ops/gdr_decode_packed_bf16.py:38` |
| groupnorm.cu | yes — `aiter/ops/groupnorm.py` |
| inverse_rope_group_quant.cu | yes — `aiter/ops/inverse_rope_group_quant.py:91` |
| mega_mhc.cu / mega_mhc_gfx1250.cu | yes — `aiter/ops/mega_mhc.py:139/176` (module_mega_mhc_stream_*) |
| mha_common.cu | yes — shared src of `aiter/ops/mha.py` modules |
| mha_v4_quant.cu | yes — `aiter/ops/mha_v4_quant.py:87-159` |
| mhc_kernels.cu | yes — `aiter/ops/mhc.py` (module_mhc) |
| moe_align_block_size_kernels.cu | yes — via module_moe_asm (`aiter/ops/moe_op.py`) |
| moe_fused_gate.cu | yes — `aiter/ops/topk.py:317 moe_fused_gate` |
| pos_encoding_kernels.cu | yes — `aiter/ops/pos_encoding.py` |
| quant_kernels.cu | yes — `aiter/ops/quant.py` (module_quant) |
| quant_mxfp4.cu / quant_mxfp4_gemm.cu / quant_mxfp6_gemm.cu | yes — `aiter/ops/quant.py` (module_quant) |
| quick_all_reduce.cu | yes — `aiter/ops/quick_all_reduce.py` (MD_NAME :10) |
| quick_reduce_scatter.cu | yes — `aiter/ops/quick_reduce_scatter.py` |
| rmsnorm_quant_kernels.cu | yes — `aiter/ops/rmsnorm.py` (module_rmsnorm_quant) |
| sample_kernels.cu | yes — `aiter/ops/sample.py` (module_sample) |
| sp_head_exchange.cu | yes — `aiter/ops/sp_head_exchange.py:11` |
| topk_gating_kernels.cu (+topk_gating/*) | yes — `aiter/ops/topk.py:20/:165` (module_moe_topk) |
| topk_per_row_kernels.cu | yes — `aiter/ops/topk.py:759 top_k_per_row_prefill` (module_top_k_per_row) |
| topk_per_row_sampled_kernels.cu | yes — `aiter/ops/topk.py:883` workspace + sampled path (module_top_k_per_row_sampled) |
| topk_plain_kernels.cu | yes — `aiter/ops/topk_plain.py:119 topk_plain` (module_topk_plain) |
| topk_softmax_kernels.cu | yes — `aiter/ops/topk.py` (module_moe_asm) |
| topk_softmax_kernels_group.cu | yes — `aiter/ops/topk.py:268/:346` (module_moe_asm) |
| custom_kernels.cu | yes — `aiter/ops/custom.py:12-28` (module_custom) |
| rope/*.cu (16) | yes — `aiter/ops/rope.py` (16 module_rope_* modules) |
| rmsnorm/*.cu (5) | yes — `aiter/ops/rmsnorm.py` (module_rmsnorm) |
| mha_native/*.cu (4) | yes — `aiter/ops/mha.py:304 mha_fwd_native_splitkv` |
| mla/metadata.cu | yes — `aiter/ops/attention.py:1024-1207` |
| mla/reduce.cu | yes — `aiter/ops/attention.py` (module_mla_reduce) |
| mla/opus_mla_decode_fwd.cu | yes — `aiter/ops/opus/mla.py:46` |
| mla/opus_mla_prefill_fwd.cu | yes — `aiter/ops/opus/mla.py:81-207` (7 wrappers) |
| mla/hk_v32/hk_v40_decode_fwd.cu | yes — `aiter/ops/attention.py` (module_hk_mla_*) |
| iq2r/*.cu | yes — `aiter/ops/iq2r.py` (module_iq2r_moe) |
| solver/sytrd_kernels.cu | **no** — standalone Makefile benchmark; `lapack_sytrd.py` is a reference, not a launcher |
| mxfp4_moe/moe_mxfp4_aux.cu | yes — `aiter/ops/moe_mxfp4_aux.py:155-240` |
| opus_mqa_logits/*.cu | yes — `aiter/ops/opus/pa_mqa_logits_mxfp4.py:151-221` |
| sparse_attn/msa/*.cu | yes — `aiter/ops/msa_block_select.py` (module_msa_sparse_attention, ctypes) |

## 汇总表

| file | algorithm class | hw_deps | emu_path |
|---|---|---|---|
| activation_kernels.cu | fused activation(+quant) | none (v_pk_mul_f32) | yes: RDNA scalar fallback (106), safe-vec kernel (2137) |
| binary_operator.cu | elementwise binary | none | none visible |
| cache_kernels.cu | KV cache mgmt + fused rope/quant | none; gfx1250 TDM (2835) | yes: non-TDM portable path |
| causal_conv1d_fwd_split_qkv.cu | causal conv1d prefill | none | none |
| causal_conv1d_update.cu | causal conv1d decode | none | none |
| chunk_gated_delta_rule_fwd_h.cu | chunked GDN state recurrence | MFMA 16x16x16 bf16 (333-339); LDS; wave64 | partial: gfx12 WMMA ↔ CDNA MFMA dual (no soft emu) |
| custom_all_reduce.cu | IPC all-reduce family | shfl_xor; IPC atomics | none |
| custom_all_reduce_ext.cu | AR instance TU | inherits | none |
| custom_all_reduce_gfx1250.cu | pointer AR (MI450) | gfx1250 transport | none |
| dsv4_dequant_gather_k.cu | gather+dequant paged K | none; wave64 dwordx4 | none |
| dsv4_rotate_quant.cu | Hadamard rotate + MX quant | DPP, gfx950 cvt fp4 | yes: scalar E2M1 encoder; host WARP_SIZE fallback |
| fused_ar_mhc_post.cu | AR+MHC fusion orchestration | inherited AR + MHC | none |
| fused_kernels.cu [not built] | fused SiLU GEMM (legacy) | none | none |
| fused_norm_quant_gemm.cu | norm+quant+hipBLASLt GEMM | hipBLASLt host call | yes: python fallback (ops py:32) |
| fused_qk_norm.cu | QK RMSNorm | none (v_pk_mul_f32) | yes: scalar else-branch (117-136) |
| fused_qk_norm_mrope_cache_quant.cu | mrope+norm+cache+quant | none | none |
| fused_qk_norm_rope_cache_quant.cu | mega norm/rope/quant/cache | gfx1250 TDM (5107+); gfx942 (114) | yes: non-TDM store path; gfx942-only gates |
| fused_qk_rmsnorm_group_quant.cu | norm+group quant | none | yes: runtime gfx950-vs-generic (1045) |
| fused_qknorm_idxrqknorm.cu | dual norm+rope+cache | none | yes: fallback_ptr scalar stores (111-131) |
| fused_split_gdr_update.cu | GDR decode split+gates | none | none |
| gated_rmsnorm_quant_kernels.cu | gated norm+fp8 quant | none | none |
| gdr_decode_packed_bf16.cu | GDR decode contraction | LDS DS-swizzle; wave64 | none |
| groupnorm.cu | group norm | none | none |
| inverse_rope_group_quant.cu | inverse rope + quant producer | gfx1250 TDM; gfx950/gfx1250 cvt | partial: strict scale-layout↔consumer pairing, no soft path |
| mega_mhc.cu | MHC mixing GEMM+norm | MFMA 16x16x32 bf16 (973+); DPP; gfx950 cvt | yes: H=0 generic variant; gfx942 generic-only (2472) |
| mega_mhc_gfx1250.cu | MHC gfx1250 | WMMA 16x16x32 bf16 (640+); TDM ring | none |
| mha_common.cu | philox unpack | none | none |
| mha_v4_quant.cu | rotate+MX quant (Q,V) | gfx950 cvt fp4/fp6 asm (101-110); DPP | yes: hd128 rotate runs gfx942+gfx950 (921); MX paths gfx950-checked |
| mhc_kernels.cu | MHC pre/post/fused GEMM | MFMA bf16 wave64 (556+) / WMMA wave32 (642+); TDM s_wait_tensorcnt | yes: fp32 GEMM loop fallback (40-45, 845-851) |
| moe_align_block_size_kernels.cu | MoE token alignment | none (LDS+atomics) | none |
| moe_fused_gate.cu | MoE gating fused | none | none |
| pos_encoding_kernels.cu | RoPE | none | none |
| quant_kernels.cu | fp8/int8/MX quant family | gfx1250 pk8 cvt (152+); gfx942 (394) | yes: per-arch fallbacks around packed cvt (364) |
| quant_mxfp4.cu | MXFP4 quant | gfx950 pk_fp4 (36-40) | yes: scalar even-round E2M1 (45-79) |
| quant_mxfp4_gemm.cu | MXFP4 quant+pack | gfx950 pk_fp4_f32 (206) | no: hard gfx950 check (318) |
| quant_mxfp6_gemm.cu | MXFP6 quant+pack | gfx950 2xpk16_fp6 (229) | no: hard gfx950 check (402) |
| quick_all_reduce.cu | quantized all-reduce | IPC; codec kernels | yes: CodecFP full precision (cuh:26) |
| quick_reduce_scatter.cu | quantized reduce-scatter phase 1 | IPC | yes: CodecFP |
| rmsnorm_quant_kernels.cu | residual norm+quant | none (v_pk_mul_f32; gfx942 260) | yes: RDNA fallback (213) + grouped-quant fallback (536) |
| sample_kernels.cu | sampling/Gumbel/philox | none | none |
| sp_head_exchange.cu | SP head allgather repack | IPC signals | none |
| topk_gating_kernels.cu (+topk_gating/*) | MoE topk gating | none (shfl/register topk) | yes: smem fallback for unmeasured arches (cuh:103-104) |
| topk_per_row_kernels.cu | radix top-k families | hipcub; DPP scan (1408); s_wait variants (503) | yes: gfx950-only kernels excluded on other targets (5193) |
| topk_per_row_sampled_kernels.cu | sampled 3-phase top-k | LDS staging; dwordx4 | yes: per-row streamed-radix fallback inlined (347-367) |
| topk_plain_kernels.cu | adaptive filter/sort/merge top-k | ballot; DPP (1340); hipcub | yes: strategy ladder + pitch fallback checks |
| topk_softmax_kernels.cu | MoE softmax topk | none | yes: non-pow2 → python side (1353, 1615) |
| topk_softmax_kernels_group.cu | grouped topk (biased) | DPP tie ranks (313) | partial: wave32 kernel excluded on GFX9 (1592); wave64-only paths |
| unary_operator.cu | elementwise unary | none | yes: non-tile-friendly → python torch |
| custom_kernels.cu | wave GEMV/split-K | MFMA fp8 32x32x16 (1892, 2107) | yes: non-MI350 `#else` kernel variants (667 etc.) |
| rope/*.cu + rope_common.h | RoPE layouts 16x | none (gfx9 helpers 7404/7528) | yes: gfx94 RNE 10-instr vs gfx95 1-instr documented (7515) |
| rmsnorm/*.cu | C-ABI RMSNorm(+quant) | none | yes: fp32 dtype path (entry.cu:25) |
| mha_native/*.cu | FMHA fwd d64 split-KV | MFMA 32x32x8 bf16 (op_gemm.hpp:181); SRDs; LDS async | none |
| mla/metadata.cu | MLA work scheduler | none | v1_0/v1_1/v1_2 alternate generations |
| mla/reduce.cu | split-KV combine | none | none (instance table) |
| mla/opus_mla_decode_fwd.cu | MLA decode (opus) | MFMA f8f6f4 16x16x128 + fp8 16x16x32 (traits 186-189); buffer_load_lds | none |
| mla/opus_mla_prefill_fwd.cu | MLA prefill v4/v4.1 | MFMA (gfx950) / WMMA+TDM (gfx1250, v41 hpp:134-172) | none |
| mla/hk_v32/hk_v40_decode_fwd.cu | HK MLA decode | MFMA + pinned VGPRs (`amdgpu_num_vgpr(72)`), buffer_load_lds | none (strict arch dispatch) |
| iq2r/iq2r_gemm_gfx950.cu | codebook GEMM (IQ2R) | scaled MFMA fp8 16x16x128 (391); LDS codebook | none (gfx950 host check 2262) |
| iq2r/iq2r_moe_aux_gfx950.cu | route sort+quant | LDS histogram | none |
| solver/sytrd_kernels.cu | sytrd tridiagonalization | none (__shfl; rocBLAS) | fp32/fp64 templated; not built into aiter |
| mxfp4_moe/moe_mxfp4_aux.cu | MoE sort/quant/scatter | gfx950 fp4 (moe_sort_quant.cuh:282) | unsupported-shape error path (not numeric emu) |
| opus_mqa_logits/pa_mqa_logits_mxfp4/*.cu | paged MQA logits MXFP4 | MFMA fp4 32x32x64 (gfx950_rows.cuh:37); WMMA fp4 + TDM (gfx1250_h64.cuh:31) | none |
| sparse_attn/msa/*.cu | sparse block score/topk | MFMA scale f8f6f4 16x16x128 (kernels.cuh:30) | none (hard gfx950+shape checks) |

**横向发现**：(1) 唯一休眠 TU 是 `fused_kernels.cu`；(2) `solver/` 是独立基准组件（gfx942 Makefile pin、rocBLAS 依赖），未接入 jit；(3) gfx1250 支持普遍但一致基于 TDM/WMMA，带 "UNVERIFIED - no HW" 标注（mhc_kernels.cu:37, 642）；(4) fp4/fp6/fp8 硬件转换是 gfx950 专属，标量 RNE 编码器是唯一软件模拟；(5) 波长双态（wave64 CDNA vs wave32 RDNA/gfx1250）由编译 guard 或 `opus::get_warp_size()` 运行期处理，最精巧的双路径在 chunk_gated_delta_rule_fwd_h、mhc_kernels、topk_softmax_kernels_group。
