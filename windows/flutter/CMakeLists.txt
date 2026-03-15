# This file controls Flutter-level build steps. It should not be edited.
cmake_minimum_required(VERSION 3.14)

set(EPHEMERAL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/ephemeral")

# Configuration provided via flutter tool.
include(${EPHEMERAL_DIR}/generated_config.cmake)

# Avoid including CMake snippet that requires the application to be built with
# the Flutter engine.
if(FLUTTER_TARGET_PLATFORM STREQUAL "windows-x64")
  set(FLUTTER_TARGET_PLATFORM "windows-x64-debug")
endif()

# === Flutter Library ===
set(FLUTTER_LIBRARY "${EPHEMERAL_DIR}/flutter_windows.dll")

# Published to parent scope for install step.
set(FLUTTER_LIBRARY ${FLUTTER_LIBRARY} PARENT_SCOPE)
set(FLUTTER_ICU_DATA_FILE "${EPHEMERAL_DIR}/icudtl.dat" PARENT_SCOPE)
set(PROJECT_BUILD_DIR ${PROJECT_BINARY_DIR} PARENT_SCOPE)
set(AOT_LIBRARY "${PROJECT_BINARY_DIR}/windows/app.so" PARENT_SCOPE)

list(APPEND FLUTTER_LIBRARY_HEADERS
  "flutter_export.h"
  "flutter_windows.h"
  "flutter_messenger.h"
  "flutter_plugin_registrar.h"
  "flutter_texture_registrar.h"
)
list(TRANSFORM FLUTTER_LIBRARY_HEADERS PREPEND "${EPHEMERAL_DIR}/")

add_library(flutter INTERFACE)
target_include_directories(flutter INTERFACE
  "${EPHEMERAL_DIR}"
)
target_link_libraries(flutter INTERFACE "${FLUTTER_LIBRARY}.lib")
add_dependencies(flutter flutter_assemble)

# === Flutter tool backend ===
add_custom_target(flutter_assemble DEPENDS
  "${FLUTTER_LIBRARY}"
  "${EPHEMERAL_DIR}/icudtl.dat"
)

add_custom_command(
  OUTPUT
    "${FLUTTER_LIBRARY}"
    "${EPHEMERAL_DIR}/icudtl.dat"
  COMMAND ${CMAKE_COMMAND} -E env
    FLUTTER_ROOT="${FLUTTER_ROOT}"
    SOURCE_DIR="${FLUTTER_SOURCE_DIR}"
    FLUTTER_TARGET_PLATFORM="${FLUTTER_TARGET_PLATFORM}"
    "${FLUTTER_TOOL_ENVIRONMENT}"
    "${FLUTTER_ROOT}/packages/flutter_tools/bin/flutter_tools.snapshot"
    assemble
    --no-version-check
    --depfile "${PROJECT_BUILD_DIR}/flutter_assemble.d"
    --output "${EPHEMERAL_DIR}/"
    ${FLUTTER_BUILD_ARGS}
  DEPENDS
    "${FLUTTER_SOURCE_DIR}/pubspec.yaml"
  VERBATIM
)

# === Flutter Wrapper ===
set(CPP_WRAPPER_SOURCES_CORE
  "core_implementations.cc"
  "standard_codec.cc"
)
set(CPP_WRAPPER_SOURCES_PLUGIN
  "plugin_registrar.cc"
)
set(CPP_WRAPPER_SOURCES_APP
  "flutter_view_controller.cc"
)

foreach(SOURCE ${CPP_WRAPPER_SOURCES_CORE} ${CPP_WRAPPER_SOURCES_PLUGIN} ${CPP_WRAPPER_SOURCES_APP})
  list(APPEND CPP_WRAPPER_SOURCES "${EPHEMERAL_DIR}/cpp_client_wrapper/${SOURCE}")
endforeach(SOURCE)

add_library(flutter_wrapper_core STATIC
  ${EPHEMERAL_DIR}/cpp_client_wrapper/core_implementations.cc
  ${EPHEMERAL_DIR}/cpp_client_wrapper/standard_codec.cc
)
apply_standard_settings(flutter_wrapper_core)
target_link_libraries(flutter_wrapper_core PUBLIC flutter)
target_include_directories(flutter_wrapper_core PUBLIC
  "${EPHEMERAL_DIR}/cpp_client_wrapper/include"
  "${EPHEMERAL_DIR}"
)
add_dependencies(flutter_wrapper_core flutter_assemble)

add_library(flutter_wrapper_plugin STATIC
  ${EPHEMERAL_DIR}/cpp_client_wrapper/plugin_registrar.cc
)
apply_standard_settings(flutter_wrapper_plugin)
target_link_libraries(flutter_wrapper_plugin PUBLIC flutter_wrapper_core)
target_include_directories(flutter_wrapper_plugin PUBLIC
  "${EPHEMERAL_DIR}/cpp_client_wrapper/include"
  "${EPHEMERAL_DIR}"
)
add_dependencies(flutter_wrapper_plugin flutter_assemble)

add_library(flutter_wrapper_app STATIC
  ${EPHEMERAL_DIR}/cpp_client_wrapper/flutter_view_controller.cc
)
apply_standard_settings(flutter_wrapper_app)
target_link_libraries(flutter_wrapper_app PUBLIC flutter_wrapper_core)
target_include_directories(flutter_wrapper_app PUBLIC
  "${EPHEMERAL_DIR}/cpp_client_wrapper/include"
  "${EPHEMERAL_DIR}"
)
add_dependencies(flutter_wrapper_app flutter_assemble)

# generated_plugins.cmake is included by the top-level CMakeLists.
set(PLUGIN_BUNDLED_LIBRARIES "" PARENT_SCOPE)
