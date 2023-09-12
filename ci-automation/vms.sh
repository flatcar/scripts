#!/bin/bash
#
# Copyright (c) 2021 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# >>> This file is supposed to be SOURCED from the repository ROOT. <<<
#
# vm_build() should be called w/ the positional INPUT parameters below.

# Vendor images build automation stub.
#   This script will build one or more vendor images ("vm") using a pre-built packages container.
#
# PREREQUISITES:
#
#   1. SDK version and OS image version are recorded in sdk_container/.repo/manifests/version.txt
#   2. Scripts repo version tag of OS image version to be built is available and checked out.
#   3. Flatcar packages container is available via build cache server
#       from "/containers/[VERSION]/flatcar-images-[ARCH]-[FLATCAR_VERSION].tar.gz"
#       or present locally. Must contain packages.
#   4. The generic Flatcar image must be present in build cache server.
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
#   3. A file ../scripts.patch to apply with "git am -3" for the scripts repo.
#
# OUTPUT:
#
#   1. Exported VM image(s), pushed to buildcache ( images/[ARCH]/[FLATCAR_VERSION]/ )
#   2. "./ci-cleanup.sh" with commands to clean up temporary build resources,
#        to be run after this step finishes / when this step is aborted.
#   3. If signer key was passed, signatures of artifacts from point 1, pushed along to buildcache.
#   4. DIGESTS of the artifacts from point 1, pushed to buildcache. If signer key was passed, armored ASCII files of the generated DIGESTS files too, pushed to buildcache.

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

    source sdk_container/.repo/manifests/version.txt
    local vernum="${FLATCAR_VERSION}"
    local docker_vernum="$(vernum_to_docker_image_version "${vernum}")"

    local packages="flatcar-packages-${arch}"
    local packages_image="${packages}:${docker_vernum}"

    docker_image_from_buildcache "${packages}" "${docker_vernum}"

    local vms="flatcar-vms-${arch}"
    local vms_container="${vms}-${docker_vernum}"

    apply_local_patches

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

    source sdk_lib/sdk_container_common.sh

    if is_official "${vernum}"; then
        export COREOS_OFFICIAL=1
    else
        export COREOS_OFFICIAL=0
    fi

    local images_in="images-in/"
    local file
    rm -rf "${images_in}"
    for file in flatcar_production_image.bin.bz2 flatcar_production_image_sysext.squashfs version.txt; do
        copy_from_buildcache "images/${arch}/${vernum}/${file}" "${images_in}"
    done
    lbunzip2 "${images_in}/flatcar_production_image.bin.bz2"
    ./run_sdk_container -x ./ci-cleanup.sh -n "${vms_container}" -C "${packages_image}" \
            -v "${vernum}" \
            mkdir -p "${CONTAINER_IMAGE_ROOT}/${arch}-usr/latest"
    ./run_sdk_container -n "${vms_container}" -C "${packages_image}" \
            -v "${vernum}" \
            mv "${images_in}" "${CONTAINER_IMAGE_ROOT}/${arch}-usr/latest-input"

    for format in ${formats}; do
        echo " ###################  VENDOR '${format}' ################### "
        COMPRESSION_FORMAT="bz2"
        if [[ "${format}" =~ ^(openstack|openstack_mini|digitalocean)$ ]];then
            COMPRESSION_FORMAT="gz,bz2"
        elif [[ "${format}" =~ ^(qemu|qemu_uefi)$ ]];then
            COMPRESSION_FORMAT="bz2,none"
        fi
        ./run_sdk_container -n "${vms_container}" -C "${packages_image}" \
            -v "${vernum}" \
            ./image_to_vm.sh --format "${format}" --board="${arch}-usr" \
                --from "${CONTAINER_IMAGE_ROOT}/${arch}-usr/latest-input" \
                --to "${CONTAINER_IMAGE_ROOT}/${arch}-usr/latest" \
                --image_compression_formats="${COMPRESSION_FORMAT}" \
                --only_store_compressed
    done

    # copy resulting images + push to buildcache
    local images_out="images/"
    rm -rf "${images_out}"
    ./run_sdk_container -n "${vms_container}" -C "${packages_image}" \
        -v "${vernum}" \
        mv "${CONTAINER_IMAGE_ROOT}/${arch}-usr/" "./${images_out}/"

    create_digests "${SIGNER}" "images/latest/"*
    sign_artifacts "${SIGNER}" "images/latest/"*
    copy_to_buildcache "images/${arch}/${vernum}/" "images/latest/"*
}
# --
