# Copyright (c) 2010 The Chromium OS Authors. All rights reserved.
# Copyright (c) 2013 The CoreOS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Lookup the current version of a binary package, downloading it if needed.
# Usage: get_binary_pkg some-pkg/name
# Prints: some-pkg/name-1.2.3
get_binary_pkg() {
    local name="$1" version

    # If possible use the version installed in $BOARD_ROOT,
    # fall back to any binary package that is available.
    version=$(pkg_version installed "${name}")
    if [[ -z "${version}" ]]; then
        version=$(pkg_version binary "${name}")
    fi

    # Nothing? Maybe we can fetch it.
    if [[ -z "${version}" && ${FLAGS_getbinpkg} -eq ${FLAGS_TRUE} ]]; then
        emerge-${BOARD} --verbose --getbinpkg --usepkgonly --fetchonly --nodeps "${name}" >&2
        version=$(pkg_version binary "${name}")
    fi

    # Cry
    if [[ -z "${version}" ]]; then
        die "Binary package missing for ${name}"
    fi

    echo "${version}"
}

# The GCC package includes both its libraries and the compiler.
# In prod images we only need the shared libraries.
extract_prod_gcc() {
    local root_fs_dir="$1" gcc pkg
    gcc=$(get_binary_pkg sys-devel/gcc)

    # FIXME(marineam): Incompatible with FEATURES=binpkg-multi-instance
    pkg="$(portageq-${BOARD} pkgdir)/${gcc}.tbz2"
    [[ -f "${pkg}" ]] || die "${pkg} is missing"

    # Normally GCC's shared libraries are installed to:
    #  /usr/lib/gcc/x86_64-cros-linux-gnu/$version/*
    # Instead we extract them to plain old /usr/lib
    qtbz2 -O -t "${pkg}" | \
        lbzcat -d -c - | \
        sudo tar -C "${root_fs_dir}" -x \
        --transform 's#/usr/lib/.*/#/usr/lib64/#' \
        --wildcards './usr/lib/gcc/*.so*' \
        --wildcards './usr/share/SLSA'

    package_provided "${gcc}"
}

