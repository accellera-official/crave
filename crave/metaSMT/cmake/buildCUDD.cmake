include(ExternalProject)

set(install_dir ${CMAKE_INSTALL_PREFIX})
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    set(install_dir ${CMAKE_BINARY_DIR}/solvers/cudd)
endif()

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)
set(CUDD_LIBDIR "${install_dir}/${CMAKE_INSTALL_LIBDIR}")

file(MAKE_DIRECTORY "${install_dir}/include")
file(MAKE_DIRECTORY "${CUDD_LIBDIR}")

set(CUDD_SOURCE_ARGS
    GIT_REPOSITORY https://github.com/nbruns1/cudd.git
    GIT_TAG cudd-3.0.0
)

# Resolve local source if in offline mode
metasmt_resolve_local_source(cudd CUDD_SOURCE_ARGS)

ExternalProject_Add(cudd_ext
    ${CUDD_SOURCE_ARGS}
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND bash -c "touch configure.ac aclocal.m4 configure Makefile.am Makefile.in && ./configure --enable-obj --enable-dddmp --prefix=${install_dir} --libdir=${CUDD_LIBDIR}"
    BUILD_COMMAND make -j${CRAVE_BUILD_JOBS}
    INSTALL_COMMAND make install
    BUILD_IN_SOURCE 1
    BUILD_BYPRODUCTS ${CUDD_LIBDIR}/libcudd.a
    STEP_TARGETS download
)

# Register for export if in online mode
metasmt_register_dep_for_export(cudd cudd_ext)

add_library(cudd::cudd UNKNOWN IMPORTED)
set_target_properties(cudd::cudd PROPERTIES
    IMPORTED_LOCATION ${CUDD_LIBDIR}/libcudd.a
    INTERFACE_INCLUDE_DIRECTORIES ${install_dir}/include
)
add_dependencies(cudd::cudd cudd_ext)
add_library(cudd ALIAS cudd::cudd)

set(cudd_CMAKE_CONFIG_DIR ${CMAKE_INSTALL_LIBDIR}/cmake/cudd)
set(SOLVER_TARGET "cudd::cudd")
set(SOLVER_VARNAME "cudd")
set(SOLVER_LIBNAME "libcudd.a")
set(SOLVER_LIBDIR "${CMAKE_INSTALL_LIBDIR}")
set(SOLVER_INCLUDEDIR "include")
set(SOLVER_FIND_DEPS "")
set(SOLVER_SET_LINK_LIBS "")

write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/cudd-config-version.cmake
    VERSION 3.0.0
    COMPATIBILITY AnyNewerVersion
)

configure_package_config_file(
    ${CMAKE_CURRENT_LIST_DIR}/solver-config.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/cudd-config.cmake
    INSTALL_DESTINATION ${cudd_CMAKE_CONFIG_DIR}
)

install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/cudd-config.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/cudd-config-version.cmake
    DESTINATION ${cudd_CMAKE_CONFIG_DIR}
)

message(STATUS "Use CUDD 3.0.0 from ${install_dir}")
