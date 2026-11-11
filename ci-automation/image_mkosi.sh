#!/bin/bash
#
# Copyright (c) 2026 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# >>> This file is supposed to be SOURCED from the repository ROOT. <<<
#
# image_mkosi_build() should be called w/ the positional INPUT parameters below.

# Experimental OS image build with mkosi (mkosi/), next to image_build().
#   Builds the production image and the OEM profiles' vendor images from the
#   packages container image_build() uses, one mkosi run per image.
#
# PREREQUISITES:
#
#   1. SDK version and OS image version are recorded in sdk_container/.repo/manifests/version.txt
#   2. Scripts repo version tag of OS image version to be built is available and checked out.
#   3. Flatcar packages container is available via build cache server
#       from "/containers/[VERSION]/flatcar-packages-[ARCH]-[FLATCAR_VERSION].tar.gz"
#       or present locally. Container must contain binary packages.
#
# INPUT:
#
#   1. Architecture (ARCH) of the TARGET OS image ("arm64", "amd64").
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
#   3. MKOSI_OEM_PROFILES. Environment variable. Whitespace-separated mkosi/mkosi.profiles/oem-*
#        profiles to build vendor images for. Defaults to every profile in the images table
#        below (without oem-gce on arm64).
#
# OUTPUT:
#
#   1. The images from the images table below, named and compressed like their
#        image_build()/vms_build() counterparts, pushed to buildcache at
#        images-mkosi/[ARCH]/[FLATCAR_VERSION]/. Never images/: release.sh publishes it as a whole.
#   2. "./ci-cleanup.sh" with commands to clean up temporary build resources,
#        to be run after this step finishes / when this step is aborted.
#   3. If signer key was passed, signatures of artifacts from point 1, pushed along to buildcache.
#   4. DIGESTS of the artifacts from point 1, pushed to buildcache. If signer key was passed, armored ASCII files of the generated DIGESTS files too, pushed to buildcache.

function image_mkosi_build() {
    # Run a subshell, so the traps, environment changes and global
    # variables are not spilled into the caller.
    (
        set -euo pipefail

        _image_mkosi_build_impl "${@}"
    )
}
# --

