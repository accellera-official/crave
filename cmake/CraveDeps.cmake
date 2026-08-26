include(ExternalProject)
include(FetchContent)

# Prefer user-provided parallelism, otherwise default to a conservative value.
if(NOT DEFINED CRAVE_BUILD_JOBS OR "${CRAVE_BUILD_JOBS}" STREQUAL "")
    if(DEFINED ENV{CMAKE_BUILD_PARALLEL_LEVEL} AND NOT "$ENV{CMAKE_BUILD_PARALLEL_LEVEL}" STREQUAL "")
        set(_crave_default_jobs "$ENV{CMAKE_BUILD_PARALLEL_LEVEL}")
    else()
        set(_crave_default_jobs "32")
    endif()
    set(CRAVE_BUILD_JOBS "${_crave_default_jobs}" CACHE STRING "Parallel build jobs for ExternalProject builds")
endif()

# Dependency helpers:
# - Set a shared install prefix for fetched deps and expose libdir for byproducts.
# - Decide whether to fetch based on FETCH_ALL_DEPS or per-dep flags.
# - Each crave_find_or_fetch_* first tries system discovery, 
#   then fetch/builds a dependency and creates imported targets for downstream use.

function(_crave_deps_set_prefix)
    if(NOT CRAVE_DEPS_PREFIX)
        set(CRAVE_DEPS_PREFIX "${CMAKE_BINARY_DIR}/_deps/install" CACHE PATH "Prefix for fetched dependencies" FORCE)
    endif()
    include(GNUInstallDirs)
    set(CRAVE_DEPS_LIBDIR "${CRAVE_DEPS_PREFIX}/${CMAKE_INSTALL_LIBDIR}" PARENT_SCOPE)
endfunction()

function(_crave_should_fetch dep_flag out_var)
    if(FETCH_ALL_DEPS)
        set(${out_var} TRUE PARENT_SCOPE)
    elseif(${dep_flag})
        set(${out_var} TRUE PARENT_SCOPE)
    else()
        set(${out_var} FALSE PARENT_SCOPE)
    endif()
endfunction()

