#!/bin/bash -ex

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
    --upload \
done
