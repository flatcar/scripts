#!/bin/bash

# Copyright (c) 2021 The Flatcar Maintainers.
# Based on work (c) 2011 The Chromium OS Authors.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Goo to attempt to resolve dependency loops on individual packages.
#
# Called like:
#
#     break_dep_loop [PKG_USE_PAIR]…
#
# PKG_USE_PAIR consists of two arguments: a package name (for example:
# sys-fs/lvm2), and a comma-separated list of USE flags to clear (for
# example: udev,systemd).
#
# For example - given a build error like:
#
# | * Error: circular dependencies:
# |
# |  (sys-apps/systemd-247.6:0/2::coreos, [...]
# |   (sys-apps/util-linux-2.33-r1:0/0::portage-stable, [...]
# |     (sys-apps/systemd-247.6:0/2::coreos, [...]
# |
# |     It might be possible to break this cycle
# |     by applying any of the following changes:
# |     - sys-apps/util-linux-2.33-r1 (Change USE: -systemd)
# |     - sys-apps/util-linux-2.33-r1 (Change USE: +build)
#
# Use:
#
#    break_dep_loop sys-apps/util-linux systemd
#
# to break the loop.

break_dep_loop() {
  local -a pkgs
  local -a all_flags
  local -a args
  local -a flag_file_entries
  local -a pkg_summaries

  if [ -z "${BOARD_ROOT}" ] ; then
    local BOARD_ROOT="${ROOT}"
  fi
  local flag_file="${BOARD_ROOT}/etc/portage/package.use/break_dep_loop"

  # Be sure to clean up use flag hackery from previous failed runs
  sudo rm -f "${flag_file}"

  if [[ $# -eq 0 ]]; then
      return 0
  fi

  # Temporarily compile/install packages with flags disabled. If a binary
  # package is available use it regardless of its version or use flags.
  local pkg
  local -a flags
  local disabled_flags
  while [[ $# -gt 0 ]]; do
    pkg="${1}"
    pkgs+=("${pkg}")
    flags=( ${2//,/ } )
    all_flags+=( "${flags[@]}" )
    disabled_flags="${flags[@]/#/-}"
    flag_file_entries+=("${pkg} ${disabled_flags}")
    args+=("--buildpkg-exclude=${pkg}")
    pkg_summaries+=("${pkg}[${disabled_flags}]")
    shift 2
  done

  # If packages are already installed we have nothing to do
  local portageq
  if [ -n "${BOARD}" ] ; then
    portageq="portageq-${BOARD}"
  else
    portageq="portageq"
    local BOARD_ROOT="${ROOT}"
  fi
  local any_package_uninstalled=0
  for pkg in "${pkgs[@]}"; do
    if ! ${portageq}  has_version "${BOARD_ROOT}" "${pkgs[@]}"; then
      any_package_uninstalled=1
      break
    fi
  done
  if [[ ${any_package_uninstalled} -eq 0 ]]; then
    echo "break_dep_loop: Package(s) ${pkgs[@]} already installed, nothing to do."
    return 0
  fi

  # Likewise, nothing to do if the flags aren't actually enabled.
  local equery="equery"
  if [ -n "${BOARD}" ] ; then
    equery="equery-${BOARD}"
  fi
  local any_flag_enabled=0
  for pkg in "${pkgs[@]}"; do
    local grep_args="${all_flags[@]/#/-e ^+}"
    if ${equery} -q uses "${pkg}" | grep -q ${grep_args}; then
      any_flag_enabled=1
      break
    fi
  done
  if [[ ${any_flag_enabled} -eq 0 ]]; then
    echo "break_dep_loop: None of the USE Flag(s) ${all_flags} are enabled for ${pkgs[@]}, nothing to do."
    return 0
  fi

  echo "break_dep_loop: Merging ${pkg_summaries[@]}"
  sudo mkdir -p "${flag_file%/*}"
  sudo tee "${flag_file}" >/dev/null <<<"${flag_file_entries[0]}"
  local entry
  for entry in "${flag_file_entries[@]:1}"; do
    sudo tee -a "${flag_file}" >/dev/null <<<"${entry}"
  done
  if [ -z "${EMERGE_CMD[@]}" ]; then
    local -a EMERGE_CMD=( "emerge" )
  fi
  # rebuild-if-unbuilt is disabled to prevent portage from needlessly
  # rebuilding zlib for some unknown reason, in turn triggering more rebuilds.
  sudo -E \
    "${EMERGE_CMD[@]}" "${EMERGE_FLAGS[@]}" \
    --rebuild-if-unbuilt=n \
    "${args[@]}" "${pkgs[@]}"
  sudo rm -f "${flag_file}"
}
