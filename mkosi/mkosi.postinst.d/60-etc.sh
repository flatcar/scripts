#!/usr/bin/env bash
# finish_image()'s /etc: populate it via tmpfiles, then label it.
. "${SRCDIR}/lib/postinst.sh"

# Populate /etc via tmpfiles; it needs the baselayout users in /etc/passwd.
for dbfile in passwd shadow group gshadow; do
  cp -f "${root_fs_dir}"/usr/share/baselayout/"${dbfile}" "${root_fs_dir}"/etc/
done

# The image's systemd-tmpfiles: the SDK's is too old for its modifiers.
mkosi-chroot /usr/bin/systemd-tmpfiles \
  --create --remove --boot --exclude-prefix=/dev
for dbfile in passwd shadow group gshadow; do
  rm -f "${root_fs_dir}"/etc/"${dbfile}"
done
"${root_fs_dir}"/usr/sbin/flatcar-tmpfiles "${root_fs_dir}"
# Drop the /etc rules, which would cause overlay upcopies, but record their
# paths in etc-no-whiteouts so no whiteout hides them.
grep -Ph '^[fcCdDLvqQpb][-=~^!+]*[ \t]*/etc' "${root_fs_dir}"/usr/lib/tmpfiles.d/* | grep -oP '/etc[^ \t]*' > "${root_fs_dir}"/usr/share/flatcar/etc-no-whiteouts
sed -i '/^[CdDL][-=~^!]*[ \t]*\/etc\//d' "${root_fs_dir}"/usr/lib/tmpfiles.d/*

# SELinux: Label the root filesystem for using 'file_contexts'.
# The labeling has to be done before moving /etc to /usr/share/flatcar/etc to prevent wrong labels for these files and as
# the relabeling on boot would cause upcopies in the overlay.
if pkg_use_enabled coreos-base/coreos selinux; then
  # setfiles from version 3.11 requires the passed path to have no symlinks
  real_root_fs_dir=$(realpath "${root_fs_dir}")
  # Upstream only labels /etc: labeling / or /usr "breaks the system".
  setfiles -Dv -r "${real_root_fs_dir}" "${real_root_fs_dir}"/etc/selinux/mcs/contexts/files/file_contexts "${real_root_fs_dir}"/etc
fi

# Set /etc/{g,}shadow group to the shadow group so unix_chkpwd/chage/expiry work.
# Belongs in an ebuild, but baselayout installs these and we don't want more deps.
chgrp \
    --reference="${root_fs_dir}/usr/bin/chage" \
    "${root_fs_dir}"/{etc,usr/share/baselayout}/{g,}shadow
