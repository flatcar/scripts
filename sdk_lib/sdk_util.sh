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
FLATCAR_DEV_BUILDS_SDK="${FLATCAR_DEV_BUILDS_SDK-$FLATCAR_DEV_BUILDS/sdk}"
FLATCAR_SDK_URL="${FLATCAR_DEV_BUILDS_SDK}/${FLATCAR_SDK_ARCH}/${FLATCAR_SDK_VERSION}/${FLATCAR_SDK_TARBALL}"

# Download the current SDK tarball (if required) and verify digests/sig
sdk_download_tarball() {
    if sdk_verify_digests; then
        return 0
    fi

    info "Downloading ${FLATCAR_SDK_TARBALL}"
    local server url suffix
    local -a suffixes

    suffixes=('' '.DIGESTS') # TODO(marineam): download .asc
    for server in "${FLATCAR_SDK_SERVERS[@]}"; do
        url="${server}/sdk/${FLATCAR_SDK_ARCH}/${FLATCAR_SDK_VERSION}/${FLATCAR_SDK_TARBALL}"
        info "URL: ${url}"
        for suffix in "${suffixes[@]}"; do
            # If all downloads fail, we will detect it later.
            if ! curl --fail --silent --show-error --location --retry-delay 1 --retry 60 \
                 --retry-connrefused --retry-max-time 60 --connect-timeout 20 \
                 --output "${FLATCAR_SDK_TARBALL_PATH}${suffix}" "${url}${suffix}"; then
                break
            fi
        done
        if _sdk_check_downloads "${FLATCAR_SDK_TARBALL_PATH}" "${suffixes[@]}"; then
            if sdk_verify_digests; then
                sdk_clean_cache
                return 0
            fi
            info "SDK digest verification failed, cleaning up and will try another server"
        else
            info "Downloading SDK from ${url} failed, cleaning up and will try another server"
        fi
        _sdk_remove_downloads "${FLATCAR_SDK_TARBALL_PATH}" "${suffixes[@]}"
    done
    die_notrace "SDK download failed!"
}

_sdk_remove_downloads() {
    local path="${1}"; shift
    # rest of the params are suffixes

    rm -f "${@/#/${path}}"
}

_sdk_check_downloads() {
    local path="${1}"; shift
    # rest of the params are suffixes
    local suffix

    for suffix; do
        if [[ ! -s "${path}${suffix}" ]]; then
            return 1
        fi
    done
    return 0
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
