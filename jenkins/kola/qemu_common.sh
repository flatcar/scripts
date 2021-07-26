#!/bin/bash
set -ex

PLATFORM="$1"
if [ "${PLATFORM}" = qemu ]; then
  TIMEOUT="12h"
  BIOS="bios-256k.bin"
elif [ "${PLATFORM}" = qemu_uefi ]; then
  TIMEOUT="14h"
  BIOS="/mnt/host/source/tmp/flatcar_production_qemu_uefi_efi_code.fd"
else
  echo "Unknown platform: \"${PLATFORM}\""
fi

sudo rm -rf *.tap src/scripts/_kola_temp tmp _kola_temp*

enter() {
  bin/cork enter --bind-gpg-agent=false -- "$@"
}

# Set up GPG for verifying tags.
export GNUPGHOME="${PWD}/.gnupg"
rm -rf "${GNUPGHOME}"
trap 'rm -rf "${GNUPGHOME}"' EXIT
mkdir --mode=0700 "${GNUPGHOME}"
gpg --import verify.asc
# Sometimes this directory is not created automatically making further private
# key imports fail, let's create it here as a workaround
mkdir -p --mode=0700 "${GNUPGHOME}/private-keys-v1.d/"

DOWNLOAD_ROOT_SDK="https://storage.googleapis.com${SDK_URL_PATH}"

bin/cork update \
    --create --downgrade-replace --verify --verify-signature --verbose \
    --sdk-url-path "${SDK_URL_PATH}" \
    --force-sync \
    --manifest-branch "refs/tags/${MANIFEST_TAG}" \
    --manifest-name "${MANIFEST_NAME}" \
    --manifest-url "${MANIFEST_URL}" -- --dev_builds_sdk="${DOWNLOAD_ROOT_SDK}"
source .repo/manifests/version.txt

[ -s verify.asc ] && verify_key=--verify-key=verify.asc || verify_key=

mkdir -p tmp
bin/cork download-image \
    --cache-dir=tmp \
    --json-key="${GOOGLE_APPLICATION_CREDENTIALS}" \
    --platform="${PLATFORM}" \
    --root="${DOWNLOAD_ROOT}/boards/${BOARD}/${FLATCAR_VERSION}" \
    --verify=true $verify_key
enter lbunzip2 -k -f /mnt/host/source/tmp/flatcar_production_image.bin.bz2

# create folder to handle case where arm64 is missing
sudo mkdir -p chroot/usr/lib/kola/arm64
# copy all of the latest mantle binaries into the chroot
sudo cp -t chroot/usr/lib/kola/arm64 bin/arm64/*
sudo cp -t chroot/usr/lib/kola/amd64 bin/amd64/*
sudo cp -t chroot/usr/bin bin/[b-z]*

if [[ "${KOLA_TESTS}" == "" ]]; then
  KOLA_TESTS="*"
fi

rm -f flatcar_test_update.gz
bin/gangue get \
    --json-key="${GOOGLE_APPLICATION_CREDENTIALS}" \
    --verify=true $verify_key \
    "${DOWNLOAD_ROOT}/boards/${BOARD}/${FLATCAR_VERSION}/flatcar_test_update.gz"
mv flatcar_test_update.gz tmp/

# Do not expand the kola test patterns globs
set -o noglob
enter sudo timeout --signal=SIGQUIT "${TIMEOUT}" kola run \
    --board="${BOARD}" \
    --channel="${GROUP}" \
    --parallel="${PARALLEL}" \
    --platform=qemu \
    --qemu-bios="${BIOS}" \
    --qemu-image=/mnt/host/source/tmp/flatcar_production_image.bin \
    --tapfile="/mnt/host/source/${JOB_NAME##*/}.tap" \
    --torcx-manifest=/mnt/host/source/torcx_manifest.json \
    --update-payload=/mnt/host/source/tmp/flatcar_test_update.gz \
    ${KOLA_TESTS}
set +o noglob

sudo rm -rf tmp
