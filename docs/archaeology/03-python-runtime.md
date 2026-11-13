# 考古③：Python 运行时/JIT/模拟线扫（原文转录）

aiter @ `1eab5ae12c93af3c8c660202d9a413f637c2f011`。路径相对仓库根。

## 1. `aiter/jit/` 机制

### 1.1 `aiter/jit/core.py`（2635 行）— 编排器

**装饰 op 流（`compile_ops`）** — `aiter/jit/core.py:2309-2635`
- `compile_ops(_md_name, fc_name, gen_func, gen_fake, ffi_type, develop)`（core.py:2309-2316）。两种 FFI：
  - `ffi_type="ctypes"`（torch-free .so 经 `ctypes.CDLL`；type-hints → C ABI 映射表 core.py:1970-2105；`build_ctypes_module` 在 .so 缺失或 `_needs_arch_rebuild` 时构建 — core.py:1947-1967；caller 带 per-call stream append core.py:2157-2261）
  - `ffi_type="pybind"`（默认）：wrapper 先试 `get_module(md)`；`ModuleNotFoundError` 时从 `optCompilerConfig.json` 经 `get_args_of_build(md_name)` 读构建参数（core.py:2349-2405），调 `build_module(...)`，re-import（core.py:2352-2405）。**这就是运行时编译触发：per-op import-or-build**
- `develop=True` 路径把 `torch.Tensor` → pybind `aiter_tensor_t` 再调 C++，并设当前 HIP stream（core.py:2590-2621）；pybind11-ABI split 检查 `_raise_on_pybind11_abi_split`（core.py:1198-1227）
- 参数类型验证靠 **exec pybind docstring** 重建签名（`check_args`, core.py:2412-2584）
- 全部被 `torch_compile_guard` 包（core.py:2624-2628）→ custom-op 注册

**构建参数注册表** — `aiter/jit/optCompilerConfig.json`，`get_args_of_build` 读（core.py:1802-1924）: per-module `srcs / flags_extra_cc / flags_extra_hip / blob_gen_cmd / third_party / torch_exclude / flags_extra_hip_per_source`；值 `eval()`（core.py:1827-1848）。`"all"` 模式枚举每模块预构建（core.py:1859-1908），CK-free 自动排除 `_get_ck_exclude_modules`（core.py:1732-1799）

**`build_module`** — core.py:1401-1729:
- Per-module lock `f"{bd_dir}/lock_{md_name}"` + `mp_lock`（core.py:1418-1419, 1724-1729）；`AITER_REBUILD` 语义（0=增量, 1=rm+清 build dir, 2=只 rm .so — core.py:1442-1446）
- 固定 HIP flags，hip 版本条件 LLVM flags（core.py:1475-1516），`--offload-arch` per `validate_and_update_archs()`（core.py:1565-1566；allowlist 957-976），per-flag probe `hip_flag_checker` via `hipcc -E`（core.py:986-999），LLVM revision probe `check_LLVM_MAIN_REVISION`（core.py:1002-1051），gfx1250 cluster-launch 与 CK-tile defines（core.py:1519-1532），CK-free `-DAITER_CK_FREE=1`（core.py:1601-1611）
- **Blob 代码生成**: `_stage_blob_sources`（core.py:1084-1101）在事务性 `blob.staging` 目录内跑每模块 `blob_gen_cmd`（Python codegen script, e.g. CK 的 `generate.py`），`require_blob_generation` 编译前后 re-validation + `atomic_copy` install（core.py:1651-1684）；generated sources 发布进稳定 `blob/` 缓存（core.py:1706-1716）
- 多进程安全: `mp_lock(lockPath, MainFunc, FinalFunc, build_after_wait)`（core.py:61-92）over `FileBaton`（`aiter/jit/utils/file_baton.py:26-` — O_CREAT|O_EXCL 锁文件戳 `pid\nhostname`，stale-lock 检测/破锁）。Ninja 级锁也在 `cpp_extension._jit_compile`（core.py 的 `cpp_extension.py:1294-1432`, FileBaton at 1353-1362）
- 缓存/产物安装目的地: python module → `get_user_jit_dir()/module_X.so`；standalone test binaries → `op_tests/cpp/mha/`（core.py:1676-1684）

**缓存位置**（core.py:917-944）:
- `get_user_jit_dir()`（core.py:922-935）: `AITER_JIT_DIR` env override → else 包内 `aiter/jit/`（可写时）→ else 整树拷贝到 **`~/.aiter/jit/`**。Build dir = `<jit_dir>/build`（core.py:938）
- 事实源目录: develop → repo root；wheel → `aiter_meta/`（setup.py:158-175 填 `aiter_meta/{3rdparty,csrc,...}`）。`AITER_META_DIR` env（core.py:883-887）
- 合并 tuned CSV 落 `/tmp/aiter_configs/<name>.csv`（mp lock 下, core.py:785-800）
- 预编译 Opus `.co`: `csrc/opus_gemm/gen_co/<arch>/`，import 时导出 `OPUS_GEN_CO_DIR`（core.py:894-905）
- 打包 FlyDSL AOT 缓存: `aiter/jit/flydsl_cache` 导出为 `FLYDSL_RUNTIME_CACHE_DIR`（`aiter/__init__.py:94-97`）

**Tuned-config 管道** — `AITER_CONFIG` 类（core.py:296-851）: env `AITER_CONFIG_*`（声明 core.py:112-278）→ `get_config_file`（lru_cached, core.py:804-851）合并 `configs/*.csv` + per-model `configs/model_configs/*.csv`，去重保最低 `us`（或 `AITER_SELECT=power` 时 power/energy, core.py:281-293, 596-611），重写源 CSV，不可调和重复即 raise（`_raise_on_duplicate_shapes`, core.py:517-661）。Legacy `cu_num`-only CSV 经 `gfx_from_cu_num`（chip_info.py:259-283；used core.py:759-766）回填 gfx 列

**Import 期 arch 解析** — `gfxs = get_gfx_list()` 模块 import（core.py:892）；`get_asm_dir()` = `hsa/<gfx>`（core.py:917-919）

