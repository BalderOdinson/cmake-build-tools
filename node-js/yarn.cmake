include(node-js/node)
include(tools/find_cmake_path)

function(yarn_project package_json)
    find_cmake_path(${package_json} OUT_VAR PACKAGE_JSON_PATH EXIT_ON_FAIL)
    cmake_path(GET PACKAGE_JSON_PATH PARENT_PATH PACKAGE_JSON_DIR)
    set_property(DIRECTORY PROPERTY PACKAGE_JSON_DIR ${PACKAGE_JSON_DIR})
    execute_process(COMMAND ${YARN_EXECUTABLE} install --frozen-lockfile --cwd=${PACKAGE_JSON_DIR})
endfunction()

function(yarn_run script_name)
    get_property(PACKAGE_JSON_DIR DIRECTORY PROPERTY PACKAGE_JSON_DIR)
    execute_process(COMMAND ${YARN_EXECUTABLE} run --cwd=${PACKAGE_JSON_DIR} ${script_name} ${ARGN})
endfunction()

function(yarn_run_output script_name out_var err_var)
    get_property(PACKAGE_JSON_DIR DIRECTORY PROPERTY PACKAGE_JSON_DIR)
    execute_process(COMMAND ${YARN_EXECUTABLE} -s run --cwd=${PACKAGE_JSON_DIR} ${script_name} ${ARGN} OUTPUT_VARIABLE OUT_VAR ERROR_VARIABLE ERR_VAR OUTPUT_STRIP_TRAILING_WHITESPACE)
    set(${out_var} ${OUT_VAR} PARENT_SCOPE)
    set(${err_var} ${ERR_VAR} PARENT_SCOPE)
endfunction()

function(FindYarn)
    FindNode()

    set(options "")
    set(oneValueArgs VERSION)
    set(multiValueArgs "")

    cmake_parse_arguments(FIND_YARN "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if (NOT FIND_YARN_VERSION)
        set(FIND_YARN_VERSION "1.22.19")
    endif ()

    set(YARN_PATH "" CACHE FILEPATH "Path where to find the yarn package manager")
    set(YARN_EXECUTABLE "" CACHE INTERNAL "Path to yarn executable")
    set(YARN_FOUND OFF CACHE INTERNAL "Indicates if yarn was found")

    set_property(GLOBAL PROPERTY TOOLS_PACKAGE_JSON_DIR ${CMAKE_CURRENT_FUNCTION_LIST_DIR})

    if (YARN_FOUND)
        execute_process(COMMAND ${YARN_EXECUTABLE} --version OUTPUT_VARIABLE YARN_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
        message("-- Found Yarn: ${YARN_EXECUTABLE} (found version \"${YARN_VERSION}\")")
        return()
    endif()

    set(YARN_BASE_URL "https://github.com/yarnpkg/yarn/releases/download/v")

    set(YARN_URL ${YARN_BASE_URL}${FIND_YARN_VERSION}/yarn-v${FIND_YARN_VERSION}.tar.gz)
    set(YARN_FOLDER_NAME "yarn-v${FIND_YARN_VERSION}")

    FetchContent_Declare(${YARN_FOLDER_NAME} URL ${YARN_URL})
    FetchContent_MakeAvailable(${YARN_FOLDER_NAME})

    set(YARN_DIR ${${YARN_FOLDER_NAME}_SOURCE_DIR})
    if (WIN32)
        set(YARN_EXECUTABLE "${YARN_DIR}/bin/yarn.cmd" CACHE INTERNAL "Path to yarn executable" FORCE)
    else ()
        set(YARN_EXECUTABLE "${YARN_DIR}/bin/yarn" CACHE INTERNAL "Path to yarn executable" FORCE)
    endif ()
    set(YARN_FOUND ON CACHE INTERNAL "Indicates if yarn was found" FORCE)
    execute_process(COMMAND ${YARN_EXECUTABLE} --version OUTPUT_VARIABLE YARN_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
    message("-- Found Yarn: ${YARN_EXECUTABLE} (found version \"${YARN_VERSION}\")")

    yarn_project(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/package.json)
endfunction()
