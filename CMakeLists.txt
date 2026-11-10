cmake_minimum_required(VERSION 3.16)
project(rocm-demo VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Algorithm cores extracted from ROCm/aiter as deterministic CPU reference
# implementations. Provenance and license per file, see include/aiter_ref/.
add_library(aiter_ref STATIC
    src/fp8.cpp
    src/moe_align.cpp
    src/topk_softmax.cpp
    src/group_quant.cpp)
target_include_directories(aiter_ref PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    target_compile_options(aiter_ref PRIVATE -Wall -Wextra)
endif()

include(CTest)
if(BUILD_TESTING)
    foreach(t IN ITEMS fp8 moe_align topk_softmax group_quant pipeline)
        add_executable(test_${t} tests/test_${t}.cpp)
        target_include_directories(test_${t} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/tests)
        target_link_libraries(test_${t} PRIVATE aiter_ref)
        if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
            target_compile_options(test_${t} PRIVATE -Wall -Wextra)
        endif()
        add_test(NAME ${t} COMMAND test_${t})
    endforeach()
endif()
