cmake_minimum_required(VERSION 3.21)
project(nttp_cfg_specialization LANGUAGES HIP CXX)
find_package(HIP REQUIRED)
add_executable(nttp_cfg_specialization src/nttp_cfg_specialization.hip)
target_compile_options(nttp_cfg_specialization PRIVATE -O2 -std=c++20)

enable_testing()
add_test(NAME nttp_cfg_specialization COMMAND nttp_cfg_specialization)
