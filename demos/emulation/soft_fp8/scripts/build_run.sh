#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail
cd "$(dirname "$0")/.."
HIPCC=${HIPCC:-hipcc}
ARCH=${ARCH:-gfx1030}
"$HIPCC" -x hip --offload-arch="$ARCH" -O3 src/main.hip -I include -o soft_fp8_demo
./soft_fp8_demo
