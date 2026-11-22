#!/bin/bash
# 内容寻址 JIT 缓存 demo：构建 + 全链路运行 + 自测（容器内，CWD=demo 根目录）
set -e -o pipefail
HERE=$(cd "$(dirname "$0")/.." && pwd)
RES="$HERE/results"
cmake -S "$HERE" -B "$HERE/build" -DCMAKE_BUILD_TYPE=Release -G Ninja > "$RES/build.log" 2>&1
cmake --build "$HERE/build" >> "$RES/build.log" 2>&1
cd "$HERE"
rm -rf "$HERE/jit_cache_results/cache"
"$HERE/build/jit_content_cache" run      | tee "$RES/run_gfx1030.log"
"$HERE/build/jit_content_cache" selftest | tee "$RES/selftest.log"
