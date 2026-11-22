cmake_minimum_required(VERSION 3.21)
project(lsa_flat_va LANGUAGES HIP CXX)
find_package(HIP REQUIRED)
add_executable(lsa_flat_va src/lsa_flat_va.hip)
target_compile_options(lsa_flat_va PRIVATE -O2)

enable_testing()
add_test(NAME lsa_flat_va COMMAND lsa_flat_va)
