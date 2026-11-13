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
| compiler | `demos/compiler/inline_asm_waitcnt` | HARDWARE_PASS + STATIC_ANALYSIS_PASS（IR/ISA 产物在 results/） |
| hardware | `demos/hardware/lds_passthrough` | HARDWARE_PASS（32 lane 位级；V#/m0/单波约束实测） |
| runtime | `demos/runtime/jit_cache_minimal` | REFERENCE_PASS（双进程单建造者实证，锚点） |
| algorithm | `demos/algorithm/moe_fused_gate` | REFERENCE_PASS（2343 checks，锚点） |

gpu/ 仍保留：`soft_tma_pipeline.s`（ISA 参照实现）与 `toolchain.hip`
（编译器接口探针 + 实证发现）；对应 cmake 顶层测试照旧。

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

gpu/: inside the ROCm container only — `gpu/run_gfx1030.sh` builds and runs
all four demos; expected output ends with all-PASS lines (see
`gpu/README.md`).

## Rust twin

`../aiter-extract` is the single-threaded Rust extraction of the round-1
modules (same upstream pin, `cargo test`); the round-2 harvest is C++-only
by decision.
