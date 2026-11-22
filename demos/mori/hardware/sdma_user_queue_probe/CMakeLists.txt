cmake_minimum_required(VERSION 3.21)
project(sdma_user_queue_probe LANGUAGES C)
add_executable(sdma_user_queue_probe src/sdma_user_queue_probe.c)
target_include_directories(sdma_user_queue_probe PRIVATE /opt/rocm/core-10.1/include)
target_link_libraries(sdma_user_queue_probe PRIVATE /opt/rocm/lib/libhsakmt.a /opt/rocm/core-10.1/lib/rocm_sysdeps/lib/libdrm_amdgpu.so /opt/rocm/core-10.1/lib/rocm_sysdeps/lib/librocm_sysdeps_drm.so.2 pthread rt /usr/lib/x86_64-linux-gnu/libnuma.so.1)

enable_testing()
add_test(NAME sdma_user_queue_probe COMMAND sdma_user_queue_probe)
