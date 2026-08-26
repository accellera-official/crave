set(install_dir ${CMAKE_INSTALL_PREFIX})
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    set(install_dir ${CMAKE_BINARY_DIR}/solvers/minisat)
endif()
set(MINISAT_INSTALL_DIR ${install_dir} CACHE PATH "minisat install prefix" FORCE)

file(MAKE_DIRECTORY "${install_dir}/include")
file(MAKE_DIRECTORY "${install_dir}/lib")
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

set(MINISAT_SOURCE_ARGS
    GIT_REPOSITORY https://github.com/stp/minisat.git
    GIT_TAG 14c78206cd12d1d36b7e042fa758747c135670a4
)

# Resolve local source if in offline mode
metasmt_resolve_local_source(minisat MINISAT_SOURCE_ARGS)

ExternalProject_Add(minisat_ext
  ${MINISAT_SOURCE_ARGS}
  DOWNLOAD_EXTRACT_TIMESTAMP TRUE
  UPDATE_COMMAND ""
  CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${install_dir}
  BUILD_COMMAND ${CMAKE_COMMAND} --build <BINARY_DIR> --parallel ${CRAVE_BUILD_JOBS}
  INSTALL_COMMAND ${CMAKE_COMMAND} --build <BINARY_DIR> --target install
  BUILD_BYPRODUCTS ${install_dir}/lib/libminisat.so
  STEP_TARGETS download
)

# Register for export if in online mode
metasmt_register_dep_for_export(minisat minisat_ext)

add_library(minisat UNKNOWN IMPORTED)
set_target_properties(minisat PROPERTIES
  IMPORTED_LOCATION ${install_dir}/lib/libminisat.so
  INTERFACE_INCLUDE_DIRECTORIES ${install_dir}/include
)
add_dependencies(minisat minisat_ext)

set(minisat_CMAKE_CONFIG_DIR ${CMAKE_INSTALL_LIBDIR}/cmake/minisat)
set(SOLVER_TARGET "minisat")
set(SOLVER_VARNAME "minisat")
set(SOLVER_LIBNAME "libminisat.so")
set(SOLVER_LIBDIR "lib")
set(SOLVER_INCLUDEDIR "include")
set(SOLVER_FIND_DEPS "")
set(SOLVER_SET_LINK_LIBS "")

write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/minisat-config-version.cmake
    VERSION 0
    COMPATIBILITY AnyNewerVersion
)

configure_package_config_file(
    ${CMAKE_CURRENT_LIST_DIR}/solver-config.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/minisat-config.cmake
    INSTALL_DESTINATION ${minisat_CMAKE_CONFIG_DIR}
)

install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/minisat-config.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/minisat-config-version.cmake
    DESTINATION ${minisat_CMAKE_CONFIG_DIR}
)

message(STATUS "Use MiniSat from ${install_dir}")
