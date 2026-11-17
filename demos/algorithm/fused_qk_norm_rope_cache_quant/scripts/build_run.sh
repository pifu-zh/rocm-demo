#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# CPU-only: any C++20 compiler works (host or container). Saves the run log
# into results/execution.log.
set -euo pipefail
cd "$(dirname "$0")/.."
CXX=${CXX:-g++}
mkdir -p results
$CXX -std=c++20 -O2 -Wall -Wextra src/fused_qk_norm_rope_cache_quant.cpp -o fused_qk_norm_rope_cache_quant
./fused_qk_norm_rope_cache_quant | tee results/execution.log
