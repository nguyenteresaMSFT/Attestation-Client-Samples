# Option 1: Use pre-built local binaries.
# Option 1: Use pre-built local binaries.
#   By default this port installs the pre-built azure-security-attestation binaries from the
#   "azure-security-attestation-pluton" directory at the repo root. The directory is resolved
#   relative to this portfile because vcpkg scrubs the environment before running portfiles,
#   so an AZURE_ATTESTATION_INSTALL_DIR env var would not otherwise be visible here. Set
#   AZURE_ATTESTATION_INSTALL_DIR (kept via VCPKG_KEEP_ENV_VARS) to override the location.
#   Two layouts are supported under the directory:
#     * Per-triplet: <dir>/<triplet>/{include,lib,debug/lib,bin,debug/bin,share}
#       (e.g. <dir>/x64-windows, <dir>/x86-windows). Preferred, lets one directory
#       serve every triplet the online port supports.
#     * Flat:        <dir>/{include,lib,debug/lib,bin,debug/bin,share}
#
# Option 2 (fallback): Download and build from GitHub when no pre-built binaries are found.

if(DEFINED ENV{AZURE_ATTESTATION_INSTALL_DIR})
    set(PREBUILT_DIR "$ENV{AZURE_ATTESTATION_INSTALL_DIR}")
else()
    get_filename_component(PREBUILT_DIR "${CURRENT_PORT_DIR}/../../../azure-security-attestation-pluton" ABSOLUTE)
endif()

# Prefer a per-triplet subdirectory (e.g. <dir>/x64-windows, <dir>/x86-windows) so a single
# directory can serve every triplet the online port supports. Fall back to the flat layout
# (<dir>/include, <dir>/lib, ...) when no such subdir exists.
unset(INSTALLED_DIR)
if(EXISTS "${PREBUILT_DIR}/${TARGET_TRIPLET}/include")
    set(INSTALLED_DIR "${PREBUILT_DIR}/${TARGET_TRIPLET}")
elseif(EXISTS "${PREBUILT_DIR}/include")
    set(INSTALLED_DIR "${PREBUILT_DIR}")
endif()

if(DEFINED INSTALLED_DIR)
    message(STATUS "azure-security-attestation: using pre-built binaries from ${INSTALLED_DIR}")

    # Copy headers
    file(INSTALL "${INSTALLED_DIR}/include/"
        DESTINATION "${CURRENT_PACKAGES_DIR}/include")

    # Copy release libraries
    file(INSTALL "${INSTALLED_DIR}/lib/"
        DESTINATION "${CURRENT_PACKAGES_DIR}/lib")

    # Copy CMake config files only (the *.cmake package config). Avoid copying vcpkg-managed
    # metadata (vcpkg_abi_info.txt, vcpkg.spdx.json, copyright) that may exist in a pre-built
    # share directory, since vcpkg regenerates those during post-build validation.
    if(EXISTS "${INSTALLED_DIR}/share/azure-security-attestation-cpp")
        file(INSTALL "${INSTALLED_DIR}/share/azure-security-attestation-cpp/"
            DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
            FILES_MATCHING PATTERN "*.cmake")
    elseif(EXISTS "${INSTALLED_DIR}/lib/cmake/azure-security-attestation-cpp")
        file(INSTALL "${INSTALLED_DIR}/lib/cmake/azure-security-attestation-cpp/"
            DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
            FILES_MATCHING PATTERN "*.cmake")
    endif()

    # Copy debug libraries if present
    if(EXISTS "${INSTALLED_DIR}/debug/lib")
        file(INSTALL "${INSTALLED_DIR}/debug/lib/"
            DESTINATION "${CURRENT_PACKAGES_DIR}/debug/lib")
    endif()

    # Copy DLLs if present (dynamic builds)
    if(EXISTS "${INSTALLED_DIR}/bin")
        file(INSTALL "${INSTALLED_DIR}/bin/"
            DESTINATION "${CURRENT_PACKAGES_DIR}/bin")
    endif()
    if(EXISTS "${INSTALLED_DIR}/debug/bin")
        file(INSTALL "${INSTALLED_DIR}/debug/bin/"
            DESTINATION "${CURRENT_PACKAGES_DIR}/debug/bin")
    endif()

    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")

    # Install copyright
    if(EXISTS "${INSTALLED_DIR}/share/${PORT}/copyright")
        file(INSTALL "${INSTALLED_DIR}/share/${PORT}/copyright"
            DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
    else()
        vcpkg_install_copyright(FILE_LIST "${CURRENT_PORT_DIR}/../../LICENSE.txt")
    endif()
else()
    message(STATUS "azure-security-attestation: no pre-built binaries found under '${PREBUILT_DIR}' for triplet '${TARGET_TRIPLET}', building from GitHub source")
    vcpkg_from_github(
        OUT_SOURCE_PATH SOURCE_PATH
        REPO Azure/azure-sdk-for-cpp
        REF 52f9437adb36dfe6affc04e9e1032c85eb6bc30b
        SHA512 38730e1c2f8a086f057fe55ee3ab1b085ec7f66dc26400ea98f3e73d495967c40f7e470ba31af63790b1c5728465711df655889ee5d422bd758c316ac520dd83
    )

    vcpkg_cmake_configure(
        SOURCE_PATH ${SOURCE_PATH}/sdk/attestation/azure-security-attestation/
        OPTIONS
            -DWARNINGS_AS_ERRORS=OFF
    )

    vcpkg_cmake_install()
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
    vcpkg_cmake_config_fixup()
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")
    vcpkg_copy_pdbs()
endif()
