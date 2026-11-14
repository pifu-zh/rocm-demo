# Host-unit-test demo for opus's device-independent half.
# CLANG-ONLY: opus.hpp uses clang intrinsics (__make_integer_seq,
# __type_pack_element) that g++ cannot parse; the build skips with a note
# when clang++ is not found.
cmake_minimum_required(VERSION 3.16)
find_program(CLANGXX_EXEC clang++ HINTS /opt/rocm/lib/llvm/bin /opt/rocm/bin)
if(NOT CLANGXX_EXEC)
    message(STATUS "clang++ not found — opus_dsl_host demo skipped (clang-only; "
                   "opus.hpp uses __make_integer_seq/__type_pack_element).")
    return()
endif()
set(CMAKE_CXX_COMPILER ${CLANGXX_EXEC})
project(opus_dsl_host_demo CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
add_executable(opus_test src/main.cpp)
target_include_directories(opus_test PRIVATE ${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/vendor)
target_compile_options(opus_test PRIVATE -Wall -Wextra)
enable_testing()
add_test(NAME opus_dsl_host COMMAND opus_test)
