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

  export PUBLISHING_SIG_RESOURCE_GROUP=${PUBLISHING_SIG_RESOURCE_GROUP:-flatcar-image-gallery-publishing}
  export STAGING_SIG_RESOURCE_GROUP=${STAGING_SIG_RESOURCE_GROUP:-flatcar-image-gallery-staging}
  export FLATCAR_STAGING_GALLERY_NAME=${FLATCAR_STAGING_GALLERY_NAME:-flatcar_staging}
  export FLATCAR_GALLERY_NAME=${FLATCAR_GALLERY_NAME:-flatcar}

  # Provide a python3 command for the k8s schedule parsing
  export PATH="$PATH:$PWD/ci-automation/python-bin"
  export K8S_VERSIONS=$(ci-automation/get_kubernetes_releases.py)
}

function _inside_capi_image_build() {
  (
    set -euo pipefail

    source sdk_lib/sdk_container_common.sh
    source ci-automation/ci_automation_common.sh
    source sdk_container/.repo/manifests/version.txt
    # Needed because we are not the SDK container here
    source sdk_container/.env
    CHANNEL="$(get_git_channel)"
    VERSION="${FLATCAR_VERSION}"
    azure_profile_config_file=""
    secret_to_file azure_profile_config_file "${AZURE_PROFILE}"
    azure_auth_config_file=""
    secret_to_file azure_auth_config_file "${AZURE_AUTH_CREDENTIALS}"
    export AZURE_CLIENT_ID=$(jq -r ".clientId" "${azure_auth_config_file}")
    export AZURE_CLIENT_SECRET=$(jq -r ".clientSecret" "${azure_auth_config_file}")

    export FLATCAR_ARCH="amd64"
    export DEBUG=true
    # FLATCAR_CHANNEL="$(get_git_channel)"
    export FLATCAR_CHANNEL="stable"
    export FLATCAR_VERSION="3510.2.5"
    export PUBLISHING_SIG_RESOURCE_GROUP="sayan-flatcar-image-gallery-publishing"
    export STAGING_SIG_RESOURCE_GROUP="sayan-flatcar-image-gallery-staging"
    export FLATCAR_GALLERY_NAME="sayan_flatcar"
    export FLATCAR_STAGING_GALLERY_NAME="sayan_flatcar_staging"
    export FLATCAR_CAPI_GALLERY_NAME="sayan_flatcar4capi"
    export FLATCAR_CAPI_STAGING_GALLERY_NAME="sayan_flatcar4capi_staging"


    mkdir -p "${HOME}/.config/pip/"
    tee "${HOME}/.config/pip/pip.conf" << END
[global]
break-system-packages = true
END

    export PATH="${HOME}/.local/bin:$PATH"
    echo "== Building Flatcar SIG images from VHDs"
    ci-automation/azure-sig.sh azure_login
    ci-automation/azure-sig.sh ensure-flatcar-staging-sig-image-version-from-vhd
    for K8S_VERSION in $K8S_VERSIONS
    do
      export KUBERNETES_SEMVER="v${K8S_VERSION}"
      echo "== Building Flatcar CAPI SIG image"
      ci-automation/azure-sig.sh build-capi-staging-image
    done

  )
}

function _capi_image_build_impl() {
  source sdk_lib/sdk_container_common.sh
  source ci-automation/ci_automation_common.sh
  source ci-automation/gpg_setup.sh

  source sdk_container/.repo/manifests/version.txt
  # Needed because we are not the SDK container here
  source sdk_container/.env
  local sdk_version="${FLATCAR_SDK_VERSION}"
  local docker_sdk_vernum=""
  docker_sdk_vernum="$(vernum_to_docker_image_version "${sdk_version}")"
  local vernum="${FLATCAR_VERSION}"
  local docker_vernum=""
  docker_vernum="$(vernum_to_docker_image_version "${vernum}")"

  local container_name="flatcar-publish-${docker_vernum}"
  local mantle_ref
  mantle_ref=$(cat sdk_container/.repo/manifests/mantle-container)

  # A job on each worker prunes old mantle images (docker image prune), no need to do it here
  echo "docker rm -f '${container_name}'" >> ./ci-cleanup.sh

  for arch in amd64
  do
    setup_capi_params

    touch sdk_container/.env # This file should already contain the required credentials as env vars
    echo "export K8S_VERSIONS='${K8S_VERSIONS}'" >> sdk_container/.env
    docker run --pull always --rm --name="${container_name}" --net host \
      -w /work -v "$PWD":/work "${mantle_ref}" bash -c "git config --global --add safe.directory /work && source ci-automation/capi_image.sh && _inside_capi_image_build"
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

      for K8S_VERSION in $K8S_VERSIONS
      do
        touch sdk_container/.env # This file should already contain the required credentials as env vars
        echo 'export KUBERNETES_SEMVER="v${K8S_VERSION}"' >> sdk_container/.env
        echo "== Publishing Flatcar SIG image"
        ci-automation/azure-sig.sh publish-flatcar-image
        # Publish Flatcar CAPI image
        ci-automation/azure-sig.sh publish-flatcar-capi-image
      done
    done
}
# --
