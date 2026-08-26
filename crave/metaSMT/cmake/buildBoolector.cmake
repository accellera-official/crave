set(BOOLECTOR_SOURCE_ARGS
  GIT_REPOSITORY https://github.com/Boolector/boolector.git
  GIT_TAG 3.2.3
)

# Resolve local source if in offline mode
metasmt_resolve_local_source(boolector BOOLECTOR_SOURCE_ARGS)

set(BOOLECTOR_BTOR2TOOLS_SOURCE_ARGS
  URL https://github.com/boolector/btor2tools/archive/1df768d75adfb13a8f922f5ffdd1d58e80cb1cc2.tar.gz
)

# Resolve local source if in offline mode
metasmt_resolve_local_source(boolector-btor2tools BOOLECTOR_BTOR2TOOLS_SOURCE_ARGS)

set(BOOLECTOR_CADICAL_SOURCE_ARGS
  URL https://github.com/arminbiere/cadical/archive/cb89cbfa16f47cb7bf1ec6ad9855e7b6d5203c18.tar.gz
)

# Resolve local source if in offline mode
metasmt_resolve_local_source(boolector-cadical BOOLECTOR_CADICAL_SOURCE_ARGS)

set(BOOLECTOR_LINGELING_SOURCE_ARGS
  URL https://github.com/arminbiere/lingeling/archive/7d5db72420b95ab356c98ca7f7a4681ed2c59c70.tar.gz
)

# Resolve local source if in offline mode
metasmt_resolve_local_source(boolector-lingeling BOOLECTOR_LINGELING_SOURCE_ARGS)

if(NOT METASMT_DEPS_DIR)
  # Fetch source trees separately so Boolector export stays source-only.
  ExternalProject_Add(boolector_export_src
    ${BOOLECTOR_SOURCE_ARGS}
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
    STEP_TARGETS download
  )
  ExternalProject_Add(boolector_btor2tools_export_src
    ${BOOLECTOR_BTOR2TOOLS_SOURCE_ARGS}
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
    STEP_TARGETS download
  )
  ExternalProject_Add(boolector_cadical_export_src
    ${BOOLECTOR_CADICAL_SOURCE_ARGS}
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
    STEP_TARGETS download
  )
  ExternalProject_Add(boolector_lingeling_export_src
    ${BOOLECTOR_LINGELING_SOURCE_ARGS}
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
    STEP_TARGETS download
  )

  ExternalProject_Get_Property(boolector_export_src SOURCE_DIR)
  set(BOOLECTOR_EXPORT_SOURCE_DIR "${SOURCE_DIR}")
  ExternalProject_Get_Property(boolector_btor2tools_export_src SOURCE_DIR)
  set(BOOLECTOR_BTOR2TOOLS_EXPORT_SOURCE_DIR "${SOURCE_DIR}")
  ExternalProject_Get_Property(boolector_cadical_export_src SOURCE_DIR)
  set(BOOLECTOR_CADICAL_EXPORT_SOURCE_DIR "${SOURCE_DIR}")
  ExternalProject_Get_Property(boolector_lingeling_export_src SOURCE_DIR)
  set(BOOLECTOR_LINGELING_EXPORT_SOURCE_DIR "${SOURCE_DIR}")

  metasmt_export_depends_on(boolector_export_src-download)
  metasmt_export_depends_on(boolector_btor2tools_export_src-download)
  metasmt_export_depends_on(boolector_cadical_export_src-download)
  metasmt_export_depends_on(boolector_lingeling_export_src-download)

  # Stage Boolector export sources directly so no helper step builds libraries.
  add_custom_command(TARGET metasmt-export-deps-stage POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory "${METASMT_EXPORT_STAGING_DIR}/boolector"
    COMMAND bash -c "cp -a '${BOOLECTOR_EXPORT_SOURCE_DIR}/.' '${METASMT_EXPORT_STAGING_DIR}/boolector'"
    COMMAND ${CMAKE_COMMAND} -E remove_directory "${METASMT_EXPORT_STAGING_DIR}/boolector/.git"
    COMMAND ${CMAKE_COMMAND} -E make_directory "${METASMT_EXPORT_STAGING_DIR}/boolector-btor2tools"
    COMMAND bash -c "cp -a '${BOOLECTOR_BTOR2TOOLS_EXPORT_SOURCE_DIR}/.' '${METASMT_EXPORT_STAGING_DIR}/boolector-btor2tools'"
    COMMAND ${CMAKE_COMMAND} -E remove_directory "${METASMT_EXPORT_STAGING_DIR}/boolector-btor2tools/.git"
    COMMAND ${CMAKE_COMMAND} -E make_directory "${METASMT_EXPORT_STAGING_DIR}/boolector-cadical"
    COMMAND bash -c "cp -a '${BOOLECTOR_CADICAL_EXPORT_SOURCE_DIR}/.' '${METASMT_EXPORT_STAGING_DIR}/boolector-cadical'"
    COMMAND ${CMAKE_COMMAND} -E remove_directory "${METASMT_EXPORT_STAGING_DIR}/boolector-cadical/.git"
    COMMAND ${CMAKE_COMMAND} -E make_directory "${METASMT_EXPORT_STAGING_DIR}/boolector-lingeling"
    COMMAND bash -c "cp -a '${BOOLECTOR_LINGELING_EXPORT_SOURCE_DIR}/.' '${METASMT_EXPORT_STAGING_DIR}/boolector-lingeling'"
    COMMAND ${CMAKE_COMMAND} -E remove_directory "${METASMT_EXPORT_STAGING_DIR}/boolector-lingeling/.git"
    COMMENT "Staging Boolector sources for export"
  )
