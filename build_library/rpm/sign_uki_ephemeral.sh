#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# sign_uki_ephemeral.sh — Sign the UKI Secure Boot chain with an ephemeral
# (self-signed) key. Covers both systemd-boot (EFI/BOOT/grub*.efi, shim's
# second stage) and the UKI + addons (EFI/Linux/*.efi, acl/uki-addons/*).
# Shim itself (EFI/BOOT/BOOT<ARCH>.EFI) is Microsoft-signed and left alone.
#
# This script generates a one-time RSA 2048-bit certificate and signs all
# applicable EFI binaries on the mounted ESP. The public certificate
# (ca.pem) is written to the output directory so it can be enrolled in:
#   - OVMF Secure Boot db  (for QEMU testing via virt-fw-vars)
#   - Azure gallery image  (for Azure VM testing via securityProfile)
#
# The private key is deleted after signing.
#
# Usage:
#   sign_uki_ephemeral.sh <esp-mount-dir> <cert-output-dir>
#
# Requirements (all available in the SDK container):
#   - openssl   (key and certificate generation)
#   - sbsign    (EFI Authenticode signing — from app-crypt/sbsigntools)

set -euo pipefail

ESP_DIR="${1:?Usage: sign_uki_ephemeral.sh <esp-mount-dir> <cert-output-dir>}"
CERT_OUTPUT_DIR="${2:?Usage: sign_uki_ephemeral.sh <esp-mount-dir> <cert-output-dir>}"

CERT_NAME="uki-signing-ca.pem"

info()  { echo "[sign_uki_ephemeral] $*"; }
error() { echo "[sign_uki_ephemeral] ERROR: $*" >&2; }

sign_efi_file() {
    local efi_file="$1"
    local local_name
    local signed_tmp

    local_name=$(basename "${efi_file}")
    info "  Signing: ${local_name}"

    signed_tmp="${WORK_DIR}/${local_name}.signed"

    sbsign \
        --key "${KEY_FILE}" \
        --cert "${CERT_FILE}" \
        --output "${signed_tmp}" \
        "${efi_file}"

    sudo mv "${signed_tmp}" "${efi_file}"
}

if [[ ! -d "${ESP_DIR}" ]]; then
    error "ESP directory does not exist: ${ESP_DIR}"
    exit 1
fi

if [[ ! -d "${ESP_DIR}/EFI/Linux" ]]; then
    error "No EFI/Linux directory on ESP — is this a UKI image?"
    exit 1
fi

mkdir -p "${CERT_OUTPUT_DIR}"

# Generate ephemeral key + certificate
WORK_DIR=$(mktemp -d)
trap 'rm -rf "${WORK_DIR}"' EXIT

KEY_FILE="${WORK_DIR}/ca.key"
CERT_FILE="${CERT_OUTPUT_DIR}/${CERT_NAME}"

info "Generating ephemeral signing certificate..."
openssl req -x509 \
    -newkey rsa:2048 \
    -days 1 \
    -noenc \
    -keyout "${KEY_FILE}" \
    -out "${CERT_FILE}" \
    -subj "/CN=ACL Ephemeral Signing $(date +%Y%m%d%H%M%S)" \
    -sha256 \
    -addext "basicConstraints=CA:FALSE" \
    -addext "extendedKeyUsage=codeSigning" \
    2>&1

info "Certificate: ${CERT_FILE}"

# Sign every EFI binary on the ESP that shim or the firmware will verify
# against UEFI db. The Secure Boot chain is:
#   firmware → EFI/BOOT/BOOT<ARCH>.EFI (shim, Microsoft-signed — DO NOT re-sign)
#           → EFI/BOOT/grub<ARCH>.efi  (systemd-boot, normally Mariner-signed;
#                                       unsigned when RPMs come from a dev
#                                       pipeline → sign with ephemeral key)
#           → EFI/Linux/<uki>.efi      (UKI + addons — sign with ephemeral key)
#           → acl/uki-addons/*.efi     (addon templates, signed for runtime use)
# Active and template copies are independent files, so each is signed directly.
# The ephemeral CA cert is enrolled in the gallery image's Secure Boot db by
# publish_to_gallery.sh, so shim accepts the signatures produced here.
declare -a efi_files=()

while IFS= read -r -d '' efi_file; do
    efi_files+=("${efi_file}")
done < <(
    find \
        "${ESP_DIR}/EFI/Linux" \
        "${ESP_DIR}/acl/uki-addons" \
        -name '*.efi' -type f -print0 2>/dev/null
    # systemd-boot is installed as grub<arch>.efi (shim looks it up by that
    # name). Match grub*.efi explicitly and skip BOOT<ARCH>.EFI (shim itself).
    find \
        "${ESP_DIR}/EFI/BOOT" \
        -maxdepth 1 -type f -iname 'grub*.efi' -print0 2>/dev/null
)

if [[ ${#efi_files[@]} -eq 0 ]]; then
    error "No EFI files found to sign"
    exit 1
fi

info "Found ${#efi_files[@]} EFI file(s) to sign"

for efi_file in "${efi_files[@]}"; do
    sign_efi_file "${efi_file}"
done

# Private key is in WORK_DIR which is cleaned up by the trap.
info "Signing complete. ${#efi_files[@]} file(s) signed."
info "Public certificate: ${CERT_FILE}"
