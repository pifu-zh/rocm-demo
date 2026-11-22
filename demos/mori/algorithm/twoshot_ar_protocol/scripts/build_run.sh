#!/bin/bash
# 双进程: rank0 后台监听，rank1 连接
set -e -o pipefail
HERE=$(cd "$(dirname "$0")/.." && pwd)
RES="$HERE/results"
cmake -S "$HERE" -B "$HERE/build" -DCMAKE_BUILD_TYPE=Release -G Ninja > "$RES/build.log" 2>&1
cmake --build "$HERE/build" >> "$RES/build.log" 2>&1
PORT=$((20000 + RANDOM % 20000))
timeout 60 "$HERE/build/twoshot_ar_protocol" 0 $PORT > "$RES/rank0.log" 2>&1 &
R0=$!
sleep 1
timeout 60 "$HERE/build/twoshot_ar_protocol" 1 $PORT > "$RES/rank1.log" 2>&1 &
R1=$!
wait $R0; RC0=$?
wait $R1; RC1=$?
echo "rank0_rc=$RC0 rank1_rc=$RC1" | tee "$RES/run_gfx1030.log"
cat "$RES/rank0.log" "$RES/rank1.log" | tee -a "$RES/run_gfx1030.log"
[ $RC0 -eq 0 ] && [ $RC1 -eq 0 ]
