#!/bin/bash
set -ex

sudo rm -rf *.tap src/scripts/_kola_temp tmp _kola_temp*

enter() {
  bin/cork enter --bind-gpg-agent=false -- "$@"
}

script() {
  enter "/mnt/host/source/src/scripts/$@"
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

# since /flatcar-jenkins/developer/sdk starts with a / we only use one
DOWNLOAD_ROOT_SDK="gs:/${SDK_URL_PATH}"

bin/cork create \
    --verify --verify-signature --replace \
    --sdk-url-path "${SDK_URL_PATH}" \
    --json-key "${GOOGLE_APPLICATION_CREDENTIALS}" \
    --manifest-branch "refs/tags/${MANIFEST_TAG}" \
    --manifest-name "${MANIFEST_NAME}" \
    --sdk-url storage.googleapis.com \
    --manifest-url "${MANIFEST_URL}"

source .repo/manifests/version.txt

[ -s verify.asc ] && verify_key=--verify-key=verify.asc || verify_key=

script update_chroot \
    --toolchain_boards="${BOARD}" --dev_builds_sdk="${DOWNLOAD_ROOT_SDK}"

mkdir -p tmp
bin/cork download-image \
    --cache-dir=tmp \
    --json-key="${GOOGLE_APPLICATION_CREDENTIALS}" \
    --platform=qemu \
    --root="${DOWNLOAD_ROOT}/boards/${BOARD}/${FLATCAR_VERSION}" \
    --verify=true $verify_key
enter lbunzip2 -k -f /mnt/host/source/tmp/flatcar_production_image.bin.bz2

# create folder to handle case where arm64 is missing
sudo mkdir -p chroot/usr/lib/kola/{arm64,amd64}
# copy all of the latest mantle binaries into the chroot
sudo cp -t chroot/usr/lib/kola/arm64 bin/arm64/*
sudo cp -t chroot/usr/lib/kola/amd64 bin/amd64/*
sudo cp -t chroot/usr/bin bin/[b-z]*

if [[ "${KOLA_TESTS}" == "" ]]; then
  KOLA_TESTS="*"
fi

# Do not expand the kola test patterns globs
set -o noglob
enter sudo timeout --signal=SIGQUIT 12h kola run \
    --board="${BOARD}" \
    --channel="${GROUP}" \
    --parallel="${PARALLEL}" \
    --platform=qemu \
    --qemu-bios=bios-256k.bin \
    --qemu-image=/mnt/host/source/tmp/flatcar_production_image.bin \
    --tapfile="/mnt/host/source/${JOB_NAME##*/}.tap" \
    --torcx-manifest=/mnt/host/source/torcx_manifest.json \
    ${KOLA_TESTS}
set +o noglob

sudo rm -rf tmp
