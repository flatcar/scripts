#!/bin/bash
#
# Copyright (c) 2023 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

if [[ -n "${FLATCAR_REPORTS_UTIL_SH_INCLUDED:-}" ]]; then
    return 0
fi

FLATCAR_REPORTS_UTIL_SH_INCLUDED=1

# Generate a ls-like listing of a directory tree.
# The ugly printf is used to predictable time format and size in bytes.
#
# Usage:
#  write_contents "${rootfs}" ${contents_file}"
write_contents() {
    local rootfs="${1}"; shift
    local output="${1}"; shift
    info "Writing ${output##*/}"
    # Ensure output is an absolute path before we change the working
    # directory.
    output=$(realpath "${output}")
    pushd "${rootfs}" >/dev/null
    # %M - file permissions
    # %n - number of hard links to file
    # %u - file's user name
    # %g - file's group name
    # %s - size in bytes
    # %Tx - modification time (Y - year, m - month, d - day, H - hours, M - minutes)
    # %P - file's path
    # %l - symlink target (empty if not a symlink)
    sudo TZ=UTC find -printf \
        '%M %2n %-7u %-7g %7s %TY-%Tm-%Td %TH:%TM ./%P -> %l\n' \
        | sort --key=8 \
        | sed -e 's/ -> $//' >"${output}"
    popd >/dev/null
}

# Generate a listing that can be used by other tools to analyze
# image/file size changes.
#
# Usage:
#  write_contents_with_technical_details "${rootfs}" ${output_file}"
write_contents_with_technical_details() {
    local rootfs="${1}"; shift
    local output="${1}"; shift
    info "Writing ${output##*/}"
    # Ensure output is an absolute path before we change the working
    # directory.
    output=$(realpath "${output}")
    pushd "${rootfs}" >/dev/null
    # %M - file permissions
    # %D - ID of a device where file resides
    # %i - inode number
    # %n - number of hard links to file
    # %s - size in bytes
    # %P - file's path
    sudo find -printf \
        '%M %D %i %n %s ./%P\n' \
        | sort --key=6 >"${output}"
    popd >/dev/null
}

