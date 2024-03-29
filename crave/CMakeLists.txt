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



project(crave)
cmake_minimum_required(VERSION 2.8.9)

set(${PROJECT_NAME}_CONFIG_DIR "share/${PROJECT_NAME}" CACHE PATH 
  "where to install CMake and Make Config files")

set(CMAKE_BUILD_TYPE Release)
############################################################
##                CRAVE settings                          ##
############################################################

option(CRAVE_ENABLE_EXPERIMENTAL "enable experimental extensions of CRAVE" on)
option(CRAVE_ENABLE_TESTS        "build tests" on)
option(CRAVE_BUILD_EXAMPLES      "build and test examples" on)

### C++11 required
include(CheckCXXCompilerFlag)
CHECK_CXX_COMPILER_FLAG("-std=c++11" COMPILER_SUPPORTS_CXX11)
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

if (MINGW)
  add_definitions(-Wa,-mbig-obj)
endif()

### packages
set(CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake)

set(Boost_NO_BOOST_CMAKE true)
set(Boost_NO_SYSTEM_PATHS true)

if (WIN32 AND (NOT MINGW))
  if (MSVC AND (NOT MSVC_VERSION LESS 1900))
    find_package(Boost REQUIRED)
  else()
    message(FATAL_ERROR "CRAVE Windows build only supports Visual Studio C++ 2015 or newer version")
  endif()
else()
  find_package(Boost REQUIRED COMPONENTS system filesystem)
endif()

find_package(GLOG)

if (GLOG_FOUND)
  add_definitions(-DCRAVE_HAVE_GLOG)
endif()

if (WITH_SYSTEMC)
  find_package(SystemC REQUIRED)
  find_package(Threads REQUIRED)
endif()

add_subdirectory(metaSMT)
list(INSERT CMAKE_PREFIX_PATH 0 "${CMAKE_BINARY_DIR}")
find_package(metaSMT REQUIRED)
string(REPLACE " " ";" metaSMT_DEFINITIONS "${metaSMT_CXXFLAGS}")
add_definitions(${metaSMT_DEFINITIONS})

### FIXME this should not be necessary, reuse variables set by metaSMT instead
if ( WIN32 )
  message(STATUS "CRAVE Windows build: explicitly disable all solvers except z3 or CUDD!" )
  set(metaSMT_USE_SWORD off)
  set(metaSMT_USE_Boolector  off)
  set(metaSMT_USE_STP off)
  set(metaSMT_USE_CVC4 off)
  set(metaSMT_USE_YICES2 off)
  set(metaSMT_USE_MiniSat off)
  set(metaSMT_USE_picosat off)
  set(metaSMT_USE_lingeling off)
  set(metaSMT_USE_Aiger off)
  set(metaSMT_USE_CW off)
endif()

### SMT solvers
if (metaSMT_USE_Boolector)
  add_definitions(-DmetaSMT_USE_Boolector)
endif()
if (metaSMT_USE_CVC4)
  add_definitions(-DmetaSMT_USE_CVC4)
endif()
if (metaSMT_USE_STP)
  add_definitions(-DmetaSMT_USE_STP)
endif()
if (metaSMT_USE_SWORD)
  add_definitions(-DmetaSMT_USE_SWORD)
endif()
if (metaSMT_USE_YICES2)
  add_definitions(-DmetaSMT_USE_YICES2)
endif()
if (metaSMT_USE_Z3)
  add_definitions(-DmetaSMT_USE_Z3)
endif()

### BDD
if (metaSMT_USE_CUDD)
  add_definitions(-DmetaSMT_USE_CUDD)
endif()

if (WITH_SYSTEMC)
  add_definitions(-DWITH_SYSTEMC)
endif()

### includes
include_directories(${metaSMT_INCLUDE_DIR})
include_directories(${Boost_INCLUDE_DIRS})

if (GLOG_FOUND)
  include_directories(${GLOG_INCLUDE_DIRS})
endif()

if(SystemC_FOUND)
  include_directories(${SystemC_INCLUDE_DIR})
endif(SystemC_FOUND)

### libs
SET(ALL_EXTERNAL_LIBS "")

if (GLOG_FOUND)
  LIST(APPEND ALL_EXTERNAL_LIBS ${GLOG_LIBRARIES})
endif()

