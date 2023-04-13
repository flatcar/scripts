# Copyright (c) 2012 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

get_binhost_url() {
	local binhost_base=$1
	local image_group=$2
	local image_path=$3
	if [ "${image_group}" == "developer" ]; then
		echo "${binhost_base}/${image_group}/boards/${BOARD}/${FLATCAR_VERSION}/${image_path}"
	else
		echo "${binhost_base}/boards/${BOARD}/${FLATCAR_VERSION_ID}/${image_path}"
	fi
}

configure_dev_portage() {
    # Need profiles at the bare minimum
    local repo
    for repo in portage-stable coreos-overlay; do
        sudo mkdir -p "$1/var/lib/portage/${repo}"
        sudo rsync -rtl --exclude=md5-cache \
            "${SRC_ROOT}/third_party/${repo}/metadata" \
            "${SRC_ROOT}/third_party/${repo}/profiles" \
            "$1/var/lib/portage/${repo}"
    done

    sudo mkdir -p "$1/etc/portage/repos.conf"
    sudo_clobber "$1/etc/portage/make.conf" <<EOF
# make.conf for Flatcar dev images
ARCH=$(get_board_arch $BOARD)
CHOST=$(get_board_chost $BOARD)

# Use /var/lib/portage instead of /usr/portage
DISTDIR="/var/lib/portage/distfiles"
PKGDIR="/var/lib/portage/pkgs"
PORT_LOGDIR="/var/log/portage"
PORTDIR="/var/lib/portage/portage-stable"
PORTDIR_OVERLAY="/var/lib/portage/coreos-overlay"
PORTAGE_BINHOST="$(get_binhost_url "$2" "$3" 'pkgs')
$(get_binhost_url "$2" "$3" 'toolchain')"
EOF

sudo_clobber "$1/etc/portage/repos.conf/coreos.conf" <<EOF
[DEFAULT]
main-repo = portage-stable

[gentoo]
disabled = true

[coreos]
location = /var/lib/portage/coreos-overlay

[portage-stable]
location = /var/lib/portage/portage-stable
EOF

    # Now set the correct profile
    sudo PORTAGE_CONFIGROOT="$1" ROOT="$1" \
        PORTDIR="$1/var/lib/portage/portage-stable" \
        PORTDIR_OVERLAY="$1/var/lib/portage/coreos-overlay" \
        eselect profile set --force $(get_board_profile $BOARD)/dev
}

create_dev_container() {
  local image_name=$1
  local disk_layout=$2
  local binhost=$3
  local update_group=$4
  local base_pkg="$5"

  if [ -z "${base_pkg}" ]; then
    echo "did not get base package!"
    exit 1
  fi

  info "Building developer image ${image_name}"
  local root_fs_dir="${BUILD_DIR}/rootfs"
  local image_contents="${image_name%.bin}_contents.txt"
  local image_contents_wtd="${image_name%.bin}_contents_wtd.txt"
  local image_packages="${image_name%.bin}_packages.txt"
  local image_licenses="${image_name%.bin}_licenses.json"

  start_image "${image_name}" "${disk_layout}" "${root_fs_dir}" "${update_group}"

  set_image_profile dev
  emerge_to_image "${root_fs_dir}" @system ${base_pkg}
  run_ldconfig "${root_fs_dir}"
  run_localedef "${root_fs_dir}"
  write_packages "${root_fs_dir}" "${BUILD_DIR}/${image_packages}"
  write_licenses "${root_fs_dir}" "${BUILD_DIR}/${image_licenses}"
  insert_licenses "${BUILD_DIR}/${image_licenses}" "${root_fs_dir}"

  # Setup portage for emerge and gmerge
  configure_dev_portage "${root_fs_dir}" "${binhost}" "${update_group}"

  # Mark the image as a developer image (input to chromeos_startup).
  # TODO(arkaitzr): Remove this file when applications no longer rely on it
  # (crosbug.com/16648). The preferred way of determining developer mode status
  # is via crossystem cros_debug?1 (checks boot args for "cros_debug").
  sudo mkdir -p "${root_fs_dir}/root"
  sudo touch "${root_fs_dir}/root/.dev_mode"

  # Remount the system partition read-write by default.
  # The remount services are provided by coreos-base/coreos-init
  systemd_enable "${root_fs_dir}" "multi-user.target" "remount-usr.service"

  finish_image "${image_name}" "${disk_layout}" "${root_fs_dir}" "${image_contents}" "${image_contents_wtd}"

  declare -a files_to_evaluate
  declare -a compressed_images
  declare -a extra_files

  files_to_evaluate+=( "${BUILD_DIR}/${image_name}" )
  compress_disk_images files_to_evaluate compressed_images extra_files

  upload_image -d "${BUILD_DIR}/${image_name}.DIGESTS" \
      "${BUILD_DIR}/${image_contents}" \
      "${BUILD_DIR}/${image_contents_wtd}" \
      "${BUILD_DIR}/${image_packages}" \
      "${BUILD_DIR}/${image_licenses}" \
      "${compressed_images[@]}" \
      "${extra_files[@]}"

  # Upload legacy digests
  upload_legacy_digests "${BUILD_DIR}/${image_name}.DIGESTS" compressed_images
}
