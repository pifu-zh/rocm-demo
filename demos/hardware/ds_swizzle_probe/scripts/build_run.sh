#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Build and run the ds_swizzle BITMASK_PERM probe on the gfx1030 card
# (inside the ROCm container). Saves the run log into results/.
set -euo pipefail
cd "$(dirname "$0")/.."
HIPCC=${HIPCC:-hipcc}
ARCH=${ARCH:-gfx1030}
mkdir -p results
"$HIPCC" -x hip --offload-arch="$ARCH" -O3 src/main.hip -o ds_swizzle_probe
./ds_swizzle_probe | tee results/execution.log
