function(generate_sql)
    set(options "")
    set(oneValueArgs TARGET NAMESPACE)
    set(multiValueArgs "")

    cmake_parse_arguments(GENERATE_SQL "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    set(SQL_INPUTS)
    get_target_property(TARGET_SOURCE_LIST ${GENERATE_SQL_TARGET} SOURCES)
    foreach(TARGET_SRC ${TARGET_SOURCE_LIST})
        if(TARGET_SRC MATCHES "sql$")
            list(APPEND SQL_INPUTS ${TARGET_SRC})
        endif()
    endforeach()

    set(OUTS)
    foreach(SQL_FILE ${SQL_INPUTS})
        get_filename_component(SQL_FILE_PATH ${SQL_FILE} ABSOLUTE)
        get_filename_component(SQL_FILE_DIR ${SQL_FILE_PATH} DIRECTORY)
        file(RELATIVE_PATH SQL_FILE_REL_DIR ${CMAKE_CURRENT_SOURCE_DIR} ${SQL_FILE_DIR})

        get_filename_component(SQL_FILE_NAME ${SQL_FILE} NAME)
        string(FIND "${SQL_FILE_NAME}" "." SQL_FILE_NAME_EXT_POS REVERSE)
        string(SUBSTRING "${SQL_FILE_NAME}" 0 ${SQL_FILE_NAME_EXT_POS} SQL_FILE_BASENAME)

        set(OUT ${CMAKE_CURRENT_BINARY_DIR}/${SQL_FILE_REL_DIR}/${SQL_FILE_BASENAME}.hpp)
        list(APPEND OUTS ${OUT})

        add_python_output(OUTPUT "${OUT}"
                SCRIPT "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/generate_sql.py"
                ARGS --out "${OUT}" --sql "${SQL_FILE_PATH}" --namespace "${GENERATE_SQL_NAMESPACE}"
                PYTHON_ENV py-tools
                DEPENDS ${SQL_FILE_PATH})
    endforeach()

    set_source_files_properties(${OUTS} PROPERTIES GENERATED TRUE)
    target_sources(${GENERATE_SQL_TARGET} PRIVATE ${OUTS})
endfunction()
