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

DOWNLOAD_ROOT=${DOWNLOAD_ROOT:-"${UPLOAD_ROOT}"}
# since /flatcar-jenkins/developer/sdk starts with a / we only use one
DOWNLOAD_ROOT_SDK="gs:/${SDK_URL_PATH}"

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

bin/cork create \
    --verify --verify-signature --replace \
    --sdk-url-path "${SDK_URL_PATH}" \
    --json-key "${GOOGLE_APPLICATION_CREDENTIALS}" \
    --sdk-url storage.googleapis.com \
    ${SCRIPTS_PATCH_ARG} ${OVERLAY_PATCH_ARG} ${PORTAGE_PATCH_ARG} \
    --manifest-branch "refs/tags/${MANIFEST_TAG}" \
    --manifest-name "${MANIFEST_NAME}" \
    --manifest-url "${MANIFEST_URL}"

enter() {
  sudo ln -f "${GOOGLE_APPLICATION_CREDENTIALS}" \
      chroot/etc/portage/gangue.json
  # we add the public key to verify the signature with gangue
  sudo ln -f ./verify.asc chroot/opt/verify.asc
  bin/cork enter --bind-gpg-agent=false -- env \
      FLATCAR_DEV_BUILDS="${DOWNLOAD_ROOT}" \
      FLATCAR_DEV_BUILDS_SDK="${DOWNLOAD_ROOT_SDK}" \
      {FETCH,RESUME}COMMAND_GS="/mnt/host/source/bin/gangue get \
--json-key=/etc/portage/gangue.json $verify_key \
"'"${URI}" "${DISTDIR}/${FILE}"' \
      "$@"
}

script() {
  enter "/mnt/host/source/src/scripts/$@"
}

source .repo/manifests/version.txt
export FLATCAR_BUILD_ID

# Fetch DIGEST to prevent re-downloading the same SDK tarball
enter /mnt/host/source/bin/gangue get --verify-key /opt/verify.asc --json-key /etc/portage/gangue.json "${DOWNLOAD_ROOT_SDK}/amd64/${FLATCAR_SDK_VERSION}/flatcar-sdk-amd64-${FLATCAR_SDK_VERSION}.tar.bz2.DIGESTS" /mnt/host/source/.cache/sdks/

script update_chroot \
    --toolchain_boards="${BOARD}" --dev_builds_sdk="${DOWNLOAD_ROOT_SDK}"

# Set up GPG for signing uploads.
gpg --import "${GPG_SECRET_KEY_FILE}"

# Wipe all of catalyst.
sudo rm -rf src/build

enter sudo FLATCAR_DEV_BUILDS_SDK="${DOWNLOAD_ROOT_SDK}" /mnt/host/source/src/scripts/build_toolchains \
    --sign="${SIGNING_USER}" \
    --sign_digests="${SIGNING_USER}" \
    --upload_root="${UPLOAD_ROOT}" \
    --upload