function(crave_find_or_fetch_boost)
    _crave_deps_set_prefix()

    _crave_should_fetch(FETCH_BOOST do_fetch)
    if(NOT do_fetch)
        if(DEFINED ENV{BOOST_ROOT})
            set(BOOST_ROOT "$ENV{BOOST_ROOT}" CACHE PATH "" FORCE)
            set(Boost_ROOT "$ENV{BOOST_ROOT}" CACHE PATH "" FORCE)
        endif()
        find_package(Boost QUIET COMPONENTS system filesystem unit_test_framework)
    endif()

    if(NOT do_fetch AND Boost_FOUND AND TARGET Boost::system)
        message(STATUS "Boost: ${Boost_VERSION} @ ${Boost_INCLUDE_DIRS}")
        return()
    endif()
    if(do_fetch)
        set(Boost_NO_SYSTEM_PATHS ON CACHE BOOL "Disable system Boost when fetching" FORCE)
    endif()

    set(BOOST_VERSION "${BOOST_VERSION}" CACHE STRING "Boost version to fetch")
    if(NOT BOOST_VERSION)
        set(BOOST_VERSION "1.85.0" CACHE STRING "Boost version to fetch" FORCE)
    endif()
    string(REPLACE "." "_" BOOST_VERSION_UNDERSCORE "${BOOST_VERSION}")
    set(BOOST_TARBALL "boost_${BOOST_VERSION_UNDERSCORE}.tar.bz2")
    set(BOOST_URL "https://archives.boost.io/release/${BOOST_VERSION}/source/${BOOST_TARBALL}")

    set(BOOST_LIBDIR_OPT "")
    if(CMAKE_INSTALL_LIBDIR)
        set(BOOST_LIBDIR_OPT "--libdir=${CRAVE_DEPS_LIBDIR}")
    endif()
    set(BOOST_LIB_EXCLUDE "python,wave,graph,graph_parallel")

    FetchContent_Declare(
        boost_src
        URL ${BOOST_URL}
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    )
    FetchContent_GetProperties(boost_src)
    if(NOT boost_src_POPULATED)
        FetchContent_Populate(boost_src)
    endif()

    ExternalProject_Add(boost_ext
        SOURCE_DIR ${boost_src_SOURCE_DIR}
        DOWNLOAD_COMMAND ""
        CONFIGURE_COMMAND ./bootstrap.sh --prefix=${CRAVE_DEPS_PREFIX} ${BOOST_LIBDIR_OPT} --without-libraries=${BOOST_LIB_EXCLUDE}
        BUILD_COMMAND ./b2 -j${CRAVE_BUILD_JOBS} link=static cxxflags=-std=c++${CMAKE_CXX_STANDARD} install
        INSTALL_COMMAND ""
        BUILD_BYPRODUCTS
            "${CRAVE_DEPS_LIBDIR}/libboost_system.a"
            "${CRAVE_DEPS_LIBDIR}/libboost_filesystem.a"
            "${CRAVE_DEPS_LIBDIR}/libboost_unit_test_framework.a"
        BUILD_IN_SOURCE 1
    )

    set(Boost_FOUND TRUE CACHE BOOL "" FORCE)
    set(Boost_VERSION "${BOOST_VERSION}" CACHE STRING "" FORCE)
    set(BOOST_ROOT "${CRAVE_DEPS_PREFIX}" CACHE PATH "" FORCE)
    set(Boost_ROOT "${CRAVE_DEPS_PREFIX}" CACHE PATH "" FORCE)
    set(Boost_INCLUDE_DIR "${boost_src_SOURCE_DIR}" CACHE PATH "" FORCE)
    set(Boost_INCLUDE_DIRS "${boost_src_SOURCE_DIR}" CACHE PATH "" FORCE)
    set(Boost_LIBRARY_DIRS "${CRAVE_DEPS_LIBDIR}" CACHE PATH "" FORCE)
    set(Boost_SYSTEM_LIBRARY "${CRAVE_DEPS_LIBDIR}/libboost_system.a" CACHE FILEPATH "" FORCE)
    set(Boost_FILESYSTEM_LIBRARY "${CRAVE_DEPS_LIBDIR}/libboost_filesystem.a" CACHE FILEPATH "" FORCE)
    set(Boost_UNIT_TEST_FRAMEWORK_LIBRARY "${CRAVE_DEPS_LIBDIR}/libboost_unit_test_framework.a" CACHE FILEPATH "" FORCE)
    set(Boost_LIBRARIES "${Boost_SYSTEM_LIBRARY};${Boost_FILESYSTEM_LIBRARY}" CACHE STRING "" FORCE)

    if(NOT TARGET Boost::system)
        add_library(Boost::system UNKNOWN IMPORTED)
        set_target_properties(Boost::system PROPERTIES
            IMPORTED_LOCATION "${Boost_SYSTEM_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${Boost_INCLUDE_DIRS}"
        )
        add_dependencies(Boost::system boost_ext)
    endif()

    if(NOT TARGET Boost::unit_test_framework)
        add_library(Boost::unit_test_framework UNKNOWN IMPORTED)
        set_target_properties(Boost::unit_test_framework PROPERTIES
            IMPORTED_LOCATION "${Boost_UNIT_TEST_FRAMEWORK_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${Boost_INCLUDE_DIRS}"
        )
        add_dependencies(Boost::unit_test_framework boost_ext)
    endif()

    if(NOT TARGET Boost::filesystem)
        add_library(Boost::filesystem UNKNOWN IMPORTED)
        set_target_properties(Boost::filesystem PROPERTIES
            IMPORTED_LOCATION "${Boost_FILESYSTEM_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${Boost_INCLUDE_DIRS}"
        )
        add_dependencies(Boost::filesystem boost_ext)
    endif()
    message(STATUS "Boost: ${Boost_VERSION} @ ${Boost_INCLUDE_DIRS}")
endfunction()

