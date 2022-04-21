#!/bin/bash
set -ex

# The build may not be started without a tag value.
[ -n "${MANIFEST_TAG}" ]

# For developer builds that are based on a non-developer release,
# we need the DOWNLOAD_ROOT variable to be the base path, keeping the
# UPLOAD_ROOT variable as the developer path.
if [[ "${RELEASE_BASE_IS_DEV}" = "false" && "${GROUP}" = "developer" && "${RELEASE_BASE}" != "" ]]; then
    DOWNLOAD_ROOT=$(echo ${DOWNLOAD_ROOT} | sed 's,/developer,,');
fi
# since /flatcar-jenkins/developer/sdk starts with a / we only use one
DOWNLOAD_ROOT_SDK="gs:/${SDK_URL_PATH}"

# Set up GPG for verifying tags.
export GNUPGHOME="${PWD}/.gnupg"
rm -rf "${GNUPGHOME}"
trap 'rm -rf "${GNUPGHOME}"' EXIT
mkdir --mode=0700 "${GNUPGHOME}"
gpg --import verify.asc
# Sometimes this directory is not created automatically making further private
# key imports fail, let's create it here as a workaround
mkdir -p --mode=0700 "${GNUPGHOME}/private-keys-v1.d/"

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
    ${SCRIPTS_PATCH_ARG} ${OVERLAY_PATCH_ARG} ${PORTAGE_PATCH_ARG} \
    --manifest-branch "refs/tags/${MANIFEST_TAG}" \
    --manifest-name "${MANIFEST_NAME}" \
    --manifest-url "${MANIFEST_URL}" \
    --sdk-url=storage.googleapis.com

enter() {
        local verify_key=
        trap 'sudo rm -f chroot/etc/portage/gangue.*' RETURN
        [ -s verify.asc ] &&
        sudo ln -f verify.asc chroot/etc/portage/gangue.asc &&
        verify_key=--verify-key=/etc/portage/gangue.asc
        sudo ln -f "${GOOGLE_APPLICATION_CREDENTIALS}" \
            chroot/etc/portage/gangue.json
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

# Set up GPG for signing uploads.
gpg --import "${GPG_SECRET_KEY_FILE}"

script update_chroot \
    --toolchain_boards="${BOARD}" --dev_builds_sdk="${DOWNLOAD_ROOT_SDK}"

script setup_board \
    --board="${BOARD}" \
    --getbinpkgver=${RELEASE_BASE:-"${FLATCAR_VERSION}" --toolchainpkgonly} \
    --skip_chroot_upgrade \
    --force

script build_packages \
    --board="${BOARD}" \
    --getbinpkgver=${RELEASE_BASE:-"${FLATCAR_VERSION}" --toolchainpkgonly} \
    --usepkg_exclude="${BINARY_PACKAGES_TO_EXCLUDE}" \
    --skip_chroot_upgrade \
    --skip_torcx_store \
    --sign="${SIGNING_USER}" \
    --sign_digests="${SIGNING_USER}" \
    --upload_root="${UPLOAD_ROOT}" \
    --upload

script build_torcx_store \
    --board="${BOARD}" \
    --sign="${SIGNING_USER}" \
    --sign_digests="${SIGNING_USER}" \
    --upload_root="${UPLOAD_ROOT}" \
    --torcx_upload_root="${TORCX_PKG_DOWNLOAD_ROOT}" \
    --tectonic_torcx_download_root="${TECTONIC_TORCX_DOWNLOAD_ROOT}" \
    --upload

if [[ "${GROUP}" = "developer" ]]
then
    GROUP="${CHANNEL_BASE}"
fi

# Update entry for latest nightly build reference (there are no symlinks in GCS and it is also good to keep it deterministic)
if [[ "${FLATCAR_BUILD_ID}" == *-*-nightly-* ]]
then
  # Extract the nightly name like "flatcar-MAJOR-nightly" from "dev-flatcar-MAJOR-nightly-NUMBER"
  NAME=$(echo "${FLATCAR_BUILD_ID}" | grep -o "dev-.*-nightly" | cut -d - -f 2-)
  echo "${FLATCAR_VERSION}" | bin/cork enter --bind-gpg-agent=false -- gsutil cp - "${UPLOAD_ROOT}/boards/${BOARD}/${NAME}.txt"
fi
