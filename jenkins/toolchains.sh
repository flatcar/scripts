#!/bin/bash
set -ex

# The build may not be started without a tag value.
[ -n "${MANIFEST_TAG}" ]

# Catalyst leaves things chowned as root.
[ -d .cache/sdks ] && sudo chown -R "$USER" .cache/sdks

# Set up GPG for verifying tags.
export GNUPGHOME="${PWD}/.gnupg"
rm -rf "${GNUPGHOME}"
trap 'rm -rf "${GNUPGHOME}"' EXIT
mkdir --mode=0700 "${GNUPGHOME}"
gpg --import verify.asc
# Sometimes this directory is not created automatically making further private
# key imports fail, let's create it here as a workaround
mkdir -p --mode=0700 "${GNUPGHOME}/private-keys-v1.d/"

SCRIPT_LOCATION="$(dirname "$(readlink -f "$0")")"
if [ -f "${SCRIPT_LOCATION}/override-vars.env" ] ; then
    source "${SCRIPT_LOCATION}/override-vars.env"
else
    DOWNLOAD_ROOT_SDK="https://storage.googleapis.com${SDK_URL_PATH}"
fi

SCRIPTS_PATCH_ARG=""
OVERLAY_PATCH_ARG=""
PORTAGE_PATCH_ARG=""
if [ "$(cat scripts.patch | wc -l)" != 0 ]; then
  SCRIPTS_PATCH_ARG="--scripts-patch scripts.patch"
fi
if [ "$(cat overlay.patch | wc -l)" != 0 ]; then
  OVERLAY_PATCH_ARG="--overlay-patch overlay.patch"
fi
if [ "$(cat portage.patch | wc -l)" != 0 ]; then
  PORTAGE_PATCH_ARG="--portage-patch portage.patch"
fi

sdk_host="${DOWNLOAD_ROOT_SDK#*://}" 
sdk_host="${sdk_host%/*}"
bin/cork update \
    --create --downgrade-replace --verify --verify-signature --verbose \
    --sdk-url "${sdk_host}" \
    --sdk-url-path "${SDK_URL_PATH}" \
    --force-sync \
    ${SCRIPTS_PATCH_ARG} ${OVERLAY_PATCH_ARG} ${PORTAGE_PATCH_ARG} \
    --manifest-branch "refs/tags/${MANIFEST_TAG}" \
    --manifest-name "${MANIFEST_NAME}" \
    --manifest-url "${MANIFEST_URL}" -- --dev_builds_sdk="${DOWNLOAD_ROOT_SDK}"

enter() {
        bin/cork enter --bind-gpg-agent=false -- "$@"
}

source .repo/manifests/version.txt
export FLATCAR_BUILD_ID

# Set up GPG for signing uploads.
gpg --import "${GPG_SECRET_KEY_FILE}"

# Wipe all of catalyst.
sudo rm -rf src/build

enter sudo FLATCAR_DEV_BUILDS_SDK="${DOWNLOAD_ROOT_SDK}" /mnt/host/source/src/scripts/build_toolchains \
    --sign="${SIGNING_USER}" \
    --sign_digests="${SIGNING_USER}" \
    --upload_root="${UPLOAD_ROOT}" \
    --upload
