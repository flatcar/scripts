#!/bin/bash
set -ex

# The build may not be started without a tag value.
[ -n "${MANIFEST_TAG}" ]

# Set up GPG for verifying tags.
export GNUPGHOME="${PWD}/.gnupg"
rm -rf "${GNUPGHOME}"
trap 'rm -rf "${GNUPGHOME}"' EXIT
mkdir --mode=0700 "${GNUPGHOME}"
gpg --import verify.asc
# Sometimes this directory is not created automatically making further private
# key imports fail, let's create it here as a workaround
mkdir -p --mode=0700 "${GNUPGHOME}/private-keys-v1.d/"

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
    --replace --verify --verify-signature --verbose \
    --sdk-url-path "${SDK_URL_PATH}" \
    --json-key "${GS_DEVEL_CREDS}" \
    ${SCRIPTS_PATCH_ARG} ${OVERLAY_PATCH_ARG} ${PORTAGE_PATCH_ARG} \
    --manifest-branch "refs/tags/${MANIFEST_TAG}" \
    --manifest-name "${MANIFEST_NAME}" \
    --manifest-url "${MANIFEST_URL}" \
    --sdk-url=storage.googleapis.com

# Clear out old images.
sudo rm -rf chroot/build tmp

enter() {
        local verify_key=
        trap 'sudo rm -f chroot/etc/portage/gangue.*' RETURN
        [ -s verify.asc ] &&
        sudo ln -f verify.asc chroot/etc/portage/gangue.asc &&
        verify_key=--verify-key=/etc/portage/gangue.asc
        sudo ln -f "${GS_DEVEL_CREDS}" chroot/etc/portage/gangue.json
        bin/cork enter --bind-gpg-agent=false -- env \
            FLATCAR_DEV_BUILDS="${GS_DEVEL_ROOT}" \
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

script update_chroot \
    --toolchain_boards="${BOARD}" --dev_builds_sdk="${DOWNLOAD_ROOT_SDK}"

# Set up GPG for signing uploads.
gpg --import "${GPG_SECRET_KEY_FILE}"

[ -s verify.asc ] && verify_key=--verify-key=verify.asc || verify_key=

mkdir -p src tmp
bin/cork download-image \
    --root="${UPLOAD_ROOT}/boards/${BOARD}/${FLATCAR_VERSION}" \
    --json-key="${GOOGLE_APPLICATION_CREDENTIALS}" \
    --cache-dir=./src \
    --platform=qemu \
    --verify=true $verify_key

img=src/flatcar_production_image.bin
[[ "${img}.bz2" -nt "${img}" ]] &&
enter lbunzip2 -k -f "/mnt/host/source/${img}.bz2"

if [[ "${FORMATS}" = "" ]]
then
  FORMATS="${FORMAT}"
fi
for FORMAT in ${FORMATS}; do
  script image_to_vm.sh \
    --board="${BOARD}" \
    --format="${FORMAT}" \
    --getbinpkg \
    --getbinpkgver="${FLATCAR_VERSION}" \
    --from=/mnt/host/source/src \
    --to=/mnt/host/source/tmp \
    --sign="${SIGNING_USER}" \
    --sign_digests="${SIGNING_USER}" \
    --download_root="${DOWNLOAD_ROOT}" \
    --upload_root="${UPLOAD_ROOT}" \
    --upload
done
