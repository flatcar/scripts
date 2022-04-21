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
    --verify --verify-signature --replace \
    --sdk-url-path "${SDK_URL_PATH}" \
    --json-key "${GS_DEVEL_CREDS}" \
    ${SCRIPTS_PATCH_ARG} ${OVERLAY_PATCH_ARG} ${PORTAGE_PATCH_ARG} \
    --manifest-branch "refs/tags/${MANIFEST_TAG}" \
    --manifest-name "${MANIFEST_NAME}" \
    --manifest-url "${MANIFEST_URL}" \
    --sdk-url=storage.googleapis.com

# Clear out old images.
sudo rm -rf chroot/build src/build torcx

enter() {
        local verify_key=
        # Run in a subshell to clean some gangue files on exit without
        # possibly clobbering the global EXIT trap.
        (
        trap 'sudo rm -f chroot/etc/portage/gangue.*' EXIT
        [ -s verify.asc ] &&
        sudo ln -f verify.asc chroot/etc/portage/gangue.asc &&
        verify_key=--verify-key=/etc/portage/gangue.asc
        sudo ln -f "${GS_DEVEL_CREDS}" chroot/etc/portage/gangue.json
        bin/cork enter --bind-gpg-agent=false -- env \
            FLATCAR_DEV_BUILDS="${DOWNLOAD_ROOT}" \
            FLATCAR_DEV_BUILDS_SDK="${DOWNLOAD_ROOT_SDK}" \
            {FETCH,RESUME}COMMAND_GS="/mnt/host/source/bin/gangue get \
--json-key=/etc/portage/gangue.json $verify_key \
"'"${URI}" "${DISTDIR}/${FILE}"' \
            "$@"
        )
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
    --getbinpkgver="${FLATCAR_VERSION}" \
    --regen_configs_only

if [ "x${COREOS_OFFICIAL}" == x1 ]
then
        script set_official --board="${BOARD}" --official
else
        script set_official --board="${BOARD}" --noofficial
fi

# Retrieve this version's torcx manifest
mkdir -p torcx/pkgs
enter gsutil cp -r \
    "${DOWNLOAD_ROOT}/torcx/manifests/${BOARD}/${FLATCAR_VERSION}/torcx_manifest.json"{,.sig} \
    /mnt/host/source/torcx/
gpg --verify torcx/torcx_manifest.json.sig

BASH_SYNTAX_ERROR_WORKAROUND=$(mktemp)
exec {keep_open}<>"${BASH_SYNTAX_ERROR_WORKAROUND}"
rm "${BASH_SYNTAX_ERROR_WORKAROUND}"
jq -r '.value.packages[] | . as $p | .name as $n | $p.versions[] | [.casDigest, .hash] | join(" ") | [$n, .] | join(" ")' "torcx/torcx_manifest.json" > "/proc/$$/fd/${keep_open}"
# Download all cas references from the manifest and verify their checksums
# TODO: technically we can skip ones that don't have a 'path' since they're not
# included in the image.
while read name digest hash
do
        mkdir -p "torcx/pkgs/${BOARD}/${name}/${digest}"
        enter gsutil cp -r "${TORCX_PKG_DOWNLOAD_ROOT}/pkgs/${BOARD}/${name}/${digest}" \
            "/mnt/host/source/torcx/pkgs/${BOARD}/${name}/"
        downloaded_hash=$(sha512sum "torcx/pkgs/${BOARD}/${name}/${digest}/"*.torcx.tgz | awk '{print $1}')
        if [[ "sha512-${downloaded_hash}" != "${hash}" ]]
        then
                echo "Torcx package had wrong hash: ${downloaded_hash} instead of ${hash}"
                exit 1
        fi
done < "/proc/$$/fd/${keep_open}"
# This was "done < <(jq ...)" but it suddenly gave a syntax error with bash 4 when run with systemd-run-wrap.sh

script build_image \
    --board="${BOARD}" \
    --group="${GROUP}" \
    --getbinpkg \
    --getbinpkgver="${FLATCAR_VERSION}" \
    --sign="${SIGNING_USER}" \
    --sign_digests="${SIGNING_USER}" \
    --torcx_manifest=/mnt/host/source/torcx/torcx_manifest.json \
    --torcx_root=/mnt/host/source/torcx/ \
    --upload_root="${UPLOAD_ROOT}" \
    --upload prodtar container

set +x
# Don't fail the whole job
set +e
echo "==================================================================="
echo
export BOARD_A="${BOARD}"
export BOARD_B="${BOARD}"
if [ "${GROUP}" != "developer" ]; then
  export CHANNEL_A="${GROUP}"
else
  export CHANNEL_A="${CHANNEL_BASE}"
fi

if [ "${CHANNEL_A}" = "lts" ]; then
  echo "Comparing to LTS is not supported yet (needs creds)"
  exit 0
fi

export VERSION_A=$(curl -s -S -f -L "https://${CHANNEL_A}.release.flatcar-linux.net/${BOARD}/current/version.txt" | grep -m 1 "FLATCAR_VERSION=" | cut -d "=" -f 2)

if [ "${GROUP}" = "developer" ]; then
  export CHANNEL_B="developer"
  export MODE_B="/developer/"
else
  export CHANNEL_B="${GROUP}"
fi
echo "Image differences compared to ${CHANNEL_A} ${VERSION_A}:"
rm -f package-diff
curl -fsSLO --retry-delay 1 --retry 60 --retry-connrefused --retry-max-time 60 --connect-timeout 20 "https://raw.githubusercontent.com/flatcar-linux/flatcar-build-scripts/master/package-diff"
chmod +x package-diff
echo "Package updates, compared to ${CHANNEL_A} ${VERSION_A}:"
FILE=flatcar_production_image_packages.txt ./package-diff "${VERSION_A}" "${FLATCAR_VERSION}"
echo
echo "Image file changes, compared to ${CHANNEL_A} ${VERSION_A}:"
FILE=flatcar_production_image_contents.txt FILESONLY=1 CUTKERNEL=1 ./package-diff "${VERSION_A}" "${FLATCAR_VERSION}"
echo
echo "Image kernel config changes, compared to ${CHANNEL_A} ${VERSION_A}:"
FILE=flatcar_production_image_kernel_config.txt ./package-diff "${VERSION_A}" "${FLATCAR_VERSION}"
echo
echo "Image file size change (includes /boot, /usr and the default rootfs partitions), compared to ${CHANNEL_A} ${VERSION_A}:"
FILE=flatcar_production_image_contents.txt CALCSIZE=1 ./package-diff "${VERSION_A}" "${FLATCAR_VERSION}"
echo
BASE_PATH="https://bucket.release.flatcar-linux.net/$(echo $UPLOAD_ROOT | sed 's|gs://||g')/boards/${BOARD}/${FLATCAR_VERSION}"
echo "Image URL: ${BASE_PATH}/flatcar_production_image.bin.bz2"
