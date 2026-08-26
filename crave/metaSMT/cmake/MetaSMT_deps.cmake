# MetaSMT Source Resolution and Export Helpers

include(FetchContent)

# Directory for staging sources for export.
set(METASMT_EXPORT_STAGING_DIR "${CMAKE_BINARY_DIR}/metasmt-export-staging")
# Final bundle path.
set(METASMT_EXPORT_DEPS_BUNDLE "${CMAKE_BINARY_DIR}/metasmt-deps.tar.gz")

if(NOT METASMT_DEPS_DIR)
    # Internal target that prepares the staging area and collects dependency sources.
    add_custom_target(metasmt-export-deps-stage
        COMMAND ${CMAKE_COMMAND} -E remove_directory "${METASMT_EXPORT_STAGING_DIR}"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${METASMT_EXPORT_STAGING_DIR}"
        COMMENT "Preparing metaSMT dependency staging area"
    )

    # Public target to create the final bundle from the staging directory.
    add_custom_target(metasmt-export-deps
        DEPENDS metasmt-export-deps-stage
        COMMAND ${CMAKE_COMMAND} -E chdir "${METASMT_EXPORT_STAGING_DIR}" ${CMAKE_COMMAND} -E tar czf "${METASMT_EXPORT_DEPS_BUNDLE}" .
        COMMENT "Creating metaSMT dependency bundle: ${METASMT_EXPORT_DEPS_BUNDLE}"
    )
endif()

# Macro to resolve local source directory if METASMT_DEPS_DIR is set.
macro(metasmt_resolve_local_source name out_var)
    if(METASMT_DEPS_DIR)
        set(_local_source "${METASMT_DEPS_DIR}/${name}")
        if(NOT IS_DIRECTORY "${_local_source}")
            message(FATAL_ERROR "Offline mode: ${name} source directory not found at ${_local_source}")
        endif()
        set(${out_var} SOURCE_DIR "${_local_source}")
        message(STATUS "Offline mode: Using local source for ${name} from ${_local_source}")
    endif()
endmacro()

# Function to add a dependency for the export staging target.
function(metasmt_export_depends_on target)
    if(NOT METASMT_DEPS_DIR)
        add_dependencies(metasmt-export-deps-stage ${target})
    endif()
endfunction()

# Function to register an arbitrary source directory for export staging.
function(metasmt_register_source_dir_for_export name source_dir)
    if(NOT METASMT_DEPS_DIR)
        add_custom_command(TARGET metasmt-export-deps-stage POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E make_directory "${METASMT_EXPORT_STAGING_DIR}/${name}"
            COMMAND ${CMAKE_COMMAND} -E copy_directory "${source_dir}" "${METASMT_EXPORT_STAGING_DIR}/${name}"
            # Drop top-level Git metadata to keep the export bundle small and source-only.
            COMMAND ${CMAKE_COMMAND} -E remove_directory "${METASMT_EXPORT_STAGING_DIR}/${name}/.git"
            COMMENT "Staging ${name} source for export from ${source_dir}"
        )
    endif()
endfunction()

# Macro to register an ExternalProject for export.
macro(metasmt_register_dep_for_export name target)
    if(NOT METASMT_DEPS_DIR)
        # Ensure we have the SOURCE_DIR property.
        ExternalProject_Get_Property(${target} SOURCE_DIR)

        # Make the staging target depend on the download step of this solver.
        # This ensures sources are available before staging.
        if(TARGET ${target}-download)
            metasmt_export_depends_on(${target}-download)
        else()
            # Fallback for backends that don't use standard download steps (if any).
            metasmt_export_depends_on(${target})
        endif()

        metasmt_register_source_dir_for_export(${name} "${SOURCE_DIR}")
    endif()
endmacro()

# Function to populate a FetchContent backend and stage its source tree for export.
function(metasmt_populate_fetchcontent name repo_name source_args_var source_dir_var)
    metasmt_resolve_local_source(${name} ${source_args_var})

    FetchContent_Declare(
        ${repo_name}
        ${${source_args_var}}
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    )
    FetchContent_GetProperties(${repo_name})

    if(NOT ${repo_name}_POPULATED)
        FetchContent_Populate(${repo_name})
    endif()

    set(${source_dir_var} "${${repo_name}_SOURCE_DIR}" PARENT_SCOPE)
    metasmt_register_source_dir_for_export(${name} "${${repo_name}_SOURCE_DIR}")
endfunction()
