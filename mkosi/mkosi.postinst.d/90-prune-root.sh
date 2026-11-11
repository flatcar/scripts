#!/usr/bin/env bash
# Leave only the mount points and staging trees the partitions are built from.
. "${SRCDIR}/lib/postinst.sh"

# Ship an empty /var; tmpfiles recreate it at first boot.
find "${root_fs_dir}/var" -mindepth 1 \( -type f -o -type l \) -delete

for folder in "${root_fs_dir}/"*; do
  case "${folder#${root_fs_dir}}" in
    # /efi: 05-esp.sh staged the ESP there.
    /boot|/usr|/oem|/var|/dev|/proc|/efi)
      :
      ;;
    *)
      rm --one-file-system -rf "${folder}" || echo FAILED
      ;;
  esac
done
