##########
# Jitify #
##########

set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/modules/ ${CMAKE_MODULE_PATH})
include(FetchContent)
cmake_policy(SET CMP0079 NEW)

# Change the source-dir to allow inclusion via jitify/jitify.hpp rather than jitify.hpp
FetchContent_Declare(
    jitify
    # Temp until https://github.com/NVIDIA/jitify/pull/132 is merged
    GIT_REPOSITORY https://github.com/Robadob/jitify.git
    #GIT_TAG        jitify2-windows-werror
    GIT_TAG        jitify2-preprocess-windows-werror
    #GIT_REPOSITORY https://github.com/NVIDIA/jitify.git
    #GIT_TAG        jitify2-preprocessing-overhaul
    SOURCE_DIR     ${FETCHCONTENT_BASE_DIR}/jitify-src/jitify
    GIT_PROGRESS   ON
    # UPDATE_DISCONNECTED   ON
)
FetchContent_GetProperties(jitify)
if(NOT jitify_POPULATED)
    FetchContent_Populate(jitify)
    # Jitify is not a cmake project, so cannot use add_subdirectory, use custom find_package.
endif()

set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH};${jitify_SOURCE_DIR}/..")
# Always find the package, even if jitify is already populated.
find_package(Jitify REQUIRED)

# Mark some CACHE vars advanced for a cleaner GUI
mark_as_advanced(FETCHCONTENT_SOURCE_DIR_JITIFY)
mark_as_advanced(FETCHCONTENT_QUIET)
mark_as_advanced(FETCHCONTENT_BASE_DIR)
mark_as_advanced(FETCHCONTENT_FULLY_DISCONNECTED)
mark_as_advanced(FETCHCONTENT_UPDATES_DISCONNECTED) 
mark_as_advanced(FETCHCONTENT_UPDATES_DISCONNECTED_JITIFY) 