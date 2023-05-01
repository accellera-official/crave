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

project ( crave2uvm )
cmake_minimum_required(VERSION 2.8)

set (CMAKE_RUNTIME_OUTPUT_DIRECTORY ${PROJECT_SOURCE_DIR}/build/bin)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${PROJECT_SOURCE_DIR}/build/lib)
set (CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake)

#SystemC
find_package(SystemC REQUIRED)

#CRAVE
find_package(CRAVE REQUIRED)

#UVM-SystemC
find_package(UVM-SystemC REQUIRED)

#Includes setzen
include_directories (${SystemC_INCLUDE_DIRS} ${CRAVE_INCLUDE_DIRS} ${UVM_SystemC_INCLUDE_DIRS} ${PROJECT_SOURCE_DIR}/src/include)

#Compiler flags
SET( CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS} -pthread -g -ggdb")

add_subdirectory (examples)
