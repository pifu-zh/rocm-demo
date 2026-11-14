# CPU-only demo: pure C++20, no HIP/GPU needed (algorithm-category host
# reference). Standalone or wired into the top-level build.
cmake_minimum_required(VERSION 3.16)
project(dsv4_dequant_gather_k_demo CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
add_executable(dsv4_dequant_gather_k src/dsv4_dequant_gather_k.cpp)
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    target_compile_options(dsv4_dequant_gather_k PRIVATE -Wall -Wextra)
endif()
enable_testing()
add_test(NAME dsv4_dequant_gather_k COMMAND dsv4_dequant_gather_k)
