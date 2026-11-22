cmake_minimum_required(VERSION 3.21)
project(dispatch_merged_reserve LANGUAGES HIP CXX)
find_package(HIP REQUIRED)
add_executable(dispatch_merged_reserve src/dispatch_merged_reserve.hip)
target_compile_options(dispatch_merged_reserve PRIVATE -O2)

enable_testing()
add_test(NAME dispatch_merged_reserve COMMAND dispatch_merged_reserve)
