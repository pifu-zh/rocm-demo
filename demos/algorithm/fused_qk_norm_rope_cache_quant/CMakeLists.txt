# CPU-only demo: pure C++20, no HIP/GPU needed (algorithm-category host
# reference). Standalone or wired into the top-level build.
cmake_minimum_required(VERSION 3.16)
project(fused_qk_norm_rope_cache_quant_demo CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
add_executable(fused_qk_norm_rope_cache_quant src/fused_qk_norm_rope_cache_quant.cpp)
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    target_compile_options(fused_qk_norm_rope_cache_quant PRIVATE -Wall -Wextra)
endif()
enable_testing()
add_test(NAME fused_qk_norm_rope_cache_quant COMMAND fused_qk_norm_rope_cache_quant)
