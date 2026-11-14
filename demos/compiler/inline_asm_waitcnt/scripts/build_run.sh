#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Build, run, and INSPECT the inline-asm vmcnt demo (compiler-feature evidence).
set -euo pipefail
cd "$(dirname "$0")/.."
HIPCC=${HIPCC:-hipcc}
LLVM=${LLVM:-/opt/rocm/lib/llvm/bin}
ARCH=${ARCH:-gfx1030}
mkdir -p results

echo "=== build (-O3) ==="
"$HIPCC" -x hip --offload-arch="$ARCH" -O3 src/main.hip -I include -o partial_drain_probe

echo "=== run (device correctness) ==="
./partial_drain_probe

echo "=== inspection: IR + ISA into results/ ==="
# Under ROCm 10.x hipcc -S/--save-temps emit LLVM IR where 7.x emitted device
# assembly (clang 24 dropped the .s stage and llc), so capture the device IR
# explicitly and run the AMDGPU backend on it — stable across 7.x and 10.x.
"$HIPCC" --cuda-device-only -x hip --offload-arch="$ARCH" -O3 -emit-llvm -c \
    src/main.hip -I include -o /tmp/partial_drain.bc
"$LLVM/clang" -x ir -target amdgcn-amd-amdhsa -mcpu="$ARCH" -O3 -S \
    /tmp/partial_drain.bc -o results/main-hip-amdgcn-amd-amdhsa-gfx1030.s
: > results/artifacts.txt
echo "s_waitcnt occurrences in main-hip-amdgcn-amd-amdhsa-gfx1030.s: $(grep -c s_waitcnt results/main-hip-amdgcn-amd-amdhsa-gfx1030.s)" >> results/artifacts.txt
# llvm-mc negative probe: the vmcnt field encoding on gfx10.3
echo "s_waitcnt vmcnt(4)" | "$LLVM/llvm-mc" -arch=amdgcn -mcpu=gfx1030 -show-encoding \
    > results/vmcnt_encoding.txt 2>&1 || true
cat results/vmcnt_encoding.txt

echo "=== done (see results/) ==="
