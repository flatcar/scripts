#!/bin/bash
#
# Copyright (c) 2021 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Helper for fetching a CI stage container image.

set -euo pipefail

function fetch_image_usage() {
    local version="$1"
    echo "Usage: fetch_image [-a <arch>]  [-v <version>] <stage>."
    echo "Fetch and docker load a container image of a CI build stage."
    echo "  <stage>     - CI build stage to fetch:"
    echo "                sdk - fetch & install the plain SDK docker image. Note that this only works for the"
    echo "                    'main' branch since maintenance branches don't build an SDK."
    echo "                packages - fetch the packages (SDK + binary packages) container image."
    echo "                image - fetch the images (SDK + packages + image) container image."
    echo " -v <version> - Custom version to fetch instead of branch version '${version}'"
    echo " -a <arch>    - OS image target architecture - 'arm64' or 'amd64'. Defaults to 'amd64'."
}
# --

function fetch_image() {
    local stage
    local arch="amd64"
    local version="${3:-}"

    local script_root="$(dirname "${BASH_SOURCE[0]}")/../.."
    source "${script_root}/ci-automation/ci_automation_common.sh"

    local vernum="$(source "${script_root}/sdk_container/.repo/manifests/version.txt";
                    echo "${FLATCAR_VERSION}")"
    local docker_vernum="$(vernum_to_docker_image_version "${vernum}")"

    while [ 0 -lt $# ] ; do
        case "$1" in
        -h) usage; exit 0;;
        -v) docker_vernum="$2"; shift; shift;;
        -a) arch="$2";          shift; shift;;
        *)  if [ -n "${stage:-}" ] ; then
                echo "ERROR: Spurious positional argument(s): '$@'"
                fetch_image_usage "${vernum}"
                exit 1
            fi
            stage="$1"
            shift;;
        esac
    done

    local image
    case "${stage}" in
        sdk)      image="flatcar-sdk-${arch}";;
        packages) image="flatcar-packages-${arch}";;
        image)    image="flatcar-images-${arch}";;
        *) echo "ERROR: unknown build stage '$1'"
           fetch_image_usage "${docker_vernum}"
           exit 1;;
    esac

    echo "Fetching '${image}:${docker_vernum}'. Depending on your connection this may take a while."
    docker_image_from_buildcache "${image}" "${docker_vernum}"

    echo "Done! Use"
    echo "   ./run_sdk_container -t -C ${image}:${docker_vernum}"
    echo "to start."
}
# --

if [ "$(basename "$0")" = "fetch_image.sh" ] ; then
    fetch_image $@
fi
