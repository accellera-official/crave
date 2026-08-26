include(ExternalProject)
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

set(install_dir ${CMAKE_INSTALL_PREFIX})
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    set(install_dir ${CMAKE_BINARY_DIR}/solvers/z3)
endif()

set(Z3_LIBDIR "${install_dir}/lib")
file(MAKE_DIRECTORY "${install_dir}/include")
file(MAKE_DIRECTORY "${Z3_LIBDIR}")

# check for prerequisites
find_package(Threads REQUIRED)
find_package(OpenMP)
if(OPENMP_FOUND)
  message(STATUS "Use Z3 with OpenMP")
else()
  set(Z3_OPENMP --noomp)
  message(STATUS "Use Z3 without OpenMP")
endif()

set(Z3_SOURCE_ARGS
    GIT_REPOSITORY https://github.com/Z3Prover/z3.git
    GIT_TAG z3-4.6.0
)

# Resolve local source if in offline mode
metasmt_resolve_local_source(z3 Z3_SOURCE_ARGS)

ExternalProject_Add(z3_ext
    ${Z3_SOURCE_ARGS}
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    UPDATE_COMMAND ""
    PATCH_COMMAND ${CMAKE_COMMAND} -E chdir <SOURCE_DIR> git apply -p0 ${CMAKE_CURRENT_LIST_DIR}/z3-z3-4.6.0__permutation_matrix.patch
    CONFIGURE_COMMAND <SOURCE_DIR>/configure --staticlib ${Z3_OPENMP} --prefix=${install_dir}
    BUILD_COMMAND make -C build -j${CRAVE_BUILD_JOBS}
    INSTALL_COMMAND make -C build install
    BUILD_IN_SOURCE 1
    BUILD_BYPRODUCTS ${Z3_LIBDIR}/libz3.a
    STEP_TARGETS download
)

# Register for export if in online mode
metasmt_register_dep_for_export(z3 z3_ext)

add_library(z3::z3 UNKNOWN IMPORTED)
set_target_properties(z3::z3 PROPERTIES
    IMPORTED_LOCATION ${Z3_LIBDIR}/libz3.a
    INTERFACE_INCLUDE_DIRECTORIES ${install_dir}/include
)
if(OPENMP_FOUND)
  set_property(TARGET z3::z3 APPEND PROPERTY INTERFACE_LINK_LIBRARIES OpenMP::OpenMP_CXX)
endif()
set_property(TARGET z3::z3 APPEND PROPERTY INTERFACE_LINK_LIBRARIES Threads::Threads)
add_dependencies(z3::z3 z3_ext)

set(z3_CMAKE_CONFIG_DIR ${CMAKE_INSTALL_LIBDIR}/cmake/z3)
set(SOLVER_TARGET "z3::z3")
set(SOLVER_VARNAME "z3")
set(SOLVER_LIBNAME "libz3.a")
set(SOLVER_LIBDIR "lib")
set(SOLVER_INCLUDEDIR "include")
set(SOLVER_FIND_DEPS "find_dependency(Threads)\nfind_dependency(OpenMP QUIET)")
set(SOLVER_SET_LINK_LIBS "set_property(TARGET z3::z3 APPEND PROPERTY INTERFACE_LINK_LIBRARIES Threads::Threads)\nif(TARGET OpenMP::OpenMP_CXX)\n    set_property(TARGET z3::z3 APPEND PROPERTY INTERFACE_LINK_LIBRARIES OpenMP::OpenMP_CXX)\nendif()")

write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/z3-config-version.cmake
    VERSION 4.6.0
    COMPATIBILITY AnyNewerVersion
)

configure_package_config_file(
    ${CMAKE_CURRENT_LIST_DIR}/solver-config.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/z3-config.cmake
    INSTALL_DESTINATION ${z3_CMAKE_CONFIG_DIR}
)

install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/z3-config.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/z3-config-version.cmake
    DESTINATION ${z3_CMAKE_CONFIG_DIR}
)

message(STATUS "Use Z3 4.6.0 from ${install_dir}")
