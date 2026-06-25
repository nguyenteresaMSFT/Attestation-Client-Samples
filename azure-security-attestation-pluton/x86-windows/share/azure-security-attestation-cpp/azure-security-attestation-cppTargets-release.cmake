#----------------------------------------------------------------
# Generated CMake target import file for configuration "Release".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "Azure::azure-security-attestation" for configuration "Release"
set_property(TARGET Azure::azure-security-attestation APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(Azure::azure-security-attestation PROPERTIES
  IMPORTED_IMPLIB_RELEASE "${_IMPORT_PREFIX}/lib/azure-security-attestation.lib"
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/bin/azure-security-attestation.dll"
  )

list(APPEND _cmake_import_check_targets Azure::azure-security-attestation )
list(APPEND _cmake_import_check_files_for_Azure::azure-security-attestation "${_IMPORT_PREFIX}/lib/azure-security-attestation.lib" "${_IMPORT_PREFIX}/bin/azure-security-attestation.dll" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
