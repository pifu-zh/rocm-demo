# CPU-only demo: pure C++20, no HIP/GPU needed (algorithm-category host
# reference). Standalone or wired into the top-level build.
cmake_minimum_required(VERSION 3.16)
project(causal_conv1d_update_demo CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
add_executable(causal_conv1d_update src/causal_conv1d_update.cpp)
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    target_compile_options(causal_conv1d_update PRIVATE -Wall -Wextra)
endif()
enable_testing()
add_test(NAME causal_conv1d_update COMMAND causal_conv1d_update)
