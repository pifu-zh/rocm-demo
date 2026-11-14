#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail
cd "$(dirname "$0")/.."
HIPCC=${HIPCC:-hipcc}
CLANG=${CLANG:-/opt/rocm/lib/llvm/bin/clang}
ARCH=${ARCH:-gfx1030}
"$CLANG" -x assembler -target amdgcn-amd-amdhsa -mcpu="$ARCH" \
    src/lds_probe_pipeline.s -o lds_probe.co
"$HIPCC" -x hip --offload-arch="$ARCH" -O3 src/main.hip -o lds_passthrough
./lds_passthrough lds_probe.co
