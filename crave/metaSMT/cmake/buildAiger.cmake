set(AIGER_SOURCE_ARGS
    URL https://fmv.jku.at/aiger/aiger-20071012.zip
)

metasmt_populate_fetchcontent(aiger aiger_repo AIGER_SOURCE_ARGS aiger_repo_SOURCE_DIR)

execute_process(
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_LIST_DIR}/AigerCMakeLists.txt CMakeLists.txt
    WORKING_DIRECTORY ${aiger_repo_SOURCE_DIR}
)

add_subdirectory(${aiger_repo_SOURCE_DIR} ${CMAKE_BINARY_DIR}/aiger)

message(STATUS "Use Aiger 20071012 from ${CMAKE_INSTALL_PREFIX}")