create_prod_image() {
  local image_name="$1"
  local disk_layout="$2"
  local update_group="$3"
  local base_pkg="$4"
  if [ -z "${base_pkg}" ]; then
    echo "did not get base package!"
    exit 1
  fi

  local base_sysexts="$5"

  info "Building production image ${image_name}"
  # The "prod-image-rootfs" directory name is important - it is used
  # to determine the package target in coreos/base/profile.bashrc
  local root_fs_dir="${BUILD_DIR}/prod-image-rootfs"
  local root_fs_sysexts_output_dir="${BUILD_DIR}/rootfs-included-sysexts"
  local image_contents="${image_name%.bin}_contents.txt"
  local image_contents_wtd="${image_name%.bin}_contents_wtd.txt"
  local image_packages="${image_name%.bin}_packages.txt"
  local image_sbom="${image_name%.bin}_sbom.json"
  local image_licenses="${image_name%.bin}_licenses.json"
  local image_kconfig="${image_name%.bin}_kernel_config.txt"
  local image_kernel="${image_name%.bin}.vmlinuz"
  local image_pcr_policy="${image_name%.bin}_pcr_policy.zip"
  local image_grub="${image_name%.bin}.grub"
  local image_shim="${image_name%.bin}.shim"
  local image_initrd_contents="${image_name%.bin}_initrd_contents.txt"
  local image_initrd_contents_wtd="${image_name%.bin}_initrd_contents_wtd.txt"
  local image_disk_usage="${image_name%.bin}_disk_usage.txt"
  local image_sysext_base="${image_name%.bin}_sysext.squashfs"

  start_image "${image_name}" "${disk_layout}" "${root_fs_dir}" "${update_group}"

  # Install minimal GCC (libs only) and then everything else
  set_image_profile prod
  extract_prod_gcc "${root_fs_dir}"
  emerge_to_image "${root_fs_dir}" "${base_pkg}"
  run_ldconfig "${root_fs_dir}"
  run_localedef "${root_fs_dir}"

  local root_with_everything="${root_fs_dir}"

  # Call helper script for adding sysexts to the base OS.
  # Helper will generate a rootfs dir with all packages (base OS and sysexts) included.
  local root_sysext_mergedir="${BUILD_DIR}/rootfs-with-sysext-pkgs"
  if [[ -n "${base_sysexts}" ]] ; then
    "${BUILD_LIBRARY_DIR}/sysext_prod_builder" \
        "${BOARD}" "${BUILD_DIR}" "${root_fs_dir}" \
        "${root_sysext_mergedir}" \
        "${root_fs_sysexts_output_dir}" \
        "${base_sysexts}"
    root_with_everything="${root_sysext_mergedir}"
  fi


  write_sbom "${root_with_everything}" "${BUILD_DIR}/${image_sbom}"
  write_licenses "${root_with_everything}" "${BUILD_DIR}/${image_licenses}"

  if [[ -n "${base_sysexts}" ]] ; then
    sudo rm -rf "${root_sysext_mergedir}"
  fi

  write_packages "${root_fs_dir}" "${BUILD_DIR}/${image_packages}"

  insert_licenses "${BUILD_DIR}/${image_licenses}" "${root_fs_dir}"
  insert_extra_slsa "${root_fs_dir}"

  # Assert that if this is supposed to be an official build that the
  # official update keys have been used.
  if [[ ${COREOS_OFFICIAL:-0} -eq 1 && "${BOARD}" != arm64-usr ]]; then
      grep -q official \
          "${root_fs_dir}"/var/db/pkg/coreos-base/coreos-au-key-*/USE \
          || die_notrace "coreos-au-key is missing the 'official' use flag"
  fi

  sudo cp -a "${root_fs_dir}" "${BUILD_DIR}/root_fs_dir2"
  sudo rsync -a --delete  "${BUILD_DIR}/configroot/etc/portage" "${BUILD_DIR}/root_fs_dir2/etc"
  sudo mksquashfs "${BUILD_DIR}/root_fs_dir2"  "${BUILD_DIR}/${image_sysext_base}" -noappend -xattrs-exclude '^btrfs.'
  sudo rm -rf "${BUILD_DIR}/root_fs_dir2"

  # clean-ups of things we do not need
  sudo rm ${root_fs_dir}/etc/csh.env
  sudo rm -rf ${root_fs_dir}/etc/env.d
  sudo rm -rf ${root_fs_dir}/usr/include
  sudo rm -rf ${root_fs_dir}/var/cache/edb
  sudo rm -rf ${root_fs_dir}/var/db/pkg

  sudo mv ${root_fs_dir}/etc/profile.env \
      ${root_fs_dir}/usr/share/baselayout/profile.env

  # Move the ld.so configs into /usr so they can be symlinked from /
  sudo mv ${root_fs_dir}/etc/ld.so.conf ${root_fs_dir}/usr/lib
  sudo mv ${root_fs_dir}/etc/ld.so.conf.d ${root_fs_dir}/usr/lib

  sudo ln --symbolic ../usr/lib/ld.so.conf ${root_fs_dir}/etc/ld.so.conf

  # Add a tmpfiles rule that symlink ld.so.conf from /usr into /
  sudo tee "${root_fs_dir}/usr/lib/tmpfiles.d/baselayout-ldso.conf" \
      > /dev/null <<EOF
L+  /etc/ld.so.conf     -   -   -   -   ../usr/lib/ld.so.conf
EOF

  # Move the PAM configuration into /usr
  sudo mkdir -p ${root_fs_dir}/usr/lib/pam.d
  sudo mv -n ${root_fs_dir}/etc/pam.d/* ${root_fs_dir}/usr/lib/pam.d/
  sudo rmdir ${root_fs_dir}/etc/pam.d

  # Remove source locale data, only need to ship the compiled archive.
  sudo rm -rf ${root_fs_dir}/usr/share/i18n/

  # Finish image will move files from /etc to /usr/share/flatcar/etc.
  # Note that image filesystem contents generated by finish_image will not
  # include sysext contents (only the sysext squashfs files themselves).
  finish_image \
      "${image_name}" \
      "${disk_layout}" \
      "${root_fs_dir}" \
      "${image_contents}" \
      "${image_contents_wtd}" \
      "${image_kernel}" \
      "${image_pcr_policy}" \
      "${image_grub}" \
      "${image_shim}" \
      "${image_kconfig}" \
      "${image_initrd_contents}" \
      "${image_initrd_contents_wtd}" \
      "${image_disk_usage}"

  # Official builds will sign and upload these files later, so remove them to
  # prevent them from being uploaded now.
  if [[ ${COREOS_OFFICIAL:-0} -eq 1 ]]; then
    rm -v \
        "${BUILD_DIR}/${image_kernel}" \
        "${BUILD_DIR}/${image_pcr_policy}" \
        "${BUILD_DIR}/${image_grub}"
  fi

  local files_to_evaluate=( "${BUILD_DIR}/${image_name}" )
  compress_disk_images files_to_evaluate
}

create_prod_tar() {
  local image_name="$1"
  local image="${BUILD_DIR}/${image_name}"
  local container="${BUILD_DIR}/flatcar-container.tar.gz"
  local lodev="$(sudo losetup --find --show -r -P "${image}")"
  local lodevbase="$(basename "${lodev}")"
  sudo mkdir -p "/mnt/${lodevbase}p9"
  sudo mount "${lodev}p9" "/mnt/${lodevbase}p9"
  sudo mount "${lodev}p3" "/mnt/${lodevbase}p9/usr"
  sudo tar --xattrs -czpf "${container}" -C "/mnt/${lodevbase}p9" .
  sudo umount "/mnt/${lodevbase}p9/usr"
  sudo umount "/mnt/${lodevbase}p9"
  sudo rmdir "/mnt/${lodevbase}p9"
  sudo losetup --detach "${lodev}"
}

create_prod_sysexts() {
  local image_name="$1"
  local image_sysext_base="${image_name%.bin}_sysext.squashfs"
  for sysext in "${EXTRA_SYSEXTS[@]}"; do
    local name pkgs useflags arches
    IFS="|" read -r name pkgs useflags arches <<< "$sysext"
    name="flatcar-$name"
    local pkg_array=(${pkgs//,/ })
    local arch_array=(${arches//,/ })
    local useflags_array=(${useflags//,/ })

    local mangle_script="${BUILD_LIBRARY_DIR}/sysext_mangle_${name}"
    if [[ ! -x "${mangle_script}" ]]; then
      mangle_script=
    fi

    if [[ -n "$arches" ]]; then
      should_skip=1
      for arch in "${arch_array[@]}"; do
        if [[ $arch == "$ARCH" ]]; then
          should_skip=0
        fi
      done
      if [[ $should_skip -eq 1 ]]; then
        continue
      fi
    fi

    sudo rm -f "${BUILD_DIR}/${name}.raw" \
	"${BUILD_DIR}/flatcar-test-update-${name}.gz" \
	"${BUILD_DIR}/${name}_*"
    # we use -E to pass the USE flags, but also MODULES_SIGN variables
    #
    # The --install_root_basename="${name}-extra-sysext-rootfs" flag
    # is important - it sets the name of a rootfs directory, which is
    # used to determine the package target in
    # coreos/base/profile.bashrc
    USE="${useflags_array[*]}" sudo -E "${SCRIPT_ROOT}/build_sysext" --board="${BOARD}" \
        --squashfs_base="${BUILD_DIR}/${image_sysext_base}" \
        --image_builddir="${BUILD_DIR}" \
        --install_root_basename="${name}-extra-sysext-rootfs" \
        ${mangle_script:+--manglefs_script=${mangle_script}} \
        "${name}" "${pkg_array[@]}"
    delta_generator \
      -private_key "/usr/share/update_engine/update-payload-key.key.pem" \
      -new_image "${BUILD_DIR}/${name}.raw" \
      -out_file "${BUILD_DIR}/flatcar_test_update-${name}.gz"
  done
}

sbsign_prod_image() {
  local image_name="$1"
  local disk_layout="$2"

  info "Signing production image ${image_name} for Secure Boot"
  local root_fs_dir="${BUILD_DIR}/rootfs"
  local image_prefix="${image_name%.bin}"
  local image_kernel="${image_prefix}.vmlinuz"
  local image_pcr_policy="${image_prefix}_pcr_policy.zip"
  local image_grub="${image_prefix}.grub"

  sbsign_image \
      "${image_name}" \
      "${disk_layout}" \
      "${root_fs_dir}" \
      "${image_kernel}" \
      "${image_pcr_policy}" \
      "${image_grub}"

  local files_to_evaluate=( "${BUILD_DIR}/${image_name}" )
  compress_disk_images files_to_evaluate
}