if(SystemC_FOUND)
  LIST(APPEND ALL_EXTERNAL_LIBS ${SystemC_LIBRARY} ${CMAKE_THREAD_LIBS_INIT})
endif(SystemC_FOUND)

if( Boost_FILESYSTEM_FOUND )
  list(APPEND ALL_EXTERNAL_LIBS ${Boost_FILESYSTEM_LIBRARY})
endif()

if( Boost_SYSTEM_FOUND )
  list(APPEND ALL_EXTERNAL_LIBS ${Boost_SYSTEM_LIBRARY})
endif()

### build
add_subdirectory(src)

### tests
if (CRAVE_ENABLE_TESTS)
  enable_testing()
  add_subdirectory(tests)
endif()

if (CRAVE_BUILD_EXAMPLES)
  enable_testing()
  add_subdirectory(examples)
endif()

### config
set(${PROJECT_NAME}_LIBS ${CMAKE_INSTALL_PREFIX}/lib/lib${PROJECT_NAME}.a ${ALL_EXTERNAL_LIBS} ${metaSMT_LIBRARIES})

GET_DIRECTORY_PROPERTY(ALL_INCLUDES INCLUDE_DIRECTORIES)
set(${PROJECT_NAME}_INCLUDE ${CMAKE_INSTALL_PREFIX}/include ${ALL_INCLUDES})

GET_DIRECTORY_PROPERTY(${PROJECT_NAME}_DEFS COMPILE_DEFINITIONS)

