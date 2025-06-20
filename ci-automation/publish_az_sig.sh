#!/bin/bash

function publish_az_sig() {
    # Run a subshell, so the traps, environment changes and global
    # variables are not spilled into the caller.
    (
        set -euo pipefail

        _publish_az_sig_impl "${@}"
    )
}
# --

function _publish_az_sig_impl() {
    local arch="$1"

    source sdk_lib/sdk_container_common.sh
    local channel=""
    channel="${get_git_channel}"

    source ci-automation/ci_automation_common.sh
    source ci-automation/gpg_setup.sh
    source sdk_container/.repo/manifests/version.txt

    # Get SDK from either the registry or import from build cache
    # This is a NOP if the image is present locally.
    local sdk_name="flatcar-sdk-${arch}"
    local docker_sdk_vernum="$(vernum_to_docker_image_version "${FLATCAR_SDK_VERSION}")"

    docker_image_from_registry_or_buildcache "${sdk_name}" "${docker_sdk_vernum}"
    local sdk_image="$(docker_image_fullname "${sdk_name}" "${docker_sdk_vernum}")"
    echo "docker image rm -f '${sdk_image}'" >> ./ci-cleanup.sh

    local docker_vernum="$(vernum_to_docker_image_version "${FLATCAR_VERSION}")"
    local publish_az_sig_container="flatcar-publish-az-sig-${arch}-${docker_vernum}"
    ./run_sdk_container -x ./ci-cleanup.sh -n "${publish_az_sig_container}" -C "${sdk_image}" \
            ./publish_azure_sig --board="${arch}-usr" \
                                --group="${channel}" --version="${FLATCAR_VERSION}" \
                                publish-flatcar-image
}
# --
