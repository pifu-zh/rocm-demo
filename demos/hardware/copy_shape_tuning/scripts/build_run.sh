#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Build and run the copy-shape tuning sweep on the gfx1030 card.
set -euo pipefail
cd "$(dirname "$0")/.."
HIPCC=${HIPCC:-hipcc}
ARCH=${ARCH:-gfx1030}
mkdir -p results
"$HIPCC" -x hip --offload-arch="$ARCH" -O3 src/main.hip -o copy_tune
./copy_tune | tee results/execution.log
