# CPU-only demo: pure C++20 (POSIX dlopen), no HIP/GPU needed (runtime-
# category host reference). Standalone or wired into the top-level build.
cmake_minimum_required(VERSION 3.16)
project(cpp_itfs_microframe_demo CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
add_executable(cpp_itfs_microframe src/cpp_itfs_microframe.cpp)
target_link_libraries(cpp_itfs_microframe PRIVATE ${CMAKE_DL_LIBS} pthread)
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    target_compile_options(cpp_itfs_microframe PRIVATE -Wall -Wextra)
endif()
enable_testing()
add_test(NAME cpp_itfs_microframe COMMAND cpp_itfs_microframe)
