#!/bin/bash
#
# Copyright (c) 2023 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# >>> This file is supposed to be SOURCED from the repository ROOT. <<<
#
# --
function capi_image_build() {
  # Run a subshell, so the traps, environment changes and global
  # variables are not spilled into the caller.
  (
      set -euo pipefail

      _capi_image_build_impl "${@}"
  )
}

function capi_image_publish() {
  # Run a subshell, so the traps, environment changes and global
  # variables are not spilled into the caller.
  (
      set -euo pipefail

      _capi_image_publish_impl "${@}"
  )
}

function setup_capi_params() {
  source sdk_lib/sdk_container_common.sh
  source ci-automation/ci_automation_common.sh
  source ci-automation/gpg_setup.sh
  source sdk_container/.repo/manifests/version.txt

  echo "==================================================================="
  azure_profile_config_file=""
  secret_to_file azure_profile_config_file "${AZURE_PROFILE}"
  azure_auth_config_file=""
  secret_to_file azure_auth_config_file "${AZURE_AUTH_CREDENTIALS}"

  FLATCAR_ARCH="amd64"
  FLATCAR_CHANNEL="$(get_git_channel)"
  FLATCAR_AZURE_AUTH_CREDENTIALS="${AZURE_AUTH_CREDENTIALS}"
  PUBLISHING_SIG_RESOURCE_GROUP=${PUBLISHING_SIG_RESOURCE_GROUP:-flatcar-image-gallery-publishing}
  STAGING_SIG_RESOURCE_GROUP=${STAGING_SIG_RESOURCE_GROUP:-flatcar-image-gallery-staging}
  FLATCAR_STAGING_GALLERY_NAME=${FLATCAR_STAGING_GALLERY_NAME:-flatcar_staging}
  FLATCAR_GALLERY_NAME=${FLATCAR_GALLERY_NAME:-flatcar}

  # Provide a python3 command for the k8s schedule parsing
  export PATH="$PATH:$PWD/ci-automation/python-bin"
  k8s_release_versions=$(ci-automation/get_kubernetes_releases.py)
}

function _capi_image_build_impl() {
    PUBLISHING_SIG_RESOURCE_GROUP="sayan-flatcar-image-gallery-publishing"
    STAGING_SIG_RESOURCE_GROUP="sayan-flatcar-image-gallery-staging"
    FLATCAR_GALLERY_NAME="sayan_flatcar"
    FLATCAR_STAGING_GALLERY_NAME="sayan-flatcar_staging"
    FLATCAR_CAPI_GALLERY_NAME="sayan_flatcar4capi"
    FLATCAR_CAPI_STAGING_GALLERY_NAME="sayan_flatcar4capi_staging"
    for arch in amd64
    do
      setup_capi_params

      for k8s_version in $k8s_release_versions
      do
        KUBERNETES_SEMVER="v${k8s_version}"
        echo "== Building Flatcar SIG images from VHDs"
        ci-automation/azure-sig.sh ensure-flatcar-staging-sig-image-version-from-vhd
        echo "== Building Flatcar CAPI SIG image"
        ci-automation/azure-sig.sh build-capi-staging-image
      done
    done
}

function _capi_image_publish_impl() {
    PUBLISHING_SIG_RESOURCE_GROUP="sayan-flatcar-image-gallery-publishing"
    STAGING_SIG_RESOURCE_GROUP="sayan-flatcar-image-gallery-staging"
    FLATCAR_GALLERY_NAME="sayan_flatcar"
    FLATCAR_STAGING_GALLERY_NAME="sayan-flatcar_staging"
    FLATCAR_CAPI_GALLERY_NAME="sayan_flatcar4capi"
    FLATCAR_CAPI_STAGING_GALLERY_NAME="sayan_flatcar4capi_staging"
    for arch in amd64
    do
      setup_capi_params

      for k8s_version in $k8s_release_versions
      do
        KUBERNETES_SEMVER="v${k8s_version}"
        echo "== Publishing Flatcar SIG image"
        ci-automation/azure-sig.sh publish-flatcar-image
        # Publish Flatcar CAPI image
        ci-automation/azure-sig.sh publish-flatcar-capi-image
      done
    done
}
# --
