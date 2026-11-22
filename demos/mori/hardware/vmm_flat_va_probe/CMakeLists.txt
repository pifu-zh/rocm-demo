cmake_minimum_required(VERSION 3.21)
project(vmm_flat_va_probe LANGUAGES CXX)
find_package(HIP REQUIRED)
add_executable(vmm_flat_va_probe src/vmm_flat_va_probe.cpp)
target_compile_options(vmm_flat_va_probe PRIVATE -O2 -std=c++17)
target_link_libraries(vmm_flat_va_probe PRIVATE hip::host)

enable_testing()
add_test(NAME vmm_flat_va_probe COMMAND vmm_flat_va_probe)
