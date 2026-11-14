#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Assemble the ISA reference and run the toolchain probe on gfx1030.
# The soft fp8/fp4/tma demos moved to demos/emulation/<name>/scripts/build_run.sh.
# Run INSIDE the ROCm container (host machines in this lab keep no ROCm):
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

echo "=== toolchain (hipRTC + builtins + ISA passthrough) ==="
"$HIPCC" -x hip --offload-arch="$ARCH" toolchain.hip -o toolchain -lhiprtc
./toolchain soft_tma_pipeline.co

echo "=== gpu/ done (soft fp8/fp4/tma demos live in demos/emulation/) ==="
