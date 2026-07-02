#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Validate Azure Container Linux (ACL) Image — VM lifecycle & test execution
#
# This script handles VM creation, script execution, and validation of ACL images.
# It can be invoked standalone or called from build_rpm_image.sh.
#
# The implementation is split across three modules:
#   validate_common.sh  — shared globals, logging, SSH, arg parsing, main entry point
#   validate_qemu.sh    — QEMU/libvirt VM lifecycle (ignition, virsh, expect console)
#   validate_azure.sh   — Azure VM lifecycle (az CLI, gallery, VHD upload)
#
# Usage:
#   ./validate_rpm_image.sh [options]
#
# Options:
#   --acg-gallery-name=NAME              Azure Compute Gallery name to override default
#   --acg-image-version-id=ID            Azure Compute Gallery image version resource ID
#   --az-storage-account=NAME            Azure storage account name to override default
#   --az-sub-id=ID                       Azure subscription ID to override default
#   --az-region=REGION                   Azure region to override default
#   --az-vm-size=SIZE                    Azure VM size (default: Standard_D2s_v5)
#   --board=BOARD                        Target board (default: amd64-usr)
#   --boot-timeout=SECS                  Timeout waiting for VM boot (default: arch-based — amd64 100s, arm64 300s)
#   --build-vm-image                     Build VM images before starting
#   --console-password=PASS              Serial console login password (empty for passwordless)
#   --console-user=USER                  Serial console login user (default: root)
#   --help                               Show this help message
#   --img-name=NAME                      Base image name prefix (default: acl_production)
#   --keep-vm                            Keep VM running after scripts complete
#   --no-cleanup                         Skip cleanup of existing VM resource groups
#   --reuse-vm                           Reuse an already-running VM
#   --run-kola-tests                     Run kola tests (qemu or azure, based on --vm-type)
#   --run-script=PATH                    Run script on VM after boot (can specify multiple)
#   --ssh-authorized-keys=KEYS           SSH public keys for VM access
#   --ssh-key=PATH                       SSH private key for VM access
#   --ssh-timeout=SECS                   Timeout waiting for SSH (default: 120)
#   --ssh-user=USER                      SSH user for VM scripts (default: core)
#   --start-vm                           Start the VM (implied by --run-script)
#   --tag=KEY=VALUE                      Add a resource tag to Azure VMs/RGs
#   --use-serial                         Use serial console for script execution
#   --use-ssh                            Use SSH for script execution
#   --use-test-image                     Boot the test VM image (with docker sysext) instead of the regular image
#   --vm-name=NAME                       Name for the VM (default: acl)
#   --vm-type=TYPE                       VM type: azure|qemu (default: qemu)
#   --vm-image-path=PATH                 Path to VM image (auto-detected if not set)
#
# Examples:
#   # Start a QEMU VM and run test scripts
#   ./validate_rpm_image.sh --start-vm --run-script=./acl/tests/run-container-test.sh
#
#   # Run all default tests
#   ./validate_rpm_image.sh --start-vm \
#       --run-script=./acl/tests/run-container-test.sh \
#       --run-script=./acl/tests/run-systemd-health-test.sh \
#       --run-script=./acl/tests/run-dmesg-io-error-test.sh \
#       --run-script=./acl/tests/run-selinux-avc-test.sh
#
#   # Reuse a running VM
#   ./validate_rpm_image.sh --reuse-vm --run-script="cat /etc/os-release"
#
#   # Run kola tests
#   ./validate_rpm_image.sh --run-kola-tests
#
# Environment Variables:
#   ACL_SDK_IMAGE           Override SDK container image
#   NO_TTY                  Set to "true" to disable TTY allocation (for CI)
#   VM_BOOT_TIMEOUT         Boot timeout in seconds (default: arch-based — amd64 100s, arm64 300s)
#   VM_SSH_USER             SSH user for VM (default: core)
#   VM_SSH_KEY              SSH private key path
#   VM_SSH_TIMEOUT          SSH connection timeout in seconds (default: 120)
#

set -euo pipefail

# Resolve this script's directory so modules can be sourced by relative path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../.."
_VALIDATE_MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source shared module (globals, logging, SSH, arg parsing).
# Platform modules (validate_qemu.sh / validate_azure.sh) are sourced inside
# validate_main after arg parsing determines VM_TYPE.
# shellcheck source=acl/validate/validate_common.sh
source "${_VALIDATE_MODULE_DIR}/validate_common.sh"

# Run main if executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    validate_main "$@"
fi
