function(find_cmake_path path)
    set(options EXIT_ON_FAIL)
    set(oneValueArgs OUT_VAR)
    set(multiValueArgs "")

    cmake_parse_arguments(FIND_CMAKE_PATH "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if (EXISTS ${path})
        set(${FIND_CMAKE_PATH_OUT_VAR} ${path} PARENT_SCOPE)
        return()
    endif ()

    cmake_path(IS_RELATIVE path SHOULD_EXPAND_PATH)
    if (SHOULD_EXPAND_PATH)
        cmake_path(ABSOLUTE_PATH path BASE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} OUTPUT_VARIABLE SOURCE_PATH)
        if (EXISTS ${SOURCE_PATH})
            set(${FIND_CMAKE_PATH_OUT_VAR} ${SOURCE_PATH} PARENT_SCOPE)
            return()
        endif ()

        cmake_path(ABSOLUTE_PATH path BASE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR} OUTPUT_VARIABLE BINARY_PATH)
        if (EXISTS ${BINARY_PATH})
            set(${FIND_CMAKE_PATH_OUT_VAR} ${BINARY_PATH} PARENT_SCOPE)
            return()
        endif ()
    endif ()

    if (FIND_CMAKE_PATH_EXIT_ON_FAIL)
        message(FATAL_ERROR "Could not find the given path ${path}")
    endif ()
endfunction()

function(find_cmake_relative_path path)
    set(options "")
    set(oneValueArgs OUT_VAR)
    set(multiValueArgs "")

    cmake_parse_arguments(FIND_CMAKE_REL_PATH "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    cmake_path(IS_PREFIX CMAKE_CURRENT_SOURCE_DIR ${path} IS_SOURCE_DIRECTORY)
    if (IS_SOURCE_DIRECTORY)
        cmake_path(RELATIVE_PATH path BASE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} OUTPUT_VARIABLE ${FIND_CMAKE_REL_PATH_OUT_VAR})
        set(${FIND_CMAKE_REL_PATH_OUT_VAR} ${${FIND_CMAKE_REL_PATH_OUT_VAR}} PARENT_SCOPE)
    endif()

    cmake_path(IS_PREFIX CMAKE_CURRENT_BINARY_DIR ${path} IS_BINARY_DIRECTORY)
    if (IS_BINARY_DIRECTORY)
        cmake_path(RELATIVE_PATH path BASE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR} OUTPUT_VARIABLE ${FIND_CMAKE_REL_PATH_OUT_VAR})
        set(${FIND_CMAKE_REL_PATH_OUT_VAR} ${${FIND_CMAKE_REL_PATH_OUT_VAR}} PARENT_SCOPE)
    endif()

    set(${FIND_CMAKE_REL_PATH_OUT_VAR} ${path})
endfunction()
