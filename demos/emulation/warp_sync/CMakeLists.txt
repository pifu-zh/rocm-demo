# GPU-only demo (hipcc, inside the ROCm container) — see demos/emulation/soft_tma/CMakeLists.txt
cmake_minimum_required(VERSION 3.16)
project(warp_sync_demo NONE)
find_program(HIPCC_EXEC hipcc)
if(NOT HIPCC_EXEC)
    message(STATUS "hipcc not found — warp_sync (GPU) demo not wired into this build tree.")
    return()
endif()
add_custom_target(warp_sync_demo
    COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/scripts/build_run.sh
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    USES_TERMINAL
    COMMENT "Building and running the warp_sync GPU demo via hipcc")
