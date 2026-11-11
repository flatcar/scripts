#!/bin/bash
# The final image's steps, run in order by mkosi.postinst. They wrap the steps
# of build_image_util.sh finish_image() and prod_image_util.sh create_prod_image()
# where mkosi needs more or different work.
. "${SRCDIR}/lib/emerge.sh"

root_fs_dir="${BUILDROOT}"

# Names must match the sub-images' Output=.
builtin_sysext_names() {
  tr ',' '\n' <<<"${DEFAULT_BASE_SYSEXTS}" | cut -d'|' -f1
}

# Bake the built-in sysexts into /usr/share/flatcar/sysext with an
# /etc/extensions symlink each, as sysext_prod_builder does.
image_bake_sysexts() {
  local sysext_dir ext_dir name src
  sysext_dir="${root_fs_dir}/usr/share/flatcar/sysext"
  ext_dir="${root_fs_dir}/etc/extensions"
  install -d -m 0755 "${sysext_dir}" "${ext_dir}"

  for name in "$@"; do
      src="${SRCDIR}/mkosi.output/${name}.raw"
      [[ -f "${src}" ]] || die "[builtin-sysext] ${src} not found; was the ${name}-sysext sub-image built?"

      install -m 0644 "${src}" "${sysext_dir}/${name}.raw"
      ln -sf "/usr/share/flatcar/sysext/${name}.raw" "${ext_dir}/${name}.raw"
      echo "[builtin-sysext] baked ${name}.raw into /usr + /etc/extensions symlink"
  done
}

# Stage the ESP (grub) in /efi; mkosi.repart/00-esp.conf copies it onto
# EFI-SYSTEM.
image_esp() {
  local esp grub_target
  esp="${root_fs_dir}/efi"

  # grub.cfg builds the command line at boot (USR slot, first boot, console, OEM).
  if [[ "$(jq '.KernelCommandLine // [] | length' "${MKOSI_CONFIG}")" != 0 ]]; then
      echo "WARNING: KernelCommandLine= is ignored: Flatcar's grub.cfg builds the kernel command line at boot; add kernel arguments to build_library/grub.cfg" >&2
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
}

# licenses.json and the extra SLSA files, from upstream's write_licenses over
# the image's pkgdb plus the named built-in sysexts', as create_prod_image does.
# A subshell: the EXIT trap and set +u must not leak into the caller.
write_image_licenses() (
    set +u
    setup_configroot
    # Base's extract_prod_gcc did this in its own configroot.
    package_provided "$(get_binary_pkg sys-devel/gcc)"

    local outdir="${SRCDIR}/mkosi.output" work merged json name d pkgs
    work="$(mktemp -d)"
    trap 'rm -rf "${work}"' EXIT

    # Union pkgdb: the image's own, plus each built-in sysext's saved one.
    merged="${work}/merged"
    mkdir -p "${merged}/var/db"
    cp -a "${root_fs_dir}/var/db/pkg" "${merged}/var/db/pkg"

    for name in "$@"; do
        d="${outdir}/${name}-sysext-pkgdb"
        [[ -d "${d}/var/db/pkg" ]] || die "[licenses] ${d} missing; was the ${name}-sysext sub-image built?"
        cp -a "${d}/var/db/pkg"/. "${merged}/var/db/pkg/"
        echo "[licenses] merged ${name}"
    done

    json="${work}/licenses.json"
    write_licenses "${merged}" "${json}"
    insert_licenses "${json}" "${root_fs_dir}"
    # SLSA for packages only in the initrd/ESP.
    insert_extra_slsa "${root_fs_dir}"

    pkgs=$(grep -c '"project"' "${json}" 2>/dev/null || true)
    echo "[licenses] wrote licenses.json.bz2 (${pkgs:-0} packages)"
)

# create_prod_image()'s clean-ups after the sysext snapshot.
image_prod_cleanups() {
  prod_image_cleanups "${root_fs_dir}"
  # TODO use FEATURES=splitdebug + INSTALL_MASK instead (as upstream Flatcar)
  rm -rf "${root_fs_dir}/usr/lib/debug"
  rm -rf "${root_fs_dir}/usr/lib64/cmake" "${root_fs_dir}/usr/lib64/pkgconfig"
}

