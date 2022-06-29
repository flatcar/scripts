#!/bin/bash
#
# Copyright (c) 2021 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# >>> This file is supposed to be SOURCED from the repository ROOT. <<<
#
# vm_build() should be called w/ the positional INPUT parameters below.

# Vendor images build automation stub.
#   This script will build one or more vendor images ("vm") using a pre-built image container.
#
# PREREQUISITES:
#
#   1. SDK version and OS image version are recorded in sdk_container/.repo/manifests/version.txt
#   2. Scripts repo version tag of OS image version to be built is available and checked out.
#   3. Flatcar image container is available via build cache server
#       from "/containers/[VERSION]/flatcar-images-[ARCH]-[FLATCAR_VERSION].tar.gz"
#       or present locally. Must contain packages and image.
#
# INPUT:
#
#   1. Architecture (ARCH) of the TARGET vm images ("arm64", "amd64").
#   2. Image formats to be built. Can be multiple, separated by spaces.
#      Run ./image_to_vm.sh -h in the SDK to get a list of supported images.
#
# OPTIONAL INPUT:
#
#   1. SIGNER. Environment variable. Name of the owner of the artifact signing key.
#        Defaults to nothing if not set - in such case, artifacts will not be signed.
#        If provided, SIGNING_KEY environment variable should also be provided, otherwise this environment variable will be ignored.
#
#   2. SIGNING_KEY. Environment variable. The artifact signing key.
#        Defaults to nothing if not set - in such case, artifacts will not be signed.
#        If provided, SIGNER environment variable should also be provided, otherwise this environment variable will be ignored.
#
# OUTPUT:
#
#   1. Exported VM image(s), pushed to buildcache ( images/[ARCH]/[FLATCAR_VERSION]/ )
#   2. "./ci-cleanup.sh" with commands to clean up temporary build resources,
#        to be run after this step finishes / when this step is aborted.
#   3. If signer key was passed, signatures of artifacts from point 1, pushed along to buildcache.

function vm_build() {
    # Run a subshell, so the traps, environment changes and global
    # variables are not spilled into the caller.
    (
        set -euo pipefail

        _vm_build_impl "${@}"
    )
}
# --

function _vm_build_impl() {
    local arch="$1"
    shift
    # $@ now contains image formats to build

    source ci-automation/ci_automation_common.sh
    source ci-automation/gpg_setup.sh
    init_submodules

    source sdk_container/.repo/manifests/version.txt
    local vernum="${FLATCAR_VERSION}"
    local docker_vernum="$(vernum_to_docker_image_version "${vernum}")"

    local image="flatcar-images-${arch}"
    local image_image="${image}:${docker_vernum}"
    local vms_container="flatcar-vms-${docker_vernum}"

    docker_image_from_buildcache "${image}" "${docker_vernum}"

    # clean up dangling containers from previous builds
    docker container rm -f "${vms_container}" || true

    local images_out="images/"
    rm -rf "${images_out}"

    echo "docker container rm -f '${vms_container}'" >> ci-cleanup.sh

    # automatically add PXE to formats if we build for Equinix Metal (packet).
    local has_packet=0
    local has_pxe=0
    for format; do
        [[ "${format}" = 'packet' ]] || [[ "${format}" = 'equinix_metal' ]] && has_packet=1
        [[ "${format}" = 'pxe' ]] && has_pxe=1
    done

    [[ ${has_packet} -eq 1 ]] && [[ ${has_pxe} -eq 0 ]] && set -- 'pxe' "${@}"

    # Convert platform names (also used to find the test scripts) to image formats they entail
    formats="$*"
    if echo "$formats" | tr ' ' '\n' | grep -q '^vmware'; then
      formats=$(echo "$formats" | tr ' ' '\n' | sed '/vmware.*/d')
      formats+=" vmware vmware_insecure vmware_ova vmware_raw"
    fi
    if echo "$formats" | tr ' ' '\n' | grep -q -P '^(ami|aws)'; then
      formats=$(echo "$formats" | tr ' ' '\n' | sed '/ami.*/d' | sed '/aws/d')
      formats+=" ami ami_vmdk"
    fi
    # Keep compatibility with SDK scripts where "equinix_metal" remains unknown.
    formats=$(echo "$formats" | tr ' ' '\n' | sed 's/equinix_metal/packet/g')

    for format in ${formats}; do
        echo " ###################  VENDOR '${format}' ################### "
        COMPRESSION_FORMAT="bz2"
        if [[ "${format}" =~ ^(openstack|openstack_mini|digitalocean)$ ]];then
            COMPRESSION_FORMAT="gz,bz2"
        fi
        ./run_sdk_container -n "${vms_container}" -C "${image_image}" \
            -v "${vernum}" \
            ./image_to_vm.sh --format "${format}" --board="${arch}-usr" \
                --from "${CONTAINER_IMAGE_ROOT}/${arch}-usr/latest" \
                --image_compression_formats="${COMPRESSION_FORMAT}"
    done

    # copy resulting images + push to buildcache
    ./run_sdk_container -n "${vms_container}" \
        -v "${vernum}" \
        cp --reflink=auto -R "${CONTAINER_IMAGE_ROOT}/${arch}-usr/" "./${images_out}/"

    cd "images/latest"
    sign_artifacts "${SIGNER}" *
    copy_to_buildcache "images/${arch}/${vernum}/" *
}
# --
