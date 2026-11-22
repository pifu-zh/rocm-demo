cmake_minimum_required(VERSION 3.21)
project(ll128_wire_format LANGUAGES CXX)
add_executable(ll128_wire_format src/ll128_wire_format.cpp)
target_compile_options(ll128_wire_format PRIVATE -O2 -std=c++20)