endif()

set(install_dir ${CMAKE_INSTALL_PREFIX})
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    set(install_dir ${CMAKE_BINARY_DIR}/solvers/boolector)
endif()

file(MAKE_DIRECTORY "${install_dir}/include")
file(MAKE_DIRECTORY "${install_dir}/lib")
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

set(BOOLECTOR_CONFIGURE_COMMAND
  bash -c "./contrib/setup-lingeling.sh && ./contrib/setup-btor2tools.sh && ./contrib/setup-cadical.sh && ./configure.sh --prefix ${install_dir} --shared"
)

if(METASMT_DEPS_DIR)
  # Build Boolector's bundled internal dependencies from the offline source trees.
  set(BOOLECTOR_CONFIGURE_COMMAND
    bash -c "set -e -o pipefail && rm -rf deps/btor2tools deps/cadical deps/lingeling deps/install && mkdir -p deps && cp -a '${METASMT_DEPS_DIR}/boolector-btor2tools' deps/btor2tools && cp -a '${METASMT_DEPS_DIR}/boolector-cadical' deps/cadical && cp -a '${METASMT_DEPS_DIR}/boolector-lingeling' deps/lingeling && source ./contrib/setup-utils.sh && cd deps/lingeling && ./configure.sh -fPIC && make -j${NPROC} && install_lib liblgl.a && install_include lglib.h && cd ../../ && cd deps/btor2tools && ./configure.sh -fPIC && make -j${NPROC} && install_lib build/libbtor2parser.a && install_include src/btor2parser/btor2parser.h && cd ../../ && cd deps/cadical && export CXXFLAGS='-fPIC' && ./configure && make -j${NPROC} && install_lib build/libcadical.a && install_include src/ccadical.h && cd ../../ && ./configure.sh --prefix ${install_dir} --shared"
  )
endif()

ExternalProject_Add(boolector_ext
  ${BOOLECTOR_SOURCE_ARGS}
  DOWNLOAD_EXTRACT_TIMESTAMP TRUE
  UPDATE_COMMAND ""
  PATCH_COMMAND ""
  CONFIGURE_COMMAND ${BOOLECTOR_CONFIGURE_COMMAND}
  BUILD_COMMAND bash -c "make -C build -j${CRAVE_BUILD_JOBS}"
  INSTALL_COMMAND bash -c "make -C build install"
  BUILD_IN_SOURCE 1
  BUILD_BYPRODUCTS ${install_dir}/lib/libboolector.so
)

set(Boolector_VERSION 3.2.3 CACHE STRING "" FORCE)
set(Boolector_FOUND TRUE CACHE BOOL "" FORCE)
set(Boolector_INCLUDE_DIRS "${install_dir}/include" CACHE PATH "" FORCE)

add_library(Boolector::boolector UNKNOWN IMPORTED)
set_target_properties(Boolector::boolector PROPERTIES
  IMPORTED_LOCATION ${install_dir}/lib/libboolector.so
  INTERFACE_INCLUDE_DIRECTORIES ${install_dir}/include
)
add_dependencies(Boolector::boolector boolector_ext)

set(boolector_CMAKE_CONFIG_DIR ${CMAKE_INSTALL_LIBDIR}/cmake/boolector)
set(SOLVER_TARGET "Boolector::boolector")
set(SOLVER_VARNAME "Boolector")
set(SOLVER_LIBNAME "libboolector.so")
set(SOLVER_LIBDIR "lib")
set(SOLVER_INCLUDEDIR "include")
set(SOLVER_FIND_DEPS "")
set(SOLVER_SET_LINK_LIBS "")

write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/boolector-config-version.cmake
    VERSION 3.2.3
    COMPATIBILITY AnyNewerVersion
)

configure_package_config_file(
    ${CMAKE_CURRENT_LIST_DIR}/solver-config.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/boolector-config.cmake
    INSTALL_DESTINATION ${boolector_CMAKE_CONFIG_DIR}
)

install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/boolector-config.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/boolector-config-version.cmake
    DESTINATION ${boolector_CMAKE_CONFIG_DIR}
)

message(STATUS "Use Boolector ${Boolector_VERSION} from ${install_dir}")
