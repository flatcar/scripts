#!/bin/bash
# Copyright (c) 2021 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -euo pipefail

# Test execution script for the qemu vendor image.
# This script is supposed to run in the mantle container.

source ci-automation/vendor_test.sh

SECUREBOOT=""
ovmf_vars=""

# ARM64 qemu tests only supported on UEFI
if [ "${CIA_ARCH}" = "arm64" ] && [ "${CIA_TESTSCRIPT}" != "qemu_uefi.sh" ] ; then
    echo "1..1" > "${CIA_TAPFILE}"
    echo "not ok - all qemu tests" >> "${CIA_TAPFILE}"
    echo "  ---" >> "${CIA_TAPFILE}"
    echo "  ERROR: ARM64 tests only supported on qemu_uefi." | tee -a "${CIA_TAPFILE}"
    echo "  ..." >> "${CIA_TAPFILE}"
    break_retest_cycle
    exit 1
fi

# Fetch image and firmware if not present
if [ -f "${QEMU_IMAGE_NAME}" ] ; then
    echo "++++ ${CIA_TESTSCRIPT}: Using existing ${QEMU_IMAGE_NAME} for testing ${CIA_VERNUM} (${CIA_ARCH}) ++++"
else
    echo "++++ ${CIA_TESTSCRIPT}: downloading ${QEMU_IMAGE_NAME} for ${CIA_VERNUM} (${CIA_ARCH}) ++++"
    rm -f "${QEMU_IMAGE_NAME}.bz2"
    copy_from_buildcache "images/${CIA_ARCH}/${CIA_VERNUM}/${QEMU_IMAGE_NAME}.bz2" .
    lbunzip2 "${QEMU_IMAGE_NAME}.bz2"
fi

firmware="${QEMU_FIRMWARE}"
if [ "${CIA_TESTSCRIPT}" = "qemu_uefi.sh" ] ; then
    firmware="${QEMU_UEFI_FIRMWARE}"
    ovmf_vars="${QEMU_UEFI_OVMF_VARS}"
fi

if [ "${CIA_TESTSCRIPT}" = "qemu_uefi_secure.sh" ] ; then
    firmware="${QEMU_UEFI_SECURE_FIRMWARE}"
    ovmf_vars="${QEMU_UEFI_SECURE_OVMF_VARS}"
    SECUREBOOT=1
fi

if [ "${CIA_TESTSCRIPT}" = "qemu_uefi.sh" ] || [ "${CIA_TESTSCRIPT}" = "qemu_uefi_secure.sh" ] ; then
    if [ -f "${firmware}" ] ; then
        echo "++++ ${CIA_TESTSCRIPT}: Using existing ${firmware} ++++"
    else
        echo "++++ ${CIA_TESTSCRIPT}: downloading ${firmware} for ${CIA_VERNUM} (${CIA_ARCH}) ++++"
        copy_from_buildcache "images/${CIA_ARCH}/${CIA_VERNUM}/${firmware}" .
    fi
    if [ -f "${ovmf_vars}" ] ; then
        echo "++++ ${CIA_TESTSCRIPT}: Using existing ${ovmf_vars} ++++"
    else
        echo "++++ ${CIA_TESTSCRIPT}: downloading ${ovmf_vars} for ${CIA_VERNUM} (${CIA_ARCH}) ++++"
        copy_from_buildcache "images/${CIA_ARCH}/${CIA_VERNUM}/${ovmf_vars}" .
    fi
fi

declare -a devcontainer_opts
if [ -n "${QEMU_DEVCONTAINER_URL}" ] ; then
    echo "++++ Using custom devcontainer URL '${QEMU_DEVCONTAINER_URL}'"
    devcontainer_opts+=( "--devcontainer-url" "${QEMU_DEVCONTAINER_URL}" )
elif [ -n "${QEMU_DEVCONTAINER_FILE}" ]; then
    echo "++++ Using custom devcontainer FILE '${QEMU_DEVCONTAINER_FILE}'"
    devcontainer_opts+=( "--devcontainer-file" "${QEMU_DEVCONTAINER_FILE}" )
fi
if [ -n "${QEMU_DEVCONTAINER_BINHOST_URL}" ] ; then
    echo "++++ Using custom devcontainer binhost '${QEMU_DEVCONTAINER_BINHOST_URL}'"
    devcontainer_opts+=( "--devcontainer-binhost-url" "${QEMU_DEVCONTAINER_BINHOST_URL}" )
fi

set -x

kola run \
    --board="${CIA_ARCH}-usr" \
    --parallel="${QEMU_PARALLEL}" \
    --platform=qemu \
    --qemu-firmware="${firmware}" \
    --qemu-image="${QEMU_IMAGE_NAME}" \
    --tapfile="${CIA_TAPFILE}" \
    "${ovmf_vars:+--qemu-ovmf-vars=${ovmf_vars}}" \
    ${QEMU_KOLA_SKIP_MANGLE:+--qemu-skip-mangle} \
    "${devcontainer_opts[@]}" \
    ${SECUREBOOT:+--enable-secureboot} \
    --image-version "${CIA_VERNUM}" \
    "${@}"

set +x
