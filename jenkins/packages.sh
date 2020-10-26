#!/bin/bash -ex

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
            {FETCH,RESUME}COMMAND_GS="/usr/bin/gangue get \
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
