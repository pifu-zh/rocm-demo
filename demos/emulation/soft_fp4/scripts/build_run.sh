#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail
cd "$(dirname "$0")/.."
HIPCC=${HIPCC:-hipcc}
ARCH=${ARCH:-gfx1030}
# Lab-shared codec: E2M1 lives in demos/emulation/soft_fp8/include (dependency
# recorded in docs/DEPENDENCY_GRAPH.md).
"$HIPCC" -x hip --offload-arch="$ARCH" -O3 src/main.hip \
    -I include -I ../soft_fp8/include -o soft_fp4_demo
./soft_fp4_demo
