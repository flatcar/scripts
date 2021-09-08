#!/bin/bash
set -ex

SCRIPTFOLDER="$(dirname "$(readlink -f "$0")")"
if [[ "$NATIVE_ARM64" == true ]]; then
  "${SCRIPTFOLDER}/qemu_uefi_arm64.sh" qemu_uefi
else
  "${SCRIPTFOLDER}/qemu_common.sh" qemu_uefi
fi
