# CPU-only demo: pure C++20, no HIP/GPU needed (algorithm-category host
# reference). Standalone or wired into the top-level build.
cmake_minimum_required(VERSION 3.16)
project(mla_reduce_warp_contract_demo CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
add_executable(mla_reduce_warp_contract src/mla_reduce_warp_contract.cpp)
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    target_compile_options(mla_reduce_warp_contract PRIVATE -Wall -Wextra)
endif()
enable_testing()
add_test(NAME mla_reduce_warp_contract COMMAND mla_reduce_warp_contract)
