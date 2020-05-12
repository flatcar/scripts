#!/bin/bash -ex

enter() {
        bin/cork enter --bind-gpg-agent=false -- "$@"
}

source .repo/manifests/version.txt
export FLATCAR_BUILD_ID

# Set up GPG for signing uploads.
gpg --import "${GPG_SECRET_KEY_FILE}"

# Wipe all of catalyst.
sudo rm -rf src/build

enter sudo \
    FLATCAR_DEV_BUILDS_SDK="${DOWNLOAD_ROOT_SDK}" \
    FORCE_STAGES="${FORCE_STAGES}" \
    /mnt/host/source/src/scripts/bootstrap_sdk \
        --sign="${SIGNING_USER}" \
        --sign_digests="${SIGNING_USER}" \
        --upload_root="${UPLOAD_ROOT}" \
        --upload
