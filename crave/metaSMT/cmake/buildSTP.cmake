include(ExternalProject)
include(CMakePackageConfigHelpers)

set(HELP2MAN_INSTALL_DIR ${CMAKE_INSTALL_PREFIX})
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    set(HELP2MAN_INSTALL_DIR ${CMAKE_BINARY_DIR}/solvers/help2man)
endif()

file(MAKE_DIRECTORY "${HELP2MAN_INSTALL_DIR}/bin")

set(HELP2MAN_SOURCE_ARGS
    URL http://ftp.gnu.org/gnu/help2man/help2man-1.49.3.tar.xz
)

# Resolve local source if in offline mode
metasmt_resolve_local_source(help2man HELP2MAN_SOURCE_ARGS)

ExternalProject_Add(help2man_ext
    ${HELP2MAN_SOURCE_ARGS}
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    CONFIGURE_COMMAND ./configure --prefix=${HELP2MAN_INSTALL_DIR}
    BUILD_COMMAND make -j${CRAVE_BUILD_JOBS}
    INSTALL_COMMAND make install
    BUILD_IN_SOURCE 1
    BUILD_BYPRODUCTS ${HELP2MAN_INSTALL_DIR}/bin/help2man
    STEP_TARGETS download
)

# Register for export if in online mode
metasmt_register_dep_for_export(help2man help2man_ext)

set(STP_SOURCE_ARGS
    GIT_REPOSITORY https://github.com/stp/stp.git
    GIT_TAG 2.3.4
)

# Resolve local source if in offline mode
metasmt_resolve_local_source(stp STP_SOURCE_ARGS)

set(install_dir ${CMAKE_INSTALL_PREFIX})
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    set(install_dir ${CMAKE_BINARY_DIR}/solvers/stp)
endif()

include(GNUInstallDirs)
set(STP_LIBDIR "${install_dir}/${CMAKE_INSTALL_LIBDIR}")

file(MAKE_DIRECTORY "${install_dir}/include")
file(MAKE_DIRECTORY "${STP_LIBDIR}")

set(MINISAT_LIB "${MINISAT_INSTALL_DIR}/lib/libminisat.so")

ExternalProject_Add(stp_ext
    ${STP_SOURCE_ARGS}
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    UPDATE_COMMAND ""
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=${install_dir}
        -DCMAKE_INSTALL_LIBDIR=${CMAKE_INSTALL_LIBDIR}
        -DENABLE_PYTHON_INTERFACE=OFF
        -DONLY_SIMPLE=ON
        -DNOCRYPTOMINISAT=ON
        -DMINISAT_INCLUDE_DIR=${MINISAT_INSTALL_DIR}/include
        -DMINISAT_LIBRARY=${MINISAT_LIB}
        -DCMAKE_PROGRAM_PATH=${HELP2MAN_INSTALL_DIR}/bin
    BUILD_COMMAND ${CMAKE_COMMAND} --build <BINARY_DIR> --parallel ${CRAVE_BUILD_JOBS}
    INSTALL_COMMAND ${CMAKE_COMMAND} --build <BINARY_DIR> --target install
    BUILD_BYPRODUCTS ${STP_LIBDIR}/libstp.so.2.3
    DEPENDS minisat_ext help2man_ext
    STEP_TARGETS download
)

# Register for export if in online mode
metasmt_register_dep_for_export(stp stp_ext)

add_library(stp UNKNOWN IMPORTED)
set_target_properties(stp PROPERTIES
    IMPORTED_LOCATION ${STP_LIBDIR}/libstp.so.2.3
    INTERFACE_INCLUDE_DIRECTORIES ${install_dir}/include
)
add_dependencies(stp stp_ext)

set(stp_CMAKE_CONFIG_DIR ${CMAKE_INSTALL_LIBDIR}/cmake/stp)
set(SOLVER_TARGET "stp")
set(SOLVER_VARNAME "stp")
set(SOLVER_LIBNAME "libstp.so.2.3")
set(SOLVER_LIBDIR "${CMAKE_INSTALL_LIBDIR}")
set(SOLVER_INCLUDEDIR "include")
set(SOLVER_FIND_DEPS "find_dependency(minisat)")
set(SOLVER_SET_LINK_LIBS "set_property(TARGET stp APPEND PROPERTY INTERFACE_LINK_LIBRARIES minisat)")

write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/stp-config-version.cmake
    VERSION 2.3.4
    COMPATIBILITY AnyNewerVersion
)

configure_package_config_file(
    ${CMAKE_CURRENT_LIST_DIR}/solver-config.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/stp-config.cmake
    INSTALL_DESTINATION ${stp_CMAKE_CONFIG_DIR}
)

install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/stp-config.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/stp-config-version.cmake
    DESTINATION ${stp_CMAKE_CONFIG_DIR}
)

message(STATUS "Use STP 2.3.4 from ${install_dir}")