### 1.2 AOT vs JIT：develop 模式 vs wheel `PREBUILD_KERNELS`
- `install_mode` 文件决定 develop vs install（core.py:866-872；setup.py:158-175 写）
- `setup.py` `PREBUILD_KERNELS` env（setup.py:30）: level 0 = 无预构建（ops 首调 JIT）；**1** = "exclude `_tune` modules; MHA 只留 fmha_v3 fwd variants"（setup.py:273-281）；**2** = 再排除 `_bwd`（282-285）；**3** = 仅 `module_fmha_v3*`（286-289）。Prebuild 驱动 `core.build_module` per module from `optCompilerConfig.json`（setup.py:298-452），加 MoE CK-2stages variants from `moe_recipes.get_moe_ck2stages_prebuild_variants`（setup.py:328-341）与 MHA varlen fwd variants from `mha_recipes`（setup.py:343-370），加 FlyDSL AOT 预编译 via `aiter.aot.flydsl.common.run_aot`（setup.py:414-429），可选 post-build retune `aiter.utility.pretune.run_pretune_modules`（setup.py:438-452）
- 运行期另一侧：`compile_ops` wrapper import；预构建 wheel 满足 `get_module` 无需编译；缺失/错 arch 模块触发 JIT（core.py:2349-2405；`_needs_arch_rebuild` 从 mmap 二进制解析 `amdhsa--gfx…` 字符串 re-check `.so` 内嵌 offload arches — core.py:1140-1148, 1230-1248，运行 gfx 不在即强制重建）
- `aiter.aot/`（pa/pa_v1/sampling/asm_mla_decode 等预编译）带 replay 模式 `AITER_AOT_REPLAY=1`：`GPU_ARCHS` 顶替 live GPU（`chip_info.get_gfx_runtime`, chip_info.py:132-143）

### 1.3 `aiter/jit/utils/` 支撑模块
- **`asm_guard.py`**（64 lines）: gfx1250 A0（gfx1250-strict）vs B0 硅片门。`_ASM_SUPPORTED` import 时探一次（asm_guard.py:43-46）from `get_gfx_runtime()` + `get_asic_revision()`；strict/A0 → False，未知 stepping → **fail closed**（asm_guard.py:21-40）。公共 `is_gfx1250_asm_supported()` / `require_gfx1250_asm(op_name)`（asm_guard.py:49-64）— Python 侧预门，镜像 `csrc/include/aiter_hip_common.h` 的 `require_gfx1250_asm_or_throw()`
- **`chip_info.py`**（774 lines）: 见 §2
- **`build_targets.py`**（164 lines）: 纯 Python arch 常量 — `GFX_MAP` id→gfx（build_targets.py:10-31, 含 gfx1250-strict）, `GFX_CU_NUMS_MAP` arch→CU counts（39-52）, `GFX_BASE_ARCH`/`base_gfx_arch`/`is_gfx1250_family`（60-80）, `torch_processor_count_to_cu` RDNA WGP-mode CU 数学（83-95）, `_parse_gpu_archs_env`（98-111）, `get_build_targets_env`（114-144）, `filter_tune_df`（147-164）
- **`torch_guard.py`**（407 lines）: `torch_compile_guard` decorator（torch_guard.py:231-407）— 把每个装饰的 python 函数注册为 `torch.ops.aiter.*` custom op（Library "aiter" FRAGMENT, 263）, schema 自动推断带 torch 2.4 fallbacks（269-288）, fake-tensor `abstract_impl` via `gen_fake`（348-373）, manual-schema allowlist `MANUAL_SCHEMA_OPS`（63-84）, never-wrap 列表 `NONE_WRAPPED_OP`（87-121, 非 tensor 参数 pybind ops）, 非 tensor 返回包装（313-343）, `needs_fixed_stride_order` per torch version tag（388-392）。还有 FakeTensorMode 逃生舱 `run_host_scalar_ops_for_real` / `run_python_ops_for_real`（15-36）与 torch-version helper（39-60）
- **`jit_cache.py`**（619 lines）: 事务性 codegen+publish 机制: `stage_blob_sources`（271-375; incomplete/complete marker files, owner-stamped `(pid, host, token)` generations, 崩溃时从最近 published 快照 restore）, `require_blob_generation`（458-461）, `publish_blob_sources`（464-513, backup/rollback）, `atomic_copy`（516-551, inode identity）, dead-owner reaping `cleanup_abandoned_blob_artifacts`（228-259）, opus `compiled_kids` sidecar w/ sha256 receipt（562-619）
- **`mha_recipes.py`**（129 lines）: 枚举 CK fmha blob-gen commands for **wheel 预构建** `mha_varlen_fwd_<variant>` modules（95-129）并算 `--targets <arch>` 修正使 ck-tile 的 `generate.py` 默认 `gfx9,gfx950` 在 gfx10/11/12 host 上不产生空 kernel 集（1-17）— build-selection fallback
- **`moe_recipes.py`**（196 lines）: 从 tuned_fmoe.csv 行构建 `module_moe_ck2stages_<a>_<b>_<preshuffle>_<c>_<act>_<q>_<stage>[_splitk]` 变体表 for 预构建（142-196）；**跳过 FlyDSL-owned variants**（`flydsl_*` kernel names, swiglu/situ-v2 MXFP4, a16w4 per_1x32 — 146-167），即 CK 预构建让位 FlyDSL 所有权
- **`cpp_extension.py`**（2173 lines, vendored from torch）: `_jit_compile` with versioner + FileBaton（1294-1432）, hipify invocation for HIP extensions at 1011-1029（include dirs）与 1378-1404（sources）, `IS_HIP_EXTENSION`（301）
- **`hipify/`**（`hipify_python.py`, `cuda_to_hip_mappings.py`, `constants.py`）: vendored torch hipify；角色：对 `hipify=True` 构建的模块做 CUDA→HIP 翻译（源改名 `.cpp→.cu` + 拷进 build tree, core.py:1054-1081；hipified includes core.py:1630-1647）
- **`hip_runtime.py`**（122 lines）: dlopen libhip for `hipGetDevice`, `hipDeviceGetAttribute`（chip_info PCI-chip-id/XCD 查询用）

## 2. 架构探测与分发决策点

### 2.1 探测（`aiter/jit/utils/chip_info.py`）
- `_detect_native()`（chip_info.py:47-64）: 解析 `rocminfo`（Linux）/ `hipinfo`（Windows）取首个 `gfx…` token；**保留 `gfx1250-strict` 身份**（comment 50-58）。lru_cache 缓存
- `get_gfx_custom_op_core()`（chip_info.py:72-89）: `GPU_ARCHS` env → `native` → `_detect_native()`；多 arch 取**最后**一个（79-82, documented limitation）；未知 gfx → **KeyError 列出受支持 archs**（85-89）。`get_gfx()`（92-95）经 `GFX_MAP` 映射回
- `get_gfx_runtime()`（chip_info.py:123-163）: 总是 live-GPU（GPU_ARCHS 仅 AOT replay 例外 136-143）；Windows torch fallback via `gcnArchName`（150-156）；未知 → KeyError（157-163）。Docstring: 运行时分发用 `get_gfx_runtime()`；build-time codegen 用 `get_gfx()`
- `get_gfx_list()`（286-299）: GPU_ARCHS or native, CPU fallback `["cpu"]`（294）— 仅构建路径
- CU 数: `get_cu_num` via rocminfo parse 或 `CU_NUM` env（315-342）；ASIC revision（174-250, agents 间取 min = 混合节点 fail-closed）；XCD 数默认 8 + warning（738-774）；设备命名 MI308/MI300/MI350/MI400（`_get_device_name` 659-684；**`RuntimeError("Unsupported gfx")`** at 684）

