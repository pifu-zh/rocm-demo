#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# CPU-only: any C++20 compiler works (host or container). Saves the run log
# into results/execution.log.
set -euo pipefail
cd "$(dirname "$0")/.."
CXX=${CXX:-g++}
mkdir -p results
$CXX -std=c++20 -O2 -Wall -Wextra src/dsv4_dequant_gather_k.cpp -o dsv4_dequant_gather_k
./dsv4_dequant_gather_k | tee results/execution.log
