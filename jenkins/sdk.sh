#!/bin/bash -ex

UPLOAD_ROOT="${UPLOAD_ROOT:-}"
UPLOAD_TYPE="${UPLOAD_TYPE:-sftp}"

enter() {
        bin/cork enter --experimental -- "$@"
}

source .repo/manifests/version.txt
export FLATCAR_BUILD_ID

# Set up GPG for signing uploads.
gpg --import "${GPG_SECRET_KEY_FILE}"

# Wipe all of catalyst.
sudo rm -rf src/build

S=/mnt/host/source/src/scripts
enter ${S}/update_chroot
enter sudo emerge -uv --jobs=2 catalyst
enter sudo ${S}/bootstrap_sdk \
    --sign="${SIGNING_USER}" \
    --sign_digests="${SIGNING_USER}" \
    --upload_root="${UPLOAD_ROOT}" \
    --upload_type="${UPLOAD_TYPE}" \
    --upload

# Free some disk space only on success to allow debugging failures.
sudo rm -rf src/build/catalyst/builds