### 2.2 不支持 gfx 会发生什么
**没有全局 torch fallback**：每层自己决定。
- JIT/build 层：`get_gfx_custom_op_core` KeyError（chip_info.py:86-89）/ `get_gfx_runtime`（159-162）；`get_build_targets()` raise `RuntimeError` 提示设 `GPU_ARCHS`（345-374）
- Op 层三种行为（§3/§4 引用）：静默换 Triton/torch（`gemm_a8w8`）、warn+stub 调用时 raise（opus）、硬 raise（`iq2r_glm53.py:438-439`, `fhmoe.py:73-75`, `mla.py:724-725`, paged attention asm gates）

### 2.3 Python 分发决策点总表

| Site | File:line | Mechanism |
|---|---|---|
| fp8 dtype per arch (fnuz vs fn) | `aiter/utility/dtypes.py:10-41` | module dict `defaultDtypes` keyed by gfx; `get_dtype_fp8()`; fallback `torch.uint8` |
| A16W16 GEMM libtype default | `aiter/tuned_gemm.py:264-319` | if-chain: gfx942→hipblaslt; bf16 asm; skinny on gfx90a/942/950; **gfx1250→triton; else torch** |
| OPUS arch support | `aiter/ops/opus/_arch.py:44-103` | `SUPPORTED_OPUS_ARCHES = {gfx942, gfx950, gfx1250}`; per-tensor `_device_arch_and_cu`（159-187） |
| A8W8 CK support gate | `aiter/ops/gemm_op_a8w8.py:61-67` | `get_gfx().startswith("gfx9")` else Triton |
| Blockscale HIP prebuilt gate | `aiter/ops/gemm_op_a8w8.py:48-58` | `_BLOCKSCALE_HIP_PREBUILT_ARCHES = {gfx940,941,942,950,1250}` else Triton |
| Blockscale M-threshold Triton | `aiter/ops/gemm_op_a8w8.py:1070, 1393-1403` | `_BLOCKSCALE_TRITON_FALLBACK_MIN_M = {gfx942:2048, gfx950:384}` |
| bpreshuffle flydsl gfx1250 backend | `aiter/ops/gemm_op_a8w8.py:188-201` | `is_gfx1250_family` → WMMA backend else MFMA path |
| `gemm_a8w8_bpreshuffle_out` arch restrict | `aiter/ops/gemm_op_a8w8.py:~1035-1040`（`if gfx not in ("gfx942","gfx950"): raise NotImplementedError`） | hard arch gate |
| PA (paged attention) ASM vs native | `aiter/ops/attention.py:35-41, 183-207` | `_PA_FWD_ASM_SUPPORTED_ARCHS=("gfx942","gfx950")`; shape/CU heuristic `_should_use_asm_kernel` |
| FMHA backend selection | `aiter/ops/mha.py:2200-2500`（e.g. 2207 `get_gfx() in ("gfx942","gfx950")`, 2227-2228 v3 gfx9-only else ck-tile, 2257-2260 & 2302-2306 gfx1250+`is_gfx1250_asm_supported()`, 2341-2343 gfx942-only D64 split-K, 2388-2393 OPUS gfx950） | giant eligibility if-chain per backend |
| MLA backend selection | `aiter/mla.py:329-330, 432-436, 578, 629, 724-725, 852-853, 1286-1297, 1352, 2366-2387, 2620` | per-variant `get_gfx()` gates + `require_gfx1250_asm` |
| fused_moe gfx950 fused sort/quant | `aiter/fused_moe.py:183-200` | runtime gfx950 + shape contract, else generic path |
| fused_moe a-dtype selection | `aiter/fused_moe.py:1129-1140` | gfx950 vs gfx1250 A8W4/FP4 choice |
| FHMoE gfx950 requirement | `aiter/fhmoe.py:73-75, 741` | `get_gfx_runtime() != "gfx950"` → raise |
| IQ2R GLM-5.3 gfx950 requirement | `aiter/iq2r_glm53.py:438-439` | raise |
| mqa_logits arch/dtype gates | `aiter/mqa_logits.py:133-145` | gfx942 fnuz vs gfx950 fn dtype sets |
| paged_mqa_logits FlyDSL gate | `aiter/paged_mqa_logits.py:170-196` | gfx950-only FlyDSL kernel + shape contract |
| topk gating gfx1250 exact sigmoid | `aiter/ops/topk.py:28-91` | expert/topk whitelist + `get_gfx_runtime() in ("gfx1250","gfx1250-strict")` |
| rmsnorm gfx1250 tail handling | `aiter/ops/rmsnorm.py:395-404` | gfx1250 wave-size branch |
| layer_norm CK vs Triton | `aiter/ops/norm.py:149-152` | `_use_triton() = not ENABLE_CK or gfx1250` |
| fused_qknorm fp8/mxfp4 cvt | `aiter/ops/fused_qknorm_idxrqknorm.py:25, 116-123` | `_FP8_CVT_GFX` allowlist; mxfp4 caches gfx950-only |
| custom_all_reduce gfx1250 module | `aiter/ops/custom_all_reduce.py:10, 292-410` | separate `module_custom_all_reduce_gfx1250` + IPC transport gate |
| mx dtype selection | `aiter/ops/quant.py:300` | `MxDtypeInt.FP8_E4M3_FNUZ if get_gfx()=="gfx942" else FP8_E4M3` |
| MHA v4 manifest per arch | `aiter/ops/mha_v4.py:348, 596-626` | `_mha_v4_manifest_path(gfx)`; missing manifest → raise |
| MegaMHC gfx1250 variant select | `aiter/ops/mega_mhc.py:36-106, 261-262` | gfx1250 split-kernel tags; gfx950/gfx1250 tuned-stream vs portable generic |
| shuffle gfx1250 interleave | `aiter/ops/shuffle.py:140-145` | `moe_shuffle_weight` gfx1250 gate |
| skinny GEMM eligibility | `aiter/tuned_gemm.py:88-109` | M/N vs cu_num heuristic |
| LDS capacity table | `aiter/jit/utils/chip_info.py:98-120` | per-arch bytes; unknown → ValueError |

## 3. FALLBACK / EMULATION 路径（优先）

层级图例：**DISPATCH** = python per-call 选后端；**RUNTIME-fallback** = try 主路径失败/缺失时降级；**BUILD** = wheel/预构建期决定。