## create CRAVE CMake config file
file(WRITE ${PROJECT_BINARY_DIR}/${PROJECT_NAME}Config.cmake
"set(${PROJECT_NAME}_FOUND 1)
set(${PROJECT_NAME}_INCLUDE_DIR ${${PROJECT_NAME}_INCLUDE})
set(${PROJECT_NAME}_LIBRARIES ${${PROJECT_NAME}_LIBS})
set(${PROJECT_NAME}_DEFINITIONS ${${PROJECT_NAME}_DEFS})
")

## create CRAVE py config file
file(WRITE ${PROJECT_BINARY_DIR}/${PROJECT_NAME}Config.py
"${PROJECT_NAME}_INCLUDES = '${${PROJECT_NAME}_INCLUDE}'
${PROJECT_NAME}_LIBRARIES = '${${PROJECT_NAME}_LIBS}'
${PROJECT_NAME}_DEFINITIONS = '${${PROJECT_NAME}_DEFS}'
")

string(REPLACE ";" " " ${PROJECT_NAME}_MLIBS "${${PROJECT_NAME}_LIBS}")
string(REPLACE ";" " -I" ${PROJECT_NAME}_MINCLUDE "${${PROJECT_NAME}_INCLUDE}")
string(REPLACE ";" " -D" ${PROJECT_NAME}_MDEFS "${${PROJECT_NAME}_DEFS}")
set(${PROJECT_NAME}_RPATH "")
foreach(LIBPATH ${${PROJECT_NAME}_LIBS})
  get_filename_component(LIBDIR ${LIBPATH} PATH)
  LIST(APPEND ${PROJECT_NAME}_RPATH -Wl,-rpath=${LIBDIR})
endforeach()  
string(REPLACE ";" " " ${PROJECT_NAME}_RPATH "${${PROJECT_NAME}_RPATH}")

## create CRAVE CMake make config file
file(WRITE ${PROJECT_BINARY_DIR}/${PROJECT_NAME}.makefile
"${PROJECT_NAME}_INCLUDES := ${${PROJECT_NAME}_MINCLUDE}
${PROJECT_NAME}_DEFINITIONS := ${${PROJECT_NAME}_MDEFS}
${PROJECT_NAME}_LIBRARIES := ${${PROJECT_NAME}_MLIBS}
${PROJECT_NAME}_RPATH := ${${PROJECT_NAME}_RPATH}
")

## create CRAVE pkgconfig make config file
string(REPLACE ";" " " ${PROJECT_NAME}_MLIBS "${${PROJECT_NAME}_LIBS}")
file(WRITE ${PROJECT_BINARY_DIR}/${PROJECT_NAME}.pc
"Name: ${PROJECT_NAME}
Description: Constraint Solver library
Cflags: -I${${PROJECT_NAME}_MINCLUDE} -D${${PROJECT_NAME}_MDEFS}
Libs: ${${PROJECT_NAME}_MLIBS} 
")

## install
INSTALL( FILES 
	${PROJECT_BINARY_DIR}/${PROJECT_NAME}Config.cmake
	${PROJECT_BINARY_DIR}/${PROJECT_NAME}Config.py
	${PROJECT_BINARY_DIR}/${PROJECT_NAME}.makefile
	DESTINATION ${${PROJECT_NAME}_CONFIG_DIR})
INSTALL( FILES 
	${PROJECT_BINARY_DIR}/${PROJECT_NAME}.pc
	DESTINATION lib/pkgconfig/)

############################################################
##                CPack settings                          ##
############################################################

option( CRAVE_BUNDLE_PACKAGE_BY_DATE "use date for package name instead of git description" on)

if( CRAVE_BUNDLE_PACKAGE_BY_DATE )

  # CPack version numbers for release tarball name.
  if(UNIX)
  execute_process(COMMAND date +%Y OUTPUT_VARIABLE CPACK_PACKAGE_VERSION_MAJOR ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE)
  execute_process(COMMAND date +%m OUTPUT_VARIABLE CPACK_PACKAGE_VERSION_MINOR ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE)
  execute_process(COMMAND date +%d OUTPUT_VARIABLE CPACK_PACKAGE_VERSION_PATCH ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE)
  endif()
  set(VERSION "${CPACK_PACKAGE_VERSION_MAJOR}-${CPACK_PACKAGE_VERSION_MINOR}-${CPACK_PACKAGE_VERSION_PATCH}")
else()
  include(cmake/get_git_version.cmake)
  get_git_version(VERSION crave-bundle-)
endif()

message(STATUS "crave-bundle VERSION: ${VERSION}")

set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "CRAVE - Constrained RAndom Verification Environment for SystemC/C++")
set(CPACK_PACKAGE_VENDOR "CRAVE development team")
set(CPACK_PACKAGE_DESCRIPTION_FILE ${CMAKE_CURRENT_SOURCE_DIR}/README.md)
set(CPACK_GENERATOR TGZ)
set(
CPACK_SOURCE_PACKAGE_FILE_NAME
"${PROJECT_NAME}-${VERSION}"
CACHE INTERNAL "tarball basename"
)
set(CPACK_SOURCE_GENERATOR TGZ)

set(CPACK_SOURCE_IGNORE_FILES
"/\\\\.git"
"/deps.*/"
"/build.*/"
"/root.*/"
"/crave-doxygen/"
"/logs/"
"crave.cfg"
"jenkins_run_crave_check.sh"
"~$"
"^${PROJECT_SOURCE_DIR}/scripts/"
"^${PROJECT_SOURCE_DIR}/crave.*"
"^${PROJECT_SOURCE_DIR}/.*.user"
)

if (NOT CRAVE_ENABLE_EXPERIMENTAL)
  LIST(APPEND CPACK_SOURCE_IGNORE_FILES "crave/experimental/" "lib/experimental")
endif()

include(CPack)

############################################################
##                CMAKE flags settings                    ##
############################################################

SET( CMAKE_CXX_FLAGS_PROFILING "-O0 -g -Wall -Wextra -pedantic --coverage" CACHE STRING
  "Flags used by the C++ compiler during maintainer builds."
  FORCE )
SET( CMAKE_C_FLAGS_PROFILING "${CMAKE_CXX_FLAGS_PROFILING}" CACHE STRING
  "Flags used by the C compiler during maintainer builds."
  FORCE )
SET( CMAKE_EXE_LINKER_FLAGS_PROFILING
  "--coverage" CACHE STRING
  "Flags used for linking binaries during maintainer builds."
  FORCE )
SET( CMAKE_SHARED_LINKER_FLAGS_PROFILING
  " --coverage" CACHE STRING
  "Flags used by the shared libraries linker during maintainer builds."
  FORCE )
MARK_AS_ADVANCED(
  CMAKE_CXX_FLAGS_PROFILING
  CMAKE_C_FLAGS_PROFILING
  CMAKE_EXE_LINKER_FLAGS_PROFILING
  CMAKE_SHARED_LINKER_FLAGS_PROFILING )
# Update the documentation string of CMAKE_BUILD_TYPE for GUIs
SET( CMAKE_BUILD_TYPE "${CMAKE_BUILD_TYPE}" CACHE STRING
  "Choose the type of build, options are: None Debug Release RelWithDebInfo MinSizeRel Profiling."
  FORCE )
  
