#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# CPU-only: any C++20 compiler works (host or container). Saves the run log
# into results/execution.log.
set -euo pipefail
cd "$(dirname "$0")/.."
CXX=${CXX:-g++}
mkdir -p results
$CXX -std=c++20 -O2 -Wall -Wextra src/causal_conv1d_fwd_split_qkv.cpp -o causal_conv1d_fwd_split_qkv
./causal_conv1d_fwd_split_qkv | tee results/execution.log
