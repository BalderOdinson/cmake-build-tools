set(options "")
set(oneValueArgs ICONS_PATH ELECTRON_DIST ELECTRON_VERSION SRC DST)
set(multiValueArgs SOURCES)

set(ARGN "")
MATH(EXPR LAST_ARG "${CMAKE_ARGC}-1")
foreach(arg RANGE ${LAST_ARG})
    list(APPEND ARGN "${CMAKE_ARGV${arg}}")
endforeach()

cmake_parse_arguments(GENERATE "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

file(READ ${GENERATE_SRC} json_content)

# Replace main with generated one
cmake_path(GET GENERATE_DST PARENT_PATH out_dir)
string(JSON main GET ${json_content} main)
cmake_path(GET main STEM main_script)
set(main_script "${main_script}.js")
foreach(source_file ${GENERATE_SOURCES})
    cmake_path(GET source_file FILENAME source_filename)
    cmake_path(COMPARE ${source_filename} EQUAL ${main_script} main_found)
    if(main_found)
        cmake_path(RELATIVE_PATH source_file BASE_DIRECTORY ${out_dir} OUTPUT_VARIABLE out_main)
        set(current_folder ".")
        cmake_path(APPEND current_folder ${out_main} OUTPUT_VARIABLE out_main)
        string(JSON json_content SET ${json_content} main "\"${out_main}\"")
        break()
    endif()
endforeach()

# Remove properties that we do not want in final package.json
string(JSON json_content REMOVE ${json_content} dependencies)
string(JSON json_content REMOVE ${json_content} devDependencies)
string(JSON json_content REMOVE ${json_content} peerDependencies)
string(JSON json_content REMOVE ${json_content} peerDependenciesMeta)
string(JSON json_content REMOVE ${json_content} bundledDependencies)
string(JSON json_content REMOVE ${json_content} optionalDependencies)

# Add required build attributes
string(JSON build_prop_type ERROR_VARIABLE has_error TYPE ${json_content} build)
if (has_error OR NOT build_prop_type STREQUAL "OBJECT")
    string(JSON json_content SET ${json_content} build "{}")
endif()

string(JSON json_content SET ${json_content} build electronVersion "\"${GENERATE_ELECTRON_VERSION}\"")
string(JSON json_content SET ${json_content} build electronDist "\"${GENERATE_ELECTRON_DIST}\"")
string(JSON json_content SET ${json_content} build npmRebuild "false")

if (GENERATE_ICONS_PATH)
    string(JSON build_prop_type ERROR_VARIABLE has_error TYPE ${json_content} build mac)
    if (has_error OR NOT build_prop_type STREQUAL "OBJECT")
        string(JSON json_content SET ${json_content} build mac "{}")
    endif()

    string(JSON build_prop_type ERROR_VARIABLE has_error TYPE ${json_content} build win)
    if (has_error OR NOT build_prop_type STREQUAL "OBJECT")
        string(JSON json_content SET ${json_content} build win "{}")
    endif()

    cmake_path(APPEND GENERATE_ICONS_PATH "mac" "icon.icns" OUTPUT_VARIABLE icon_mac)
    cmake_path(APPEND GENERATE_ICONS_PATH "win" "icon.ico" OUTPUT_VARIABLE icon_win)

    string(JSON json_content SET ${json_content} build mac icon "\"${icon_mac}\"")
    string(JSON json_content SET ${json_content} build win icon "\"${icon_win}\"")

    # Copy icons to the assets folder
    file(MAKE_DIRECTORY ${out_dir}/assets)
    file(COPY_FILE ${GENERATE_ICONS_PATH}/png/64x64.png ${out_dir}/assets/icon.png)
    file(COPY_FILE ${GENERATE_ICONS_PATH}/png/128x128.png ${out_dir}/assets/icon@2x.png)
    file(COPY_FILE ${GENERATE_ICONS_PATH}/png/256x256.png ${out_dir}/assets/icon@4x.png)
    file(COPY_FILE ${GENERATE_ICONS_PATH}/png/512x512.png ${out_dir}/assets/icon@8x.png)
endif()

# Write final json
file(WRITE ${GENERATE_DST} ${json_content})
