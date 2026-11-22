#!/bin/bash
# 纯 CPU demo：宿主无编译器 → 容器内构建（无 HIP 设备参与）
set -e -o pipefail
HERE=$(cd "$(dirname "$0")/.." && pwd)
RES="$HERE/results"
cmake -S "$HERE" -B "$HERE/build" -DCMAKE_BUILD_TYPE=Release -G Ninja > "$RES/build.log" 2>&1
cmake --build "$HERE/build" >> "$RES/build.log" 2>&1
"$HERE/build/io_sim_model" | tee "$RES/run_cpu.log"
