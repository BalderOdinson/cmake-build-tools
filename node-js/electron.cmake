include(common/common)

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

function(target_app_name target app_name)
    set_property(TARGET ${target} PROPERTY APP_NAME ${app_name})
endfunction()

function(target_description target description)
    set_property(TARGET ${target} PROPERTY APP_DESCRIPTION ${description})
endfunction()

function(target_version target version)
    set_property(TARGET ${target} PROPERTY APP_VERSION ${version})
endfunction()

function(target_main target main)
    set_property(TARGET ${target} PROPERTY APP_MAIN ${main})
endfunction()

function(add_electron_executable target main_process renderer_process)
    get_property(TOOLS_PACKAGE_JSON_DIR GLOBAL PROPERTY TOOLS_PACKAGE_JSON_DIR)
    get_property(PACKAGE_JSON_DIR DIRECTORY PROPERTY PACKAGE_JSON_DIR)
    get_property(ELECTRON_VERSION DIRECTORY PROPERTY ELECTRON_VERSION)

    set(app_name $<TARGET_PROPERTY:${target},APP_NAME>)
    set(app_name_expand $<IF:$<BOOL:${app_name}>,${app_name},${target}>)
    set(description $<TARGET_PROPERTY:${target},APP_DESCRIPTION>)
    set(description_expand $<IF:$<BOOL:${description}>,${description},${target}>)
    set(version $<TARGET_PROPERTY:${target},APP_VERSION>)
    set(version_expand $<IF:$<BOOL:${version}>,${version},0.0.1>)
    set(main $<TARGET_PROPERTY:${target},APP_MAIN>)
    set(main_expand $<IF:$<BOOL:${main}>,./${main_process}/${main},./${main_process}/main.js>)
    set(out_package_json ${CMAKE_CURRENT_BINARY_DIR}/out/package.json)
    set(template_package_json ${TOOLS_PACKAGE_JSON_DIR}/template.package.json)
    expand_template(SOURCE ${template_package_json}
            DESTINATION ${out_package_json}
            KEYS "@name@" "@description@" "@version@" "@main@"
            VALUES ${app_name_expand} ${description_expand} ${version_expand} ${main_expand}
            DEPENDS ${main_process} ${template_package_json})

    set(out_dir ${CMAKE_CURRENT_BINARY_DIR}/out/${target})
    set(electron_packager ${NPX_EXECUTABLE} electron-packager)
    set(electron_packager_env ${CMAKE_COMMAND} -E env NODE_PATH=${PACKAGE_JSON_DIR}/node_modules)
    set(electron_packager_args ${CMAKE_CURRENT_BINARY_DIR}/out
            --overwrite
            --electron-version ${ELECTRON_VERSION}
            --out "${out_dir}")
    set(main_process_dependencies $<TARGET_PROPERTY:${main_process},OUTPUTS>)
    set(main_process_dependencies_expand $<GENEX_EVAL:${main_process_dependencies}>)
    set(renderer_process_dependencies $<TARGET_PROPERTY:${renderer_process},OUTPUTS>)
    set(renderer_process_dependencies_expand $<GENEX_EVAL:${renderer_process_dependencies}>)
    add_custom_command(OUTPUT "${out_dir}"
            COMMAND ${electron_packager_env} ${electron_packager} ${electron_packager_args}
            WORKING_DIRECTORY ${PACKAGE_JSON_DIR}
            COMMENT "Packaging ${out_dir}"
            DEPENDS ${main_process_dependencies_expand} ${renderer_process_dependencies_expand} ${out_package_json})

    add_custom_target(${target} DEPENDS ${out_dir} ${main_process} ${renderer_process})
endfunction()
