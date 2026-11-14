# GPU-only demo (hipcc, inside the ROCm container) — see
# demos/hardware/lds_passthrough/CMakeLists.txt for the gating pattern.
cmake_minimum_required(VERSION 3.16)
project(sched_group_barrier_probe_demo NONE)
find_program(HIPCC_EXEC hipcc)
if(NOT HIPCC_EXEC)
    message(STATUS "hipcc not found — sched_group_barrier_probe (GPU) demo not wired.")
    return()
endif()
add_custom_target(sched_group_barrier_probe_demo
    COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/scripts/build_run.sh
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    USES_TERMINAL
    COMMENT "Building and running the sched_group_barrier probe via hipcc")
