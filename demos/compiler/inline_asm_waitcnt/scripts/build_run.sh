#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Build, run, and INSPECT the inline-asm vmcnt demo (compiler-feature evidence).
set -euo pipefail
cd "$(dirname "$0")/.."
HIPCC=${HIPCC:-hipcc}
LLVM=/opt/rocm-7.2.4/lib/llvm/bin
ARCH=${ARCH:-gfx1030}
mkdir -p results

echo "=== build (-O3) ==="
"$HIPCC" -x hip --offload-arch="$ARCH" -O3 src/main.hip -I include -o partial_drain_probe

echo "=== run (device correctness) ==="
./partial_drain_probe

echo "=== inspection: IR + ISA into results/ ==="
"$HIPCC" -x hip --offload-arch="$ARCH" -O3 --save-temps -S src/main.hip -o /dev/null 2>/dev/null || true
# save-temps leaves host+device artifacts beside the source
for f in main-hip-amdgcn-*.s main-hip-*.ll; do
    [ -f "$f" ] || continue
    cp "$f" results/
    echo "s_waitcnt occurrences in $f: $(grep -c s_waitcnt "$f")" >> results/artifacts.txt
done
# llvm-mc negative probe: the vmcnt field encoding on gfx10.3
echo "s_waitcnt vmcnt(4)" | "$LLVM/llvm-mc" -arch=amdgcn -mcpu=gfx1030 -show-encoding \
    > results/vmcnt_encoding.txt 2>&1 || true
cat results/vmcnt_encoding.txt

echo "=== done (see results/) ==="
