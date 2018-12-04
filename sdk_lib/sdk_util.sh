#!/bin/bash

# Copyright (c) 2013 The CoreOS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# common.sh must be properly sourced before this file.
[[ -n "${FLATCAR_SDK_VERSION}" ]] || exit 1

FLATCAR_SDK_ARCH="amd64" # We are unlikely to support anything else.
FLATCAR_SDK_TARBALL="flatcar-sdk-${FLATCAR_SDK_ARCH}-${FLATCAR_SDK_VERSION}.tar.bz2"
FLATCAR_SDK_TARBALL_CACHE="${REPO_CACHE_DIR}/sdks"
FLATCAR_SDK_TARBALL_PATH="${FLATCAR_SDK_TARBALL_CACHE}/${FLATCAR_SDK_TARBALL}"
FLATCAR_SDK_URL="${FLATCAR_DEV_BUILDS}/sdk/${FLATCAR_SDK_ARCH}/${FLATCAR_SDK_VERSION}/${FLATCAR_SDK_TARBALL}"

# Return true when $1 is less than or equal to $2
ver_lte() {
    [ "$1" = "$(echo -e "$1\\n$2" | sort --version-sort | head -n1)" ]
}

# First, try to download the given version of an SDK tarball.
# If it does not exist, fall back to the next recent version available.
sdk_download_tarball_graceful() {
    # an array of Flatcar versions, without prefix "v", by descending order.
    FLATCAR_VERS=$(curl -s https://api.github.com/repos/flatcar-linux/manifest/releases | jq -r '.[].tag_name' | sed -e 's/^v//' | sort -r)

    while read -r ver; do
        # skip newer versions than ${FLATCAR_SDK_VERSION}
        if ! ver_lte "$ver" "${FLATCAR_SDK_VERSION}"; then
            continue
        fi

        FLATCAR_SDK_TARBALL="flatcar-sdk-${FLATCAR_SDK_ARCH}-${ver}.tar.bz2"
        FLATCAR_SDK_URL="${FLATCAR_DEV_BUILDS}/sdk/${FLATCAR_SDK_ARCH}/${ver}/${FLATCAR_SDK_TARBALL}"
        if sdk_download_tarball; then
            break
        fi

        echo "Cannot get $SDK_URL. Trying the next recent version."
        sleep 1
    done <<< "$FLATCAR_VERS"
}

# Download the current SDK tarball (if required) and verify digests/sig
sdk_download_tarball() {
    if sdk_verify_digests; then
        return 0
    fi

    info "Downloading ${FLATCAR_SDK_TARBALL}"
    info "URL: ${FLATCAR_SDK_URL}"
    local suffix
    for suffix in "" ".DIGESTS"; do # TODO(marineam): download .asc
        wget --tries=3 --timeout=30 --continue \
            -O  "${FLATCAR_SDK_TARBALL_PATH}${suffix}" \
            "${FLATCAR_SDK_URL}${suffix}" \
            || return 1
    done

    sdk_verify_digests || die_notrace "SDK digest verification failed!"
    sdk_clean_cache
}

sdk_verify_digests() {
    if [[ ! -f "${FLATCAR_SDK_TARBALL_PATH}" || \
          ! -f "${FLATCAR_SDK_TARBALL_PATH}.DIGESTS" ]]; then
        return 1
    fi

    # TODO(marineam): Add gpg signature verification too.

    verify_digests "${FLATCAR_SDK_TARBALL_PATH}" || return 1
}

sdk_clean_cache() {
    pushd "${FLATCAR_SDK_TARBALL_CACHE}" >/dev/null
    local filename
    for filename in *; do
        if [[ "${filename}" == "${FLATCAR_SDK_TARBALL}"* ]]; then
            continue
        fi
        info "Cleaning up ${filename}"
        # Not a big deal if this fails
        rm -f "${filename}" || true
    done
    popd >/dev/null
}
