# Minimum CMake version 3.18 for CUDA --std=c++17
cmake_minimum_required(VERSION 3.18...3.25 FATAL_ERROR)

# Set the location of the ROOT flame gpu project relative to this CMakeList.txt
get_filename_component(FLAMEGPU_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/../../.. REALPATH)

# Handle CMAKE_CUDA_ARCHITECTURES gracefully
include(${FLAMEGPU_ROOT}/cmake/CUDAArchitectures.cmake)
flamegpu_init_cuda_architectures(PROJECT host_functions)

# Name the project and enable required languages
project(host_functions CXX CUDA)

# Include common rules.
include(${FLAMEGPU_ROOT}/cmake/common.cmake)

# Define output location of binary files
SET(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin/${CMAKE_BUILD_TYPE}/)

# Prepare list of source files
# Can't do this automatically, as CMake wouldn't know when to regen (as CMakeLists.txt would be unchanged)
SET(STATIC_SRC
    ${CMAKE_CURRENT_SOURCE_DIR}/src/model.cu
)

# define the model at a static library target,  demonstrating flamegpu_add_library
flamegpu_add_library("${PROJECT_NAME}_static" "${STATIC_SRC}" "${FLAMEGPU_ROOT}" "${PROJECT_BINARY_DIR}" TRUE)

# Create the actual executable, and link against the static lib
set(MAIN_SRC
    ${CMAKE_CURRENT_SOURCE_DIR}/src/main.cu
)
flamegpu_add_executable("${PROJECT_NAME}" "${MAIN_SRC}" "${FLAMEGPU_ROOT}" "${PROJECT_BINARY_DIR}" TRUE)
target_link_libraries(${PROJECT_NAME} PRIVATE ${PROJECT_NAME}_static)

# Also set as startup project (if top level project)
set_property(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"  PROPERTY VS_STARTUP_PROJECT "${PROJECT_NAME}")