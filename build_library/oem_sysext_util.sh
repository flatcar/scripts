#!/bin/bash
#
# Copyright (c) 2023 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

source "${BUILD_LIBRARY_DIR}/reports_util.sh" || exit 1

_generate_listing() {
    local rootfs="${1%/}"; shift
    local listing="${1}"; shift

    local slashes="${rootfs//[^\/]}"
    local slash_count="${#slashes}"

    # Invoking find with sudo as it's used for traversing root-owned
    # rootfs, which means that some places may be unreachable by the
    # sdk user.
    sudo find "${rootfs}//" | cut -d/ -f$((slash_count + 2))- | sort >"${listing}"
}

_prepend_action () {
    local -n prepend_array="${1}"; shift

    prepend_array=( "${#}" "${@}" "${prepend_array[@]}" )
}

_invoke_actions () {
    local arg_count
    local command
    while [[ "${#}" -gt 0 ]]; do
        arg_count="${1}"
        shift
        command=( "${@:1:${arg_count}}" )
        shift "${arg_count}"
        "${command[@]}" || :
    done
}

# Architecture values are taken from systemd.unit(5).
declare -A SYSEXT_ARCHES
SYSEXT_ARCHES['amd64-usr']='x86-64'
SYSEXT_ARCHES['arm64-usr']='arm64'

declare -r SYSEXT_ARCHES

