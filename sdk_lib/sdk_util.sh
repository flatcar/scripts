#!/bin/bash

# Copyright (c) 2013 The CoreOS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# common.sh must be properly sourced before this file.
[[ -n "${FLATCAR_SDK_VERSION}" ]] || exit 1

FLATCAR_SDK_ARCH="amd64" # We are unlikely to support anything else.
FLATCAR_SDK_TARBALL="flatcar-sdk-${FLATCAR_SDK_ARCH}-${FLATCAR_SDK_VERSION}.tar.bz2"
FLATCAR_SEED_TARBALL_CACHE="${REPO_CACHE_DIR}/sdks"
FLATCAR_SDK_TARBALL_PATH="${FLATCAR_SEED_TARBALL_CACHE}/${FLATCAR_SDK_TARBALL}"
FLATCAR_DEV_BUILDS_SDK="${FLATCAR_DEV_BUILDS_SDK-$FLATCAR_DEV_BUILDS/sdk}"

# Download the seed tarball (if required) and verify digests/sig
seed_tarball_download() {
    local filename=${1##*/} path=$1 urls

    if [[ $1 == *://* ]]; then
        path=${FLATCAR_SEED_TARBALL_CACHE}/${filename}
        urls=( "$1" )
    elif [[ $1 == ${FLATCAR_SDK_TARBALL_PATH} ]]; then
        urls=( "${FLATCAR_SDK_SERVERS[@]/%//sdk/${FLATCAR_SDK_ARCH}/${FLATCAR_SDK_VERSION}/${filename}}" )
    elif [[ -f $1 ]]; then
        # A non-default local tarball doesn't need a digest.
        echo "$1"
        return 0
    else
        die_notrace "Seed tarball not found: $1"
    fi

    echo "${path}"
    verify_digests "${path}" && return 0

    info "Downloading ${filename}"
    local url suffix suffixes=('' '.DIGESTS') # TODO(marineam): download .asc

    for url in "${urls[@]}"; do
        info "URL: ${url}"
        for suffix in "${suffixes[@]}"; do
            # If all downloads fail, we will detect it later.
            if ! curl --fail --silent --show-error --location --retry-delay 1 --retry 60 \
                 --retry-connrefused --retry-max-time 60 --connect-timeout 20 \
                 --output "${path}${suffix}" "${url}${suffix}"; then
                break
            fi
        done
        if _seed_tarball_check_downloads "${path}" "${suffixes[@]}"; then
            if verify_digests "${path}"; then
                find "${FLATCAR_SEED_TARBALL_CACHE}" -maxdepth 1 -type f \
                    ! -name "${filename}*" -fprintf /dev/stderr "Cleaning up %f\n" -delete || :
                return 0
            fi
            info "Seed tarball digest verification failed, cleaning up and will try another server"
        else
            info "Downloading seed tarball from ${url} failed, cleaning up and will try another server"
        fi
        find "${FLATCAR_SEED_TARBALL_CACHE}" -maxdepth 1 -type f \
            -name "${filename}*" -delete
    done
    die_notrace "Seed tarball download failed!"
}

_seed_tarball_check_downloads() {
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
