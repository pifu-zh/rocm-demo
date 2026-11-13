# GPU-only demo (hipcc + clang assembler, inside the ROCm container) — see
# demos/emulation/soft_tma/CMakeLists.txt for the gating pattern.
cmake_minimum_required(VERSION 3.16)
project(lds_passthrough_demo NONE)
find_program(HIPCC_EXEC hipcc)
if(NOT HIPCC_EXEC)
    message(STATUS "hipcc not found — lds_passthrough (GPU) demo not wired into this build tree.")
    return()
endif()
add_custom_target(lds_passthrough_demo
    COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/scripts/build_run.sh
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    USES_TERMINAL
    COMMENT "Building and running the lds_passthrough GPU demo")
