set(LINGELING_SOURCE_ARGS
    URL https://fmv.jku.at/lingeling/lingeling-ayv-86bf266-140429.zip
)

metasmt_populate_fetchcontent(lingeling lingeling_repo LINGELING_SOURCE_ARGS lingeling_repo_SOURCE_DIR)

execute_process(
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_LIST_DIR}/LingelingCMakeLists.txt CMakeLists.txt
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_LIST_DIR}/lglcfg.h.in.cmake .
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_LIST_DIR}/lglcflags.h.in.cmake .
    WORKING_DIRECTORY ${lingeling_repo_SOURCE_DIR}
)

add_subdirectory(${lingeling_repo_SOURCE_DIR} ${CMAKE_BINARY_DIR}/lingeling)

message(STATUS "Use Lingeling ayv-86bf266-140429 from ${CMAKE_INSTALL_PREFIX}")
