cmake_minimum_required(VERSION 3.21)
project(ipc_symmetric_heap LANGUAGES HIP CXX)
find_package(HIP REQUIRED)
add_executable(ipc_symmetric_heap src/ipc_symmetric_heap.hip)
target_compile_options(ipc_symmetric_heap PRIVATE -O2 -std=c++17)
target_link_libraries(ipc_symmetric_heap PRIVATE hip::host)

enable_testing()
add_test(NAME ipc_symmetric_heap COMMAND ipc_symmetric_heap)
