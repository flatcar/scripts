#!/bin/bash

VERSION_ID=stable

USAGE="Usage: $0 [-V version] [-d /target/path]
Options:
    -d DEST     Create Flatcar VDI image to the given path.
    -V VERSION  Version to install (e.g. alpha) [default: ${VERSION_ID}]
    -h          This help

This tool creates a Flatcar VDI image to be used with VirtualBox.
"

# Image signing key: buildbot@flatcar-linux.org
GPG_KEY_URL="https://www.flatcar.org/security/image-signing-key/Flatcar_Image_Signing_Key.pem"
GPG_LONG_ID="E25D9AED0593B34A"
GPG_KEY="$(wget -qO- $GPG_KEY_URL)"

while getopts "V:d:a:h" OPTION
do
    case $OPTION in
        V) VERSION_ID="$OPTARG" ;;
        d) DEST="$OPTARG" ;;
        h) echo "$USAGE"; exit;;
        *) exit 1;;
    esac
done

# root user forbidden
if [ $(id -u) -eq 0 ]; then
    echo "$0: This script should not be run as root." >&2
    exit 1
fi

# VirtualBox tools required
which VBoxManage &>/dev/null
if [ $? -ne 0 ]; then
    echo "$0: VBoxManage tool is required to convert image." >&2
    exit 1
fi

if [ -z "${DEST}" ]; then
    DEST=$PWD
fi

if [[ ! -d "${DEST}" ]]; then
    echo "$0: Target path (${DEST}) does not exist." >&2
    exit 1
fi

WORKDIR="${DEST}/tmp.${RANDOM}"
mkdir "$WORKDIR"
trap "rm -rf '${WORKDIR}'" EXIT

RAW_IMAGE_NAME="flatcar_production_image.bin"
IMAGE_NAME="${RAW_IMAGE_NAME}.bz2"
DIGESTS_NAME="${IMAGE_NAME}.DIGESTS.asc"

case ${VERSION_ID}  in
    stable) BASE_URL="https://stable.release.flatcar-linux.net/amd64-usr/current" ;;
    alpha) BASE_URL="https://alpha.release.flatcar-linux.net/amd64-usr/current" ;;
    beta) BASE_URL="https://beta.release.flatcar-linux.net/amd64-usr/current" ;;
    *) BASE_URL="https://alpha.release.flatcar-linux.net/amd64-usr/${VERSION_ID}" ;;
esac

IMAGE_URL="${BASE_URL}/${IMAGE_NAME}"
DIGESTS_URL="${BASE_URL}/${DIGESTS_NAME}"
DOWN_IMAGE="${WORKDIR}/${RAW_IMAGE_NAME}"

if ! wget --spider --quiet "${IMAGE_URL}"; then
    echo "$0: Image URL unavailable: $IMAGE_URL" >&2
    exit 1
fi

if ! wget --spider --quiet "${DIGESTS_URL}"; then
    echo "$0: Image signature unavailable: $DIGESTS_URL" >&2
    exit 1
fi

# Gets Flatcar verion from version.txt file
VERSION_NAME="version.txt"
VERSION_URL="${BASE_URL}/${VERSION_NAME}"
wget --no-verbose -O "${WORKDIR}/${VERSION_NAME}" "${VERSION_URL}"
. "${WORKDIR}/${VERSION_NAME}"
VDI_IMAGE_NAME="flatcar_production_${FLATCAR_BUILD}.${FLATCAR_BRANCH}.${FLATCAR_PATCH}.vdi"
VDI_IMAGE="${DEST}/${VDI_IMAGE_NAME}"

# Setup GnuPG for verifying the image signature
export GNUPGHOME="${WORKDIR}/gnupg"
mkdir "${GNUPGHOME}"
gpg --batch --quiet --import <<<"$GPG_KEY"

echo "Downloading and verifying ${IMAGE_NAME}..."
wget --no-verbose -O "${WORKDIR}/${DIGESTS_NAME}" "${DIGESTS_URL}"
if ! gpg --batch --trusted-key "${GPG_LONG_ID}" \
    --verify "${WORKDIR}/${DIGESTS_NAME}"
then
    echo "$0: GPG signature verification failed for ${DIGESTS_NAME}" >&2
    exit 1
fi

wget -O "${WORKDIR}/${IMAGE_NAME}" "${IMAGE_URL}"

# DIGESTS may include README and other extra files we don't need, filter them.
# Also filter one hash at a time, not required but avoids warnings from *sum.
for sum in sha1 sha512; do
    (cd "${WORKDIR}"
    grep -i -A1 "^# ${sum} HASH$" "${WORKDIR}/${DIGESTS_NAME}" \
        | grep "${IMAGE_NAME}$" | ${sum}sum -c /dev/stdin)
done

echo "Writing ${IMAGE_NAME} to ${DOWN_IMAGE}..."
bzcat -v --stdout "${WORKDIR}/${IMAGE_NAME}" >"${DOWN_IMAGE}"

echo "Converting ${RAW_IMAGE_NAME} to VirtualBox format..."
VBoxManage convertdd "${DOWN_IMAGE}" "${VDI_IMAGE}" --format VDI

rm -rf "${WORKDIR}"
trap - EXIT

echo "Success! Flatcar ${VERSION_ID} VDI image was created on ${VDI_IMAGE_NAME}"

# vim: ts=4 et
