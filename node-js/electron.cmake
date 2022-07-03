include(tools/find_cmake_path)

function(FindElectron)
    if (WIN32)
        set(ELECTRON_EXECUTABLE ${CMAKE_CURRENT_SOURCE_DIR}/node_modules/electron/dist/electron.exe)
    else ()
        set(ELECTRON_EXECUTABLE ${CMAKE_CURRENT_SOURCE_DIR}/node_modules/electron/dist/electron)
    endif ()
    set_property(DIRECTORY PROPERTY ELECTRON_EXECUTABLE ${ELECTRON_EXECUTABLE})
    # Sometimes ELECTRON_RUN_AS_NODE=1 might be set due to other rules.
    # To ensure this does not happens we unset ELECTRON_RUN_AS_NODE
    if ($ENV{ELECTRON_RUN_AS_NODE})
        unset(ENV{ELECTRON_RUN_AS_NODE})
    endif()
    execute_process(COMMAND ${ELECTRON_EXECUTABLE} --version OUTPUT_VARIABLE ELECTRON_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
    string(REGEX REPLACE "\r?\n" "" ELECTRON_VERSION ${ELECTRON_VERSION})
    string(SUBSTRING ${ELECTRON_VERSION} 1 -1 ELECTRON_VERSION)
    message("-- Found Electron: ${ELECTRON_EXECUTABLE} (found version \"${ELECTRON_VERSION}\")")
    set_property(DIRECTORY PROPERTY ELECTRON_VERSION ${ELECTRON_VERSION})
endfunction()

function(target_set_icon target app_icon)
    find_cmake_path(${app_icon} OUT_VAR app_icon_full)
    set_property(TARGET ${target} PROPERTY APP_ICON ${app_icon_full})
endfunction()

function(add_electron_executable target main_process renderer_process)
    get_property(TOOLS_PACKAGE_JSON_DIR GLOBAL PROPERTY TOOLS_PACKAGE_JSON_DIR)
    get_property(PACKAGE_JSON_DIR DIRECTORY PROPERTY PACKAGE_JSON_DIR)
    get_property(ELECTRON_VERSION DIRECTORY PROPERTY ELECTRON_VERSION)
    get_property(ELECTRON_EXECUTABLE DIRECTORY PROPERTY ELECTRON_EXECUTABLE)

    # Generate app icon
    set(assets_out ${CMAKE_CURRENT_BINARY_DIR}/assets)

    set(app_name $<TARGET_PROPERTY:${target},APP_NAME>)
    set(app_name_expand $<IF:$<BOOL:${app_name}>,${app_name},${target}>)

    set(app_icon $<TARGET_PROPERTY:${target},APP_ICON>)
    set(icon_generator ${NPX_EXECUTABLE} electron-icon-maker)
    set(icon_generator_env ${CMAKE_COMMAND} -E env NODE_PATH=${PACKAGE_JSON_DIR}/node_modules)
    set(icon_generator_args --input=${app_icon} --output=${assets_out})
    add_custom_command(OUTPUT ${assets_out}/icons/mac/icon.icns
            COMMAND ${icon_generator_env} ${icon_generator} ${icon_generator_args}
            WORKING_DIRECTORY ${PACKAGE_JSON_DIR}
            COMMENT "Generating icon"
            DEPENDS ${app_icon})

    # Generate package.json
    set(main_sources $<TARGET_GENEX_EVAL:${main_process},$<TARGET_PROPERTY:${main_process},OUTPUTS>>)
    set(out_package_json ${CMAKE_CURRENT_BINARY_DIR}/out/package.json)

    set(icon_out $<IF:$<BOOL:${app_icon}>,${assets_out}/icons/mac/icon.icns,>)
    set(icon_arg0 $<IF:$<BOOL:${app_icon}>,ICONS_PATH,>)
    set(icon_arg1 $<IF:$<BOOL:${app_icon}>,${assets_out}/icons,>)

    set(generate_package_json_cmd ${CMAKE_COMMAND} -P
        ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/generate_package_json.cmake
        SRC ${PACKAGE_JSON_DIR}/package.json
        DST ${out_package_json}
        SOURCES ${main_sources}
        ELECTRON_VERSION ${ELECTRON_VERSION}
        ELECTRON_EXECUTABLE ${ELECTRON_EXECUTABLE}
        ${icon_arg0} ${icon_arg1})
    add_custom_command(OUTPUT ${out_package_json}
        COMMAND ${generate_package_json_cmd}
        COMMENT "Generating package.json"
        VERBATIM
        DEPENDS ${PACKAGE_JSON_DIR}/package.json
        ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/generate_package_json.cmake
        ${main_process}
        ${icon_out})

    # Define final output dir
    set(out_dir ${CMAKE_CURRENT_BINARY_DIR}/out/dist)

    # Run electron packager
    set(electron_builder ${NPX_EXECUTABLE} electron-builder)
    set(electron_builder_env ${CMAKE_COMMAND} -E env NODE_PATH=${PACKAGE_JSON_DIR}/node_modules)
    set(electron_builder_args --project ${CMAKE_CURRENT_BINARY_DIR}/out)
    set(main_process_dependencies $<TARGET_PROPERTY:${main_process},OUTPUTS>)
    set(main_process_dependencies_expand $<GENEX_EVAL:${main_process_dependencies}>)
    set(renderer_process_dependencies $<TARGET_PROPERTY:${renderer_process},OUTPUTS>)
    set(renderer_process_dependencies_expand $<GENEX_EVAL:${renderer_process_dependencies}>)
    add_custom_command(OUTPUT "${out_dir}"
            COMMAND ${electron_builder_env} ${electron_builder} ${electron_builder_args}
            WORKING_DIRECTORY ${PACKAGE_JSON_DIR}
            COMMENT "Packaging ${out_dir}"
            DEPENDS ${main_process_dependencies_expand} ${renderer_process_dependencies_expand} ${out_package_json})

    add_custom_target(${target} DEPENDS ${out_dir} ${main_process} ${renderer_process})
endfunction()
