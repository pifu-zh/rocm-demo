# CPU-only demo: pure C++20, no HIP/GPU needed (algorithm-category host
# reference). Standalone or wired into the top-level build.
cmake_minimum_required(VERSION 3.16)
project(opus_mla_decode_splitkv_demo CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
add_executable(opus_mla_decode_splitkv src/opus_mla_decode_splitkv.cpp)
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    target_compile_options(opus_mla_decode_splitkv PRIVATE -Wall -Wextra)
endif()
enable_testing()
add_test(NAME opus_mla_decode_splitkv COMMAND opus_mla_decode_splitkv)
