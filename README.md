# rocm-demo — AITER Lab

Design harvest from [ROCm/aiter](https://github.com/ROCm/aiter) — the
borrowable designs of an inference operator library, extracted as
self-contained, verified demos. Part of the cuda-oxide adapt-rocm research
line (Rust GPU toolchain on RX 6950 XT / gfx1030, RDNA2).

This repo doubles as the **AITER Lab** (charter 2026-11-13): systematic
dissection of aiter's algorithms / compiler machinery / hardware mechanisms
/ software-emulation paths, re-implemented as independent minimal demos
under `demos/<category>/<concept>/` with per-demo build, tests, inspection
artifacts, hardware matrix and recorded verification levels
(SOURCE_VERIFIED → REFERENCE_PASS → STATIC_ANALYSIS_PASS → COMPILE_PASS →
HARDWARE_PASS → PERFORMANCE_MEASURED).

Knowledge map (Milestone 1, aiter @ `1eab5ae12`):

- `docs/SOURCE_INDEX.md` — source/technique entry index
- `docs/TECHNIQUE_CATALOG.md` — curated technique entries + existing-demo
  verification levels
- `docs/ARCH_MATRIX.md` — arch × capability matrix (aiter evidence + lab
  measurements)
- `docs/BACKEND_MATRIX.md` — backend relationships & selection logic
- `docs/DEPENDENCY_GRAPH.md` — module dependencies & lab cut-points
- `docs/EMULATION_CATALOG.md` — software-emulation/fallback catalog
  (SIM / LOWER / RT-FB / DISPATCH / ALG classification)

Three layers:

- **core/** — pure-CPU deterministic reference cores (`aiter_ref`):
  algorithm pieces with no hardware dependency, pinned as host C++20 with
  unit tests. Build: CMake >= 3.16, nothing else. These are also the
  host-side independent references future GPU ports need.
- **design/** — host-side engineering-pattern demos (`aiter_design`):
  aiter's runtime machinery (JIT compile cache, per-op dispatch) reduced to
  minimal C++17 libraries with behavioral tests. POSIX-only.
- **gpu/** — HIP process demos for gfx1030 (soft fp8/fp4 math, the soft-TMA
  software pipeline as hand-written ISA, compiler-toolchain interfaces).
  No ROCm on the host: build & run inside the container, see `gpu/README.md`.

Upstream pin: aiter @ `1eab5ae12c93af3c8c660202d9a413f637c2f011`
(shallow clone, 2026-11-09). aiter's MIT license text:
`LICENSES/MIT.txt`. New glue (tests, harness, build files, design
reductions): Apache-2.0. Upstream licenses preserved per file.

## core/ modules

| Module | Upstream source (aiter @ 1eab5ae12) | License | Line |
|---|---|---|---|
| `moe_align` | `csrc/kernels/moe_align_block_size_kernels.cu` | Apache-2.0 (© AMD, © vLLM team) | 1 |
| `topk_softmax` | `csrc/kernels/topk_softmax_kernels.cu` (`moeSoftmax`+`moeTopK`), `csrc/include/hip_reduce.h` | MIT (© AMD) | 1 |
| `group_quant` | `csrc/kernels/quant_kernels.cu` (continuous fp32-scale path), `csrc/include/quant_amax_floor.h` | MIT (© AMD) | 1 |
| `fp8` | cuda-oxide `crates/cuda-device/src/fp8.rs` (on-card-validated codec) | Apache-2.0 (© NVIDIA) | 1 |
| `moe_fused_gate` | `csrc/kernels/moe_fused_gate.cu` (grouped biased routing; ArgMin/ArgMax tie-break from `hip_reduce.h`) | Apache-2.0 (© AMD, adapted from sglang) | 2 |
| `sample` | `csrc/kernels/sample_kernels.cu` (greedy/Philox/outer-exponential sampling) + bit-exact `rocrand_device::philox4x32_10_engine` port | MIT (© AMD, © D. E. Shaw Research) | 2 |
| `rope` | `csrc/kernels/rope/rope_common.h` + general_{1c,2c}_cached/uncached fwd family | MIT (© AMD) | 2 |
| `kv_cache` | `csrc/kernels/cache_kernels.cu` → `reshape_and_cache_flash_kernel` (block-table KV scatter) | Apache-2.0 (© vLLM team, © AMD) | 2 |
| `hadamard_quant` | `csrc/kernels/dsv4_rotate_quant.cu` (row Hadamard butterfly + fp4/fp8 group quant), `csrc/include/quant.h` hadamard_rotate | MIT (© AMD) | 2 |
| `gdn_state` | `csrc/kernels/chunk_gated_delta_rule_fwd_h.cu` (inter-chunk GDN state recurrence) | MIT (© AMD) | 2 |

Round-1 modules (line 1) harvest the MoE scheduling chain and per-token
group quantization. Round-2 modules (line 2) harvest the routing, sampling,
positional-encoding, KV-cache, quantization-rotation and linear-attention
state lines. Semantics, pinned quirks and documented scope exclusions live
in each header (`include/aiter_ref/*.hpp`); every module's tests validate
against an independent reference (double-precision, brute-force codec, or
sort-based reformulation), never against itself.

Highlights pinned by the round-2 tests:

- `moe_fused_gate`: value-first/lower-key tie-breaks make the device DPP
  reduction tree order-independent; pad rows write -1/0.0 on routed slots
  but still write shared-expert slots (upstream quirk).
- `sample`: Philox engine bit-exact against vectors generated from ROCm
  7.2's hiprand headers; in-kernel sampling and noise-decoupled sampling
  pick identical tokens for the same (seed, offset); the exponential
  transform's u>=1-2^-24 clamp is sign-flipped vs PyTorch (pinned as-is).
- `hadamard_quant`: butterfly == naive Hadamard matmul; the rotate-vs-
  direct quantization trade-off is measured and pinned BOTH ways (spike
  rows win ~3x MSE, smooth rows lose).
- `gdn_state`: chunked recurrence matches a double-precision reference
  with identical quantization points (worst error 0.1% of the
  accumulation bound); snapshots quantize at bf16, gated values quantize
  at bf16, the decay applies to H before the delta adds.

## design/ demos

| Demo | Upstream source | Designs demonstrated |
|---|---|---|
| `jit_cache` | `aiter/jit/core.py`, `aiter/jit/utils/{jit_cache,file_baton}.py` | content-addressed cache key; identity sidecar; temp+rename atomic publish; FileBaton cross-process lock with dead-pid stale detection & break-and-redo |
| `dispatch` | `aiter/fused_moe_registry.py`, `csrc/include/aiter_dispatch.h` | name registry with duplicate rejection; arch-tiered resolution (specialized → generic → fallback); lazy "module:attr" binding with cache; `impl__<name>__<config>` kernel-name codec |

`jit_cache`'s two-process test proves the single-builder guarantee (racing
processes on one key: exactly one compiles, the loser hits the cache) and
that a crashed holder's lock is broken and its work redone.

## demos/ — lab 结构（Milestone 2，五类覆盖）

| 类目 | Demo | 状态 |
|---|---|---|
| emulation | `demos/emulation/soft_tma` | HARDWARE_PASS + PERFORMANCE_MEASURED（C++ B=4 507.6 GB/s = 91.1% of ISA 参照） |
| emulation | `demos/emulation/soft_fp8` | HARDWARE_PASS + PERFORMANCE_MEASURED（219,488 穷举 0 失败；流 477-533 GB/s） |
| emulation | `demos/emulation/soft_fp4` | HARDWARE_PASS + PERFORMANCE_MEASURED（穷举 0 失败；MXFP4 SF 点积界内） |
| emulation | `demos/emulation/warp_sync` | HARDWARE_PASS + PERFORMANCE_MEASURED（四原语 PASS；mbarrier 230.6 ns = 1.6× native） |
| emulation | `demos/emulation/soft_tx_mbarrier` | HARDWARE_PASS（M4：expect_tx 字节门控闭环——两实验室共同开放缺口的 gfx1030 软替代；5 组 PASS 1.96× plain；clang-24 llvm.assume 删 spin + 软件流水线跨原子重排两个工具链发现） |
| compiler | `demos/compiler/inline_asm_waitcnt` | HARDWARE_PASS + STATIC_ANALYSIS_PASS（IR/ISA 产物在 results/） |
| compiler/DSL | `demos/compiler/opus_dsl_host` | SOURCE_VERIFIED + REFERENCE_PASS（M4：opus DSL 本体首次一等剥离——vendor 单头 opus_host_slice.hpp，slice/索引代数 52 checks；clang-only：`__make_integer_seq`/`__type_pack_element` 内建，g++ 无法解析） |
| compiler/DSL | `demos/compiler/binary_op_dispatch` | SOURCE_VERIFIED + REFERENCE_PASS（M5：二元算子形状分类器 + 实例化矩阵梯 19 checks；非 3-D 中维广播 fallback；2 ops × 3 dtype 对 emitter） |
| hardware | `demos/hardware/lds_passthrough` | HARDWARE_PASS（32 lane 位级；V#/m0/单波约束实测） |
| hardware | `demos/hardware/ds_swizzle_probe` | HARDWARE_PASS（M3：BITMASK_PERM=src(i)^N 实测；gfx1030 编译 wave32 发现——xor32 不可达、shfl_xor 缺省宽度陷阱；builtin 需 union 位 punning 实测） |
| hardware | `demos/hardware/v_dot2_probe` | HARDWARE_PASS（M3：gfx1030 有 v_dot2c_f32_f16 无 bf16 dot2（dot9 独占）；f32 累加模型 1M 步位级精确；dot2=2.0-2.2× fma 实测） |
| hardware | `demos/hardware/sched_group_barrier_probe` | HARDWARE_PASS + STATIC_ANALYSIS_PASS（M3：注解=纯调度提示逐位等价；gfx1030 可用 id 0x8/0x11/0x18/0x28；发现 LLVM 调度器段错误雷区——同 gid 模式安全，与上游用法一致） |
| hardware | `demos/hardware/copy_shape_tuning` | HARDWARE_PASS + PERFORMANCE_MEASURED（M4：拷贝形状扫描——v4×e1 任意块大小 = 494-500 GB/s 上限（shipped 已最优），e2/e4 塌 32-52%、v2/v1 塌 60-76%；L2 驻留假象 + 字节单位陷阱两次实测） |
| runtime | `demos/runtime/jit_cache_minimal` | REFERENCE_PASS（双进程单建造者实证，锚点） |
| runtime | `demos/runtime/cpp_itfs_microframe` | SOURCE_VERIFIED + REFERENCE_PASS（M3：LRUCache/内容寻址命名/dlopen RAII/build-if-missing 编排 21 checks；MD5 RFC 向量钉死；opus --genco 归 compiler 线锚点） |
| algorithm | `demos/algorithm/moe_fused_gate` | REFERENCE_PASS（2343 checks，锚点） |
| algorithm | `demos/algorithm/mxfp4_moe_aux` | SOURCE_VERIFIED + REFERENCE_PASS（M3：6 组 8237 checks；双排序变体互证 + 量化契约 + 隐式 `d_hidden%128` 约束；发现 oracle 一致性≠正确性教训） |
| algorithm | `demos/algorithm/gdr_decode_chain` | SOURCE_VERIFIED + REFERENCE_PASS（M3：5 组 8,470,774 checks；GDR delta-rule 双 schedule + ds_swizzle XOR butterfly + swizzled fp32 state 池 + LDS bank pad；sentinel 策略不对称已钉） |
| algorithm | `demos/algorithm/quickreduce_codec` | SOURCE_VERIFIED + REFERENCE_PASS（M3：Q4/Q3/Q6 位级编解码器 56,855 checks；符号翻转量化设计点 + 真实 tile 布局环回 + 压缩比 3.56×/4.57×/2.46×；IPC communicator 范围排除） |
| algorithm | `demos/algorithm/topk_plain_strategies` | SOURCE_VERIFIED + REFERENCE_PASS（M3：ballot 过滤/分块排序/对折归约策略阶梯 + radix 决策公式 116 checks；输出=集合非顺序契约；过滤安全性论证提炼） |
| algorithm | `demos/algorithm/causal_conv1d_update` | REFERENCE_PASS（M4：Mamba 式滑窗状态机制——两遍守卫式搬移/环形游标/连续批处理 377 checks；双实现互证；x_vals 种子必须内联 pass-2 的承重细节实测） |
| algorithm | `demos/algorithm/dsv4_hadamard_rotate_quant` | REFERENCE_PASS（M4：Hadamard 蝴蝶旋转 vs 显式矩阵 oracle（O(n log n) vs O(n²) 对撞）+ FP4/E8M0 scale 契约（Natural/Flydsl/Opus 布局）+ 能量守恒不变量 741 checks） |
| algorithm | `demos/algorithm/gdn_prefill_fwd_h` | REFERENCE_PASS（M4：分块门控 delta-rule 递推 + 进入态快照链 + 尾部钳制 + 槽间接 49,157 checks；矩阵/逐对双计划互证；g 的 chunk 内重置契约钉死） |
| algorithm | `demos/algorithm/radix_topk_select` | REFERENCE_PASS（M4：fp32 反序 twiddle + 多轮基数选择 + 平局后填规则 + 分档调度阈值 149 checks；key 升序=值降序的反直觉方向实测） |
| algorithm | `demos/algorithm/dsv4_dequant_gather_k` | REFERENCE_PASS（M4：DSV4 分页 K 记录反量化 gather——分支无 fp8×双 bias 256B 穷举 + e8m0 + 分页置换间接 + bf16 透传 779 checks；KV 双向补全） |
| algorithm | `demos/algorithm/gated_rmsnorm_quant` | REFERENCE_PASS（M5：门控 RMSNorm + FP8 组量化——per-head/per-token 两种量化范围 + scale 布局 + 零守卫 + clamp 饱和 484 checks；shfl_xor 蝴蝶的阶段结构教训） |

gpu/ 仍保留：`soft_tma_pipeline.s`（ISA 参照实现，被
`demos/emulation/soft_tma` 消费）与 `toolchain.hip`（编译器接口探针 +
实证发现）；构建走 `gpu/run_gfx1030.sh`。

## gpu/ demos

See `gpu/README.md` (container build line, lineage, measured numbers, and
the round's empirical findings — among them a real `__builtin_amdgcn_raw_ptr_buffer_load_lds`
miscompile on gfx1030/ROCm 7.2 and the single-wave constraint of the
buffer_load→LDS passthrough).

## Not ported (documented scope exclusions)

`topk_plain` radix select, E8M0/MX scale shuffles, `scale_ub`, gfx1250
tuning, multi-block `moe_align` variants, rope thd/2d layouts + backward +
fused variants, varlen/chunk-offset GDN paths, per-k-channel gk decay, the
blob-generation staging machinery of the JIT cache, Windows pid probes.

## Build & test

core/ and design/: pure CPU (C++20, CMake >= 3.16, no dependencies):

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build -j
ctest --test-dir build --output-on-failure
```

gpu/ and demos/: inside the ROCm container only — `gpu/run_gfx1030.sh`
assembles the ISA reference and runs the toolchain probe; each
`demos/*/*/scripts/build_run.sh` builds and runs one demo. Expected output
ends with all-PASS lines (see `gpu/README.md` and per-demo READMEs).

## Rust twin

`../aiter-extract` is the single-threaded Rust extraction of the round-1
modules (same upstream pin, `cargo test`); the round-2 harvest is C++-only
by decision.