### (a) CK→Triton fallbacks
1. `aiter/ops/gemm_op_a8w8.py:61-67` `_ck_a8w8_supported()` — CK/asm INT8 a8w8 只带 gfx9 code objects；用于 **731-738**: `gemm_a8w8` 在非 gfx9（RDNA gfx11/gfx12）路由到 `aiter/ops/triton/gemm/basic/gemm_a8w8.py::gemm_a8w8`。**DISPATCH**（silent）
2. `aiter/ops/gemm_op_a8w8.py:53-58` `_hip_blockscale_supported()` + prebuilt arch set（48-50）: comment 说在 HIP 调用前 gate，因为未覆盖 arch（e.g. gfx1201）会 **SIGSEGV uncatchably**。用于 1393（config miss → Triton）, 1614。**DISPATCH**
3. `aiter/ops/gemm_op_a8w8.py:1070, 1396-1403` — untuned blockscale 大 M 偏好 Triton over CK default tile（per-arch measured thresholds）。**DISPATCH**（perf-heuristic）
4. `aiter/ops/gemm_op_a8w8.py:209-229` — FlyDSL bpreshuffle launcher 拒绝 M>K 或 K 不可整除 → 回退 CK（`gemm_a8w8_bpreshuffle_ck`）*除非*输出超 CK 2 GiB 寻址限制（`_ck_bpreshuffle_output_fits` 148-151），此时保留 FlyDSL 错误。**RUNTIME-fallback**
5. `aiter/ops/gemm_op_a8w8.py:953-969` — untuned gfx1250 bpreshuffle → 启发式 FlyDSL WMMA kernel 选择（`kernels_list`/`kernel_fits_shape`）。**DISPATCH**
6. `aiter/ops/gemm_op_a8w8.py:250-259` + 285-293 — "A tuned FlyDSL row must execute FlyDSL, never silently select another backend"；FlyDSL **ImportError 变 AssertionError**（285-293）。反回退契约
7. `aiter/ops/norm.py:149-152` — CK-free builds（`ENABLE_CK=0`）或 gfx1250 用 Triton layer_norm 替代 CK binding。**DISPATCH**

### (b) hipBLASLt / solMap 默认（`aiter/tuned_gemm.py`）
- `solMap`（tuned_gemm.py:797-805）: `torch | hipblaslt | skinny | asm | triton | flydsl | opus` → tuned CSV libtype 驱动 `solfunc` at 448-464。**DISPATCH**
- Untuned defaults（tuned_gemm.py:264-319）: gfx942 bpreshuffle → **hipblaslt** solidx −1（268-271）；bf16 N,K%64==0 → **asm**（272-281）；skinny shapes on gfx90a/gfx942/gfx950 → **skinny** wvSplitK kernels（292-299）；**gfx1250/gfx1250-strict unscaled bf16/fp16 → Triton（gluon）a16w16 kernel 因为 hipBLASLt 在那明显慢**（301-311）；其余 → **torch**（313-315）。**DISPATCH** 带 arch-conditioned fallback
- `torch_gemm` FP8 路径 → `_torch_scaled_gemm`（573-599）: `torch._scaled_mm`；**RuntimeError → FP32 emulation**: `F.linear(inp.to(fp32), w.to(fp32)) * scale_a * scale_b`（595-599）。**RUNTIME-fallback to torch-native math emulation**
- `opus_gemm` 当 opus 包 import 失败（`_opus_launch is None`, set at 33-36 via blanket try/except around `aiter.ops.opus.opus_gemm`）→ warning + `torch_gemm`（738-753）。**RUNTIME-fallback**
- `get_GEMM_A16W16_tuned_config` 丢弃 stale 行：未知 FlyDSL kernel name（169-174）, 不可解析 OPUS kid/splitK（177-233）→ 下一个 padded-M 候选，else 默认 fallback 链。**DISPATCH with graceful degradation**
- `_gemm_a16w16` 不可 view 的 ≥3-D input → `F.linear`（416-421）。**RUNTIME-fallback to torch**
- `is_skinny_default_shape`（88-109）+ skinny sols 0/1/2 → wvSpltK/LLMM1/wv_splitk_small（527-532）。**DISPATCH**

### (c) 架构条件 python 分支（gfx1250 → triton/flydsl/torch）
- tuned_gemm gfx1250→triton: tuned_gemm.py:301-311（上）
- gfx1250 bpreshuffle→FlyDSL WMMA: gemm_op_a8w8.py:188-194 & 943-969
- gfx1250 mxfp8 untuned 形状 best-effort kernel: `_flydsl_mxfp8_fallback_kernel` gemm_op_a8w8.py:~1435-1470
- gfx1250 A8W4 quant-dtype choice（`AITER_FORCE_A8W4` 下强制 fp8）: fused_moe.py:1136-1140
- gfx1250 exact-sigmoid topk 当 HIP 契约不匹配 → Triton fallback: topk.py:28-91 + `_gfx1250_exact_sigmoid_topk` → `aiter/ops/triton/moe/moe_routing/topk_gating.exact_sigmoid_biased_topk`（97-107）。**DISPATCH**
- gfx1250 custom-allreduce 专用模块 + 跳过 VMM registration block（deadlock workaround）: custom_all_reduce.py:10, 292+；communication.py:72-77。**DISPATCH/BUILD**
- gfx1250 A0 asm gate（asm_guard）启动时静默重路由框架：asm_guard.py:49-54（"Frameworks can call this at startup to select a backend before the hard gate"）；硬 `require_gfx1250_asm` raise 点: mla.py:805, 832, 1352, 1638, 1869, 1929, 2387, 2696；mha.py:618, 704, 853, 1098；attention.py:494。**DISPATCH + fail-closed gate**

### (d) try/except ImportError → python fallback
1. `aiter/ops/fused_norm_quant_gemm.py:22-34, 73-95` — fused C++ JIT 模块（`module_fused_norm_quant_gemm`）缺失/失败 → **python fallback**: `rmsnorm_quant`（CK）+ `hipb_mm`（hipBLASLt）两调用。**RUNTIME-fallback**（ImportError/OSError/RuntimeError，load-time 与 call-time 都有）
2. `aiter/tuned_gemm.py:33-36` — opus import 失败 → `_opus_launch=None` → torch_gemm（738-753）。**RUNTIME-fallback**
3. `aiter/__init__.py:156-162` — `topk_select` 需要可选 Linux-only `flydsl` 包；`ModuleNotFoundError` 仅当 `exc.name == "flydsl"` 吞掉，其余 re-raise
4. `aiter/__init__.py:200-214` — Iris/Triton comms（`ops.triton.comms`）可选；ImportError/AttributeError → `IRIS_COMM_AVAILABLE=False`
5. `aiter/ops/qsa.py:26-45` — FlyDSL qsa layout / sparse-prefill imports → `_HAS_FLYDSL` / `_HAS_FLYDSL_PREFILL` flags gating backend choice
6. `aiter/ops/gemm_op_a6w6.py:249-252` — `import triton` guarded → `_HAS_TRITON`；fused Triton quantize+pack 只在 triton 存在时编译
7. `aiter/mqa_logits.py:123-129`, `aiter/paged_mqa_logits.py:167-174` — FlyDSL kernel import 失败 → None → 非 FlyDSL 路径
8. `aiter/__init__.py:78-92` — **Windows 无 ROCm toolchain 翻 `AITER_TRITON_ONLY=1`** 并 log "falling back to the Triton ops"（Linux loud raise）。还有 opt-in env `AITER_TRITON_ONLY`（61-64）。**Package-level fallback to the Triton-only sublayer**（`is_gfx1250_asm_supported`/`require_gfx1250_asm` stub True/no-op at 186-192）
9. `aiter/__init__.py:101-184` — op imports 刻意**不加** try/except（comment 104-112: silent truncation 曾破坏 vLLM）；opus 自 guard（见 (e)）

