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
  source sdk_lib/sdk_container_common.sh
  local vernum="$(get_git_version)"
  local channel="$(get_git_channel)"

  source ci-automation/ci_automation_common.sh
  source ci-automation/gpg_setup.sh

  if { [[ "$vernum" != *"nightly"* ]] || [[ "$channel" != "developer" ]] } && [[ "$push_non_nightly_builds" != "true" ]]; then
    echo "INFO: Version '$vernum' is not a nightly build, or channel is not developer and PUSH_NON_NIGHTLY_BUILDS is not enabled. Skipping publish step."
    exit 0
  fi

  FLATCAR_GALLERY_IMAGE_NAME="flatcar-${channel}-${arch}"
  version=$(cut -d '-' -f2 <<< "${vernum}")

  local date=""
  if [[ "$vernum" == *nightly* ]]; then
    date=$(cut -d '-' -f4 <<< "${vernum}")
    FLATCAR_GALLERY_VERSION="${version%.*}.${date:2}"
  else
    date=$(date +'%y%m%d')
    FLATCAR_GALLERY_VERSION="${version%.*}.${date}"
  fi

  TMP_DIR=$(mktemp -d /var/tmp/flatcar.XXXXXX)
  # Cleanup on exit (success or failure)
  trap 'echo "Cleaning up..."; rm -rf "${TMP_DIR}"' EXIT

  FLATCAR_LOCAL_FILE_URL="https://bincache.flatcar-linux.net/images/amd64/${FLATCAR_VERSION}/flatcar_production_azure_image.vhd.bz2"

  # -- Clean up --
  echo "FLATCAR_GALLERY_IMAGE_NAME ${FLATCAR_GALLERY_IMAGE_NAME}"
  echo "FLATCAR_GALLERY_VERSION ${FLATCAR_GALLERY_VERSION}"
  echo "Channel ${channel}"
  export VHD_STORAGE_ACCOUNT_NAME="sayantestsbwesteurope"
  export VHD_STORAGE_CONTAINER_NAME="vhd"
  # -- end clean up --

  docker run --pull always --rm --net host \
    --env VHD_STORAGE_ACCOUNT_NAME="${VHD_STORAGE_ACCOUNT_NAME}" \
    --env VHD_STORAGE_CONTAINER_NAME="${VHD_STORAGE_CONTAINER_NAME}" \
    --env FLATCAR_ARCH="${arch}" \
    --env FLATCAR_CHANNEL="${channel}" \
    --env FLATCAR_GALLERY_VERSION="${FLATCAR_GALLERY_VERSION}" \
    --env FLATCAR_GALLERY_IMAGE_NAME="${FLATCAR_GALLERY_IMAGE_NAME}" \
    --env FLATCAR_LOCAL_FILE_URL="${FLATCAR_LOCAL_FILE_URL}" \
    -v "$PWD":/work \
    -v "${TMP_DIR}":/data/ \
    -w /work \
    mcr.microsoft.com/azure-cli \
    /work/az_sig_publish
}
# --
