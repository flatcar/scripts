#!/bin/bash

function az_sig_publish() {
  # Run a subshell, so the traps, environment changes and global
  # variables are not spilled into the caller.
  (
      set -euo pipefail

      _az_sig_publish_impl "${@}"
  )
}

# --
function _az_sig_publish_impl() {
  local arch="$1"
  local push_non_nightly_builds="${PUSH_NON_NIGHTLY_BUILDS:-}"

  source sdk_container/.repo/manifests/version.txt
  local vernum="${FLATCAR_VERSION}"

  source ci-automation/ci_automation_common.sh
  source ci-automation/gpg_setup.sh

  if [[ "$vernum" != *nightly* && "${push_non_nightly_builds}" != "true" ]]; then
    echo "INFO: Version '$vernum' is not a nightly build, and PUSH_NON_NIGHTLY_BUILDS is not enabled. Skipping publish step."
    exit 0
  fi

  if [[ "$vernum" == *nightly* ]]; then
    IFS='-' read -r nchannel nversion nnightly ndate ntime <<< "$vernum"
    FLATCAR_IMAGE_NAME="flatcar-${nchannel}-${nnightly}-${arch}"
    FLATCAR_VERSION="${nversion%.*}.${ndate}${ntime}"
  else
    source sdk_lib/sdk_container_common.sh
    local channel=""
    channel="$(get_git_channel)"
    FLATCAR_IMAGE_NAME="flatcar-${channel}-${arch}"
    datetime=$(date +'%Y%m%d%H%M')
    version="${vernum%%+*}"
    FLATCAR_VERSION="${version%.*}.${datetime}"
  fi

  echo "${FLATCAR_VERSION}"
  echo "${FLATCAR_IMAGE_NAME}"

  #azure_auth_config_file=""
  #secret_to_file azure_auth_config_file "${AZURE_AUTH_CREDENTIALS}"
  #export AZURE_CLIENT_ID=$(jq -r '.clientId' "${azure_auth_config_file}")
  #export AZURE_CLIENT_SECRET=$(jq -r '.clientSecret' "${azure_auth_config_file}")
  #export AZURE_TENANT_ID=$(jq -r '.tenantId' "${azure_auth_config_file}")

  docker run --pull always --rm --net host \
    --env AZURE_CLIENT_ID \
    --env AZURE_CLIENT_SECRET \
    --env AZURE_TENANT_ID \
    --env VHD_STORAGE_ACCOUNT_NAME \
    --env AZURE_LOCATION \
    --env PUBLISHING_SIG_RESOURCE_GROUP \
    --env STAGING_SIG_RESOURCE_GROUP \
    --env FLATCAR_STAGING_GALLERY_NAME \
    --env FLATCAR_GALLERY_NAME \
    --env FLATCAR_ARCH="${arch}" \
    --env FLATCAR_VERSION="${FLATCAR_VERSION}" \
    --env FLATCAR_IMAGE_NAME="${FLATCAR_IMAGE_NAME}" \
    -v "$PWD":/work \
    -w /work \
    mcr.microsoft.com/azure-cli \
    /work/az_sig_publish
}
# --
