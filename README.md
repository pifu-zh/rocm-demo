# rocm-demo

CPU reference implementations of algorithm cores extracted from
[ROCm/aiter](https://github.com/ROCm/aiter) — the parts of an inference
operator library that are pure index/float logic with no CDNA-specific
hardware dependency, pinned as deterministic host code with unit tests.

Part of the cuda-oxide adapt-rocm research line (Rust GPU toolchain on
RX 6950 XT / gfx1030, RDNA2). aiter's data-movement line (soft TMA:
`s_clause` batching + `vmcnt(N)` partial-drain software pipelining) was
already extracted and closed elsewhere; this repo harvests the next line:
the **MoE scheduling chain** and **per-token-group quantization**. These
make good GPU-port candidates on gfx1030 — histogram / prefix-scan /
scatter exercise atomics, LDS and scans — and the unit tests here are the
host-side independent reference such ports need.

## Layout

- `include/aiter_ref/`, `src/`, `tests/` — the C++ reference library
  (`aiter_ref`) and its unit tests, built and run by CMake/CTest.

| Module | Upstream source (aiter @ 1eab5ae12) | License |
|---|---|---|
| `moe_align` | `csrc/kernels/moe_align_block_size_kernels.cu` | Apache-2.0 (© AMD, © vLLM team) |
| `topk_softmax` | `csrc/kernels/topk_softmax_kernels.cu` (`moeSoftmax`+`moeTopK`), `csrc/include/hip_reduce.h` | MIT (© AMD) |
| `group_quant` | `csrc/kernels/quant_kernels.cu` (continuous fp32-scale path), `csrc/include/quant_amax_floor.h` | MIT (© AMD) |
| `fp8` | cuda-oxide `crates/cuda-device/src/fp8.rs` (on-card-validated codec) | Apache-2.0 (© NVIDIA) |

New glue code (tests, harness, build files): Apache-2.0. Upstream licenses
are preserved per file (`LICENSES/MIT.txt` for the MIT files).

## Semantics pinned by the tests

- **`moe_align`**: histogram → block-count prefix sum → per-block metadata
  (`token_nums` counts down by `block_size`) → scatter. On the device the
  scatter uses `atomicAdd` cursors, so per-expert token order is
  nondeterministic; this port is ascending-deterministic. On-card ports
  must be compared per-segment as multisets, never element-wise.
- **`topk_softmax`**: stable softmax; iterative-argmax top-k with
  lower-expert-index tie-break; optional renorm (skipped on exactly-zero
  sum); out-of-range experts report the sentinel `num_experts`. Pinned
  upstream quirk: for `start_expert > 0` the exclusion loop compares stored
  local ids against global indices, so nothing is excluded — one expert can
  fill every slot (see the quirk test). Other kernel variants in the same
  upstream file were not checked.
- **`group_quant`**: `amax = max(1e-10, max |x|)`, `scale = amax / qmax`
  stored as the dequant scale, quantize via the float reciprocal with
  round-to-nearest-even + clamp (fp8 saturates `.satfinite`). fp8
  quantization is verified against a brute-force 256-way nearest-value
  reference, including the sign-preserving ±0 tie.
- **`fp8`**: E4M3FN codec (no infinities, `0x7F`/`0xFF` = NaN, max finite
  448), 256/256 byte round trip + boundary/tie checks.

## Not ported (documented scope exclusions)

Grouped/biased routing (`moe_fused_gate.cu`), radix `topk_plain`, E8M0 (MX)
byte scales, `scale_ub`, hadamard32 rotate, scale layout shuffles, gfx1250
tuning, pad-row/`finished` handling, multi-block `moe_align` variants (the
upstream single-block launch caps `num_experts <= 1024`).

## Build & test

Pure CPU: no GPU, no ROCm/HIP, no external dependencies (C++20,
CMake >= 3.16).

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build -j
ctest --test-dir build --output-on-failure
```

## Upstream pin

aiter shallow clone of `1eab5ae12c93af3c8c660202d9a413f637c2f011`
(2026-11-09). aiter's MIT license text: `LICENSES/MIT.txt`.
