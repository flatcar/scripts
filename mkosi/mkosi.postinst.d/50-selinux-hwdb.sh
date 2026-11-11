#!/usr/bin/env bash
# SELinux policy and the hwdb, before /etc is populated and frozen.
. "${SRCDIR}/lib/postinst.sh"

# Build the selinux policy
if pkg_use_enabled coreos-base/coreos selinux; then
  mkosi-chroot bash -c "cd /usr/share/selinux/mcs && semodule -s mcs -i *.pp"
fi

# Undo mkosi's run_hwdb(), which moves hwdb.bin out of /etc where the systemd
# ebuild puts it.
mkosi-chroot systemd-hwdb update
rm -f "${root_fs_dir}/usr/lib/udev/hwdb.bin"
