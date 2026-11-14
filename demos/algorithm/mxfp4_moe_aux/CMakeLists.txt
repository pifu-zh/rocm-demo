# CPU-only demo: pure C++20, no HIP/GPU needed (algorithm-category host
# reference). Standalone or wired into the top-level build.
cmake_minimum_required(VERSION 3.16)
project(mxfp4_moe_aux_demo CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
add_executable(mxfp4_moe_aux src/mxfp4_moe_aux.cpp)
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    target_compile_options(mxfp4_moe_aux PRIVATE -Wall -Wextra)
endif()

# Three-way E2M1 encoder cross-verification (aiter FlyDSL / cuda-oxide /
# lab) — see tests/e2m1_crosscheck.cpp header for the expected divergence
# classes.
add_executable(e2m1_crosscheck tests/e2m1_crosscheck.cpp)
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    target_compile_options(e2m1_crosscheck PRIVATE -Wall -Wextra)
endif()
enable_testing()
add_test(NAME mxfp4_moe_aux COMMAND mxfp4_moe_aux)
add_test(NAME e2m1_crosscheck COMMAND e2m1_crosscheck)
