cmake_minimum_required(VERSION 3.25)

project(fgof_expect VERSION 0.1.0 LANGUAGES Fortran)

if(NOT TARGET fgof::pty)
  if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/../fgof-pty/CMakeLists.txt")
    add_subdirectory("${CMAKE_CURRENT_LIST_DIR}/../fgof-pty" "${CMAKE_CURRENT_BINARY_DIR}/_deps/fgof-pty")
  else()
    message(FATAL_ERROR "fgof-expect requires fgof-pty")
  endif()
endif()

add_library(fgof_expect
  src/fgof_expect_types.f90
  src/fgof_expect.f90
)
add_library(fgof::expect ALIAS fgof_expect)

set_target_properties(fgof_expect PROPERTIES
  Fortran_MODULE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/mod"
)

target_include_directories(fgof_expect PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/mod>
)

target_link_libraries(fgof_expect PUBLIC fgof::pty)

target_compile_options(fgof_expect PRIVATE
  $<$<COMPILE_LANG_AND_ID:Fortran,GNU>:-std=f2018 -Wall -Wextra -Wpedantic -Werror>
)
