cmake_minimum_required(VERSION 3.21)
project(sdma5_copy_experiment LANGUAGES HIP CXX)
find_package(HIP REQUIRED)
add_executable(sdma5_copy_experiment src/sdma5_copy_experiment.hip)
target_include_directories(sdma5_copy_experiment PRIVATE /opt/rocm/core-10.1/include)
target_link_libraries(sdma5_copy_experiment PRIVATE
  /opt/rocm/lib/libhsakmt.a
  /opt/rocm/core-10.1/lib/rocm_sysdeps/lib/libdrm_amdgpu.so
  /opt/rocm/core-10.1/lib/rocm_sysdeps/lib/librocm_sysdeps_drm.so.2
  /usr/lib/x86_64-linux-gnu/libnuma.so.1 pthread rt)
target_compile_options(sdma5_copy_experiment PRIVATE -O2)