function(crave_find_or_fetch_systemc)
    _crave_deps_set_prefix()
    _crave_should_fetch(FETCH_SYSTEMC do_fetch)
    if(NOT do_fetch)
        if(DEFINED ENV{SYSTEMC_HOME})
            set(SystemC_ROOT "$ENV{SYSTEMC_HOME}" CACHE PATH "" FORCE)
            set(SystemCLanguage_ROOT "$ENV{SYSTEMC_HOME}" CACHE PATH "" FORCE)
        endif()
        include(SystemCPackage)
    endif()

    if(SystemC_FOUND AND TARGET SystemC::systemc)
        message(STATUS "SystemC: ${SystemC_INCLUDE_DIRS}")
        return()
    endif()

    set(SYSTEMC_VERSION "${SYSTEMC_VERSION}" CACHE STRING "SystemC version to fetch")
    if(NOT SYSTEMC_VERSION)
        set(SYSTEMC_VERSION "2.3.4" CACHE STRING "SystemC version to fetch" FORCE)
    endif()
    set(SYSTEMC_URL "https://github.com/accellera-official/systemc/archive/refs/tags/${SYSTEMC_VERSION}.tar.gz")

    ExternalProject_Add(systemc_ext
        URL ${SYSTEMC_URL}
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE
        CMAKE_ARGS
            -DCMAKE_INSTALL_PREFIX=${CRAVE_DEPS_PREFIX}
            -DCMAKE_INSTALL_LIBDIR=${CMAKE_INSTALL_LIBDIR}
            -DCMAKE_BUILD_TYPE=RelWithDebInfo
            -DCMAKE_CXX_STANDARD=${CMAKE_CXX_STANDARD}
            -DBUILD_SHARED_LIBS=OFF
            -DENABLE_PHASE_CALLBACKS_TRACING=OFF
        BUILD_COMMAND ${CMAKE_COMMAND} --build <BINARY_DIR> --parallel ${CRAVE_BUILD_JOBS}
        BUILD_BYPRODUCTS "${CRAVE_DEPS_LIBDIR}/libsystemc.a"
        INSTALL_DIR ${CRAVE_DEPS_PREFIX}
    )

    file(MAKE_DIRECTORY "${CRAVE_DEPS_PREFIX}/include")
    set(SystemC_FOUND TRUE CACHE BOOL "" FORCE)
    set(SystemC_INCLUDE_DIRS "${CRAVE_DEPS_PREFIX}/include" CACHE PATH "" FORCE)
    set(SystemC_LIBRARY "${CRAVE_DEPS_LIBDIR}/libsystemc.a" CACHE FILEPATH "" FORCE)

    if(NOT TARGET SystemC::systemc)
        add_library(SystemC::systemc UNKNOWN IMPORTED)
        set_target_properties(SystemC::systemc PROPERTIES
            IMPORTED_LOCATION "${SystemC_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${SystemC_INCLUDE_DIRS}"
        )
        add_dependencies(SystemC::systemc systemc_ext)
    endif()
    install(FILES "${CRAVE_DEPS_LIBDIR}/libsystemc.a" DESTINATION ${CMAKE_INSTALL_LIBDIR})
    install(DIRECTORY "${CRAVE_DEPS_PREFIX}/include/" DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
    message(STATUS "SystemC: ${SYSTEMC_VERSION} @ ${SystemC_INCLUDE_DIRS}")
endfunction()

function(crave_find_or_fetch_uvm_systemc)
    _crave_deps_set_prefix()

    _crave_should_fetch(FETCH_UVM_SC do_fetch)
    if(NOT do_fetch)
        if(DEFINED ENV{UVM_SYSTEMC_HOME})
            set(UVM_SYSTEMC_HOME "$ENV{UVM_SYSTEMC_HOME}" CACHE PATH "" FORCE)
        endif()
        find_package(UVM-SystemC QUIET)
    endif()

    if(UVM_SystemC_FOUND AND TARGET UVM::uvm-systemc)
        message(STATUS "UVM-SystemC: unknown version @ ${UVM_SystemC_INCLUDE_DIRS}")
        return()
    endif()

    # Explicit UVM-SystemC URL (can be overridden via presets).
    set(UVM_SYSTEMC_URL "${UVM_SYSTEMC_URL}" CACHE STRING "UVM-SystemC tarball URL to fetch")
    if(NOT UVM_SYSTEMC_URL)
        set(UVM_SYSTEMC_URL "https://github.com/accellera-official/uvm-systemc/archive/refs/tags/1.0-beta4.tar.gz" CACHE STRING "UVM-SystemC tarball URL to fetch" FORCE)
    endif()

    if(DEFINED ENV{SYSTEMC_HOME})
        ExternalProject_Add(uvm_systemc_ext
            URL ${UVM_SYSTEMC_URL}
            DOWNLOAD_EXTRACT_TIMESTAMP TRUE
            CONFIGURE_COMMAND <SOURCE_DIR>/config/bootstrap
            COMMAND ${CMAKE_COMMAND} -E env CXXFLAGS=-std=c++${CMAKE_CXX_STANDARD} <SOURCE_DIR>/configure --enable-debug --enable-shared=no --with-layout=unix --with-systemc=$ENV{SYSTEMC_HOME} --prefix=${CRAVE_DEPS_PREFIX} --libdir=${CRAVE_DEPS_LIBDIR}
            BUILD_COMMAND make -j${CRAVE_BUILD_JOBS}
            INSTALL_COMMAND make install
            BUILD_BYPRODUCTS "${CRAVE_DEPS_LIBDIR}/libuvm-systemc.a"
            BUILD_IN_SOURCE 1
        )
    else()
        ExternalProject_Add(uvm_systemc_ext
            URL ${UVM_SYSTEMC_URL}
            DOWNLOAD_EXTRACT_TIMESTAMP TRUE
            CONFIGURE_COMMAND <SOURCE_DIR>/config/bootstrap
            COMMAND ${CMAKE_COMMAND} -E env CXXFLAGS=-std=c++${CMAKE_CXX_STANDARD} <SOURCE_DIR>/configure --enable-debug --enable-shared=no --with-layout=unix --with-systemc=${CRAVE_DEPS_PREFIX} --prefix=${CRAVE_DEPS_PREFIX} --libdir=${CRAVE_DEPS_LIBDIR}
            BUILD_COMMAND make -j${CRAVE_BUILD_JOBS}
            INSTALL_COMMAND make install
            BUILD_BYPRODUCTS "${CRAVE_DEPS_LIBDIR}/libuvm-systemc.a"
            BUILD_IN_SOURCE 1
           DEPENDS systemc_ext
        )
    endif()

    file(MAKE_DIRECTORY "${CRAVE_DEPS_PREFIX}/include")
    set(UVM_SystemC_FOUND TRUE CACHE BOOL "" FORCE)
    set(UVM_SystemC_INCLUDE_DIRS "${CRAVE_DEPS_PREFIX}/include" CACHE PATH "" FORCE)
    set(UVM_SystemC_LIBRARY "${CRAVE_DEPS_LIBDIR}/libuvm-systemc.a" CACHE FILEPATH "" FORCE)
    set(UVM_SystemC_LIBRARIES "${UVM_SystemC_LIBRARY}" CACHE STRING "" FORCE)

    if(NOT TARGET UVM::uvm-systemc)
        add_library(UVM::uvm-systemc UNKNOWN IMPORTED)
        set_target_properties(UVM::uvm-systemc PROPERTIES
            IMPORTED_LOCATION "${UVM_SystemC_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${UVM_SystemC_INCLUDE_DIRS}"
        )
        add_dependencies(UVM::uvm-systemc uvm_systemc_ext)
    endif()
    install(FILES "${CRAVE_DEPS_LIBDIR}/libuvm-systemc.a" DESTINATION ${CMAKE_INSTALL_LIBDIR})
    install(DIRECTORY "${CRAVE_DEPS_PREFIX}/include/" DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
    message(STATUS "UVM-SystemC: ${UVM_SYSTEMC_URL} @ ${UVM_SystemC_INCLUDE_DIRS}")
endfunction()
