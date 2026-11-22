#!/bin/bash
set -e
HERE=$(cd "$(dirname "$0")/.." && pwd)
RES="$HERE/results"
cmake -S "$HERE" -B "$HERE/build" -DCMAKE_BUILD_TYPE=Release -G Ninja > "$RES/build.log" 2>&1
cmake --build "$HERE/build" >> "$RES/build.log" 2>&1
"$HERE/build/proxy_ring_publish_order" | tee "$RES/run_gfx1030.log"
