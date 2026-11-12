#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Build & run every gpu/ demo on gfx1030. Run INSIDE the ROCm container
# (host machines in this lab keep no ROCm):
#   docker start gfx-m1   # or: docker run --device=/dev/kfd --device=/dev/dri ...
#   docker exec gfx-m1 bash /home/zhuo/workspace/src/rocm-demo/gpu/run_gfx1030.sh
set -euo pipefail
cd "$(dirname "$0")"

HIPCC=${HIPCC:-hipcc}
CLANG=${CLANG:-/opt/rocm-7.2.4/lib/llvm/bin/clang}
ARCH=${ARCH:-gfx1030}

echo "=== assemble soft_tma_pipeline.s -> .co ==="
"$CLANG" -x assembler -target amdgcn-amd-amdhsa -mcpu="$ARCH" \
    soft_tma_pipeline.s -o soft_tma_pipeline.co

echo "=== soft_fp8 ==="
"$HIPCC" -x hip --offload-arch="$ARCH" soft_fp8.hip -o soft_fp8
./soft_fp8

echo "=== soft_fp4 ==="
"$HIPCC" -x hip --offload-arch="$ARCH" soft_fp4.hip -o soft_fp4
./soft_fp4

echo "=== soft_tma (ISA pipeline + plain baseline) ==="
"$HIPCC" -x hip --offload-arch="$ARCH" soft_tma.hip -o soft_tma
./soft_tma soft_tma_pipeline.co

echo "=== toolchain (hipRTC + builtins + ISA passthrough) ==="
"$HIPCC" -x hip --offload-arch="$ARCH" toolchain.hip -o toolchain -lhiprtc
./toolchain soft_tma_pipeline.co

echo "=== all gpu demos done ==="
