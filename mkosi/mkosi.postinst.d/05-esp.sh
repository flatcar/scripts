#!/usr/bin/env bash
# Stage the ESP (grub) in /efi; mkosi.repart/00-esp.conf copies it onto
# EFI-SYSTEM.
. "${SRCDIR}/lib/postinst.sh"

# grub_install.sh only generates the memdisk grub.cfg when the ESP has none, so
# seed it from upstream's file. The @@MOUNTUSR@@ sed repeats grub_install.sh's own.
esp="${root_fs_dir}/efi"
install -d "${esp}/flatcar/grub"
grub_tmp="$(mktemp -d)"
sed -e 's/@@MOUNTUSR@@/mount.usr=\/dev\/mapper\/usr verity.usr/' \
    "${BUILD_LIBRARY_DIR}/grub.cfg" > "${grub_tmp}/grub.cfg"
tar cf "${esp}/flatcar/grub/grub.cfg.tar" -C "${grub_tmp}" grub.cfg
rm -rf "${grub_tmp}"

# grub.cfg builds the command line at boot (USR slot, first boot, console, OEM).
if [[ "$(jq '.KernelCommandLine // [] | length' "${MKOSI_CONFIG}")" != 0 ]]; then
    echo "WARNING: KernelCommandLine= is ignored: Flatcar's grub.cfg builds the kernel command line at boot; add kernel arguments to the grub.cfg seeding in mkosi.postinst.d/05-esp.sh" >&2
fi

# build_image_util.sh finish_image():823-846, EFI target only: i386-pc and
# x86_64-xen need a loop-mounted disk, which does not exist yet.
case "${BOARD}" in
  amd64-usr) grub_target=x86_64-efi ;;
  arm64-usr) grub_target=arm64-efi ;;
esac
"${BUILD_LIBRARY_DIR}/grub_install.sh" \
    --board="${BOARD}" \
    --target="${grub_target}" \
    --verity \
    --skip_emerge \
    --esp_dir="${esp}" \
    --esp_part_label=EFI-SYSTEM

