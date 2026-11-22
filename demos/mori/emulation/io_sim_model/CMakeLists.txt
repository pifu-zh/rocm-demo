cmake_minimum_required(VERSION 3.21)
project(io_sim_model LANGUAGES CXX)
add_executable(io_sim_model src/test_main.cpp)
target_include_directories(io_sim_model PRIVATE src)
target_compile_options(io_sim_model PRIVATE -O2 -std=c++20 -pthread)
target_link_libraries(io_sim_model PRIVATE pthread)

enable_testing()
add_test(NAME io_sim_model COMMAND io_sim_model)
