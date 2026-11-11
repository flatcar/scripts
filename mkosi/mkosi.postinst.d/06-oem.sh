#!/usr/bin/env bash
# OEM partition contents for an oem-<flavor> profile, via image_to_vm's
# install_oem_sysext: the sysext, its active marker, oem-release and grub.cfg.
. "${SRCDIR}/lib/postinst.sh"

[[ -n "${FLATCAR_VM_TYPE:-}" ]] || exit 0

# install_oem_sysext reads oem-release with systemd-dissect, which needs loop
# devices and sysfs to verify them; mkosi gives scripts a private /dev without
# loop devices and no /sys. The mounts only live in this script's sandbox.
mount -t devtmpfs devtmpfs /dev
mkdir -p /sys
mount -t sysfs sysfs /sys

set_vm_type "${FLATCAR_VM_TYPE}" || die "Unknown FLATCAR_VM_TYPE=${FLATCAR_VM_TYPE}"
FLAGS_from="${SRCDIR}/mkosi.output"
VM_TMP_ROOT="${root_fs_dir}"
install_oem_sysext
