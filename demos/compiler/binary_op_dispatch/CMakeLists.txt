# CPU-only demo: pure C++20, no HIP/GPU needed (compiler/DSL-category host
# reference). Standalone or wired into the top-level build.
cmake_minimum_required(VERSION 3.16)
project(binary_op_dispatch_demo CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
add_executable(binary_op_dispatch src/binary_op_dispatch.cpp)
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    target_compile_options(binary_op_dispatch PRIVATE -Wall -Wextra)
endif()
enable_testing()
add_test(NAME binary_op_dispatch COMMAND binary_op_dispatch)
