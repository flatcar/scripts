# Copyright (c) 2021 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# This file contains common functions used across SDK container scripts.

#
# globals
#
sdk_container_common_versionfile="sdk_container/.repo/manifests/version.txt"
sdk_container_common_registry="ghcr.io/flatcar"

# Check for podman and docker; use docker if present, podman alternatively.
# Podman needs 'sudo' since we need privileged containers for the SDK.

is_podman=false
if command -v podman >/dev/null; then
    # podman is present
    if command -v docker >/dev/null ; then
        # docker is present, too
        if docker help | grep -q -i podman; then
            # "docker" is actually podman.
            # NOTE that 'docker --version' does not reliably work for podman detection
            #  since 'podman' uses argv[0] in its version string.
            #  A symlink docker->podman will result in 'podman' using the 'docker' argv[0].
            is_podman=true
        fi
    else
        # docker is not present
        is_podman=true
    fi
fi

docker_a=( docker )
if "${is_podman}"; then
  docker_a=( sudo -E podman )
fi
docker=${docker_a[*]}

function call_docker() {
    "${docker_a[@]}" "${@}"
}

function docker_build() {
    PROGRESS_NO_TRUNC=1 call_docker build --progress plain "${@}"
}

# --

# Common "echo" function

function yell() {
    echo -e "\n###### $@ ######"
}
# --

# Guess the SDK version from the current git commit.
#
function get_git_version() {
    local tag="$(git tag --points-at HEAD)"
    if [ -z "$tag" ] ; then
        git describe --tags
    else
        echo "$tag"
    fi
}
# --

function get_sdk_version_from_versionfile() {
    ( source "$sdk_container_common_versionfile"; echo "$FLATCAR_SDK_VERSION"; )
}
# --

function get_version_from_versionfile() {
    ( source "$sdk_container_common_versionfile"; echo "$FLATCAR_VERSION"; )
}
# --

# return true if a given version number is an official build
#
function is_official() {
    local vernum="$1"

    local official="$(echo "$vernum" | sed -n 's/^[0-9]\+\.[0-9]\+\.[0-9]\+$/true/p')"

    test -n "$official"
}
# --

# extract the build ID suffix from a version string ("alpha-3244.0.1-nightly2" => "nightly2")
#
function build_id_from_version() {
    local version="$1"

    # support vernums and versions ("alpha-"... is optional)
    echo "${version}" | sed -n 's/^\([a-z]\+-\)\?[0-9.]\+[-+]\(.*\)$/\2/p'
}
# --

# Get channel from a version string ("alpha-3244.0.1-nightly2" => "alpha")
#
function channel_from_version() {
    local version="$1"
    local channel=""

    channel=$(echo "${version}" | cut -d - -f 1)
    if [ "${channel}" != "alpha" ] && [ "${channel}" != "beta" ] && [ "${channel}" != "stable" ] && [ "${channel}" != "lts" ]; then
        channel="developer"
    fi
    echo "${channel}"
}
# --

function get_git_channel() {
	channel_from_version "$(get_git_version)"
}
# --

# extract the version number (w/o build ID) from a version string ("alpha-3244.0.1-nightly2" => "3244.0.1")
#
function vernum_from_version() {
    local version="$1"

    # support vernums and versions ("alpha-"... is optional)
    echo "${version}" | sed -n 's/^\([a-z]\+-\)\?\([0-9.]\+\).*/\2/p'
}
# --

# Strip prefix from version string if present ("alpha-3233.0.0[-...]" => "3233.0.0[-...]")
#  and add a "+[build suffix]" if this is a non-official build. The "+" matches the version
#  string generation in the build scripts.
function strip_version_prefix() {
    local version="$1"

    local build_id="$(build_id_from_version "${version}")"
    local version_id="$(vernum_from_version "${version}")"

    if [ -n "${build_id}" ] ; then
        echo "${version_id}+${build_id}"
    else
        echo "${version_id}"
    fi
}
# --

