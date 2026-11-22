cmake_minimum_required(VERSION 3.21)
project(p2p_cas_atomic LANGUAGES HIP CXX)
find_package(HIP REQUIRED)
add_executable(p2p_cas_atomic src/p2p_cas_atomic.hip)
target_compile_options(p2p_cas_atomic PRIVATE -O2)

enable_testing()
add_test(NAME p2p_cas_atomic COMMAND p2p_cas_atomic)
