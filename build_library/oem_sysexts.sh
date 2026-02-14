#!/bin/bash
# OEM sysext helpers.

# Auto-detect scripts repo root from this file's location.
# oem_sysexts.sh is at: <scripts_repo>/build_library/oem_sysexts.sh
_OEM_SYSEXTS_SCRIPTS_ROOT="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")/..")"

get_oem_overlay_root() {
  local overlay_root="/mnt/host/source/src/third_party/coreos-overlay"

  if [[ ! -d "${overlay_root}" ]]; then
    overlay_root="${_OEM_SYSEXTS_SCRIPTS_ROOT}/sdk_container/src/third_party/coreos-overlay"
  fi

  if [[ ! -d "${overlay_root}" ]]; then
    echo "No coreos-overlay repo found (tried SDK and ${_OEM_SYSEXTS_SCRIPTS_ROOT})" >&2
    exit 1
  fi

  printf '%s' "${overlay_root}"
}

_get_oem_ids() {
  local arch list_var_name
  arch=${1}; shift
  list_var_name=${1}; shift

  local overlay_root
  overlay_root=$(get_oem_overlay_root)

  local -a ebuilds=("${overlay_root}/coreos-base/common-oem-files/common-oem-files-"*'.ebuild')
  if [[ ${#ebuilds[@]} -eq 0 ]] || [[ ! -e ${ebuilds[0]} ]]; then
    echo "No coreos-base/common-oem-files ebuilds?!" >&2
    exit 1
  fi

  # This defines local COMMON_OEMIDS, AMD64_ONLY_OEMIDS,
  # ARM64_ONLY_OEMIDS and OEMIDS variable. We don't use the last
  # one. Also defines global-by-default EAPI, which we make local
  # here to avoid making it global.
  local EAPI
  source "${ebuilds[0]}" flatcar-local-variables

  local -n arch_oemids_ref="${arch^^}_ONLY_OEMIDS"
  local all_oemids=(
    "${COMMON_OEMIDS[@]}"
    "${arch_oemids_ref[@]}"
  )

  mapfile -t "${list_var_name}" < <(printf '%s\n' "${all_oemids[@]}" | sort)
}

# Gets a list of OEMs that are using sysexts.
#
# 1 - arch
# 2 - name of an array variable to store the result in
get_oem_id_list() {
  _get_oem_ids "$@"
}

# Gets a list of OEM sysext descriptors.
#
# 1 - arch
# 2 - name of an array variable to store the result in
#
# Format: "name|metapackage|useflags"
get_oem_sysext_matrix() {
  local arch list_var_name
  arch=${1}; shift
  list_var_name=${1}; shift

  local -a oem_ids
  _get_oem_ids "${arch}" oem_ids

  local -a matrix=()
  local oem_id
  for oem_id in "${oem_ids[@]}"; do
    matrix+=("oem-${oem_id}|coreos-base/oem-${oem_id}|flatcar-oem")
  done

  local -n matrix_ref="${list_var_name}"
  matrix_ref=("${matrix[@]}")
}
