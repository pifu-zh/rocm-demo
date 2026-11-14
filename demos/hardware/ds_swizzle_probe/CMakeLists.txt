# GPU-only demo (hipcc, inside the ROCm container) — see
# demos/hardware/lds_passthrough/CMakeLists.txt for the gating pattern.
cmake_minimum_required(VERSION 3.16)
project(ds_swizzle_probe_demo NONE)
find_program(HIPCC_EXEC hipcc)
if(NOT HIPCC_EXEC)
    message(STATUS "hipcc not found — ds_swizzle_probe (GPU) demo not wired into this build tree.")
    return()
endif()
add_custom_target(ds_swizzle_probe_demo
    COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/scripts/build_run.sh
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    USES_TERMINAL
    COMMENT "Building and running the ds_swizzle probe via hipcc")
