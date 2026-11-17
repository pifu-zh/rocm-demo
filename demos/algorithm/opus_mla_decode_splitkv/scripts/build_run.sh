#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
CXX=${CXX:-g++}
mkdir -p results
$CXX -std=c++20 -O2 -Wall -Wextra src/opus_mla_decode_splitkv.cpp -o opus_mla_decode_splitkv
./opus_mla_decode_splitkv | tee results/execution.log
