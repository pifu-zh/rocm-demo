# CPU-only demo: pure C++20, no HIP/GPU needed (algorithm-category host
# reference). Standalone or wired into the top-level build.
cmake_minimum_required(VERSION 3.16)
project(gdn_prefill_fwd_h_demo CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
add_executable(gdn_prefill_fwd_h src/gdn_prefill_fwd_h.cpp)
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    target_compile_options(gdn_prefill_fwd_h PRIVATE -Wall -Wextra)
endif()
enable_testing()
add_test(NAME gdn_prefill_fwd_h COMMAND gdn_prefill_fwd_h)
