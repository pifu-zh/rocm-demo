# CPU-only demo: pure C++20, no HIP/GPU needed (algorithm-category host
# reference). Standalone or wired into the top-level build.
cmake_minimum_required(VERSION 3.16)
project(concat_and_cache_mla_seg_demo CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
add_executable(concat_and_cache_mla_seg src/concat_and_cache_mla_seg.cpp)
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    target_compile_options(concat_and_cache_mla_seg PRIVATE -Wall -Wextra)
endif()
enable_testing()
add_test(NAME concat_and_cache_mla_seg COMMAND concat_and_cache_mla_seg)