### (e) warn+stub（import 存活，调用抛错）— opus 模式
`aiter/ops/opus/_arch.py:1-146` 记录政策：`_detect_arch` never raises（51-103；GPU_ARCHS → rocminfo → unknown）；不支持的 arch 上 opus 子包 `__init__` 装**调用时才 raise 的 stub**，使 aiter 包 import 不级联失败；`_check_arch`（106-145）是硬 ImportError 变体。存在原因：`aiter/__init__.py` 不能在 opus import 行之后丢掉 30+ ops

### (f) torch-native fallback（不支持形状 / 软件模拟）
1. `aiter/ops/moe_op.py:153-160` — `moe_sum`: C kernel 只实现 topk ∈ {2,4,5}；**else `torch.sum(input, dim=1, out=output)`**。**DISPATCH**（shape-conditioned torch-native）
2. `aiter/ops/moe_op.py:44-73` — `topk_softmax`: 非 2 幂或 >256 experts 分配全 softmax workspace 走两趟 in-kernel 路径（C 侧处理；python sizing `needs_workspace` at 54-59）。*fused shared-gate* 变体只支持 **pow2 ≤512**，否则拒绝（moe_op.py:113-114）
3. `aiter/tuned_gemm.py:573-599` — FP8 `torch._scaled_mm` 拒绝 → **fp32 matmul emulation**（见 (b)）
4. `aiter/ops/topk.py:28-107` — gfx1250 HIP topk 契约不匹配 → Triton exact sigmoid topk
5. `aiter/ops/mha.py` — 非 gfx9 arch "must fall back to ck-tile" for fmha v3（mha.py:2227-2228）；OPUS gfx950-only dense fwd（2388-2393）
6. 纯 torch **correctness oracles**（设计如此，非热路径）：`aiter/ops/iq2r_reference.py:5-20`（"Pure-Torch correctness oracle… deliberately explicit"）；`aiter/ops/torch_ref/fused_compress_attn.py:4-9`（"Pure-PyTorch reference… ~100x slower… Not on the inference hot path"）；`aiter/ops/quant.py` `get_torch_quant` vs `get_hip_quant` vs `get_triton_quant`（350-397）— 同一 quant 由 backend 选 torch/HIP/Triton 实现
7. `aiter/ops/fused_moe.py:1810-1872` — MXMOE pair 不支持 → 以 family disabled 重新 resolve metadata（"A tuned fast row that this invocation cannot run is discarded, not raised on", 1826-1828）；仅当 *无* fallback backend 能满足 `block_size_M`（1831-1834）或该形状无安全 backend（1861-1866）才显式 `NotImplementedError`。**DISPATCH with tiered fallback**（`_PADDED_M_TIERS` tier walk at 4281-4292；act-type-disabled fallback table 4173-4197）
8. `aiter/fhmoe.py:622, 746` — tuned-row lookup 异常 → fall back（generic resolve）
9. `aiter/fused_moe_registry.py:90` — registration errors swallowed 保 alternate impls 可加载

### (g) fp8 dtype fnuz vs fn per arch（dtype 级模拟边界）
- `aiter/utility/dtypes.py:10-21` — `gfx942 → torch.float8_e4m3fnuz`；gfx950/gfx1100/1101/1102/1150/1151/1200/1201/1250/1250-strict → `torch.float8_e4m3fn`。无 GPU/no-HIP 或未知 arch → **`torch.uint8` fallback**（`_8bit_fallback`, lines 23-41）。`fp8_e8m0`, `int4`, `float4_e2m1fn_x2` 同样 `getattr(..., fallback)`（42-44）。**BUILD/DISPATCH**（module-level 常量，处处作 `dtypes.fp8` 消费）
- `aiter/ops/quant.py:300` — MX dtype enum 在 gfx942 选 `FP8_E4M3_FNUZ` else `FP8_E4M3`
- `aiter/mqa_logits.py:12-13, 140-145` — gfx950 用 fn，gfx942 接受 fnuz

## 4. `aiter/ops/` 清单（module → backend）

JIT 模块名来自 `optCompilerConfig.json`；op 列表来自 `aiter/__init__.py:118-184` import 顺序（权威清单）。

