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

SET(CRAVE_LIB_SRC 
  lib/ConstrainedRandom.cpp
  lib/ConstrainedRandomInit.cpp
  lib/EvalVisitor.cpp
  lib/FixWidthVisitor.cpp
  lib/GetSupportSetVisitor.cpp
  lib/metaSMTNodeVisitor.cpp
  lib/metaSMTNodeVisitorYices2.cpp
  lib/ReplaceVisitor.cpp
  lib/ToDotNodeVisitor.cpp
  lib/CraveSettings.cpp
  lib/Generator.cpp
  lib/SettingType.cpp
  lib/VariableCoverageGenerator.cpp
  lib/ConstraintPartition.cpp
  lib/Evaluator.cpp
  lib/RandObjGenerator.cpp
  lib/VariableCoverageSolver.cpp
  lib/VariableDefaultSolver.cpp
  lib/VariableGeneratorType.cpp
  lib/VariableSolver.cpp
  lib/VectorGenerator.cpp
  lib/UserVectorConstraint.cpp
  lib/UserConstraintType.cpp
  lib/ConstraintManager.cpp
  lib/ConstraintPartitioner.cpp
  lib/Operators.cpp
  lib/Distribution.cpp
  lib/RandomBase.cpp
  lib/VariableGeneratorMT.cpp
  lib/ComplexityEstimationVisitor.cpp
  lib/RandomSeedManager.cpp
)

if (CRAVE_ENABLE_EXPERIMENTAL)
  LIST(APPEND CRAVE_LIB_SRC
    lib/experimental/Object.cpp	
    lib/experimental/GraphVisitor.cpp	
    lib/experimental/ConstrainedRandomGraph.cpp  
    lib/experimental/Experimental.cpp
    lib/experimental/ConstraintBase.cpp
    lib/experimental/SequenceItem.cpp
    lib/experimental/Expression.cpp
    lib/experimental/graph/Rule.cpp
  )
endif (CRAVE_ENABLE_EXPERIMENTAL)

add_library (${PROJECT_NAME}
  ${CRAVE_LIB_SRC}
)

add_library(crave::crave ALIAS ${PROJECT_NAME})

if(NOT TARGET Boost::filesystem)
  message(FATAL_ERROR "Boost::filesystem target missing. Ensure crave_find_or_fetch_boost() ran before configuring crave.")
endif()
target_link_libraries (${PROJECT_NAME} PRIVATE Boost::filesystem)

find_package(GLOG)
if(GLOG_FOUND)
  target_compile_options(${PROJECT_NAME} PUBLIC -DCRAVE_HAVE_GLOG)
  target_include_directories(${PROJECT_NAME} PUBLIC ${GLOG_INCLUDE_DIRS})
  target_link_libraries (${PROJECT_NAME} PUBLIC ${GLOG_LIBRARIES})
endif()


if(MINGW)
    target_compile_options(${PROJECT_NAME} PRIVATE -Wa,-mbig-obj)
endif()
if(metaSMT_USE_Boolector)
    target_compile_definitions(${PROJECT_NAME} PRIVATE -DmetaSMT_USE_Boolector)
endif()
if(metaSMT_USE_CVC4)
  target_compile_definitions(${PROJECT_NAME} PRIVATE -DmetaSMT_USE_CVC4)
endif()
if(metaSMT_USE_STP)
  target_compile_definitions(${PROJECT_NAME} PRIVATE -DmetaSMT_USE_STP)
endif()
if(metaSMT_USE_SWORD)
  target_compile_definitions(${PROJECT_NAME} PRIVATE -DmetaSMT_USE_SWORD)
endif()
if(metaSMT_USE_YICES2)
  target_compile_definitions(${PROJECT_NAME} PRIVATE -DmetaSMT_USE_YICES2)
endif()
if(metaSMT_USE_Z3)
  target_compile_definitions(${PROJECT_NAME} PRIVATE -DmetaSMT_USE_Z3 -DmetaSMT_Z3_ULL_API)
endif()
if(metaSMT_USE_CUDD)
  target_compile_definitions(${PROJECT_NAME} PRIVATE -DmetaSMT_USE_CUDD)
endif()

target_link_libraries(${PROJECT_NAME} PUBLIC metaSMT::metaSMT Boost::filesystem)
if(WITH_SYSTEMC)
  target_link_libraries (${PROJECT_NAME} PUBLIC SystemC::systemc Threads::Threads)
  target_compile_definitions(${PROJECT_NAME} PRIVATE -DWITH_SYSTEMC)
endif()

target_include_directories(${PROJECT_NAME} PUBLIC 
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
    $<INSTALL_INTERFACE:include>)

#### INSTALL 
include(GNUInstallDirs)
install(TARGETS ${PROJECT_NAME} EXPORT crave-targets
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/crave
)

set(CRAVE_CMAKE_CONFIG_DIR ${CMAKE_INSTALL_LIBDIR}/cmake/crave)
include(CMakePackageConfigHelpers)

install(EXPORT crave-targets
    NAMESPACE crave::
    DESTINATION ${CRAVE_CMAKE_CONFIG_DIR}
)

write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/crave-config-version.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY AnyNewerVersion
)

configure_package_config_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/../cmake/crave-config.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/crave-config.cmake
    INSTALL_DESTINATION ${CRAVE_CMAKE_CONFIG_DIR}
)

install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/crave-config.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/crave-config-version.cmake
    DESTINATION ${CRAVE_CMAKE_CONFIG_DIR})


install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/crave
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    FILES_MATCHING PATTERN "*.hpp"
)
