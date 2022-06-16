cmake_minimum_required(VERSION 3.21)

project(cmake-build-tools)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}")
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}" PARENT_SCOPE)

# Find python
include(python/python.cmake)
FindPython()
use_python_env(NAME py-tools REQUIREMENTS python/requirements.txt)
