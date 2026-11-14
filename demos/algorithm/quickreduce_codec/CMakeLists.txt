# CPU-only demo: pure C++20, no HIP/GPU needed (algorithm-category host
# reference). Standalone or wired into the top-level build.
cmake_minimum_required(VERSION 3.16)
project(quickreduce_codec_demo CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
add_executable(quickreduce_codec src/quickreduce_codec.cpp)
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    target_compile_options(quickreduce_codec PRIVATE -Wall -Wextra)
endif()
enable_testing()
add_test(NAME quickreduce_codec COMMAND quickreduce_codec)
