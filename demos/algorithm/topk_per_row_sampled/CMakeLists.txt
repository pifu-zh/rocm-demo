# CPU-only demo: pure C++20, no HIP/GPU needed (algorithm-category host
# reference). Standalone or wired into the top-level build.
cmake_minimum_required(VERSION 3.16)
project(topk_per_row_sampled_demo CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
add_executable(topk_per_row_sampled src/topk_per_row_sampled.cpp)
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    target_compile_options(topk_per_row_sampled PRIVATE -Wall -Wextra)
endif()
enable_testing()
add_test(NAME topk_per_row_sampled COMMAND topk_per_row_sampled)
