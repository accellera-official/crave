set(PICOSAT_SOURCE_ARGS
    URL https://fmv.jku.at/picosat/picosat-965.tar.gz
)

metasmt_populate_fetchcontent(picosat picosat_repo PICOSAT_SOURCE_ARGS picosat_repo_SOURCE_DIR)

execute_process(
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_LIST_DIR}/PicosatCMakeLists.txt CMakeLists.txt
    WORKING_DIRECTORY ${picosat_repo_SOURCE_DIR}
)

add_subdirectory(${picosat_repo_SOURCE_DIR} ${CMAKE_BINARY_DIR}/picosat)

message(STATUS "Use PicoSAT 965 from ${CMAKE_INSTALL_PREFIX}")
