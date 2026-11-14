#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Host unit tests for opus's device-independent half. CLANG-ONLY: opus.hpp
# uses the __make_integer_seq / __type_pack_element compiler intrinsics
# (clang builtins); g++ cannot parse it.
set -euo pipefail
cd "$(dirname "$0")/.."
CLANGXX=${CLANGXX:-/opt/rocm/lib/llvm/bin/clang++}
mkdir -p results
"$CLANGXX" -std=c++20 -O2 -I. -Ivendor src/main.cpp -o opus_test
./opus_test | tee results/execution.log
