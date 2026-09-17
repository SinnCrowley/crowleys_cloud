cmake_minimum_required(VERSION 3.15)

# Run after staging the executable; BundleUtilities copies transitive dependencies
# and rewrites their install names relative to the executable.
if(NOT CMAKE_HOST_APPLE OR NOT EXISTS "${EXECUTABLE}")
  message(FATAL_ERROR "Pass -DEXECUTABLE=<staged macOS executable>")
endif()
# This is a portable directory, not an .app/Contents/MacOS layout.
function(gp_item_default_embedded_path_override item result)
  set(${result} "@executable_path" PARENT_SCOPE)
endfunction()
include(BundleUtilities)
fixup_bundle("${EXECUTABLE}" "" "")
# install_name_tool invalidates existing signatures. Sign libraries first.
get_filename_component(bundle_dir "${EXECUTABLE}" DIRECTORY)
file(GLOB libraries "${bundle_dir}/*.dylib")
foreach(binary IN LISTS libraries)
  execute_process(COMMAND codesign --force --sign - "${binary}" RESULT_VARIABLE result)
  if(NOT result EQUAL 0)
    message(FATAL_ERROR "Ad-hoc signing failed: ${binary}")
  endif()
endforeach()
execute_process(COMMAND codesign --force --sign - "${EXECUTABLE}" RESULT_VARIABLE result)
if(NOT result EQUAL 0)
  message(FATAL_ERROR "Ad-hoc signing failed: ${EXECUTABLE}")
endif()
verify_app("${EXECUTABLE}")
