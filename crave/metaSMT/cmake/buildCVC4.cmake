include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/buildGMP.cmake)

set(CVC4_SOURCE_ARGS
  GIT_REPOSITORY https://github.com/CVC4/CVC4-archived.git
  GIT_TAG 1.8
)

# Resolve local source if in offline mode.
metasmt_resolve_local_source(cvc4 CVC4_SOURCE_ARGS)

set(CVC4_PREPARED_DEPS_SOURCE_ARGS "")
# Resolve the prepared CVC4 ANTLR dependency bundle if in offline mode.
metasmt_resolve_local_source(cvc4-antlr CVC4_PREPARED_DEPS_SOURCE_ARGS)
if(METASMT_DEPS_DIR)
  list(GET CVC4_PREPARED_DEPS_SOURCE_ARGS 1 CVC4_PREPARED_DEPS_DIR)
  if(NOT EXISTS "${CVC4_PREPARED_DEPS_DIR}/bin/antlr3")
    message(FATAL_ERROR "Offline mode: cvc4-antlr bundle is missing bin/antlr3 at ${CVC4_PREPARED_DEPS_DIR}")
  endif()
  if(NOT EXISTS "${CVC4_PREPARED_DEPS_DIR}/include/antlr3.h")
    message(FATAL_ERROR "Offline mode: cvc4-antlr bundle is missing include/antlr3.h at ${CVC4_PREPARED_DEPS_DIR}")
  endif()
  if(NOT EXISTS "${CVC4_PREPARED_DEPS_DIR}/share/java/antlr-3.4-complete.jar")
    message(FATAL_ERROR "Offline mode: cvc4-antlr bundle is missing share/java/antlr-3.4-complete.jar at ${CVC4_PREPARED_DEPS_DIR}")
  endif()
endif()

set(install_dir ${CMAKE_INSTALL_PREFIX})
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    set(install_dir ${CMAKE_BINARY_DIR}/solvers/cvc4)
endif()

file(MAKE_DIRECTORY "${install_dir}/include")
file(MAKE_DIRECTORY "${install_dir}/lib")
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

set(CVC4_CONFIGURE_COMMAND
  bash -c "cd <SOURCE_DIR> && ./contrib/get-antlr-3.4 && ./configure.sh --python3 --prefix=${install_dir} --gmp-dir=${GMP_INSTALL_DIR} --antlr-dir=<SOURCE_DIR>/deps/install"
)
if(METASMT_DEPS_DIR)
  # Reuse the prepared dependency from the offline bundle instead of rebuilding it.
  set(CVC4_CONFIGURE_COMMAND
    bash -c "cd <SOURCE_DIR> && rm -rf deps/install && mkdir -p deps && cp -a '${CVC4_PREPARED_DEPS_DIR}' deps/install && ./configure.sh --python3 --prefix=${install_dir} --gmp-dir=${GMP_INSTALL_DIR} --antlr-dir=<SOURCE_DIR>/deps/install"
  )
endif()

ExternalProject_Add(cvc4_ext
  ${CVC4_SOURCE_ARGS}
  DOWNLOAD_EXTRACT_TIMESTAMP TRUE
  UPDATE_COMMAND ""
  CONFIGURE_COMMAND ${CVC4_CONFIGURE_COMMAND}
  BUILD_COMMAND bash -c "make -C build -j${CRAVE_BUILD_JOBS}"
  INSTALL_COMMAND bash -c "make -C build install"
  BUILD_IN_SOURCE 1
  BUILD_BYPRODUCTS ${install_dir}/lib/libcvc4.so.7
  DEPENDS gmp_ext
  STEP_TARGETS download configure
)

# Stage the raw CVC4 source tree for export in online mode.
metasmt_register_dep_for_export(cvc4 cvc4_ext)

if(NOT METASMT_DEPS_DIR)
  ExternalProject_Get_Property(cvc4_ext SOURCE_DIR)

  # Export the prepared ANTLR dependency exactly as CVC4 created it online.
  metasmt_export_depends_on(cvc4_ext-configure)
  metasmt_register_source_dir_for_export(cvc4-antlr "${SOURCE_DIR}/deps/install")
endif()

set(CVC4_FOUND TRUE CACHE BOOL "" FORCE)
set(CVC4_INCLUDE_DIRS "${install_dir}/include" CACHE PATH "" FORCE)

add_library(CVC4::cvc4 UNKNOWN IMPORTED)
set_target_properties(CVC4::cvc4 PROPERTIES
  IMPORTED_LOCATION ${install_dir}/lib/libcvc4.so.7
  INTERFACE_INCLUDE_DIRECTORIES ${install_dir}/include
  INTERFACE_LINK_LIBRARIES gmp::gmp
)
add_dependencies(CVC4::cvc4 cvc4_ext)

set(cvc4_CMAKE_CONFIG_DIR ${CMAKE_INSTALL_LIBDIR}/cmake/cvc4)
set(SOLVER_TARGET "CVC4::cvc4")
set(SOLVER_VARNAME "CVC4")
set(SOLVER_LIBNAME "libcvc4.so.7")
set(SOLVER_LIBDIR "lib")
set(SOLVER_INCLUDEDIR "include")
set(SOLVER_FIND_DEPS "find_dependency(gmp)")
set(SOLVER_SET_LINK_LIBS "set_property(TARGET CVC4::cvc4 APPEND PROPERTY INTERFACE_LINK_LIBRARIES gmp::gmp)")

write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/cvc4-config-version.cmake
    VERSION 1.8
    COMPATIBILITY AnyNewerVersion
)

configure_package_config_file(
    ${CMAKE_CURRENT_LIST_DIR}/solver-config.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/cvc4-config.cmake
    INSTALL_DESTINATION ${cvc4_CMAKE_CONFIG_DIR}
)

install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/cvc4-config.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/cvc4-config-version.cmake
    DESTINATION ${cvc4_CMAKE_CONFIG_DIR}
)

message(STATUS "Use CVC4 1.8 from ${install_dir}")
