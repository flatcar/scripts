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
sdk_container_common_env_file="sdk_container/.sdkenv"

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

docker="docker"
if "${is_podman}"; then
  docker="sudo podman"
fi

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
#
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

#
# Set up SDK environment variables.
#  Environment vars are put in a file that is sourced by the container's
#  .bashrc (if present). GNUPGHOME and SSH_AUTH_SOCK are set
#  to container-specific paths if applicable.

function setup_sdk_env() {
    local var

    rm -f "$sdk_container_common_env_file"

    # conditionally set up gnupg, ssh socket, and gcloud auth / boto
    #  depending on availability on the host
    GNUPGHOME="${GNUPGHOME:-$HOME/.gnupg}"
    if [ -d "${GNUPGHOME}" ] ; then
        echo "GNUPGHOME=\"/home/sdk/.gnupg\""  >> "$sdk_container_common_env_file"
        echo "export GNUPGHOME"  >> "$sdk_container_common_env_file"
        export GNUPGHOME
    fi

    if [ -e "${SSH_AUTH_SOCK:-}" ] ; then
        local sockname="$(basename "${SSH_AUTH_SOCK}")"
        echo "SSH_AUTH_SOCK=\"/run/sdk/ssh/$sockname\""  >> "$sdk_container_common_env_file"
        echo "export SSH_AUTH_SOCK"  >> "$sdk_container_common_env_file"
    fi

    # keep in sync with 90_env_keep
    for var in FLATCAR_BUILD_ID COREOS_OFFICIAL \
        EMAIL GIT_AUTHOR_EMAIL GIT_AUTHOR_NAME \
        GIT_COMMITTER_EMAIL GIT_COMMITTER_NAME \
        GIT_PROXY_COMMAND GIT_SSH RSYNC_PROXY \
        GPG_AGENT_INFO FORCE_STAGES \
        SIGNER \
        all_proxy ftp_proxy http_proxy https_proxy no_proxy; do

        if [ -n "${!var:-}" ] ; then
            echo "${var}=\"${!var}\"" >> "$sdk_container_common_env_file"
            echo "export ${var}" >> "$sdk_container_common_env_file"
        fi
    done
}
# --

# Set up gcloud legacy creds (via GOOGLE_APPLICATION_CREDENTIALS)
#  for the SDK container.
#  This will also create a boto config right next to the
#  GOOGLE_APPLICATION_CREDENTIALS json file.

function setup_gsutil() {
    local creds="${GOOGLE_APPLICATION_CREDENTIALS:-$HOME/.config/gcloud/application_default_credentials.json}"
    if [ ! -e "$creds" ]; then
        return
    fi

    local creds_dir="$(dirname "$creds")"
    local botofile="$creds_dir/boto-flatcar-sdk"

    # TODO t-lo: move generation of boto file to sdk_entry so
    #               it's only created inside the container.

    # read creds file and create boto file for gsutil
    local tmp="$(mktemp)"
    trap "rm -f '$tmp'" EXIT

    local oauth_refresh="$(jq  -r '.refresh_token' "$creds")"
    local client_id="$(jq  -r '.client_id' "$creds")"
    local client_secret="$(jq  -r '.client_secret' "$creds")"

    cat >>"$tmp" <<EOF
[Credentials]
gs_oauth2_refresh_token = $oauth_refresh

[OAuth2]
client_id = $client_id
client_secret = $client_secret
EOF
    mv "$tmp" "$botofile"

    echo "BOTO_PATH=\"$botofile\"" >> "$sdk_container_common_env_file"
    echo "export BOTO_PATH" >> "$sdk_container_common_env_file"
    echo "GOOGLE_APPLICATION_CREDENTIALS=\"$creds\"" >> "$sdk_container_common_env_file"
    echo "export GOOGLE_APPLICATION_CREDENTIALS" >> "$sdk_container_common_env_file"

    BOTO_PATH="$botofile"
    GOOGLE_APPLICATION_CREDENTIALS="$creds"
    export BOTO_PATH
    export GOOGLE_APPLICATION_CREDENTIALS
}

   
# --

# Generate volume mount command line options for docker
#  to pass gpg, ssh, and gcloud auth host directories
#  into the SDK container.

function gnupg_ssh_gcloud_mount_opts() {
    local sdk_gnupg_home="/home/sdk/.gnupg"
    local gpgagent_dir="/run/user/$(id -u)/gnupg"

    # pass host GPG home and Agent directories to container
    if [ -d "$GNUPGHOME" ] ; then
        echo "-v $GNUPGHOME:$sdk_gnupg_home"
    fi
    if [ -d "$gpgagent_dir" ] ; then
        echo "-v $gpgagent_dir:$gpgagent_dir"
    fi

    if [ -e "${SSH_AUTH_SOCK:-}" ] ; then
        local sshsockdir="$(dirname "$SSH_AUTH_SOCK")"
        echo "-v $sshsockdir:/run/sdk/ssh"
    fi

    if [ -e "${GOOGLE_APPLICATION_CREDENTIALS:-}" ] ; then
        local creds_dir="$(dirname "${GOOGLE_APPLICATION_CREDENTIALS}")"
        if [ -d "$creds_dir" ] ; then
            echo "-v $creds_dir:$creds_dir"
        fi
    fi
}
