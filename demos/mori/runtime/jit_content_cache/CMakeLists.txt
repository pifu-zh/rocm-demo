cmake_minimum_required(VERSION 3.21)
project(jit_content_cache LANGUAGES CXX)
find_package(HIP REQUIRED)
# host-only C++（mori §3.5：JIT 框架本身构建期不需要 hipcc 设备编译）
add_executable(jit_content_cache src/main.cpp)
target_include_directories(jit_content_cache PRIVATE src)
target_compile_options(jit_content_cache PRIVATE -O2 -std=c++20)
target_link_libraries(jit_content_cache PRIVATE hip::host)
