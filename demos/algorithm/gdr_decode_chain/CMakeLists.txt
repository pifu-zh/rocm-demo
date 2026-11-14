# CPU-only demo: pure C++20, no HIP/GPU needed (algorithm-category host
# reference). Standalone or wired into the top-level build.
cmake_minimum_required(VERSION 3.16)
project(gdr_decode_chain_demo CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
add_executable(gdr_decode_chain src/gdr_decode_chain.cpp)
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    target_compile_options(gdr_decode_chain PRIVATE -Wall -Wextra)
endif()
enable_testing()
add_test(NAME gdr_decode_chain COMMAND gdr_decode_chain)
