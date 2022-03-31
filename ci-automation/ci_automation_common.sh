#!/bin/bash
#
# Copyright (c) 2021 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# CI automation common functions.

source ci-automation/ci-config.env
: ${PIGZ:=pigz}
: ${docker:=docker}

function init_submodules() {
    git submodule init
    git submodule update
}
# --

function update_submodule() {
    local submodule="$1"
    local commit_ish="$2"

    cd "sdk_container/src/third_party/${submodule}"
    git fetch --all --tags
    git checkout "${commit_ish}"
    cd -
}
# --

function check_version_string() {
    local version="$1"

    if ! echo "${version}" | grep -qE '^(main-|alpha-|beta-|stable-|lts-)' ; then
        echo "ERROR: invalid version '${version}', must start with 'main-', 'alpha-', 'beta-', 'stable-', or 'lts-'"
        exit 1
    fi
}
# --

function update_submodules() {
    local coreos_git="$1"
    local portage_git="$2"

    init_submodules
    update_submodule "coreos-overlay" "${coreos_git}"
    update_submodule "portage-stable" "${portage_git}"
}
# --

function update_and_push_version() {
    local version="$1"
    local push_to_branch="${2:-false}"

    # set up author and email so git does not complain when tagging
    if ! git config --get user.name >/dev/null 2>&1 ; then
        git -C . config user.name "${CI_GIT_AUTHOR}"
    fi
    if ! git config --get user.email >/dev/null 2>&1 ; then
        git -C . config user.email "${CI_GIT_EMAIL}"
    fi

    # Add and commit local changes
    git add "sdk_container/src/third_party/coreos-overlay"
    git add "sdk_container/src/third_party/portage-stable"
    git add "sdk_container/.repo/manifests/version.txt"

    git commit --allow-empty -m "New version: ${version}"

    git fetch --all --tags --force
    local ret=0
    git diff --exit-code "${version}" || ret=$?
    # This will return != 0 if
    #  - the remote tag does not exist (rc: 127)
    #  - the tag does not exist locally (rc: 128)
    #  - the remote tag has changes compared to the local tree (rc: 1)
    if [ "$ret" = "0" ]; then
      echo "Reusing existing tag" >&2
      git checkout -f --recurse-submodules "${version}"
      return
    elif [ "$ret" = "1" ]; then
      echo "Remote tag exists already and is not equal" >&2
      return 1
    elif [ "$ret" != "127" ] && [ "$ret" != "128" ]; then
      echo "Error: Unexpected git diff return code ($ret)" >&2
      return 1
    fi

    local -a TAG_ARGS
    if [ "${SIGN-0}" = 1 ]; then
      TAG_ARGS=("-s" "-m" "${version}")
    fi

    git tag -f "${TAG_ARGS[@]}" "${version}"

    if [ "${push_to_branch}" = "true" ]; then
      local branch="$(git rev-parse --abbrev-ref HEAD)"
      git push origin "${branch}"
    fi

    git push origin "${version}"
}
# --

function copy_from_buildcache() {
    local what="$1"
    local where_to="$2"

    mkdir -p "$where_to"
    curl --fail --silent --show-error --location --retry-delay 1 --retry 60 \
        --retry-connrefused --retry-max-time 60 --connect-timeout 20 \
        --remote-name --output-dir "${where_to}" "https://${BUILDCACHE_SERVER}/${what}" 
}
# --

function gen_sshcmd() {
    echo -n "ssh -o BatchMode=yes"
    echo -n " -o StrictHostKeyChecking=no"
    echo -n " -o UserKnownHostsFile=/dev/null"
    echo    " -o NumberOfPasswordPrompts=0"
}
# --

function copy_to_buildcache() {
    local remote_path="${BUILDCACHE_PATH_PREFIX}/$1"
    shift

    local sshcmd="$(gen_sshcmd)"

    $sshcmd "${BUILDCACHE_USER}@${BUILDCACHE_SERVER}" \
        "mkdir -p ${remote_path}"

    rsync -Pav -e "${sshcmd}" "$@" \
        "${BUILDCACHE_USER}@${BUILDCACHE_SERVER}:${remote_path}"
}
# --

function image_exists_locally() {
    local name="$1"
    local version="$2"
    local image="${name}:${version}"

    local image_exists="$($docker images "${image}" \
                            --no-trunc --format '{{.Repository}}:{{.Tag}}')"

    [ "${image}" = "${image_exists}" ]
}
# --

# Derive docker-safe image version string from vernum.
#
function vernum_to_docker_image_version() {
    local vernum="$1"
    echo "$vernum" | sed 's/[+]/-/g'
}
# --

# Return the full name (repo+name+tag) of an image. Useful for SDK images
#  pulled from the registry (which have the registry pre-pended)
function docker_image_fullname() {
    local image="$1"
    local version="$2"

    $docker images --no-trunc --format '{{.Repository}}:{{.Tag}}' \
        | grep -E "^(${CONTAINER_REGISTRY}/)*${image}:${version}$"
}
# --

function docker_image_to_buildcache() {
    local image="$1"
    local version="$2"

    # strip potential container registry prefix
    local tarball="$(basename "$image")-${version}.tar.gz"

    $docker save "${image}":"${version}" | $PIGZ -c > "${tarball}"
    copy_to_buildcache "containers/${version}" "${tarball}"
}
# --

function docker_commit_to_buildcache() {
    local container="$1"
    local image_name="$2"
    local image_version="$3"

    $docker commit "${container}" "${image_name}:${image_version}"
    docker_image_to_buildcache "${image_name}" "${image_version}"
}
# --

function docker_image_from_buildcache() {
    local name="$1"
    local version="$2"
    local tgz="${name}-${version}.tar.gz"

    if image_exists_locally "${name}" "${version}" ; then
        return
    fi

    local url="https://${BUILDCACHE_SERVER}/containers/${version}/${tgz}"

    curl --fail --silent --show-error --location --retry-delay 1 --retry 60 \
        --retry-connrefused --retry-max-time 60 --connect-timeout 20 \
        --remote-name "${url}"

    cat "${tgz}" | $PIGZ -d -c | $docker load

    rm "${tgz}"
}
# --

function docker_image_from_registry_or_buildcache() {
    local image="$1"
    local version="$2"

    if image_exists_locally "${CONTAINER_REGISTRY}/${image}" "${version}" ; then
        return
    fi

    if $docker pull "${CONTAINER_REGISTRY}/${image}:${version}" ; then
        return
    fi

    echo "Falling back to tar ball download..." >&2
    docker_image_from_buildcache "${image}" "${version}"
}
# --