**CK/C++ JIT（`compile_ops`）ops：**
- `activation.py` → module_activation（CK, develop pybind）
- `cache.py` → module_cache（CK; paged KV ops）
- `custom.py` → module_custom（CK misc）
- `custom_all_reduce.py` → module_custom_all_reduce（+gfx1250 variant）— IPC allreduce
- `quick_all_reduce.py` / `quick_reduce_scatter.py` → module_quick_all_reduce — INT4/INT8 quick allreduce
- `rmsnorm.py`, `norm.py` → module_rmsnorm / module_norm（CK）— norm.py 在 CK-free/gfx1250 落 Triton
- `quant.py` → module_smoothquant, module_quant, module_rmsnorm_quant, module_gated_rmsnorm_quant
- `rope.py` / `pos_encoding.py` → module_rope_*（16 variants）, module_pos_encoding
- `topk_plain.py` → module_topk_plain; `topk.py` → module_top_k_per_row(+_sampled); `topk_select.py` → FlyDSL-backed
- `sample.py` → module_sample; `bert_padding.py` → CK pad ops
- `moe_op.py` → module_moe_asm（topk_softmax/moe_sum/moe_align_block_size, develop）, module_moe_topksoftmax_asm + module_moe_topk_ck（ctypes）, module_moe_fmoe_asm（fmoe ctypes）, module_moe_ck2stages / module_moe_cktile2stages
- `moe_sorting.py` → CK sorting; `moe_sorting_opus.py` → module_moe_sorting_opus; `moe_mxfp4_aux.py` → module_moe_mxfp4_aux
- `gemm_op_a16w16.py` → module_gemm_a16w16_asm（ctypes, ASM splitK w/ semaphore workspace）; dispatch 走 `aiter/tuned_gemm.py` solMap
- `gemm_op_a8w8.py` → module_gemm_a8w8（CK）, module_gemm_a8w8_bpreshuffle_ck/cktile, module_gemm_a8w8_blockscale_ck/cktile/asm（ctypes）, module_gemm_a8w8_blockscale_bpreshuffle[_asm/cktile], module_gemm_a8w8_mxfp8[_bpreshuffle] — 加 Triton/FlyDSL alternates
- `gemm_op_a16w8.py`, `gemm_op_a4w4.py`, `gemm_op_a4w6.py`, `gemm_op_a6w4.py`, `gemm_op_a6w6.py`, `gemm_op_a8w4.py` → per-dtype CK/ASM GEMM modules（a4w4 也 `module_gemm_a4w4_mxscale_bpreshuffle`）
- `batched_gemm_op_a8w8.py`, `batched_gemm_op_bf16.py` → CK batched GEMM modules（BatchedGemmDispatchMap）
- `attention.py` → module_attention（CK PA naive）+ module_attention_asm（ctypes PA）+ module_pa_decode_bf16_asm（gfx1250）+ module_pa_metadata/mla_metadata/ps_metadata; gluon PA via `triton/gluon/pa_decode_gluon`; `csrc/cpp_itfs/pa/*` C++ ITF
- `mha.py`（4827 lines）→ module_fmha_v3_fwd/bwd/varlen*, module_mha_varlen_fwd*, ck-tile mha, OPUS gfx950 fwd, gfx1250 asm fwd set
- `mha_v4.py` → MHA v4 block-sparse（manifest-per-arch, `hsa/<gfx>` asm）
- `mla.py`（top-level `aiter/mla.py` + `ops/asm/mla_decode_v4.py`）→ mla asm modules（gfx942/950/1250 variants）+ FlyDSL reduce kernels
- `deepgemm.py` → module_deepgemm（CK-backed deepgemm）+ module_deepgemm_opus（opus code objects）
- `gradlib.py` → module_hipbsolgemm（hipBLASLt: hipb_mm/findallsols/grouped/multistream）+ module_rocsolgemm（rocBLAS rocb_mm）
- `communication.py` → dist env init; `communication/` helpers in `aiter/dist/`
- `mhc.py` / `mega_mhc.py` → module_mhc(+seam_asm)/mega_mhc stream kernels（gfx950/gfx1250 tuned, portable generic otherwise）
- `causal_conv1d_fwd_split_qkv.py`, `causal_conv1d_update.py` → CK conv1d + FlyDSL update kernels
- `chunk_gated_delta_rule_fwd_h.py`, `fused_split_gdr_update.py`, `gdr_decode_packed_bf16.py` → GDN/gated-delta CK/FlyDSL
- `fused_qknorm_idxrqknorm.py`, `fused_qk_norm_mrope_cache_quant.py`, `fused_qk_norm_rope_cache_quant.py`, `fused_qk_rmsnorm_group_quant.py`, `inverse_rope_group_quant.py`, `gated_rmsnorm_fp8_*.py` → CK fused norm/rope/quant modules
- `fused_norm_quant_gemm.py` → module_fused_norm_quant_gemm（C++ fused rmsnorm+quant+hipBLASLt; python fallback per §3d）
- `iq2r.py` / `iq2r_encoder.py` / `iq2r_format.py` → module_iq2r_moe / IQ2R gfx950 encode（compiled）vs `iq2r_reference.py` torch oracle
- `shuffle.py` → weight preshuffle helpers（python + CK）
- `sampling.py` → module sampling（AOT 预编译也有）
- `trans_ragged_layout.py`, `prefill_batch_metadata.py` → CK layout helpers

**FlyDSL（`aiter/ops/flydsl/`, ~80 files）** — 第三方 `flydsl` 包 kernels: gemm_kernels/gemm_a16w16_* /gemm_a8w8_mxfp8*/batched_gemm_a8w8_{gfx950,gfx1250}, mxfp4_gemm1/2, moe_kernels, fhmoe, mega_moe_tp, mla_kernels, fmha_kernels/fmha_bwd_gfx942, pa_decode, fp8_mqa_logits_kernels, one_shot_allreduce, quick_allreduce_int4, conv3d_gfx1250, topk/, kernels/ subdir。Gate: min version 0.2.4（`flydsl/__init__.py:15-23`）；许多文件 per-arch（gfx950/gfx1250 后缀）

**Triton（`aiter/ops/triton/`）** — 见 §6

**torch_ref / reference** — `aiter/ops/torch_ref/fused_compress_attn.py`, `aiter/ops/iq2r_reference.py`

## 5. `aiter/dist/` 与 `aiter/plugin/`

**`aiter/dist/`**（vLLM-derived 分布式层）:
- `parallel_state.py` — GroupCoordinator / TP/EP 状态机，custom-op wrapped all-reduce/fused_allreduce_rmsnorm(_quant) entry points（lines 44-470）, graph-capture context
- `device_communicators/`: `custom_all_reduce.py`（IPC handles, Lamport buffers）, `quick_all_reduce.py`, `communicator_pynccl.py` + `pynccl_wrapper.py`（NCCL ctypes）, `communicator_cuda.py`, `all2all.py`, `vmm_allocator.py`（VMM pools）, `flydsl_utils.py`, `_all_reduce_config.py`, `rocm_version.py`
- `shm_broadcast.py` — shared-memory broadcast ring; `cuda_wrapper.py`; `communication_op.py`; `utils.py`

**`aiter/plugin/`** — 单个 1169-line `__init__.py`: **实验性 out-of-tree kernel-provider 注册表**。契约：AITER 持有 op contracts + fallback/no-fallback-after-run 规则；providers 出 "kernel plugins" 实现 `KernelProvider`，经 `aiter.plugins` entry-point group 注册（`ENTRY_POINT_GROUP`, plugin/__init__.py:60）, API 版本化带 superseded-version warnings（48-58）, 仅框架 `configure(enable=...)` 启用；`AITER_PLUGINS=0` 是唯一 env kill-switch（17-19）。Op/dataclasses（`Op`, `KernelCandidate` 自报 `qualification`）at 66+

## 6. aiter 中的 Triton kernels

