include(tools/find_cmake_path)

function(FindPython)
    # Find Python
    find_package(Python3 COMPONENTS Interpreter)
    set(System_Python3_EXECUTABLE "${Python3_EXECUTABLE}" CACHE INTERNAL "Path to system python executable")
endfunction()

function(use_python_env)
    set(options "")
    set(oneValueArgs NAME REQUIREMENTS)
    set(multiValueArgs "")

    cmake_parse_arguments(USE_PYTHON_ENV "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # Create virtual environment
    execute_process(COMMAND "${System_Python3_EXECUTABLE}" -m venv "${CMAKE_CURRENT_BINARY_DIR}/${USE_PYTHON_ENV_NAME}/venv")
    # Change the context of the search
    set(ENV{VIRTUAL_ENV} "${CMAKE_CURRENT_BINARY_DIR}/${USE_PYTHON_ENV_NAME}/venv")
    set(Python3_FIND_VIRTUALENV FIRST)
    # Unset Python3_EXECUTABLE because it is also an input variable (see documentation, Artifacts Specification section)
    unset(Python3_EXECUTABLE)
    # Launch a new search
    find_package(Python3 COMPONENTS Interpreter)
    # Install dependencies
    find_cmake_path(${USE_PYTHON_ENV_REQUIREMENTS} OUT_VAR REQUIREMENTS_TXT EXIT_ON_FAIL)
    execute_process(COMMAND "${Python3_EXECUTABLE}" -m pip install -r "${REQUIREMENTS_TXT}")
    set("${USE_PYTHON_ENV_NAME}_Python3_EXECUTABLE" "${Python3_EXECUTABLE}" CACHE INTERNAL "Path to python venv executable")
endfunction()

function(add_python_output)
    set(options "")
    set(oneValueArgs SCRIPT PYTHON_ENV)
    set(multiValueArgs DEPENDS OUTPUT ARGS)

    cmake_parse_arguments(ADD_PYTHON_OUTPUT "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    set(PYTHON_EXECUTABLE_VAR ${ADD_PYTHON_OUTPUT_PYTHON_ENV}_Python3_EXECUTABLE)

    find_cmake_path(${ADD_PYTHON_OUTPUT_SCRIPT} OUT_VAR ADD_PYTHON_OUTPUT_SCRIPT EXIT_ON_FAIL)

    add_custom_command(OUTPUT ${ADD_PYTHON_OUTPUT_OUTPUT}
            COMMAND "${${PYTHON_EXECUTABLE_VAR}}" "${ADD_PYTHON_OUTPUT_SCRIPT}" ${ADD_PYTHON_OUTPUT_ARGS}
            COMMENT "Generating ${ADD_PYTHON_OUTPUT_OUTPUT}"
            VERBATIM
            DEPENDS "${ADD_PYTHON_OUTPUT_SCRIPT}" ${ADD_PYTHON_OUTPUT_DEPENDS})
endfunction()

function(run_python)
    set(options "")
    set(oneValueArgs SCRIPT PYTHON_ENV)
    set(multiValueArgs ARGS)

    cmake_parse_arguments(RUN_PYTHON "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    set(PYTHON_EXECUTABLE_VAR ${RUN_PYTHON_PYTHON_ENV}_Python3_EXECUTABLE)

    find_cmake_path(${RUN_PYTHON_SCRIPT} OUT_VAR RUN_PYTHON_SCRIPT EXIT_ON_FAIL)

    execute_process(COMMAND "${${PYTHON_EXECUTABLE_VAR}}" ${RUN_PYTHON_SCRIPT} ${RUN_PYTHON_ARGS})
endfunction()
