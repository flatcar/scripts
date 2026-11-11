#!/usr/bin/env bash
# Users and groups go into /usr/share/baselayout, not /etc.
. "${SRCDIR}/lib/postinst.sh"

found=""
# check if there are any dynamically allocated user IDs
# we want to forbid "-", "X:-" (.*:-), "-:X" (-:.*), "/X" (/.*)
found=$({ grep '^[ug]' "${root_fs_dir}"/usr/lib/sysusers.d/*.conf || true ; } | awk '{print $3}' | { grep -x -- "-\|.*:-\|-:.*\|/.*" || true ; })
if [ "${found}" != "" ]; then
  die "Found dynamic ID allocation instead of hardcoded ID in /usr/lib/sysusers.d/*.conf (third column must not use '-', 'X:-', '-:X', or '/path')"
fi
# Create users and groups from /etc/ via systemd-sysusers, then fold new
# entries into /usr/share/baselayout so they live in /usr
systemd-sysusers --root="${root_fs_dir}"
for databasefile in passwd group shadow gshadow; do
  newentries=$(comm -23 <(cut -d ":" -f 1 "${root_fs_dir}/etc/${databasefile}" | sort) <(cut -d ":" -f 1 "${root_fs_dir}/usr/share/baselayout/${databasefile}" | sort))
  for newentry in ${newentries}; do
    grep "^${newentry}:" "${root_fs_dir}/etc/${databasefile}" | tee -a "${root_fs_dir}/usr/share/baselayout/${databasefile}"
  done
  rm -f "${root_fs_dir}/etc/${databasefile}" "${root_fs_dir}/etc/${databasefile}-"
done
