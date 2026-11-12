# GPU-only demo: NOT part of the top-level CPU build. This CMakeLists exists
# to satisfy the lab's per-demo build standard; the actual toolchain is hipcc
# (inside the ROCm container). Configure with -DENABLE_GPU_DEMOS=ON on a
# ROCm-enabled host to wire it in.
cmake_minimum_required(VERSION 3.16)
project(soft_tma_demo NONE)

find_program(HIPCC_EXEC hipcc)
if(NOT HIPCC_EXEC)
    message(STATUS "hipcc not found — soft_tma (GPU) demo not wired into this build tree. "
                   "Use scripts/build_run.sh inside the ROCm container.")
    return()
endif()

add_custom_target(soft_tma_demo
    COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/scripts/build_run.sh
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    USES_TERMINAL
    COMMENT "Building and running the soft_tma GPU demo via hipcc")