function _image_mkosi_build_impl() {
    local arch="$1"

    source sdk_lib/sdk_container_common.sh
    local channel=""
    channel="$(get_git_channel)"
    source ci-automation/ci_automation_common.sh
    source ci-automation/gpg_setup.sh

    source sdk_container/.repo/manifests/version.txt
    local vernum="${FLATCAR_VERSION}"
    local docker_vernum="$(vernum_to_docker_image_version "${vernum}")"

    local packages="flatcar-packages-${arch}"
    local packages_image="${packages}:${docker_vernum}"

    docker_image_from_buildcache "${packages}" "${docker_vernum}"

    local image_container="flatcar-images-mkosi-${arch}-${docker_vernum}"
    local official_arg=""
    if is_official "${vernum}"; then
            export COREOS_OFFICIAL=1
            official_arg="--official"
    else
            export COREOS_OFFICIAL=0
            official_arg="--noofficial"
    fi

    apply_local_patches

    local mkosi_arch default_profiles
    case "${arch}" in
        amd64) mkosi_arch=x86-64; default_profiles="oem-azure oem-ami oem-gce oem-openstack oem-hetzner oem-akamai oem-stackit oem-oraclecloud";;
        arm64) mkosi_arch=arm64; default_profiles="oem-azure oem-ami oem-openstack oem-hetzner oem-akamai oem-stackit oem-oraclecloud";;
        *) echo "Unsupported architecture '${arch}'" >&2; return 1;;
    esac
    local -a profiles
    read -r -a profiles <<<"${MKOSI_OEM_PROFILES-${default_profiles}}"

    # Like image_build(): only the packages container's binary packages, no
    # source builds and no remote binhost.
    local -a mkosi=(
        sudo --preserve-env=MODULES_SIGN_KEY,MODULES_SIGN_CERT,MODULE_SIGNING_KEY_DIR,COREOS_OFFICIAL
        mkosi --architecture="${mkosi_arch}"
              --environment=FLATCAR_UPDATE_GROUP="${channel}"
              --environment=FLATCAR_SOURCE_BUILD=0
              --environment=FLATCAR_ALLOW_REMOTE_BINPKGS=0
    )

    ./run_sdk_container -x ./ci-cleanup.sh -n "${image_container}" -C "${packages_image}" \
            -v "${vernum}" \
            ./set_official --board="${arch}-usr" "${official_arg}"

    # The SDK doesn't ship mkosi yet.
    ./run_sdk_container -n "${image_container}" -C "${packages_image}" \
            -v "${vernum}" \
            sudo emerge --oneshot --noreplace --verbose app-admin/mkosi

    # mkosi runs as root, so the host can't remove its output or key itself.
    echo "docker run --rm --entrypoint rm -v '${PWD}/mkosi:/mkosi' '${packages_image}' -rf /mkosi/mkosi.output /mkosi/mkosi.key /mkosi/mkosi.crt" >> ./ci-cleanup.sh

    # A per-build key signs the sysexts and the confext, like build_image's
    # SYSEXT_SIGNING_KEY_DIR one.
    ./run_sdk_container -n "${image_container}" -C "${packages_image}" \
            -v "${vernum}" \
            bash -c 'cd mkosi && rm -f mkosi.key mkosi.crt && mkosi genkey'

    # The first run's -ff also drops the cache, which a reused workspace may
    # hold from an older build; the profiles then reuse its fresh base tree.
    local profile force=-ff
    for profile in "" "${profiles[@]}"; do
        ./run_sdk_container -n "${image_container}" -C "${packages_image}" \
                -v "${vernum}" \
                bash -c 'cd mkosi && "$@"' -- \
                "${mkosi[@]}" ${profile:+--profile="${profile}"} "${force}" build
        force=-f
    done

    local images_out="images-mkosi"
    rm -rf "${images_out}"
    mkdir -p "${images_out}"
    # source:destination:compression; vms.sh picks the same compression per
    # format for image_to_vm.sh.
    local -a images=( "image.raw:flatcar_production_image.bin:bz2" )
    for profile in "${profiles[@]}"; do
        case "${profile}" in
            oem-azure)       images+=( flatcar_production_azure_image.vhd::bz2 );;
            oem-ami)         images+=( flatcar_production_ami_image.bin::bz2 );;
            oem-gce)         images+=( flatcar_production_gce.tar.gz:: );;
            oem-qemu)        images+=( flatcar_production_qemu_uefi_image.img::bz2 flatcar_production_qemu_uefi.sh:: );;
            oem-openstack)   images+=( flatcar_production_openstack_image.img:: );;
            oem-hetzner)     images+=( flatcar_production_hetzner_image.bin::bz2 );;
            oem-akamai)      images+=( flatcar_production_akamai_image.bin::gz );;
            oem-stackit)     images+=( flatcar_production_stackit_image.img:: );;
            oem-oraclecloud) images+=( flatcar_production_oraclecloud_image.img:: );;
            *) echo "No known image for mkosi profile '${profile}'" >&2; return 1;;
        esac
    done
    local entry src dst compression
    for entry in "${images[@]}"; do
        IFS=: read -r src dst compression <<<"${entry}"
        dst="${dst:-${src}}"
        ./run_sdk_container -n "${image_container}" -C "${packages_image}" \
                -v "${vernum}" \
                bash -c 'sudo mv "mkosi/mkosi.output/$1" "$2" && sudo chown "$(id -u):$(id -g)" "$2" && case "$3" in bz2) lbzip2 -f "$2";; gz) pigz -f "$2";; esac' -- \
                "${src}" "${images_out}/${dst}" "${compression}"
    done

    create_digests "${SIGNER}" "${images_out}/"*
    sign_artifacts "${SIGNER}" "${images_out}/"*
    copy_to_buildcache "${images_out}/${arch}/${vernum}/" "${images_out}/"*
}
# --
