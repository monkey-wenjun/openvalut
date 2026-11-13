cmake_minimum_required(VERSION 3.15)
set(PROJECT_NAME "winsparkle_flutter")
project(${PROJECT_NAME} LANGUAGES CXX)

set(PLUGIN_NAME "${PROJECT_NAME}_plugin")

add_library(${PLUGIN_NAME} SHARED
  "${PLUGIN_NAME}.cpp"
)
apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)

set_target_properties(${PLUGIN_NAME} PROPERTIES VS_GLOBAL_IgnoreImportLibrary "true")

# add_library(WinSparkle SHARED IMPORTED)
# set_property(TARGET WinSparkle 
#   PROPERTY IMPORTED_LOCATION C:/dev/winsparkle_flutter/windows/WinSparkle.dll
#   PROPERTY IMPORTED_IMPLIB C:/dev/winsparkle_flutter/windows/WinSparkle.lib)
# # set_property(TARGET WinSparkle 
# #   PROPERTY IMPORTED_LOCATION ${PROJECT_SOURCE_DIR}/WinSparkle.dll
# #   PROPERTY IMPORTED_IMPLIB ${PROJECT_SOURCE_DIR}/WinSparkle.lib)
# target_link_libraries(${PLUGIN_NAME} PRIVATE WinSparkle)
# find_library(WinSparkle NAMES WinSparkle PATHS ${PROJECT_SOURCE_DIR})
# target_link_libraries(${PLUGIN_NAME} PRIVATE WinSparkle)

# List of absolute paths to libraries that should be bundled with the plugin
set(winsparkle_flutter_bundled_libraries
  ""
  "${CMAKE_CURRENT_SOURCE_DIR}/WinSparkle.dll"
  PARENT_SCOPE
)
