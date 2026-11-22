cmake_minimum_required(VERSION 3.21)
project(shmem_p2p_chain LANGUAGES HIP CXX)
find_package(HIP REQUIRED)
add_executable(shmem_p2p_chain src/shmem_p2p_chain.hip)
target_compile_options(shmem_p2p_chain PRIVATE -O2 -std=c++17)

enable_testing()
add_test(NAME shmem_p2p_chain COMMAND ${CMAKE_SOURCE_DIR}/scripts/build_run.sh)
