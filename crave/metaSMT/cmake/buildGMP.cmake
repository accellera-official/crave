if(NOT TARGET gmp::gmp)
    set(GMP_INSTALL_DIR ${CMAKE_INSTALL_PREFIX})
    if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
        set(GMP_INSTALL_DIR ${CMAKE_BINARY_DIR}/solvers/gmp)
    endif()

    # GMP's libtool expects ${prefix}/lib; using lib64 breaks install of .la files.
    set(GMP_LIBDIR "${GMP_INSTALL_DIR}/lib")

    file(MAKE_DIRECTORY "${GMP_INSTALL_DIR}/include")
    file(MAKE_DIRECTORY "${GMP_LIBDIR}")

    ExternalProject_Add(gmp_ext
        URL https://gmplib.org/download/gmp/gmp-6.2.1.tar.xz
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE
        CONFIGURE_COMMAND ./configure --prefix=${GMP_INSTALL_DIR} --libdir=${GMP_LIBDIR} --enable-cxx
        BUILD_COMMAND make -j${CRAVE_BUILD_JOBS}
        INSTALL_COMMAND make install
        BUILD_IN_SOURCE 1
        BUILD_BYPRODUCTS
            ${GMP_LIBDIR}/libgmp.so
    )

    add_library(gmp::gmp UNKNOWN IMPORTED)
    set_target_properties(gmp::gmp PROPERTIES
        IMPORTED_LOCATION ${GMP_LIBDIR}/libgmp.so
        INTERFACE_INCLUDE_DIRECTORIES ${GMP_INSTALL_DIR}/include
    )
    add_dependencies(gmp::gmp gmp_ext)

    add_library(gmp INTERFACE)
    target_link_libraries(gmp INTERFACE gmp::gmp)

    message(STATUS "Use GMP 6.2.1 from ${GMP_INSTALL_DIR}")

    include(GNUInstallDirs)
    include(CMakePackageConfigHelpers)
    set(gmp_CMAKE_CONFIG_DIR ${CMAKE_INSTALL_LIBDIR}/cmake/gmp)
    set(SOLVER_TARGET "gmp::gmp")
    set(SOLVER_VARNAME "gmp")
    set(SOLVER_LIBNAME "libgmp.so")
    set(SOLVER_LIBDIR "lib")
    set(SOLVER_INCLUDEDIR "include")
    set(SOLVER_FIND_DEPS "")
    set(SOLVER_SET_LINK_LIBS "")

    write_basic_package_version_file(
        ${CMAKE_CURRENT_BINARY_DIR}/gmp-config-version.cmake
        VERSION 6.2.1
        COMPATIBILITY AnyNewerVersion
    )

    configure_package_config_file(
        ${CMAKE_CURRENT_LIST_DIR}/solver-config.cmake.in
        ${CMAKE_CURRENT_BINARY_DIR}/gmp-config.cmake
        INSTALL_DESTINATION ${gmp_CMAKE_CONFIG_DIR}
    )

    install(FILES
        ${CMAKE_CURRENT_BINARY_DIR}/gmp-config.cmake
        ${CMAKE_CURRENT_BINARY_DIR}/gmp-config-version.cmake
        DESTINATION ${gmp_CMAKE_CONFIG_DIR})
endif()