image_kernel() {
  local btf_tmp
  finish_image_kernel "${root_fs_dir}"

  # coreos-kernel and coreos-modules build separate vmlinuxes; if their BTF
  # diverges, the kernel refuses every module (BTF: -40) and boot fails.
  btf_tmp="$(mktemp -d)"
  "/build/${BOARD}/usr/src/linux/scripts/extract-vmlinux" \
      "${root_fs_dir}/boot/flatcar/vmlinuz-a" > "${btf_tmp}/vmlinux"
  xz -dc "${root_fs_dir}"/usr/lib/modules/*/kernel/lib/zstd/zstd_compress.ko.xz > "${btf_tmp}/m.ko"
  if ! pahole --btf_base "${btf_tmp}/vmlinux" -F btf "${btf_tmp}/m.ko" >/dev/null; then
    die "Module BTF does not match vmlinuz-a: rebuild coreos-modules and coreos-kernel together"
  fi
  rm -rf "${btf_tmp}"
}

# Unlike finish_image(), unconditionally: /boot is a plain directory here, not
# a mounted partition.
image_var_tmpfiles() {
  finish_image_var_tmpfiles "${root_fs_dir}"
  finish_image_first_boot "${root_fs_dir}"
}

# SELinux policy and the hwdb, before /etc is populated and frozen.
image_selinux_hwdb() {
  # Build the selinux policy
  if pkg_use_enabled coreos-base/coreos selinux; then
    mkosi-chroot bash -c "cd /usr/share/selinux/mcs && semodule -s mcs -i *.pp"
  fi

  # Undo mkosi's run_hwdb(), which moves hwdb.bin out of /etc where the systemd
  # ebuild puts it.
  mkosi-chroot systemd-hwdb update
  rm -f "${root_fs_dir}/usr/lib/udev/hwdb.bin"
}

# finish_image()'s /etc: populate it via tmpfiles, then label it.
image_etc() {
  local dbfile real_root_fs_dir
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
  finish_image_etc_no_whiteouts "${root_fs_dir}"

  # SELinux: Label the root filesystem for using 'file_contexts'.
  # The labeling has to be done before moving /etc to /usr/share/flatcar/etc to prevent wrong labels for these files and as
  # the relabeling on boot would cause upcopies in the overlay.
  if pkg_use_enabled coreos-base/coreos selinux; then
    # setfiles from version 3.11 requires the passed path to have no symlinks
    real_root_fs_dir=$(realpath "${root_fs_dir}")
    # Upstream only labels /etc: labeling / or /usr "breaks the system".
    setfiles -Dv -r "${real_root_fs_dir}" "${real_root_fs_dir}"/etc/selinux/mcs/contexts/files/file_contexts "${real_root_fs_dir}"/etc
  fi

  finish_image_shadow_group "${root_fs_dir}"
}

# Freeze /etc into /usr/share/flatcar/etc and the signed default confext, with
# mkosi's verity key: mkosi installs its cert into /usr/lib/verity.d.
image_confext() {
  local verity_key verity_cert
  verity_key="$(jq -r '.VerityKey // empty' "${MKOSI_CONFIG}")"
  verity_cert="$(jq -r '.VerityCertificate // empty' "${MKOSI_CONFIG}")"
  [[ -n "${verity_key}" && -n "${verity_cert}" ]] || die "VerityKey= and VerityCertificate= must be set to sign the default confext"
  [[ "$(jq -r '.VerityKeySource.Type' "${MKOSI_CONFIG}")" == file ]] || die "VerityKeySource= must be a file to sign the default confext"

  finish_image_freeze_etc "${root_fs_dir}"
  # finish_image_confext stages in BUILD_DIR.
  mkdir -p "${BUILD_DIR}"
  finish_image_confext "${root_fs_dir}" "${verity_key}" "${verity_cert}"
}

# Leave only the mount points and staging trees the partitions are built from.
image_prune_root() {
  local folder
  # Ship an empty /var; tmpfiles recreate it at first boot.
  find "${root_fs_dir}/var" -mindepth 1 \( -type f -o -type l \) -delete

  for folder in "${root_fs_dir}/"*; do
    case "${folder#${root_fs_dir}}" in
      # /efi: image_esp staged the ESP there.
      /boot|/usr|/oem|/var|/dev|/proc|/efi)
        :
        ;;
      *)
        rm --one-file-system -rf "${folder}" || echo FAILED
        ;;
    esac
  done
}
