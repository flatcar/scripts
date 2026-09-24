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
    local root_fs_dir="${1}"; shift
    local binhost="${1}"; shift
    local update_group="${1}"; shift
    local repos="/home/core/scripts/sdk_container/src/third_party"

    sudo mkdir -p "${root_fs_dir}/etc/portage/repos.conf"
    sudo_clobber "${root_fs_dir}/etc/portage/make.conf" <<EOF
# make.conf for Flatcar dev images
ARCH=$(get_board_arch $BOARD)
CHOST=$(get_board_chost $BOARD)
PORTAGE_BINHOST="$(get_binhost_url "${binhost}" "${update_group}" 'pkgs')"
EOF

    sudo_clobber "${root_fs_dir}/etc/portage/repos.conf/gentoo.conf" <<EOF
[DEFAULT]
main-repo = gentoo

[gentoo]
location = ${repos}/gentoo
EOF

    sudo_clobber "${root_fs_dir}/etc/portage/repos.conf/coreos-overlay.conf" <<EOF
[coreos-overlay]
location = ${repos}/coreos-overlay
package-priority = 1
EOF

    # Now set the correct profile. We do not use the eselect tool because the
    # Portage configuration is broken until emerge-gitclone is run.
    local profile_name=$(get_board_profile "${BOARD}")
    # Turn coreos-overlay:coreos/amd64/generic into coreos/amd64/generic/dev
    local profile_directory="${root_fs_dir}${repos}/coreos-overlay/profiles/${profile_name#*:}/dev"
    local profile_link="${root_fs_dir}/etc/portage/make.profile"
    sudo ln -sfrT "${profile_directory}" "${profile_link}"
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
  # The "dev-image-rootfs" directory name is important - it is used to
  # determine the package target in coreos/base/profile.bashrc
  local root_fs_dir="${BUILD_DIR}/dev-image-rootfs"
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
  files_to_evaluate+=( "${BUILD_DIR}/${image_name}" )
  compress_disk_images files_to_evaluate
}