# Usage: _get_sysext_arch board [board...]
_get_sysext_arch() {
    local board
    for board in "$@"; do
        if [[ ${#SYSEXT_ARCHES["${board}"]} -ne 0 ]]; then
            echo "${SYSEXT_ARCHES["${board}"]}"
        else
            die "Unknown board '${board}'"
        fi
    done
}

oem_sysext_create() {
    local oem="${1}"; shift
    local board="${1}"; shift
    local version_id="${1}"; shift
    local prod_image="${1}"; shift
    local prod_pkgdb="${1}"; shift
    local work_dir="${1}"; shift

    local base_pkg="coreos-base/${oem}"
    local sysext_work_dir="${work_dir}/sysext-${oem}"
    local prod_rw_image="${sysext_work_dir}/prod_for_sysext.bin"
    local prod_rw_rootfs="${sysext_work_dir}/prod_rw_rootfs"

    local cleanup_actions=()
    trap '_invoke_actions "${cleanup_actions[@]}"' EXIT

    _prepend_action cleanup_actions rmdir "${sysext_work_dir}"
    mkdir -p "${sysext_work_dir}"

    info 'Creating a production image copy for work rootfs'
    _prepend_action cleanup_actions rm -f "${prod_rw_image}"
    cp --sparse=always "${prod_image}" "${prod_rw_image}"

    info 'Preparing work image for mounting'
    "${BUILD_LIBRARY_DIR}/disk_util" --disk_layout=base \
        tune --randomize_uuid "${prod_rw_image}" OEM
    "${BUILD_LIBRARY_DIR}/disk_util" --disk_layout=base \
        tune --enable2fs_rw "${prod_rw_image}" USR-A

    info "Mounting work image to ${prod_rw_rootfs}"
    _prepend_action cleanup_actions rmdir "${prod_rw_rootfs}"
    _prepend_action cleanup_actions "${BUILD_LIBRARY_DIR}/disk_util" --disk_layout=base \
        umount "${prod_rw_rootfs}"
    "${BUILD_LIBRARY_DIR}/disk_util" --disk_layout=base \
        mount --writable_verity "${prod_rw_image}" "${prod_rw_rootfs}"

    local initial_files="${sysext_work_dir}/initial_files"
    info "Generating list of initial files in work image"
    _prepend_action cleanup_actions rm -f "${initial_files}"
    _generate_listing "${prod_rw_rootfs}" "${initial_files}"

    info "Stuffing package database into into ${prod_rw_rootfs}"
    sudo tar -xf "${prod_pkgdb}" -C "${prod_rw_rootfs}"

    # Split into two steps because we want to always install
    # $${base_pkg} from the ebuild (build_packages doesn't handle it)
    # *but* we never want to build anything else from source
    # here. emerge doesn't have a way to enforce this in a single
    # command.
    info "Building ${base_pkg}"
    "emerge-${board}" --nodeps --buildpkgonly --usepkg n --verbose "${base_pkg}"

    info "Installing ${base_pkg} to ${prod_rw_rootfs}"
    sudo emerge \
         --config-root="/build/${board}" \
         --root="${prod_rw_rootfs}" \
         --sysroot="${prod_rw_rootfs}" \
         --root-deps=rdeps \
         --usepkgonly \
         --verbose \
         "${base_pkg}"

    info "Removing portage db from ${prod_rw_rootfs}"
    sudo rm -rf \
       "${prod_rw_rootfs}/var/cache/edb" \
       "${prod_rw_rootfs}/var/db/pkg"

    local all_files="${sysext_work_dir}/all_files"
    local sysext_files="${sysext_work_dir}/sysext_files"

    info "Generating list of files in work image after installing OEM package"
    _prepend_action cleanup_actions rm -f "${all_files}"
    _generate_listing "${prod_rw_rootfs}" "${all_files}"

    info "Generating list of files for sysext image"
    _prepend_action cleanup_actions rm -f "${sysext_files}"
    comm -1 -3 "${initial_files}" "${all_files}" >"${sysext_files}"

    info "Copying files for sysext image"
    local sysext_rootfs="${sysext_work_dir}/sysext_rootfs"
    _prepend_action cleanup_actions rm -rf "${sysext_rootfs}"
    rsync --links --files-from="${sysext_files}" "${prod_rw_rootfs}" "${sysext_rootfs}"

    info "Mangling files for sysext image"
    local overlay_path mangle_fs
    overlay_path=$(portageq get_repo_path / coreos)
    mangle_fs="${overlay_path}/${base_pkg}/files/manglefs.sh"
    if [[ -x "${mangle_fs}" ]]; then
        "${mangle_fs}" "${sysext_rootfs}"
    fi

    local entry
    info "Removing non-/usr directories from sysext image"
    for entry in "${sysext_rootfs}"/*; do
        if [[ "${entry}" = */usr ]]; then
            continue
        fi
        info "  Removing ${entry##*/}"
        rm -rf "${entry}"
    done

    local metadata metadata_file metadata_version_entry
    info "Adding sysext metadata"
    mkdir -p "${sysext_rootfs}/usr/lib/extension-release.d"
    if [[ "${version_id}" = 'initial' ]]; then
        metadata_version_entry="SYSEXT_LEVEL=1.0"
    else
        metadata_version_entry="VERSION_ID=${version_id}"
    fi
    metadata=(
        'ID=flatcar'
        "${metadata_version_entry}"
        "ARCHITECTURE=$(_get_sysext_arch "${board}")"
    )
    metadata_file="${sysext_rootfs}/usr/lib/extension-release.d/extension-release.${oem}"
    printf '%s\n' "${metadata[@]}" >"${metadata_file}"

    info "Generating a squashfs image"
    local sysext_raw_image_filename="${oem}.raw"
    local output_raw_image="${sysext_work_dir}/${sysext_raw_image_filename}"
    _prepend_action cleanup_actions rm -f "${output_raw_image}"
    mksquashfs "${sysext_rootfs}" "${output_raw_image}" -all-root

    info "Generating image reports"
    local sysext_mounted="${sysext_work_dir}/squashfs_mounted"
    _prepend_action cleanup_actions rmdir "${sysext_mounted}"
    mkdir "${sysext_mounted}"
    _prepend_action cleanup_actions sudo umount "${sysext_mounted}"
    sudo mount -t squashfs -o loop "${output_raw_image}" "${sysext_mounted}"
    local contents="${sysext_raw_image_filename%.raw}_contents.txt"
    local contents_wtd="${sysext_raw_image_filename%.raw}_contents_wtd.txt"
    local disk_usage="${sysext_raw_image_filename%.raw}_disk_usage.txt"
    _prepend_action cleanup_actions rm -f "${sysext_work_dir}/${contents}"
    write_contents "${sysext_mounted}" "${sysext_work_dir}/${contents}"
    _prepend_action cleanup_actions rm -f "${sysext_work_dir}/${contents_wtd}"
    write_contents_with_technical_details "${sysext_mounted}" "${sysext_work_dir}/${contents_wtd}"
    _prepend_action cleanup_actions rm -f "${sysext_work_dir}/${disk_usage}"
    write_disk_space_usage_in_paths "${sysext_mounted}" "${sysext_work_dir}/${disk_usage}"

    local to_move
    for to_move in "${sysext_raw_image_filename}" "${contents}" "${contents_wtd}" "${disk_usage}"; do
        mv "${sysext_work_dir}/${to_move}" "${work_dir}/${to_move}"
    done

    info "Alles jut, cleaning up"
    trap - EXIT
    _invoke_actions "${cleanup_actions[@]}"
}
