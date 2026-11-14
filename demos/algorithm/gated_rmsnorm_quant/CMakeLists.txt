# CPU-only demo: pure C++20, no HIP/GPU needed (algorithm-category host
# reference). Standalone or wired into the top-level build.
cmake_minimum_required(VERSION 3.16)
project(gated_rmsnorm_quant_demo CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
add_executable(gated_rmsnorm_quant src/gated_rmsnorm_quant.cpp)
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    target_compile_options(gated_rmsnorm_quant PRIVATE -Wall -Wextra)
endif()
enable_testing()
add_test(NAME gated_rmsnorm_quant COMMAND gated_rmsnorm_quant)