- `aiter/` 下 **206 个 python 文件**含 `@triton.jit`
- 作者 Triton kernels 在 `aiter/ops/triton/`（子树: `gemm/`（basic a8w8, a16w16, blockscale, blockscale_group32, …）, `moe/`（incl. `moe_routing/topk_gating`）, `attention/`, `fusions/`（~20 fused eps）, `normalization/`, `quant/`, `rope/`, `conv/`, `gluon/` + `_gluon_kernels/`（gluon PA decode — AMD gluon 语言）, `comms/`（Iris all_gather/reduce_scatter）, `gated_delta_net/`, `kimi_delta_attn/`, `softmax.py`, `topk.py`, `kv_cache.py`, `cross_entropy.py`, `gather_kv_b_proj.py`）, 加 AOT copies `aiter/aot/triton/` 与 `aiter/utility/triton/triton_metadata_redirect.py`
- **C 侧 Triton 使用**: `csrc/cpp_itfs/utils.py:439-486` `compile_hsaco_from_triton(kernel, ...)` 把 `triton.JITFunction` 编成 **HSACO/code object**（存 `triton_version` metadata）供 HIP driver API 加载；C++ launcher class at 563-620 检查 `check_hsaco(...)`，缺失经 609-611 重编，否则经 Triton 启动。这是让 C++ ITFs（e.g. `csrc/cpp_itfs/pa/pa.py`）嵌入 Triton kernels 的桥
- FlyDSL **不是** Triton：独立 `flydsl` 包（HIP 级 DSL）带自己的 AOT cache（`aiter/jit/flydsl_cache`, `aiter/aot/flydsl/`）

## 7. 验证 / 基准工具

- **`aiter/test_common.py`**（662 lines）: `ensure_spawn_method`（24）, `perftest` decorator（49, CUDA-graph replay support at 139）, `benchmark`（165）, `device_memory_profiling`（185）, `run_iters`/`run_iters_rotate`（226-241）, `run_perftest`（243）, `log_args`（271）, `post_process_data`（297）, `get_trace_perf`（367, profiler-trace parsing）, catastrophic-check helpers `_relmag_catastrophic`/`_check_catastrophic`（454-518）, `checkAllclose`（520）/`assertAllclose`（632）带 rtol/atol + err ratio, `tensor_dump`/`tensor_load`（647-657）
- **`aiter/test_mha_common.py`**（808 lines）: MHA test harness（ref impls, tolerance policy）
- **`aiter/benchmark_data_init.py`**（348 lines）: 可复现基准输入生成 — `make_generator(seed)`（38）, `add_data_init_args`（43）, distribution samplers `_sample_data_f32`/`_sample_scale_f32`（95-121）, `fill`（139）, `fill_scale`（167）, fp4/fp8/e8m0/e4m3 fillers `fill_fp4`（212）, `fill_fp8`（244）, `fill_scale_e8m0`（288）, `fill_scale_e4m3`（324）— 每个 op 基准读相同数据
- **`aiter/benchmark_reporting.py`**（36 lines）: `print_json_table(name, rows)` — 单记录 JSON 输出供 parent drivers/CI 消费
- **`aiter/smi_monitor.py`**（574 lines）: amdsmi-backed GPU telemetry — `GpuMonitor` context manager（346-448, sampling interval default 0.05 s）, BDF resolution via HIP device → amdsmi handle（216-309）, per-call tagging（`benchmark_call_context` 111, `replay_with_smi_metadata` 120）, amdsmi 缺席时 graceful degradation（159-195）
- **Tuning infra**（`aiter/utility/`）: `mp_tuner.py`（multi-process tuner with per-GPU pools, error-ratio merge, 435 `mp_tuner`）, `base_tuner.py`（`TunerCommon` 42）, `pretune.py`（`run_pretune_modules` 347, wired into setup.py:438-452）, `selection_policy.py` / `power_configs.py` / `tune_result.py`（AITER_SELECT power/latency ranking）, `graph_alloc.py`（`capture_scoped_cache`/`persistent_alloc` — graph-safe workspaces）

## 8. `aiter/quantization/` — quant config/数据结构

- **`aiter/ops/enum.py`**（21 lines）: `ActivationType`, `QuantType`, `MlaVersion` 是 **C++ pybind enums** 经 `compile_ops("module_aiter_core", ...)` import 并 re-typed（`Enum = int` alias）。python 用值: `QuantType.No/per_Tensor/per_Token/per_1x32/per_1x128/per_256x128/per_1024x128`（quant.py:350-397; `_QUANT_ALIAS per_128x128→per_1x128` in moe_recipes.py:18）
- **`aiter/utility/aiter_types.py`** — `aiter_dtypes` id table（AiterDtype enum ids）+ `aiter_tensor_t` layout（ctypes/pybind bridging in `dtypes.py:64+`）
- **`aiter/utility/dtypes.py`** — dtype registry incl. per-arch fp8（§3g）与 `d_dtypes`, `AITER_DTYPE_*` ids
- **`aiter/utility/mx_types.py`** — MX（microscaling）types: `MxDtypeInt`（FP4_E2M1, FP8_E4M3_FNUZ, FP8_E4M3, …）, `MxScaleRoundModeInt` + `MX_DEFAULT_ROUND_MODE`, `MxScaleRoundMode`（4 种 rounding formulas; consumed by `per_1x32_f4_quant`, quant.py:97-206）；`fp4_utils.py` — fp4 packing helpers
- **`aiter/ops/quant.py`** — quant op 面: `get_torch_quant/get_hip_quant/get_triton_quant(qType)` backend tables（350-397）, `per_block_quant_wrapper((1,128)|(256,128)|(1024,128))`（331-348）, `per_1x32_f4_quant` / `per_1x32_i4_quant` / `per_1x32_f8_scale_f8_quant` / `per_tensor_quant`
- **`aiter/quantization/iq2r/`** — IQ2R（2-bit importance-weighted quant）包: `glm5/compile.py`（962 lines; GLM-5.3 weight compile pipeline, gfx950）, `glm5/calibrate.py`（638 lines; importance/codebook calibration）, torch oracle `aiter/ops/iq2r_reference.py` + 字节格式 spec `aiter/ops/iq2r_format.py`（`IQ2R_*` layout constants: atoms/triplets/lanes/tiles, codebook 512x8, scale block 32）。顶层 driver `aiter/iq2r_glm53.py`（551 lines; gfx950-only, raise at 438-439）

## 汇总表

