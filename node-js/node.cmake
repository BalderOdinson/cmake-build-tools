include(FetchContent)
include(tools/find_cmake_path)

function(FindNode)
    set(options "")
    set(oneValueArgs VERSION)
    set(multiValueArgs "")

    cmake_parse_arguments(FIND_NODE "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if (NOT FIND_NODE_VERSION)
        set(FIND_NODE_VERSION "16.15.1")
    endif ()

    set(NODE_PATH "" CACHE FILEPATH "Path where to find the node")
    set(NODE_EXECUTABLE "" CACHE INTERNAL "Path to node executable")
    set(NPM_EXECUTABLE "" CACHE INTERNAL "Path to npm executable")
    set(NPX_EXECUTABLE "" CACHE INTERNAL "Path to npx executable")
    set(NODE_FOUND OFF CACHE INTERNAL "Indicates if node was found")

    if (NODE_FOUND)
        execute_process(COMMAND ${NODE_EXECUTABLE} --version OUTPUT_VARIABLE NODE_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
        message("-- Found Node: ${NODE_EXECUTABLE} (found version \"${NODE_VERSION}\")")
        execute_process(COMMAND ${NPM_EXECUTABLE} --version OUTPUT_VARIABLE NPM_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
        message("-- Found Npm: ${NPM_EXECUTABLE} (found version \"${NPM_VERSION}\")")
        execute_process(COMMAND ${NPX_EXECUTABLE} --version OUTPUT_VARIABLE NPX_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
        message("-- Found Npx: ${NPX_EXECUTABLE} (found version \"${NPX_VERSION}\")")
        return()
    endif ()

    set(NODE_BASE_URL "https://nodejs.org/dist/v")
    if (WIN32)
        set(NODE_OS "win")
        set(NODE_FILE_EXTENSION ".zip")
        if (${CMAKE_HOST_SYSTEM_PROCESSOR} STREQUAL "X86")
            set(NODE_ARCH "x86")
        elseif(${CMAKE_HOST_SYSTEM_PROCESSOR} STREQUAL "AMD64")
            set(NODE_ARCH "x64")
        else()
            message(FATAL_ERROR "NodeJs does not support host architecture!")
        endif()
    elseif (UNIX)
        set(NODE_FILE_EXTENSION ".tar.gz")
        if (APPLE)
            set(NODE_OS "darwin")
            if (${CMAKE_HOST_SYSTEM_PROCESSOR} STREQUAL "x86_64")
                set(NODE_ARCH "x64")
            elseif(${CMAKE_HOST_SYSTEM_PROCESSOR} STREQUAL "arm64")
                set(NODE_ARCH "arm64")
            else()
                message(FATAL_ERROR "NodeJs does not support host architecture!")
            endif()
        else ()
            set(NODE_OS "linux")
            if (${CMAKE_HOST_SYSTEM_PROCESSOR} STREQUAL "x86_64")
                set(NODE_ARCH "x64")
            elseif(${CMAKE_HOST_SYSTEM_PROCESSOR} STREQUAL "arm")
                set(NODE_ARCH "armv7l")
            elseif(${CMAKE_HOST_SYSTEM_PROCESSOR} STREQUAL "aarch64_be")
                set(NODE_ARCH "arm64")
            elseif(${CMAKE_HOST_SYSTEM_PROCESSOR} STREQUAL "aarch64")
                set(NODE_ARCH "arm64")
            elseif(${CMAKE_HOST_SYSTEM_PROCESSOR} STREQUAL "armv8b")
                set(NODE_ARCH "arm64")
            elseif(${CMAKE_HOST_SYSTEM_PROCESSOR} STREQUAL "armv8l")
                set(NODE_ARCH "arm64")
            elseif(${CMAKE_HOST_SYSTEM_PROCESSOR} STREQUAL "s390x")
                set(NODE_ARCH "s390x")
            elseif(${CMAKE_HOST_SYSTEM_PROCESSOR} STREQUAL "ppc64le")
                set(NODE_ARCH "ppc64le")
            else()
                message(FATAL_ERROR "NodeJs does not support host architecture!")
            endif()
        endif ()
    else ()
        message(FATAL_ERROR "NodeJs is only supported on Windows, Linux and MacOS")
    endif ()
    set(NODE_URL ${NODE_BASE_URL}${FIND_NODE_VERSION}/node-v${FIND_NODE_VERSION}-${NODE_OS}-${NODE_ARCH}${NODE_FILE_EXTENSION})
    set(NODE_FOLDER_NAME "node-v${FIND_NODE_VERSION}-${NODE_OS}-${NODE_ARCH}")

    FetchContent_Declare(${NODE_FOLDER_NAME} URL ${NODE_URL})
    FetchContent_MakeAvailable(${NODE_FOLDER_NAME})

    set(NODE_DIR ${${NODE_FOLDER_NAME}_SOURCE_DIR})
    if (WIN32)
        set(NODE_EXECUTABLE "${NODE_DIR}/node.exe" CACHE INTERNAL "Path to node executable" FORCE)
        set(NPM_EXECUTABLE "${NODE_DIR}/npm.cmd" CACHE INTERNAL "Path to npm executable" FORCE)
        set(NPX_EXECUTABLE "${NODE_DIR}/npx.cmd" CACHE INTERNAL "Path to npx executable" FORCE)
    else ()
        set(NODE_EXECUTABLE "${NODE_DIR}/bin/node" CACHE INTERNAL "Path to node executable" FORCE)
        set(NPM_EXECUTABLE "${NODE_DIR}/bin/npm" CACHE INTERNAL "Path to npm executable" FORCE)
        set(NPX_EXECUTABLE "${NODE_DIR}/bin/npx" CACHE INTERNAL "Path to npx executable" FORCE)
    endif ()

    set(NODE_FOUND ON CACHE INTERNAL "Indicates if node was found" FORCE)
    execute_process(COMMAND ${NODE_EXECUTABLE} --version OUTPUT_VARIABLE NODE_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
    message("-- Found Node: ${NODE_EXECUTABLE} (found version \"${NODE_VERSION}\")")
    execute_process(COMMAND ${NPM_EXECUTABLE} --version OUTPUT_VARIABLE NPM_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
    message("-- Found Npm: ${NPM_EXECUTABLE} (found version \"${NPM_VERSION}\")")
    execute_process(COMMAND ${NPX_EXECUTABLE} --version OUTPUT_VARIABLE NPX_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
    message("-- Found Npx: ${NPX_EXECUTABLE} (found version \"${NPX_VERSION}\")")
endfunction()

function(target_babel_config target babel_config)
    set_property(TARGET ${target} PROPERTY BABEL_CONFIG ${babel_config})
endfunction()

function(target_esbuild_flags target)
    set_property(TARGET ${target} PROPERTY ESBUILD_FLAGS ${ARGN})
endfunction()

function(target_platform target platform)
    set_property(TARGET ${target} PROPERTY ESBUILD_PLATFORM ${platform})
endfunction()

function(target_native_module target)
    set(options "")
    set(oneValueArgs MODULE IMPORT_ALIAS)
    set(multiValueArgs "" "")

    cmake_parse_arguments(NATIVE_LIBRARY "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    find_cmake_path(${NATIVE_LIBRARY_MODULE} OUT_VAR src)
    if (src)
        cmake_path(GET NATIVE_LIBRARY_MODULE FILENAME out_filename)
        set(out ${CMAKE_CURRENT_BINARY_DIR}/out/${target}/${out_filename})
    else ()
        set(src $<TARGET_FILE:${NATIVE_LIBRARY_MODULE}>)
        set(out_filename ${NATIVE_LIBRARY_MODULE}.node)
        set(out ${CMAKE_CURRENT_BINARY_DIR}/out/${target}/${out_filename})
    endif ()

    add_custom_command(OUTPUT ${out}
            COMMAND ${CMAKE_COMMAND} -E copy ${src} ${out}
            COMMENT "Copying native module ${out}"
            DEPENDS ${src})

    get_property(IMPORT_ALIASES TARGET ${target} PROPERTY IMPORT_ALIASES)
    set_property(TARGET ${target} PROPERTY IMPORT_ALIASES ${IMPORT_ALIASES} "'${NATIVE_LIBRARY_IMPORT_ALIAS}':'./${out_filename}'")

    get_property(NATIVE_MODULES TARGET ${target} PROPERTY NATIVE_MODULES)
    set_property(TARGET ${target} PROPERTY NATIVE_MODULES ${NATIVE_MODULES} ${out})
endfunction()

function(target_included_assets target)
    set(assets "")
    foreach (asset ${ARGN})
        find_cmake_path(${asset} OUT_VAR src EXIT_ON_FAIL)
        find_cmake_relative_path(${src} OUT_VAR out_filename)
        cmake_path(APPEND CMAKE_CURRENT_BINARY_DIR ${target} ${out_filename} OUTPUT_VARIABLE out)
        add_custom_command(OUTPUT
                COMMAND ${CMAKE_COMMAND} -E copy ${src} ${out}
                COMMENT "Copying asset ${IMPORT_ALIAS}"
                DEPENDS ${src})
        set(assets ${assets} ${out})
    endforeach ()
    set_property(TARGET ${target} PROPERTY ASSETS ${assets})
endfunction()

function(target_bundle_resource target)
    set(options "")
    set(oneValueArgs SRC OUT)
    set(multiValueArgs "")

    cmake_parse_arguments(BUNDLE_RESOURCE "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    find_cmake_path(${BUNDLE_RESOURCE_SRC} OUT_VAR src)
    set(out ${CMAKE_CURRENT_BINARY_DIR}/out/${target}/${BUNDLE_RESOURCE_OUT})

    add_custom_command(OUTPUT ${out}
            COMMAND ${CMAKE_COMMAND} -E copy ${src} ${out}
            COMMENT "Copying resource ${out}"
            DEPENDS ${src})

    get_property(BUNDLE_RESOURCES TARGET ${target} PROPERTY BUNDLE_RESOURCES)
    set_property(TARGET ${target} PROPERTY BUNDLE_RESOURCES ${BUNDLE_RESOURCES} ${out})
endfunction()

function(add_js_library target)
    get_property(PACKAGE_JSON_DIR DIRECTORY PROPERTY PACKAGE_JSON_DIR)
    get_property(TOOLS_PACKAGE_JSON_DIR GLOBAL PROPERTY TOOLS_PACKAGE_JSON_DIR)

    set(options "")
    set(oneValueArgs "")
    set(multiValueArgs SRCS ENTRY_POINTS)

    cmake_parse_arguments(JS_LIBRARY "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    set(babel_config ${CMAKE_CURRENT_BINARY_DIR}/${target}/babel.config.js)
    set(extended_babel_config $<TARGET_PROPERTY:${target},BABEL_CONFIG>)
    set(config_file_value $<IF:$<BOOL:${extended_babel_config}>,${CMAKE_CURRENT_SOURCE_DIR}/${extended_babel_config},undefined>)
    set(imports $<GENEX_EVAL:$<TARGET_PROPERTY:${target},IMPORT_ALIASES>>)
    set(imports_expand "{$<$<BOOL:${imports}>:${imports}>}")
    set(template_babel_config ${TOOLS_PACKAGE_JSON_DIR}/babel.config.js)
    expand_template(SOURCE ${template_babel_config}
            DESTINATION ${babel_config}
            KEYS "@babelrc@" "@imports@"
            VALUES ${config_file_value} ${imports_expand}
            DEPENDS "$<$<BOOL:${extended_babel_config}>:${CMAKE_CURRENT_SOURCE_DIR}/${extended_babel_config}>" ${template_babel_config})

    set(outs "")
    set(entry_points "")
    foreach (src ${JS_LIBRARY_SRCS})
        find_cmake_path(${src} OUT_VAR src_abs EXIT_ON_FAIL)
        find_cmake_relative_path(${src_abs} OUT_VAR src_rel)
        cmake_path(GET src_rel STEM LAST_ONLY out_filename)
        cmake_path(GET src_rel PARENT_PATH out_dir)
        cmake_path(APPEND CMAKE_CURRENT_BINARY_DIR ${target} ${out_dir} ${out_filename}.js OUTPUT_VARIABLE out)

        set(babel_set_env ${CMAKE_COMMAND} -E env CMAKE_CURRENT_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
                CMAKE_CURRENT_BINARY_DIR=${CMAKE_CURRENT_BINARY_DIR}
                NODE_PATH=${PACKAGE_JSON_DIR}/node_modules)
        set(babel ${NPX_EXECUTABLE} babel)
        set(babel_args $<$<CONFIG:DEBUG>:-s>
                -o "${out}"
                "${src_abs}"
                --config-file ${babel_config})
        add_custom_command(OUTPUT "${out}"
                COMMAND ${babel_set_env} ${babel} ${babel_args}
                WORKING_DIRECTORY ${PACKAGE_JSON_DIR}
                COMMENT "Compiling ${src} -> ${out}"
                DEPENDS ${src_abs} ${babel_config})
        set(outs ${outs} ${out})
        if (src IN_LIST JS_LIBRARY_ENTRY_POINTS)
            set(entry_points ${entry_points} ${out})
        endif ()
    endforeach ()

    set(bundle "")
    set(assets $<TARGET_PROPERTY:${target},ASSETS>)
    set(assets_expand $<$<BOOL:${assets}>:${assets}>)
    foreach (entry_point ${entry_points})
        cmake_path(GET entry_point FILENAME out_filename)
        set(out ${CMAKE_CURRENT_BINARY_DIR}/out/${target}/${out_filename})
        set(esbuild_user_flags $<TARGET_PROPERTY:${target},ESBUILD_FLAGS>)
        set(esbuild_user_flags_expand $<$<BOOL:${esbuild_user_flags}>:${esbuild_user_flags}>)
        set(esbuild_platform $<TARGET_PROPERTY:${target},ESBUILD_PLATFORM>)
        set(esbuild_platform_expand $<$<BOOL:${esbuild_platform}>:--platform=${esbuild_platform}>)
        set(esbuild_set_env ${CMAKE_COMMAND} -E env NODE_PATH=${PACKAGE_JSON_DIR}/node_modules)
        set(esbuild ${NPX_EXECUTABLE} esbuild)
        set(esbuild_args ${entry_point}
                --bundle
                ${esbuild_platform_expand}
                --log-level=warning
                $<$<CONFIG:DEBUG>:--sourcemap>
                $<$<CONFIG:RELEASE>:--minify>
                --outfile="${out}"
                ${esbuild_user_flags_expand})
        add_custom_command(OUTPUT "${out}"
                COMMAND ${esbuild_set_env} ${esbuild} ${esbuild_args}
                WORKING_DIRECTORY ${PACKAGE_JSON_DIR}
                COMMENT "Bundling ${entry_point} -> ${out}"
                DEPENDS ${outs} ${assets_expand}
                COMMAND_EXPAND_LISTS)
        set(bundle ${bundle} ${out})
    endforeach ()

    set(bundle_resources $<TARGET_PROPERTY:${target},BUNDLE_RESOURCES>)
    set(bundle_resources_expand $<$<BOOL:${bundle_resources}>:${bundle_resources}>)
    set(native_modules $<TARGET_PROPERTY:${target},NATIVE_MODULES>)
    set(native_modules_expand $<$<BOOL:${native_modules}>:${native_modules}>)
    add_custom_target(${target} DEPENDS ${bundle} ${bundle_resources_expand} ${native_modules_expand})
    set_property(TARGET ${target} PROPERTY OUTPUTS ${bundle} ${bundle_resources_expand} ${native_modules_expand})
endfunction()