# Generate a report like the following if more than one relative path
# in rootfs was passed:
#
# File    Size  Used Avail Use% Type
# /boot   127M   62M   65M  50% vfat
# /usr    983M  721M  212M  78% ext2
# /       6,0G   13M  5,6G   1% ext4
# SUM     7,0G  796M  5,9G  12% -
#
# or, in case of 0 or 1 relative path:
#
# File  Size  Used Avail Use% Type
# /      27M   27M     0 100% squashfs
#
# Usage:
#  write_disk_space_usage_in_paths "${rootfs}" "${output_file}" ./boot ./usr ./
write_disk_space_usage_in_paths() {
    local rootfs="${1}"; shift
    local output="${1}"; shift
    info "Writing ${output##*/}"
    # Ensure output is an absolute path before we change the working
    # directory.
    output=$(realpath "${output}")
    pushd "${rootfs}" >/dev/null
    local extra_flags
    extra_flags=()
    if [[ ${#} -eq 0 ]]; then
        set -- ./
    fi
    if [[ ${#} -gt 1 ]]; then
        extra_flags+=('--total')
    fi
    # The sed's first command turns './<path>' into '/<path> ', second
    # command replaces '- ' with 'SUM' for the total row. All this to
    # keep the numbers neatly aligned in columns.
    sudo df \
         --human-readable \
         "${extra_flags[@]}" \
         --output='file,size,used,avail,pcent,fstype' \
         "${@}" | \
        sed \
            -e 's#^\.\(/[^ ]*\)#\1 #' \
            -e 's/^-  /SUM/' >"${output}"
    popd >/dev/null
}

# Generate a report like the following:
#
# File    Size  Used Avail Use% Type
# /boot   127M   62M   65M  50% vfat
# /usr    983M  721M  212M  78% ext2
# /       6,0G   13M  5,6G   1% ext4
# SUM     7,0G  796M  5,9G  12% -
write_disk_space_usage() {
    write_disk_space_usage_in_paths "${1}" "${2}" ./boot ./usr ./
}

# Where the SPDX package manifests are written to in a rootfs.
# systemd-sysext merges every sysext's copy of this directory over the image's,
# so a booted machine sees one directory holding the image's manifest and one
# per merged sysext.
OS_MANIFESTS_DIR="/usr/share/os-manifests"

# Usage:
#
#  write_package_manifest image  "${root}" "${name}" "${version}" "${packages_file}" "${created_epoch}"
#  write_package_manifest sysext "${root}" "${name}" "${version}" "${packages_file}" "${created_epoch}"
#
# The kind picks the filename. An image writes package-manifest.spdx.json and a
# sysext writes package-manifest.<name>.spdx.json, so the copies merged into one
# /usr safely.
#
# The document is not validated here. Its shape is a property of the generator,
# not of any one rootfs, so it is checked against a fixture and a golden SPDX
# 2.2 document by the Build RPMs job of the ACL GitHub PR pipeline, which runs
# /build_library/rpm/tests/test_generate_package_manifest.sh.
write_package_manifest() {
    local kind="${1}"
    local root="${2}"
    local name="${3}"
    local version="${4}"
    local packages_file="${5}"
    local created_epoch="${6}"

    local infix
    case "${kind}" in
        image)  infix="" ;;
        sysext) infix=".${name}" ;;
        *) die "write_package_manifest: expected kind 'image' or 'sysext', got '${kind}'" ;;
    esac

    local output="${root}${OS_MANIFESTS_DIR}/package-manifest${infix}.spdx.json"

    info "Writing ${output##*/}"

    # build_image runs as the sdk user, so writing into an image rootfs needs sudo.
    sudo install -d -m 0755 "${output%/*}"

    # --force because BUILD_DIR is caller-supplied.
    sudo "${BUILD_LIBRARY_DIR}/rpm/generate_package_manifest.py" \
        --packages-file="${packages_file}" \
        --manifest-file="${output}" \
        --manifest-name="${name}" \
        --manifest-version="${version}" \
        --created-epoch="${created_epoch}" \
        --force

    sudo chmod 0644 "${output}"
}

# Write an SPDX SBOM for a rootfs tree.
write_sysext_sbom() {
    local rootfs="${1}"; shift
    local output="${1}"; shift
    local output_name="${output##*/}"
    local rpm_manifest="${1:-}"
    info "Writing ${output_name}"
    output=$(realpath "${output}")

    local scan_root="${rootfs}"
    local overlay_root=""
    local lowerdir=""
    local overlay_upper
    local overlay_work
    local overlay_merged
    local rc

    if [[ "${PACKAGE_SOURCE_MODE}" == "RPM" ]]; then
        if [[ -n "${rpm_manifest}" ]] && [[ -f "${rpm_manifest}" ]]; then
            rpm_manifest=$(realpath "${rpm_manifest}")
            lowerdir=$(realpath "${rootfs}")
            overlay_root=$(mktemp -d)
            overlay_upper="${overlay_root}/upper"
            overlay_work="${overlay_root}/work"
            overlay_merged="${overlay_root}/merged"

            # Overlay the read-only sysext mount so Syft can see the generated RPM
            # manifest at its expected path without modifying the original rootfs.
            sudo mkdir -p "${overlay_upper}" "${overlay_work}" "${overlay_merged}"
            sudo mount -t overlay overlay \
                -o "lowerdir=${lowerdir},upperdir=${overlay_upper},workdir=${overlay_work}" \
                "${overlay_merged}"
            sudo mkdir -p "${overlay_merged}/var/lib/rpmmanifest"
            sudo install -m 0644 "${rpm_manifest}" "${overlay_merged}/var/lib/rpmmanifest/container-manifest-2"

            scan_root="${overlay_merged}"
        else
            warn "RPM manifest file is unavailable for ${output_name}; continuing with filesystem-only sysext SBOM scan"
        fi
    fi

    info "Scanning ${scan_root} with Syft for sysext SBOM generation"
    if sudo syft scan "${scan_root}" -o spdx-json="${output}"; then
        rc=0
    else
        rc=$?
    fi

    if [[ -n "${overlay_root}" ]]; then
        sudo umount "${scan_root}" 2>/dev/null || true
        sudo rm -rf "${overlay_root}"
    fi

    return ${rc}
}
