########################################################################################
##	MIT License
########################################################################################
##	Copyright (c) 2011-2016 University of Bremen, Germany.
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
PROJECT(metaSMT VERSION 4.0 LANGUAGES CXX)

set(META_SMT_VERSION ${PROJECT_VERSION} CACHE STRING "metaSMT project version")

option(metaSMT_REQUIRE_CXX11 "make C++11 a requirement" on)

if ( NOT metaSMT_REQUIRE_CXX11 AND WIN32 )
  message(FATAL_ERROR "Windows build requires CXX11")
endif()

include(CheckCXXCompilerFlag)

if (metaSMT_REQUIRE_CXX11)
  if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
    if (CMAKE_CXX_COMPILER_VERSION VERSION_LESS 6.1)
      if(COMPILER_SUPPORTS_CXX11)
        add_definitions(-std=c++11)
      else()
        message(FATAL_ERROR "The compiler ${CMAKE_CXX_COMPILER} does not support -std=c++11. Please use a different C++ compiler.")
      endif()
    endif()
  else()
    if(COMPILER_SUPPORTS_CXX11)
      add_definitions(-std=c++11)
    else()
      message(FATAL_ERROR "The compiler ${CMAKE_CXX_COMPILER} does not support -std=c++11. Please use a different C++ compiler.")
    endif()
  endif()
endif()

include(CheckIncludeFileCXX)
include(FeatureSummary)

include(CTest)

set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake/Modules )

set(Boost_NO_BOOST_CMAKE true)
set(Boost_NO_SYSTEM_PATHS true)
if(NOT TARGET Boost::system OR NOT TARGET Boost::filesystem OR NOT TARGET Boost::unit_test_framework)
  message(FATAL_ERROR "Boost targets are missing. Ensure crave_find_or_fetch_boost() ran before configuring metaSMT.")
endif()

# From v1.57.0 Boost.Any does not require RTTI
if(NOT Boost_VERSION)
  set(Boost_VERSION 0)
endif()
if (Boost_VERSION VERSION_LESS 105700)
  message( STATUS "metaSMT requires RTTI" )
  set(metaSMT_REQUIRE_RTTI true)
else()
  message( STATUS "metaSMT does not require RTTI" )
  set(metaSMT_REQUIRE_RTTI false)
endif()

SET_PACKAGE_PROPERTIES(BOOST PROPERTIES DESCRIPTION "Portable C++ libraries" URL "http://www.boost.org/" TYPE REQUIRED PURPOSE "Boost provides free peer-reviewed portable C++ source libraries.")

include_directories(${Boost_INCLUDE_DIRS})

list(INSERT CMAKE_PREFIX_PATH 0 "${CMAKE_SOURCE_DIR}/cmake")

###  
# Options to force disable certain solvers. 
# set all solvers to "on" with good support and experimental or
# work in progress to "off"
###
option(metaSMT_USE_Boolector  "try to use Boolector solver" on)
option(metaSMT_USE_Z3         "try to use Z3 solver" on)
option(metaSMT_USE_STP        "try to use STP solver" on)
option(metaSMT_USE_CVC4       "try to use CVC4 solver" on)
option(metaSMT_USE_YICES2     "try to use Yices2 solver" on)
option(metaSMT_USE_CUDD       "try to use CUDD BDD package" on )
option(metaSMT_USE_MiniSat    "try to use minisat SAT solver" on)
option(metaSMT_USE_picosat    "try to use picosat SAT solver" on)
option(metaSMT_USE_lingeling  "try to use lingeling SAT solver" on)
option(metaSMT_USE_Aiger      "try to use aiger" on)
option(metaSMT_USE_CW         "try to use clause writers" on)

set(METASMT_DEPS_DIR "" CACHE PATH "Path to an unpacked metaSMT offline dependency bundle.")

# Source-resolution and export helpers for metaSMT dependencies
include(cmake/MetaSMT_deps.cmake)

option(metaSMT_DOC_Doxygen    "try to build doxygen documentation" off)
option(metaSMT_ENABLE_TESTS   "build tests (recommended)" on)

set(metaSMT_CONFIG_DIR "share/metaSMT" CACHE PATH 
  "where to install CMake and Make Config files")

if ( NOT TIMEOUT )
  set(TIMEOUT 60 CACHE STRING "The timeout for tests")
endif()

include(ExternalProject)
include(FetchContent)

if(metaSMT_USE_Boolector)
  include(cmake/buildBoolector.cmake)
endif()

if (metaSMT_USE_Z3)
  include(cmake/buildZ3.cmake)
endif()

if (metaSMT_USE_YICES2)
  include(cmake/buildYICES2.cmake)
endif()

if(metaSMT_USE_CVC4)
  include(cmake/buildCVC4.cmake)
endif()

if (metaSMT_USE_CUDD)
  include(cmake/buildCUDD.cmake)
endif ()

if (metaSMT_USE_Aiger)
  include(cmake/buildAiger.cmake)
endif()

if (metaSMT_USE_MiniSat OR metaSMT_USE_STP)
  include(cmake/buildMiniSat.cmake)
endif ()

if(metaSMT_USE_STP)
  include(cmake/buildSTP.cmake)
endif()

if (metaSMT_USE_picosat )
  include(cmake/buildPicoSat.cmake)
endif()

if( metaSMT_USE_lingeling )
  include(cmake/buildLingeling.cmake)
endif()

if (metaSMT_DOC_Doxygen)
  find_package(Doxygen)
else ()
  set(Doxygen_FOUND 0)
endif ()

############################################################
############# subdirectories ###############################
############################################################

add_subdirectory(src)
add_subdirectory(doc)

if(metaSMT_ENABLE_TESTS)
  enable_testing()
  add_subdirectory(tests)
endif()
