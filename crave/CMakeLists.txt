########################################################################################
##	MIT License
########################################################################################
##	Copyright (c) 2012-2020 University of Bremen, Germany. 
##  	Copyright (c) 2015-2020 DFKI GmbH Bremen, Germany.
##  	Copyright (c) 2020 Johannes Kepler University Linz, Austria.
##
##	Permission is hereby granted, free of charge, to any person obtaining a copy
##	of this software and associated documentation files (the "Software"), to deal
##	in the Software without restriction, including without limitation the rights
##	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
##	copies of the Software, and to permit persons to whom the Software is
##	furnished to do so, subject to the following conditions:
##
##	The above copyright notice and this permission notice shall be included in all
##	copies or substantial portions of the Software.
##
##	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
##	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
##	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
##	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
##	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
##	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
##	SOFTWARE.
##########################################################################################
cmake_minimum_required(VERSION 3.20)
project(crave VERSION 1.0.0 LANGUAGES CXX)

if (NOT CMAKE_CXX_STANDARD)
  set(CMAKE_CXX_STANDARD 11)
endif()
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(${PROJECT_NAME}_CONFIG_DIR "share/${PROJECT_NAME}" CACHE PATH "where to install CMake and Make Config files")

set(CMAKE_POSITION_INDEPENDENT_CODE ON)
list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake)

option(CRAVE_ENABLE_EXPERIMENTAL "enable experimental extensions of CRAVE" ON)
option(CRAVE_ENABLE_TESTS "build tests" ON)
option(CRAVE_BUILD_EXAMPLES "build and test examples" ON)

if(WITH_SYSTEMC)
    crave_find_or_fetch_systemc()
    find_package(Threads REQUIRED)
endif()

add_subdirectory(metaSMT)
add_subdirectory(src)

if(CRAVE_ENABLE_TESTS)
    enable_testing()
    add_subdirectory(tests)
endif()

if(CRAVE_BUILD_EXAMPLES)
    enable_testing()
    add_subdirectory(examples)
endif()
