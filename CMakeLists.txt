cmake_minimum_required(VERSION 3.10)

#C++ library
set(Gcov_coverage_cpp_source_SRC
    ${CMAKE_CURRENT_LIST_DIR}/cpp_source/cpp_string.cpp
)

add_library(Gcov_coverage_cpp_source STATIC ${Gcov_coverage_cpp_source_SRC})
set_target_properties(Gcov_coverage_cpp_source PROPERTIES
  COMPILE_FLAGS "${LIBLLVM_CXX_FLAGS} -I${CMAKE_CURRENT_LIST_DIR}/cpp_source/llvm-cov"
  ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/
  LIBRARY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/
  )

#Link all the D files and C++
file(GLOB_RECURSE SRC_FILES ${CMAKE_CURRENT_LIST_DIR}/source/*.d)
set(flags "-I${CMAKE_CURRENT_LIST_DIR}/source")
