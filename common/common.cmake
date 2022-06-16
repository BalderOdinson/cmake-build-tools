include(python/python)
include(tools/find_cmake_path)

function(expand_template)
    set(options "")
    set(oneValueArgs SOURCE DESTINATION)
    set(multiValueArgs KEYS VALUES DEPENDS)

    cmake_parse_arguments(EXPAND_TEMPLATE "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    find_cmake_path(${EXPAND_TEMPLATE_SOURCE} OUT_VAR EXPAND_TEMPLATE_SOURCE EXIT_ON_FAIL)
    set(args ${EXPAND_TEMPLATE_SOURCE} ${EXPAND_TEMPLATE_DESTINATION})

    foreach(key value IN ZIP_LISTS EXPAND_TEMPLATE_KEYS EXPAND_TEMPLATE_VALUES)
        set(args ${args} ${key} ${value})
    endforeach()

    add_python_output(OUTPUT "${EXPAND_TEMPLATE_DESTINATION}"
            SCRIPT ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/expand_template.py
            ARGS ${args}
            PYTHON_ENV py-tools
            DEPENDS ${EXPAND_TEMPLATE_SOURCE} ${EXPAND_TEMPLATE_DEPENDS})
endfunction()
