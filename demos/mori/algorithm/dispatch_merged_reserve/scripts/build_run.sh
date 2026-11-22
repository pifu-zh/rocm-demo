#!/bin/bash
# 构建+运行（在 ROCm 容器内执行；gfx1030）
set -e
HERE=$(cd "$(dirname "$0")/.." && pwd)
cmake -S "$HERE" -B "$HERE/build" -DCMAKE_BUILD_TYPE=Release -G Ninja > "$HERE/results/build.log" 2>&1
cmake --build "$HERE/build" >> "$HERE/results/build.log" 2>&1
"$HERE/build/dispatch_merged_reserve" | tee "$HERE/results/run_gfx1030.log"
