#!/bin/bash
# RAS 心跳复现（纯 CPU，宿主无编译器 → 容器内构建；时序可缩放 env 见下）
set -e -o pipefail
HERE=$(cd "$(dirname "$0")/.." && pwd)
RES="$HERE/results"
cmake -S "$HERE" -B "$HERE/build" -DCMAKE_BUILD_TYPE=Release -G Ninja > "$RES/build.log" 2>&1
cmake --build "$HERE/build" >> "$RES/build.log" 2>&1
# 短时序（上游默认 heartbeat=1000ms/timeout=max(20s,3×hb)/peerGone=60s 对测试过长；
# MORI_LAB_RAS_* 环境变量与上游 MORI_RAS_* 的缩放精神一致）
MORI_LAB_RAS_HEARTBEAT_MS=100 MORI_LAB_RAS_TIMEOUT_MS=300 MORI_LAB_RAS_PEER_GONE_MS=2000 \
  "$HERE/build/ras_heartbeat" | tee "$RES/run_cpu.log"
