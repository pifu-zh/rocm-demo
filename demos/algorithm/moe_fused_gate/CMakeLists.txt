# Reference demo: reuses the shared aiter_ref library built by the top-level
# CMakeLists (dependency recorded — see docs/DEPENDENCY_GRAPH.md §4). The
# technique entry and test are the same as the top-level `moe_fused_gate`
# ctest; this directory is the lab-catalog anchor for the algorithm category.
cmake_minimum_required(VERSION 3.16)
project(moe_fused_gate_demo NONE)
message(STATUS "moe_fused_gate: implemented in the top-level aiter_ref build "
               "(ctest -R moe_fused_gate); this anchor documents the "
               "algorithm-category demo. See README.md.")
