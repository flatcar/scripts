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

  source sdk_lib/sdk_container_common.sh
  local channel=""
  channel="$(get_git_channel)"

  source sdk_container/.repo/manifests/version.txt
  local vernum="${FLATCAR_VERSION}"

  source ci-automation/ci_automation_common.sh
  source ci-automation/gpg_setup.sh

  if [[ "$vernum" != *nightly* ]]; then
    echo "INFO: Version '$vernum' is not a nightly build. Skipping publish step."
    exit 1
  fi

  docker run --pull always --rm --net host \
    --env AZURE_AUTH_CREDENTIALS \
    --env AZURE_PROFILE \
    --env VHD_STORAGE_ACCOUNT_NAME \
    --env AZURE_LOCATION \
    --env PUBLISHING_SIG_RESOURCE_GROUP \
    --env STAGING_SIG_RESOURCE_GROUP \
    --env FLATCAR_STAGING_GALLERY_NAME \
    --env FLATCAR_GALLERY_NAME \
    --env FLATCAR_ARCH
    --env FLATCAR_VERSION \
    --env FLATCAR_CHANNEL \
    -v "$PWD":/work \
    -w /work \
    mcr.microsoft.com/azure-cli \
    /work/az_sig_publish
}
# --
