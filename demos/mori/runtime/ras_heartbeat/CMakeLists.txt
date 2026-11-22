cmake_minimum_required(VERSION 3.21)
project(ras_heartbeat LANGUAGES CXX)
add_executable(ras_heartbeat src/ras_heartbeat.cpp)
target_compile_options(ras_heartbeat PRIVATE -O2 -std=c++20 -pthread)
target_link_libraries(ras_heartbeat PRIVATE pthread)

enable_testing()
add_test(NAME ras_heartbeat COMMAND ras_heartbeat)
