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

# Gets a list of OEMs that are using sysexts.
#
# 1 - arch
# 2 - name of an array variable to store the result in
get_oem_id_list() {
  local arch=${1}; shift
  local -n list_var_ref=${1}; shift

  local overlay_root dir ebuild regex
  overlay_root=$(get_oem_overlay_root)

  for dir in "${overlay_root}"/coreos-base/oem-*; do
    for ebuild in "${dir}"/*.ebuild; do
      if [[ ! -e ${ebuild} ]]; then
        echo "No coreos-base/oem-* ebuilds?!" >&2
        exit 1
      fi

      # Check the KEYWORDS by sourcing the ebuild. We can't rely on Portage
      # because this needs to work outside the SDK. OEM ebuilds are relatively
      # boring, so this should be sufficient. This doesn't check whether the
      # KEYWORDS are stable, but that shouldn't matter.
      regex="\b${arch}\b"
      if ( set +eu; . "${ebuild}" &>/dev/null; [[ ${KEYWORDS} =~ ${regex} ]] ); then
        list_var_ref+=( "${dir##*/oem-}" )
        break
      fi
    done
  done
}

# Gets a list of OEM sysext descriptors.
#
# 1 - arch
# 2 - name of an array variable to store the result in
#
# Format: "name|metapackage|useflags"
get_oem_sysext_matrix() {
  local arch=${1}; shift
  declare -n list_var_ref=${1}; shift

  local -a oem_ids
  get_oem_id_list "${arch}" oem_ids

  local oem_id
  for oem_id in "${oem_ids[@]}"; do
    list_var_ref+=( "oem-${oem_id}|coreos-base/oem-${oem_id}|" )
  done
}
