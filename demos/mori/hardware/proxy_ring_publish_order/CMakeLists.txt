cmake_minimum_required(VERSION 3.21)
project(proxy_ring_publish_order LANGUAGES HIP CXX)
find_package(HIP REQUIRED)
add_executable(proxy_ring_publish_order src/proxy_ring_publish_order.hip)
target_compile_options(proxy_ring_publish_order PRIVATE -O2)

enable_testing()
add_test(NAME proxy_ring_publish_order COMMAND proxy_ring_publish_order)
