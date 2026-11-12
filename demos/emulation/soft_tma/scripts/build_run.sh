#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Build & run the soft_tma demo (inside the ROCm container; host keeps no ROCm).
set -euo pipefail
cd "$(dirname "$0")/.."

HIPCC=${HIPCC:-hipcc}
CLANG=${CLANG:-/opt/rocm-7.2.4/lib/llvm/bin/clang}
ARCH=${ARCH:-gfx1030}
REPO_ROOT=$(cd ../.. && pwd)

echo "=== assemble ISA reference (soft_tma_pipeline.s) ==="
"$CLANG" -x assembler -target amdgcn-amd-amdhsa -mcpu="$ARCH" \
    "$REPO_ROOT/gpu/soft_tma_pipeline.s" -o "$REPO_ROOT/gpu/soft_tma_pipeline.co"

echo "=== build ==="
"$HIPCC" -x hip --offload-arch="$ARCH" -O3 src/main.hip -I include -o soft_tma_demo

echo "=== run (correctness + triad grading + ISA reference) ==="
./soft_tma_demo "$REPO_ROOT/gpu/soft_tma_pipeline.co"
