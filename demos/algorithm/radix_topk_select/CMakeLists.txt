# CPU-only demo: pure C++20, no HIP/GPU needed (algorithm-category host
# reference). Standalone or wired into the top-level build.
cmake_minimum_required(VERSION 3.16)
project(radix_topk_select_demo CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
add_executable(radix_topk_select src/radix_topk_select.cpp)
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    target_compile_options(radix_topk_select PRIVATE -Wall -Wextra)
endif()
enable_testing()
add_test(NAME radix_topk_select COMMAND radix_topk_select)