# Derive docker-safe image version string from vernum.
# Keep in sync with ci-automation/ci_automation_common.sh
function vernum_to_docker_image_version() {
    local vernum="$1"
    echo "$vernum" | sed 's/[+]/-/g'
}
# --

# Creates the Flatcar build / SDK version file.
# Must be called from the script root.
#
#  In the versionfile, FLATCAR_VERSION is the OS image version _number_ plus a build ID if this is no
#   official build. The FLATCAR_VERSION_ID is the plain vernum w/o build ID - it's the same as FLATCAR_VERSION
#   for official builds. The FLATCAR_BUILD_ID is the build ID suffix for non-official builds.
#   Lastly, the FLATCAR_SDK_VERSION is the full version number (including build ID if no official SDK release)
#   the OS image is to be built with.
#
function create_versionfile() {
    local sdk_version="$1"
    local os_version="${2:-$sdk_version}"
    local build_id="$(build_id_from_version "${os_version}")"
    local version_id="$(vernum_from_version "${os_version}")"

    sdk_version="$(strip_version_prefix "${sdk_version}")"
    os_version="$(strip_version_prefix "${os_version}")"
    yell "Writing versionfile '$sdk_container_common_versionfile' to SDK '$sdk_version', OS '$os_version'."

    cat >"$sdk_container_common_versionfile" <<EOF
FLATCAR_VERSION=${os_version}
FLATCAR_VERSION_ID=${version_id}
FLATCAR_BUILD_ID="${build_id}"
FLATCAR_SDK_VERSION=${sdk_version}
EOF
}
# --

# Generate command line options for Docker to pass GPG and SSH host directories
# into the SDK container.
function credential_docker_args() {
    local -n args_ref="${1}"; shift
    args_ref=()

    local sdk_gnupg_home="/home/sdk/.gnupg"
    local gpgagent_dir="/run/user/${UID}/gnupg"

    # pass host GPG home and Agent directories to container
    : "${GNUPGHOME:="${HOME}"/.gnupg}"
    if [[ -d ${GNUPGHOME:-} ]] ; then
        args_ref+=(
            -v "$GNUPGHOME:$sdk_gnupg_home"
            -e GNUPGHOME="$sdk_gnupg_home"
        )
    fi
    if [[ -d ${gpgagent_dir} ]] ; then
        args_ref+=( -v "${gpgagent_dir}:${gpgagent_dir}" )
    fi

    if [[ -e ${SSH_AUTH_SOCK:-} ]] ; then
        args_ref+=(
            -v "${SSH_AUTH_SOCK%/*}:/run/sdk/ssh"
            -e SSH_AUTH_SOCK="/run/sdk/ssh/${SSH_AUTH_SOCK##*/}"
        )
    fi
}

function scavenge_for_configure_logs() {
    local -a sudo_cmd=()
    while [[ $# -gt 0 ]]; do
        case ${1} in
            --use-sudo) sudo_cmd=( sudo ); shift;;
            --) shift; break;;
            --*) echo "unknown flag for $0: $1" >&2; exit 1;;
            *) break;;
        esac
    done
    local dir=${1}; shift
    local logdir=${1}; shift

    # TODO: Add more interesting files
    local -a interesting_files=( config.log CMakeConfigureLog.yaml meson-log.txt ) find_flags=()
    for f in "${interesting_files[@]}"; do
        if [[ ${#find_flags[@]} -ne 0 ]]; then
            find_flags+=( '-o' )
        fi
        find_flags+=( '-name' "${f}" )
    done
    local -a logs
    local l d
    mapfile -t logs < <("${sudo_cmd[@]}" find "${dir}" "${find_flags[@]}")
    for l in "${logs[@]}"; do
        d=${l#"${dir}"}
        d=${d#/}
        if [[ ${d} = */* ]]; then
            d=${d%/*}
        else
            d='.'
        fi
        "${sudo_cmd[@]}" mkdir -p "${logdir}/config-logs/${d}"
        "${sudo_cmd[@]}" cp -a "${l}" "${logdir}/config-logs/${d}"
    done
}
