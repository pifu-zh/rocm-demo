#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Build and run the V_DOT2 probe on the gfx1030 card (ROCm container).
set -euo pipefail
cd "$(dirname "$0")/.."
HIPCC=${HIPCC:-hipcc}
ARCH=${ARCH:-gfx1030}
mkdir -p results
"$HIPCC" -x hip --offload-arch="$ARCH" -O3 src/main.hip -o v_dot2_probe
./v_dot2_probe | tee results/execution.log
