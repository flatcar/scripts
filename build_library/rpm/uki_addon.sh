#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#
# Build a UKI addon (.addon.efi) containing the OEM-specific kernel
# command-line arguments for a given platform.
#
# Usage (called by install_uki_oem_addon in vm_image_util.sh):
#   uki_addon.sh <esp_dir> <oem_use> <arch> <board_root> <oem_files_dir>
#
# Arguments:
#   esp_dir        Path to the mounted ESP filesystem
#   oem_use        OEM USE flag (e.g. "qemu", "azure", "ami")
#   arch           Board architecture: "amd64" or "arm64"
#   board_root     Path to a root filesystem containing the EFI stub under
#                  usr/lib/systemd/boot/efi/.  May be the board sysroot
#                  (e.g. /build/amd64-usr) or the mounted image rootfs.
#   oem_files_dir  Path to common-oem-files/files/ directory containing
#                  per-platform uki.cfg files
#
# uki.cfg variables (all optional):
#   ADDON_OEM_ID           Override oem_id (defaults to ${oem_use})
#   ADDON_CONSOLE_AMD64    console= args for x86_64
#   ADDON_CONSOLE_ARM64    console= args for aarch64
#   ADDON_APPEND           Extra kernel arguments
#
# Output:
#   ${esp_dir}/EFI/Linux/<uki_name>.extra.d/oem.addon.efi

set -euo pipefail

# Parse arguments
if [[ $# -lt 5 ]]; then
    echo "Usage: $0 <esp_dir> <oem_use> <arch> <board_root> <oem_files_dir>" >&2
    exit 1
fi

ESP_DIR="$1"
OEM_USE="$2"
ARCH="$3"
BOARD_ROOT="$4"
OEM_FILES_DIR="$5"

# Source common.sh for info/warn/die helpers if available, otherwise
# define minimal stubs so the script can also be tested standalone.
if declare -F info &>/dev/null && declare -F die &>/dev/null; then
    : # already available (sourced by caller)
else
    info()  { echo "INFO:  $*"; }
    warn()  { echo "WARN:  $*" >&2; }
    die()   { echo "ERROR: $*" >&2; exit 1; }
fi

# Determine EFI architecture suffix
case "${ARCH}" in
    amd64)  EFI_ARCH="x64" ;;
    arm64)  EFI_ARCH="aa64" ;;
    *)      die "UKI addon: Unsupported architecture: ${ARCH}" ;;
esac

# Locate the EFI stub from the image's /usr partition.
EFI_STUB="${BOARD_ROOT}/usr/lib/systemd/boot/efi/linux${EFI_ARCH}.efi.stub"
if [[ ! -f "${EFI_STUB}" ]]; then
    die "UKI addon: EFI stub not found at ${EFI_STUB}. Is systemd-boot installed in the image?"
fi

# Detect the main UKI name from the ESP (UAPI-compliant: vmlinuz-<version>.efi)
uki_files=()
while IFS= read -r f; do uki_files+=("$f"); done < <(find "${ESP_DIR}/EFI/Linux/" -maxdepth 1 -name 'vmlinuz-*.efi' -printf '%f\n' | sort -V)
if [[ ${#uki_files[@]} -eq 0 ]]; then
    die "UKI addon: No UKI file (vmlinuz-*.efi) found in ${ESP_DIR}/EFI/Linux/. Was uki_install.sh run?"
fi
if [[ ${#uki_files[@]} -ne 1 ]]; then
    die "UKI addon: Expected exactly 1 UKI file, found ${#uki_files[@]}: ${uki_files[*]}"
fi
UKI_NAME="${uki_files[0]}"
UKI_PATH="${ESP_DIR}/EFI/Linux/${UKI_NAME}"

# Source the platform's uki.cfg (if it exists)
# Reset all ADDON_* variables so a missing uki.cfg gives clean defaults.
ADDON_OEM_ID=""
ADDON_CONSOLE_AMD64=""
ADDON_CONSOLE_ARM64=""
ADDON_APPEND=""

UKI_CFG_DIR="${OEM_FILES_DIR}/${OEM_USE}"
UKI_CFG="${UKI_CFG_DIR}/uki.cfg"

if [[ -f "${UKI_CFG}" ]]; then
    info "UKI addon: Sourcing ${UKI_CFG}"
    # shellcheck disable=SC1090
    source "${UKI_CFG}"
else
    info "UKI addon: No uki.cfg for '${OEM_USE}'; using defaults"
fi

# Construct the addon command line
# OEM ID: use ADDON_OEM_ID if set, otherwise the USE flag itself.
oem_id="${ADDON_OEM_ID:-${OEM_USE}}"

addon_cmdline="flatcar.oem.id=${oem_id}"

# Console args: pick the architecture-appropriate set.
case "${ARCH}" in
    amd64)  console_args="${ADDON_CONSOLE_AMD64}" ;;
    arm64)  console_args="${ADDON_CONSOLE_ARM64}" ;;
esac
if [[ -n "${console_args}" ]]; then
    addon_cmdline+=" ${console_args}"
fi

# Append extra args (linux_append equivalent).
if [[ -n "${ADDON_APPEND}" ]]; then
    addon_cmdline+=" ${ADDON_APPEND}"
fi

info "UKI addon: oem_id=${oem_id}  arch=${ARCH}"
info "UKI addon: cmdline = ${addon_cmdline}"

# Build the addon with ukify
if ! command -v ukify &>/dev/null; then
    die "UKI addon: ukify not found on PATH"
fi

addon_temp_dir=$(mktemp -d)
trap 'rm -rf "${addon_temp_dir}"' EXIT

addon_cmdline_file="${addon_temp_dir}/addon-cmdline.txt"
echo "${addon_cmdline}" > "${addon_cmdline_file}"

addon_output="${addon_temp_dir}/oem.addon.efi"

info "UKI addon: Building addon with ukify"
sudo ukify build \
    --cmdline=@"${addon_cmdline_file}" \
    --stub="${EFI_STUB}" \
    --output="${addon_output}"

if [[ ! -f "${addon_output}" ]]; then
    die "UKI addon: ukify failed to produce ${addon_output}"
fi

info "UKI addon: Built successfully ($(du -h "${addon_output}" | cut -f1))"

# Install the addon to the ESP
ADDON_DIR="${ESP_DIR}/EFI/Linux/${UKI_NAME}.extra.d"
sudo mkdir -p "${ADDON_DIR}"
sudo cp "${addon_output}" "${ADDON_DIR}/oem.addon.efi"

info "UKI addon: Installed → EFI/Linux/${UKI_NAME}.extra.d/oem.addon.efi"

# Clean up
rm -rf "${addon_temp_dir}"
trap - EXIT
