cmake_minimum_required(VERSION 3.21)
project(umbp_sim_model LANGUAGES CXX)
add_executable(umbp_sim_model src/test_main.cpp)
target_include_directories(umbp_sim_model PRIVATE src)
target_compile_options(umbp_sim_model PRIVATE -O2 -std=c++20)

enable_testing()
add_test(NAME umbp_sim_model COMMAND umbp_sim_model)
