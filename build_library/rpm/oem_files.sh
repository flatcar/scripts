#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#
# Generate OEM partition files (oem-release, grub.cfg) directly for RPM
# mode, bypassing the portage common-oem-files ebuild.
#
# Usage (called by install_oem_package in vm_image_util.sh):
#   oem_files.sh <oem_use> <version> <oem_dest_dir> <bootloader_mode> <oem_files_dir>
#
# Arguments:
#   oem_use         OEM USE flag (e.g. "qemu", "azure", "ami")
#   version         Image version for VERSION_ID in oem-release
#   oem_dest_dir    Destination directory (e.g. ${VM_TMP_ROOT}/oem)
#   bootloader_mode "uki" or "grub"
#   oem_files_dir   Path to common-oem-files/files/ directory containing
#                   per-platform grub.cfg.frag files
#
# Output:
#   ${oem_dest_dir}/oem-release   (always)
#   ${oem_dest_dir}/grub.cfg      (GRUB mode only)

set -euo pipefail

# Source common.sh helpers if available, otherwise define stubs.
if declare -F info &>/dev/null && declare -F die &>/dev/null; then
    :
else
    info()  { echo "INFO:  $*"; }
    warn()  { echo "WARN:  $*" >&2; }
    die()   { echo "ERROR: $*" >&2; exit 1; }
fi

# ── OEM metadata ─────────────────────────────────────────────────
# Maps OEM USE flag → "display name|homepage".
# Sourced from the existing oem-* ebuilds.
declare -A OEM_METADATA=(
    [azure]="Microsoft Azure|https://azure.microsoft.com/"
    [qemu]="QEMU|https://www.qemu.org/"
    [ami]="Amazon EC2|https://aws.amazon.com/ec2/"
    [gce]="Google Compute Engine|https://cloud.google.com/compute"
    [vmware]="VMware|"
    [openstack]="Openstack|https://www.openstack.org/"
    [hetzner]="Hetzner|https://www.hetzner.com/"
    [packet]="Equinix Metal|https://metal.equinix.com/"
    [hyperv]="Microsoft Hyper-V|"
    [digitalocean]="DigitalOcean|https://www.digitalocean.com/"
    [scaleway]="Scaleway|https://www.scaleway.com/"
    [proxmoxve]="Proxmox VE|https://www.proxmox.com/"
    [akamai]="Akamai|https://www.akamai.com/"
    [stackit]="STACKIT|https://www.stackit.de/"
    [kubevirt]="KubeVirt|https://kubevirt.io/"
    [nutanix]="Nutanix|https://www.nutanix.com/"
)

# OEM IDs that differ from the USE flag on the kernel cmdline
# (Ignition/Afterburn expect these values).
declare -A OEM_ID_OVERRIDES=(
    [ami]="ec2"
    [stackit]="openstack"
)

# ── Argument parsing ─────────────────────────────────────────────

if [[ $# -lt 5 ]]; then
    echo "Usage: $0 <oem_use> <version> <oem_dest_dir> <bootloader_mode> <oem_files_dir>" >&2
    exit 1
fi

OEM_USE="$1"
VERSION="$2"
OEM_DEST_DIR="$3"
BOOTLOADER_MODE="$4"
OEM_FILES_DIR="$5"

# ── Lookup metadata ──────────────────────────────────────────────

meta="${OEM_METADATA[${OEM_USE}]:-}"
if [[ -z "${meta}" ]]; then
    die "oem_files: No OEM metadata for '${OEM_USE}'"
fi

OEM_NAME="${meta%%|*}"
OEM_HOMEPAGE="${meta#*|}"
OEM_ID="${OEM_ID_OVERRIDES[${OEM_USE}]:-${OEM_USE}}"

# ── Generate oem-release ─────────────────────────────────────────

info "oem_files: Generating oem-release for '${OEM_USE}'"

oem_release="ID=${OEM_USE}
VERSION_ID=${VERSION}
NAME=\"${OEM_NAME}\""
if [[ -n "${OEM_HOMEPAGE}" ]]; then
    oem_release+="
HOME_URL=\"${OEM_HOMEPAGE}\""
fi
oem_release+="
BUG_REPORT_URL=\"https://aka.ms/azurelinux\""

sudo mkdir -p "${OEM_DEST_DIR}"
echo "${oem_release}" | sudo tee "${OEM_DEST_DIR}/oem-release" > /dev/null

info "oem_files: Wrote ${OEM_DEST_DIR}/oem-release"

# ── Generate grub.cfg (GRUB mode only) ──────────────────────────

if [[ "${BOOTLOADER_MODE}" != "uki" ]]; then
    grub_frag="${OEM_FILES_DIR}/${OEM_USE}/grub.cfg.frag"

    info "oem_files: Generating grub.cfg for '${OEM_USE}'"
    {
        echo "# GRUB settings"
        echo ""
        echo "set oem_id=\"${OEM_ID}\""
        if [[ -f "${grub_frag}" ]]; then
            cat "${grub_frag}"
        fi
    } | sudo tee "${OEM_DEST_DIR}/grub.cfg" > /dev/null

    info "oem_files: Wrote ${OEM_DEST_DIR}/grub.cfg"
else
    info "oem_files: UKI mode — skipping grub.cfg"
fi
