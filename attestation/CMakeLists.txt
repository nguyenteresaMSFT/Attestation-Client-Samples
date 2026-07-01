# Copyright (c) Microsoft Corporation. All rights reserved.
# SPDX-License-Identifier: MIT

set(ATTEST_PACKAGE_DIR "${CMAKE_BINARY_DIR}/packages/Microsoft.Attestation.Client" CACHE STRING "")

# azure-security-attestation SDK is provided by the local
# Azure.Security.Attestation.Unofficial NuGet package (installed from the repo root by the
# top-level CMakeLists.txt). Layout inside the package:
#   build/native/include            - public headers
#   runtimes/win-x64/native         - release .lib/.dll
#   runtimes/win-x64/native/debug   - debug .lib/.dll
#   dependencies/win-x64/{debug,release} - azure-core, OpenSSL, libcurl, zlib binaries
set(ATTEST_SDK_PKG_DIR "${CMAKE_BINARY_DIR}/packages/Azure.Security.Attestation.Unofficial" CACHE STRING "")
set(ATTEST_SDK_INCLUDE_DIR "${ATTEST_SDK_PKG_DIR}/build/native/include")
set(ATTEST_SDK_NATIVE_DIR "${ATTEST_SDK_PKG_DIR}/runtimes/win-x64/native")
set(ATTEST_SDK_DEPS_DIR "${ATTEST_SDK_PKG_DIR}/dependencies/win-x64")

# Select the debug or release artifacts based on the active configuration.
set(ATTEST_SDK_LIB "$<IF:$<CONFIG:Debug>,${ATTEST_SDK_NATIVE_DIR}/debug/azure-security-attestation.lib,${ATTEST_SDK_NATIVE_DIR}/azure-security-attestation.lib>")
set(ATTEST_SDK_DLL "$<IF:$<CONFIG:Debug>,${ATTEST_SDK_NATIVE_DIR}/debug/azure-security-attestation.dll,${ATTEST_SDK_NATIVE_DIR}/azure-security-attestation.dll>")
set(ATTEST_SDK_DEPS_CONFIG_DIR "$<IF:$<CONFIG:Debug>,${ATTEST_SDK_DEPS_DIR}/debug,${ATTEST_SDK_DEPS_DIR}/release>")

macro (define_sample samplename is_enclave)

    project(attestation-${samplename})

    include_directories("${ATTEST_PACKAGE_DIR}/inc" "${ATTEST_SDK_INCLUDE_DIR}")

    add_executable(
        attestation-${samplename}
        ${samplename}.cpp
        attest.cpp 
        utils.cpp)

    target_link_libraries(attestation-${samplename} PRIVATE ncrypt)

    set_property(TARGET attestation-${samplename} PROPERTY CXX_STANDARD 20)

    find_package(azure-identity-cpp CONFIG REQUIRED)
    target_link_libraries(attestation-${samplename} PRIVATE "${ATTEST_PACKAGE_DIR}/lib/azure-attest-manager.lib" Azure::azure-identity "${ATTEST_SDK_LIB}")

    install(
        FILES "${ATTEST_PACKAGE_DIR}/bin/azure-attest-manager.dll" "${ATTEST_PACKAGE_DIR}/bin/AzureAttestManager.dll" "${ATTEST_PACKAGE_DIR}/bin/AzureAttestNormal.dll"
        DESTINATION "${CMAKE_CURRENT_BINARY_DIR}"
    )

    # The attestation SDK and its dependencies come as raw files (not a vcpkg target with
    # automatic app-local DLL deployment), so copy the runtime DLLs next to the executable.
    # This includes the Microsoft.Attestation.Client DLLs and the azure-security-attestation SDK
    # DLL plus its dependencies, so the samples can be run directly from the build output directory.
    add_custom_command(TARGET attestation-${samplename} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${ATTEST_PACKAGE_DIR}/bin/azure-attest-manager.dll"
            "${ATTEST_PACKAGE_DIR}/bin/AzureAttestManager.dll"
            "${ATTEST_PACKAGE_DIR}/bin/AzureAttestNormal.dll"
            "$<TARGET_FILE_DIR:attestation-${samplename}>"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${ATTEST_SDK_DLL}" "$<TARGET_FILE_DIR:attestation-${samplename}>"
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${ATTEST_SDK_DEPS_CONFIG_DIR}" "$<TARGET_FILE_DIR:attestation-${samplename}>"
        VERBATIM)

    if("${is_enclave}" STREQUAL "TRUE")
        target_link_libraries(attestation-${samplename} PRIVATE onecore.lib)

        add_custom_command(TARGET attestation-${samplename} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${ATTEST_PACKAGE_DIR}/bin/AzureAttest.dll"
                "$<TARGET_FILE_DIR:attestation-${samplename}>"
            VERBATIM)

        install(
            FILES "${ATTEST_PACKAGE_DIR}/bin/AzureAttest.dll"
            DESTINATION "${CMAKE_CURRENT_BINARY_DIR}"
        )
    endif()
endmacro()

define_sample(sample_boot_att FALSE)
define_sample(sample_tpm_key_att FALSE)
define_sample(sample_enclave_att TRUE)
define_sample(sample_pluton_att FALSE)