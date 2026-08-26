include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/buildGMP.cmake)

set(GPERF_SOURCE_ARGS
  URL https://ftp.gnu.org/pub/gnu/gperf/gperf-3.1.tar.gz
)

# Resolve local source if in offline mode
metasmt_resolve_local_source(gperf GPERF_SOURCE_ARGS)

set(GPERF_INSTALL_DIR ${CMAKE_INSTALL_PREFIX})
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    set(GPERF_INSTALL_DIR ${CMAKE_BINARY_DIR}/solvers/gperf)
endif()

file(MAKE_DIRECTORY "${GPERF_INSTALL_DIR}/bin")

ExternalProject_Add(gperf_ext
  ${GPERF_SOURCE_ARGS}
  DOWNLOAD_EXTRACT_TIMESTAMP TRUE
  CONFIGURE_COMMAND ./configure --prefix=${GPERF_INSTALL_DIR}
  BUILD_COMMAND make -j${CRAVE_BUILD_JOBS}
  INSTALL_COMMAND make install
  BUILD_IN_SOURCE 1
  BUILD_BYPRODUCTS ${GPERF_INSTALL_DIR}/bin/gperf
  STEP_TARGETS download
)

# Stage gperf for export because Yices2 needs it as an internal offline dependency.
metasmt_register_dep_for_export(gperf gperf_ext)

set(YICES2_SOURCE_ARGS
  GIT_REPOSITORY https://github.com/SRI-CSL/yices2.git
  GIT_TAG Yices-2.6.4
)

# Resolve local source if in offline mode
metasmt_resolve_local_source(yices2 YICES2_SOURCE_ARGS)

set(install_dir ${CMAKE_INSTALL_PREFIX})
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    set(install_dir ${CMAKE_BINARY_DIR}/solvers/yices2)
endif()

file(MAKE_DIRECTORY "${install_dir}/include")
file(MAKE_DIRECTORY "${install_dir}/lib")

ExternalProject_Add(yices2_ext
  ${YICES2_SOURCE_ARGS}
  CONFIGURE_COMMAND bash -c "autoconf && ./configure --prefix=${install_dir} GPERF=${GPERF_INSTALL_DIR}/bin/gperf CPPFLAGS=-I${GMP_INSTALL_DIR}/include LDFLAGS=-L${GMP_INSTALL_DIR}/lib"
  BUILD_COMMAND make -j${CRAVE_BUILD_JOBS}
  INSTALL_COMMAND make -j${CRAVE_BUILD_JOBS} install
  BUILD_IN_SOURCE 1
  BUILD_BYPRODUCTS ${install_dir}/lib/libyices.a
  DEPENDS gperf_ext gmp_ext
  STEP_TARGETS download
)

# Stage yices2 for export in online mode.
metasmt_register_dep_for_export(yices2 yices2_ext)

add_library(yices2::yices2 UNKNOWN IMPORTED)
set_target_properties(yices2::yices2 PROPERTIES
  IMPORTED_LOCATION ${install_dir}/lib/libyices.a
  INTERFACE_INCLUDE_DIRECTORIES ${install_dir}/include
)
add_dependencies(yices2::yices2 yices2_ext)

add_library(yices2 INTERFACE)
target_link_libraries(yices2 INTERFACE yices2::yices2 gmp::gmp)
# install the target
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)
set(yices2_CMAKE_CONFIG_DIR ${CMAKE_INSTALL_LIBDIR}/cmake/yices2)

install(TARGETS yices2 EXPORT yices2-targets)

install(
  EXPORT yices2-targets
  DESTINATION ${yices2_CMAKE_CONFIG_DIR}
)

write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/yices2-config-version.cmake
    VERSION 2.6.4
    COMPATIBILITY AnyNewerVersion
)

configure_package_config_file(
    ${CMAKE_CURRENT_LIST_DIR}/yices2-config.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/yices2-config.cmake
    INSTALL_DESTINATION ${yices2_CMAKE_CONFIG_DIR}
)

install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/yices2-config.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/yices2-config-version.cmake
    DESTINATION ${yices2_CMAKE_CONFIG_DIR})
message(STATUS "Use Yices2 2.6.4 from ${install_dir}")
