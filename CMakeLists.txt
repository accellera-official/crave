###############################################################################
#
# Licensed to Accellera Systems Initiative Inc. (Accellera) under one or
# more contributor license agreements.  See the NOTICE file distributed
# with this work for additional information regarding copyright ownership.
# Accellera licenses this file to you under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with the
# License.  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.  See the License for the specific language governing
# permissions and limitations under the License.
#
###############################################################################

cmake_minimum_required(VERSION 3.20)
project(crave2uvm VERSION 1.0 LANGUAGES CXX)

if (NOT CMAKE_CXX_STANDARD)
  set(CMAKE_CXX_STANDARD 11)
endif()
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake)

option(FETCH_ALL_DEPS "Force download/build of all external deps, ignoring system installs" OFF)
option(FETCH_BOOST "Force download/build of Boost, ignoring system installs" OFF)
option(FETCH_SYSTEMC "Force download/build of SystemC, ignoring system installs" OFF)
option(FETCH_UVM_SC "Force download/build of UVM-SystemC, ignoring system installs" OFF)
set(CRAVE_DEPS_PREFIX "${CMAKE_BINARY_DIR}/_deps/install" CACHE PATH "Prefix for fetched dependencies")
include(${PROJECT_SOURCE_DIR}/cmake/CraveDeps.cmake)

crave_find_or_fetch_boost()
crave_find_or_fetch_systemc()
crave_find_or_fetch_uvm_systemc()

option(BUILD_CRAVE "Build CRAVE and metaSMT as part of the project or import it from a different location" ON)
if(BUILD_CRAVE)
    add_subdirectory(crave)
else(BUILD_CRAVE)
    find_package(CRAVE REQUIRED)
    if(NOT CRAVE_FOUND)
        message(FATAL_ERROR "CRAVE not found. Please provide the path to CRAVE.")
    endif()
endif()

##################################################################################################
### CRAVE2UVM
##################################################################################################
add_library(crave2uvm INTERFACE)
target_include_directories(crave2uvm INTERFACE
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src/include>
    $<INSTALL_INTERFACE:include>
)
add_library(crave2uvm::crave2uvm ALIAS crave2uvm)
target_link_libraries(crave2uvm INTERFACE crave::crave)

include(GNUInstallDirs)
install(TARGETS crave2uvm EXPORT crave2uvm-targets
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/src/include/
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/crave2uvm
    FILES_MATCHING PATTERN "*.h"
)

set(CRAVE2UVM_CMAKE_CONFIG_DIR ${CMAKE_INSTALL_LIBDIR}/cmake/crave2uvm)
include(CMakePackageConfigHelpers)

install(EXPORT crave2uvm-targets
    NAMESPACE crave2uvm::
    DESTINATION ${CRAVE2UVM_CMAKE_CONFIG_DIR}
)

write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/crave2uvm-config-version.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY AnyNewerVersion
)

configure_package_config_file(
    ${CMAKE_CURRENT_LIST_DIR}/cmake/crave2uvm-config.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/crave2uvm-config.cmake
    INSTALL_DESTINATION ${CRAVE2UVM_CMAKE_CONFIG_DIR}
)

install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/crave2uvm-config.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/crave2uvm-config-version.cmake
    DESTINATION ${CRAVE2UVM_CMAKE_CONFIG_DIR})

add_subdirectory(examples)