| Mechanism | Layer | File:line | Type |
|---|---|---|---|
| `compile_ops` import-or-build flow | python-jit | `aiter/jit/core.py:2309-2405` | dispatch/build |
| Build args from `optCompilerConfig.json`（eval） | python-jit/build | `aiter/jit/core.py:1802-1924` | build-selection |
| `build_module` + blob codegen staging | python-jit | `aiter/jit/core.py:1401-1729`; `aiter/jit/utils/jit_cache.py:271-375` | build |
| mp build safety（FileBaton / mp_lock） | python-jit | `aiter/jit/core.py:61-92`; `aiter/jit/utils/file_baton.py:26+`; `cpp_extension.py:1353-1362` | build |
| JIT cache dirs（`AITER_JIT_DIR`, pkg dir, `~/.aiter/jit`） | python-jit | `aiter/jit/core.py:922-938` | build |
| Wheel prebuild levels 1/2/3 | python-build | `setup.py:30, 273-295, 298-452` | build-selection |
| MHA prebuild variants（+`--targets` 非 gfx9 修正） | python-build | `aiter/jit/utils/mha_recipes.py:1-17, 95-129` | build-selection |
| MoE CK-2stages prebuild variants（FlyDSL-owned 跳过） | python-build | `aiter/jit/utils/moe_recipes.py:142-196` | build-selection |
| Arch detect（`_detect_native`/`get_gfx`/`get_gfx_runtime`） | python-dispatch/build | `aiter/jit/utils/chip_info.py:47-64, 72-95, 123-163` | dispatch |
| Unsupported gfx → KeyError / RuntimeError（无全局 fallback） | python-jit | `chip_info.py:86-89, 159-162, 345-374, 684` | dispatch (fail) |
| gfx1250 A0/strict asm gate（fail-closed） | python-dispatch | `aiter/jit/utils/asm_guard.py:12-64` | dispatch/fallback-gate |
| Wrong-arch .so rebuild（`_so_offload_archs`） | python-jit | `aiter/jit/core.py:1140-1148, 1230-1248` | build |
| torch.compile custom-op guard | python-jit | `aiter/jit/utils/torch_guard.py:231-407` | dispatch |
| ctypes torch-free FFI | python-jit | `aiter/jit/core.py:1947-2261` | dispatch |
| fp8 fnuz(gfx942)/fn(else) + uint8 fallback | python-dispatch | `aiter/utility/dtypes.py:10-41` | build-selection |
| A8W8 CK→Triton on non-gfx9 | python-dispatch | `aiter/ops/gemm_op_a8w8.py:61-67, 731-738` | fallback (silent) |
| Blockscale HIP prebuilt arch gate → Triton | python-dispatch | `aiter/ops/gemm_op_a8w8.py:48-58, 1393, 1614` | fallback |
| Blockscale big-M Triton preference | python-dispatch | `aiter/ops/gemm_op_a8w8.py:1070, 1396-1403` | fallback (perf) |
| FlyDSL launch reject → CK（带 2GiB guard） | python-dispatch | `aiter/ops/gemm_op_a8w8.py:148-151, 209-229` | runtime-fallback |
| Untuned gfx1250 bpreshuffle → FlyDSL WMMA heuristic | python-dispatch | `aiter/ops/gemm_op_a8w8.py:943-969` | fallback |
| solMap（torch/hipblaslt/skinny/asm/triton/flydsl/opus） | python-dispatch | `aiter/tuned_gemm.py:797-805, 448-464` | dispatch |
| Untuned default: gfx942→hipblaslt; bf16→asm; skinny; gfx1250→triton; else torch | python-dispatch | `aiter/tuned_gemm.py:264-319` | fallback |
| `torch._scaled_mm` → fp32 matmul emulation | python-dispatch | `aiter/tuned_gemm.py:573-599` | runtime-fallback (emulation) |
| opus unavailable → torch_gemm | python-dispatch | `aiter/tuned_gemm.py:33-36, 724-753` | runtime-fallback |
| opus arch stub/warn pattern | python-dispatch | `aiter/ops/opus/_arch.py:51-146` | dispatch |
| Stale tuned-row skip（flydsl/opus names） | python-dispatch | `aiter/tuned_gemm.py:160-243` | runtime-fallback |
| fused_norm_quant_gemm C++ → python rmsnorm+hipb_mm | python-dispatch | `aiter/ops/fused_norm_quant_gemm.py:22-34, 73-95` | runtime-fallback |
| `moe_sum` topk∉{2,4,5} → torch.sum | python-dispatch | `aiter/ops/moe_op.py:153-160` | fallback (torch-native) |
| topk_softmax non-pow2 workspace path | python-dispatch | `aiter/ops/moe_op.py:44-73` | dispatch |
| gfx1250 topk contract → Triton exact sigmoid | python-dispatch | `aiter/ops/topk.py:28-107` | fallback |
| layer_norm CK→Triton（CK-free/gfx1250） | python-dispatch | `aiter/ops/norm.py:149-170` | fallback |
| fused_moe tuned-row discard + tier walk | python-dispatch | `aiter/fused_moe.py:1810-1872, 4276-4292` | runtime-fallback |
| Windows/no-ROCm → AITER_TRITON_ONLY | python-package | `aiter/__init__.py:61-100, 186-198` | fallback (package-level) |
| flydsl optional imports → feature flags | python-dispatch | `aiter/__init__.py:156-162`; `aiter/ops/qsa.py:26-45`; `mqa_logits.py:123-129` | runtime-fallback |
| MX dtype fnuz/fn per arch | python-dispatch | `aiter/ops/quant.py:300`; `aiter/utility/mx_types.py` | build-selection |
| PA asm vs native/gluon selection | python-dispatch | `aiter/ops/attention.py:35-41, 183-266` | dispatch |
| fmha backend eligibility chain | python-dispatch | `aiter/ops/mha.py:2200-2500` | dispatch |
| Triton→HSACO for C++ ITFs | python-build（csrc side） | `csrc/cpp_itfs/utils.py:439-486, 563-620` | build |
| Tuned-CSV merge/dedup/power overlay | python-jit | `aiter/jit/core.py:517-661, 804-851`; `aiter/utility/power_configs.py` | build-selection |
| hipify（.cpp→.cu, CUDA→HIP 源变换） | python-jit | `aiter/jit/core.py:1054-1081, 1630-1647`; `aiter/jit/utils/cpp_extension.py:1011-1029, 1378-1404` | build |
| gfx1250-strict → gfx1250 family reuse（tuned rows） | python-dispatch | `aiter/jit/utils/build_targets.py:60-80`; `aiter/tuned_gemm.py:134-141`; `aiter/ops/gemm_op_a8w8.py:~690-694, ~700-706` | fallback |
| Hard gfx950-only raises | python-dispatch | `aiter/iq2r_glm53.py:438-439`; `aiter/fhmoe.py:73-75`; `aiter/mla.py:629, 724-725` | dispatch (fail) |

**大图**：Python 层是薄而宽的分发网。JIT 核心（`aiter/jit/`）决定*构建什么*（AOT wheel 预构建级别、blob codegen、tuned-CSV 按 (gfx,cu_num) 过滤）；per-op python 决定*哪个后端运行*（tuned-CSV `libtype` 优先，然后一串架构/形状条件 fallback，终点是 Triton、FlyDSL 或 torch-native emulation）；**没有统一"不支持架构"处理器**——不支持的 gfx 要么局部 raise（gfx950-only ops、gfx1250 asm gate），要么静默降级 Triton/torch（RDNA gemm、gfx1250 a16w16、Windows 无 ROCm）。
