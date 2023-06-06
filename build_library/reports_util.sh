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
        '%M %D %i %n %s ./%P\n' >"${output}"
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
