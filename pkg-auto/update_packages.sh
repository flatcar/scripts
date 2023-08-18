#!/bin/bash

##
## Updates the packages
##
## Parameters:
## -h: this help
##
## Positional:
## 0: scripts directory
## 1: Gentoo directory
## 2: new branch name with updates
##
## Environment variables:
## WORKDIR
## NO_CLEANUP
## SCRIPTS_BASE
## ARM64_PACKAGES_IMAGE
## AMD64_PACKAGES_IMAGE
## ARM64_PROD_LISTING
## AMD64_PROD_LISTING
## ARM64_DEV_LISTING
## AMD64_DEV_LISTING
## LISTINGS_DIR

set -euo pipefail

this=${0}
this_name=$(basename "${this}")
this_dir=$(dirname "${this}")

function info {
    echo "${this_name}: ${*}"
}

function fail {
    info "${@}" >&2
    exit 1
}

function join_by() {
  local delimiter=${1-}
  local first=${2-}
  if shift 2; then
    printf '%s' "${first}" "${@/#/${delimiter}}";
  fi
}

_cleanup_actions=''

function add_cleanup {
    if [[ -n "${NO_CLEANUP}" ]]; then
        return
    fi
    local joined
    joined=$(join_by ' ; ' "${@}")
    _cleanup_actions="${joined} ; ${_cleanup_actions}"
    trap "${_cleanup_actions}" EXIT
}

if [[ ${#} -eq 1 ]] && [[ ${1} = '-h' ]]; then
    grep '^##' "${this}" | sed -e 's/##[[:space:]]*//'
    exit 0
fi

if [[ ${#} -ne 3 ]]; then
    fail 'Expected three parameters: a scripts directory, a Gentoo directory and a result branch name'
fi

scripts=$(realpath "${1}")
gentoo=$(realpath "${2}")
branch_name=${3}

: "${WORKDIR:=}"
: "${NO_CLEANUP:=}"
: "${SCRIPTS_BASE:=origin/main}"

if [[ -z "${WORKDIR}" ]]; then
    WORKDIR=$(mktemp --tmpdir --directory "up-XXXXXXXX")
    if [[ -n "${NO_CLEANUP}" ]]; then
        info "Workdir in ${WORKDIR}"
    fi
fi

WORKDIR=$(realpath "${WORKDIR}")
mkdir -p "${WORKDIR}"

add_cleanup "rmdir ${WORKDIR@Q}"

bot_name='Flatcar Buildbot'
bot_email='buildbot@flatcar-linux.org'

old_state_branch="old-state-${RANDOM}"
old_state="${WORKDIR}/old_state"
new_state_branch="new-state-${RANDOM}"
new_state="${WORKDIR}/new_state"

git -C "${scripts}" worktree add -b "${old_state_branch}" "${old_state}" "${SCRIPTS_BASE}"
git -C "${scripts}" worktree add -b "${new_state_branch}" "${new_state}" "${SCRIPTS_BASE}"

add_cleanup \
    "git -C ${scripts@Q} worktree remove ${old_state@Q}" \
    "git -C ${scripts@Q} worktree remove ${new_state@Q}" \
    "git -C ${scripts@Q} branch -D ${old_state_branch@Q}" \
    "git -C ${scripts@Q} branch -D ${new_state_branch@Q}"

updated=()
missing_in_scripts=()
missing_in_gentoo=()

for role in AUTHOR COMMITTER; do
    export "GIT_${role}_NAME=${bot_name}"
    export "GIT_${role}_EMAIL=${bot_email}"
done

packages_list=$(realpath "${new_state}/.github/workflows/portage-stable-packages-list")
missing_in_scripts=()
missing_in_gentoo=()
portage_stable_suffix='sdk_container/src/third_party/portage-stable'
portage_stable="${new_state}/${portage_stable_suffix}"
pushd "${portage_stable}"
sync_script="${this_dir}/pkg-auto/sync-with-gentoo.sh"
new_head=$(git -C "${new_state}" rev-parse HEAD)
declare -A pkgs_set
while read -r package; do
    old_head=${new_head}
    if [[ ! -e "${package}" ]]; then
        # If this happens, it means that the package was moved to overlay
        # or dropped, the list ought to be updated.
        missing_in_scripts+=("${package}")
        continue
    fi
    if [[ ! -e "${gentoo}/${package}" ]]; then
        # If this happens, it means that the package was obsoleted or moved
        # in Gentoo. The obsoletion needs to be handled in the case-by-case
        # manner, while move should be handled by doing the same move
        # in portage-stable. The build should not break because of the move,
        # because most likely it's already reflected in the profiles/updates
        # directory.
        missing_in_gentoo+=("${package}")
        continue
    fi
    GENTOO_REPO="${gentoo}" "${sync_script}" "${package}"
    new_head=$(git -C "${new_state}" rev-parse HEAD)
    if [[ "${old_head}" != "${new_head}" ]]; then
        pkgs_set=()
        while read -r line; do
            line=${line#"${portage_stable_suffix}/"}
            category=${line%%/*}
            case "${category}" in
                eclass|virtual|*-*)
                    pkg_and_rest=${line#"${category}"}
                    pkg=${pkg_and_rest%%/*}
                    if [[ -n "${pkg}" ]]; then
                        pkgs_set["${category}/${pkg}"]=x
                    fi
                    ;;
                *)
                    pkgs_set["${category}"]=x
                    ;;
            esac
        done < <(git -C "${new_state}" diff-tree --no-commit-id --name-only HEAD -r)
        updated+=("${!pkgs_set[@]}")
    fi
done < <(grep '^[^#]' "${packages_list}")
popd

packages_list_sort="${this_dir}/sort_packages_list.py"
# Remove missing in scripts entries from package automation
if [[ ${#missing_in_scripts[@]} -gt 0 ]]; then
    grep --invert-match --line-regexp --regexp="$(join_by '\|' "${missing_in_scripts[@]}")" "${packages_list}" >"${WORKDIR}/pkg-list"
    "${packages_list_sort}" "${WORKDIR}/pkg-list" >"${packages_list}"
    rm -f "${WORKDIR}/pkg-list"
    git -C "${new_state}" add "${packages_list}"
    git -C "${new_state}" commit -m '.github: Drop missing packages from automation'
fi

renamed_from=()
renamed_to=()
# bidirectional mapping of a new name and an old name
declare -A renamed_map_n_o renamed_map_o_n
renamed_map_n_o=()
renamed_map_o_n=()

function manual {
    echo "$*" >>"${WORKDIR}/manual"
}

for missing in "${missing_in_gentoo[@]}"; do
    new_name=$({ grep --recursive --regexp="^move ${missing} " "${portage_stable}/profiles/updates/" || :; } | cut -d' ' -f3)
    if [[ -z "${new_name}" ]]; then
        manual "${missing} is gone from Gentoo and no rename found"
        continue
    fi
    mkdir -p "${portage_stable}/${new_name%/*}"
    git -C "${new_state}" mv "${portage_stable}/${missing}" "${portage_stable}/${new_name}"
    old_basename=${missing#*/}
    new_basename=${new_name#*/}
    if [[ "${old_basename}" != "${new_basename}" ]]; then
        for ebuild in "${portage_stable}/${new_name}/${old_basename}-"*'.ebuild'; do
            old_ebuild_filename=${ebuild##*/}
            new_ebuild_filename=${new_basename}${ebuild##*/"${old_basename}"}
            git -C "${new_state}" mv "${portage_stable}/${new_name}/${old_ebuild_filename}" "${portage_stable}/${new_name}/${new_ebuild_filename}"
        done
    fi
    # TODO: changes entries about rename (for old and new name)
    git -C "${new_state}" commit "${missing}: Rename to ${new_name}"
    pushd "${portage_stable}"
    GENTOO_REPO="${gentoo}" "${sync_script}" "${new_name}"
    popd
    renamed_from+=("${missing}")
    renamed_to+=("${new_name}")
    renamed_map_n_o["${new_name}"]="${missing}"
    renamed_map_o_n["${missing}"]="${new_name}"
    updates+=("${new_name}")
done
if [[ ${#renamed_from[@]} -gt 0 ]]; then
    {
        grep --invert-match --line-regexp --regexp="$(join_by '\|' "${renamed_from[@]}")" "${packages_list}"
        printf '%s\n' "${renamed_to[@]}"
    } >"${WORKDIR}/pkg-list"
    "${packages_list_sort}" "${WORKDIR}/pkg-list" >"${packages_list}"
    rm -f "${WORKDIR}/pkg-list"
    git -C "${new_state}" add "${packages_list}"
    git -C "${new_state}" commit -m '.github: Update package names in automation'
fi

# 1. download amd64 and arm64 packages containers and listings for devcontainer and prod images
# 2. to get old and new versions, do for each $arch:
# 2a. run_sdk_container with the $arch packages image
#      (package info - package name, version and slot)
# 2b. get amd64 (not $arch!) SDK package info from /var/db/pkg
#      (ext package info - package info + bdeps)
# 2c. get $arch image ext package info from /build/$arch-usr/var/db/pkg
# 2d. use emerge to get new package info for amd64 SDK
# 2e. use emerge-$arch to get new package info for $arch image
#     (bdeps could be packages that appear in lines without 'to /build/$arch-usr/')

mkdir "${WORKDIR}/pkg-reports" "${WORKDIR}/sdk-images"
add_cleanup \
    "rm -rf ${WORKDIR@Q}/pkg-reports" \
    "rmdir ${WORKDIR@Q}/sdk-images"

function download {
    local url="${1}"; shift
    local output="${1}"; shift

    curl \
        --fail \
        --silent \
        --show-error \
        --location \
        --retry-delay 1 \
        --retry 60 \
        --retry-connrefused \
        --retry-max-time 60 \
        --connect-timeout 20 \
        "${url}" >"${output}"
}

arches=(amd64 arm64)
last_nightly_version_id=$(source "${new_state}/sdk_container/.repo/manifests/version.txt"; printf '%s' "${FLATCAR_VERSION_ID}")
last_nightly_build_id=$(source "${new_state}/sdk_container/.repo/manifests/version.txt"; printf '%s' "${FLATCAR_BUILD_ID}")
for arch in "${arches[@]}"; do
    packages_image_var_name="${arch^^}_PACKAGES_IMAGE"
    packages_image_name="flatcar-packages-${arch}:${last_nightly_version_id}-${last_nightly_build_id}"
    declare -n packages_image_var="${packages_image_var_name}"
    if [[ -n "${packages_image_var:-}" ]]; then
        packages_image_name=${packages_image_var}
        if ! docker images --format '{{.Repository}}:{{.Tag}}' | grep -q -x -F "${packages_image_name}"; then
            fail "No SDK image named '${packages_image_name}' available locally, pull it before running this script"
        fi
    elif ! docker images --format '{{.Repository}}:{{.Tag}}' | grep -q -x -F "${packages_image_name}"; then
        download "https://bincache.flatcar-linux.net/containers/${last_nightly_version_id}-${last_nightly_build_id}/flatcar-packages-${arch}-${last_nightly_version_id}-${last_nightly_build_id}.tar.zst" "${WORKDIR}/sdk-images/sdk-${arch}.tar.zst"
        add_cleanup "rm -f ${WORKDIR@Q}/sdk-images/sdk-${arch}.tar.zst"
        zstd -d -c "${WORKDIR}/sdk-images/sdk-${arch}.tar.zst" | docker load
        add_cleanup "docker rmi ${packages_image_name@Q}"
    fi
    unset -n packages_image_var
    declare -A kinds
    kinds=(
        [prod]=flatcar_production_image_packages.txt
        [dev]=flatcar_developer_container_packages.txt
    )
    for kind in "${!kinds[@]}"; do
        listing_var_name="${arch^^}_${kind^^}_LISTING"
        listing_name=${kinds["${kind}"]}
        listing="${WORKDIR}/listings/${arch}-${kind}"
        declare -n listing_var="${listing_var_name}"
        if [[ -n "${listing_var:-}" ]]; then
            if [[ "${listing_var}" =~ /^[a-z+-]+:\/\// ]]; then
                download "${listing_var}" "${listing}"
            else
                cp -a "${listing_var}" "${listing}"
            fi
        elif [[ -n "${LISTINGS_DIR}" ]]; then
            cp -a "${LISTINGS_DIR}/${listing_name}" "${listing}"
        else
            download "https://bincache.flatcar-linux.net/images/${arch}/${last_nightly_version_id}+${last_nightly_build_id}/${listing_name}" "${listing}"
        fi
        unset -n listing_var
    done
done

for arch in "${arches[@]}"; do
    for sdk_run_kind in old new; do
        state_var_name="${sdk_run_kind}_state"
        sdk_run_state="${!state_var_name}_sdk_run"
        state_branch_var_name="${sdk_run_kind}_state_branch"
        sdk_run_state_branch="${!state_branch_var_name}-sdk-run"

        git -C "${scripts}" \
            worktree add -b "${sdk_run_state_branch}" "${sdk_run_state}" "${!state_branch_var_name}"
        add_cleanup \
            "git -C ${scripts@Q} worktree remove ${sdk_run_state@Q}" \
            "git -C ${scripts@Q} branch -D ${sdk_run_state_branch@Q}"
        cp -a "${this_dir}/pkg-auto/inside-sdk-container.sh" "${sdk_run_state}"
        add_cleanup "rm -f ${sdk_run_state@Q}/inside-sdk-container.sh"
        pushd "${sdk_run_state}"
        ./run_sdk_container -C "${packages_image_name}" -n "pkg-${sdk_run_kind}-${arch}" --rm ./inside-sdk-container.sh "${arch}" pkg-reports
        popd
        mv "${sdk_run_state}/pkg-reports" "${WORKDIR}/pkg-reports/${sdk_run_kind}-${arch}"
    done
done

# TODO: report bdeps missing from SDK

# load package info into memory

## MVM - multi-value-map

source "${this_dir}/map.sh"

# pkginfo: map[pkg]map[slot]version
# earlier: map[pkg][]verslot
function pkginfo_name() {
    local which arch report pkginfo_pn_name_var_name

    which=${1}; shift
    arch=${1}; shift
    report=${1}; shift
    pkginfo_pn_name_var_name=${1}; shift
    local -n pkginfo_pn_name_var="${pkginfo_pn_name_var_name}"

    pkginfo_pn_name_var="pkginfo_mvm_${which}_${arch}_${report//-/_}"
}

function pkginfo_constructor() {
    mvm_mvc_map_constructor "${@}"
}

function pkginfo_destructor() {
    mvm_mvc_map_destructor "${@}"
}

function pkginfo_adder() {
    local mark
    local -n pkginfo_pa_map_var="${1}"; shift
    while [[ ${#} -gt 1 ]]; do
        mark=${pkginfo_pa_map_var["${1}"]:-}
        if [[ -n "${mark}" ]]; then
            fail "multiple versions for a single slot for a package in a single report"
        fi
        pkginfo_pa_map_var["${1}"]=${2}
        shift 2
    done
}

function pkginfo_declare() {
    local which arch report pkginfo_pd_name_var_name
    local -a extras

    which=${1}; shift
    arch=${1}; shift
    report=${1}; shift
    pkginfo_pd_name_var_name=${1}; shift

    pkginfo_name "${which}" "${arch}" "${report}" "${pkginfo_pd_name_var_name}"
    extras=(
        'which' "${which}"
        'arch' "${arch}"
        'report' "${report}"
    )

    mvm_declare "${!pkginfo_pd_name_var_name}" pkginfo -- "${extras[@]}"
}

function pkginfo_process_file() {
    mvm_call "${1}" pkginfo_c_process_file "${@:2}"
}

function pkginfo_c_process_file() {
    local pkginfo_pcpf_pkg_set_var_name pkginfo_pcpf_pkg_slots_mvm_var_name which arch report pkg version_slot v s throw_away

    pkginfo_pcpf_pkg_set_var_name=${1}; shift
    local -n pkginfo_pcpf_pkg_set_var="${pkginfo_pcpf_pkg_set_var_name}"
    pkginfo_pcpf_pkg_slots_mvm_var_name=${1}; shift

    mvm_c_get_extra 'which' which
    mvm_c_get_extra 'arch' arch
    mvm_c_get_extra 'report' report

    while read -r pkg version_slot throw_away; do
        v=${version_slot%%:*}
        s=${version_slot##*:}
        mvm_c_add "${pkg}" "${s}" "${v}"
        pkginfo_pcpf_pkg_set_var["${pkg}"]='x'
        mvm_add "${pkginfo_pcpf_pkg_slots_mvm_var_name}" "${pkg}" "${s}"
    done < <("${WORKDIR}/pkg-reports/${which}-${arch}/${report}")
}

ARCHES=(amd64 arm64)
WHICH=(old new)
SDK_PKGS=sdk-pkgs
BOARD_PKGS=board-pkgs
REPORTS=("${SDK_PKGS}" "${BOARD_PKGS}")

function read_reports() {
    local rr_all_pkgs_var_name rr_pkg_slots_mvm_var_name arch which report pi_name
    local -A all_packages_set

    rr_all_pkgs_var_name=${1}; shift
    rr_pkg_slots_mvm_var_name=${1}; shift
    all_packages_set=()
    for arch in "${ARCHES[@]}"; do
        for which in "${WHICH[@]}"; do
            for report in "${REPORTS[@]}"; do
                pkginfo_declare "${which}" "${arch}" "${report}" pi_name
                pkginfo_process_file "${pi_name}" all_packages_set "${rr_pkg_slots_mvm_var_name}"
            done
        done
    done
    local -n rr_all_pkgs_var="${rr_all_pkgs_var_name}"
    rr_all_pkgs_var=( "${!all_packages_set[@]}" )
}

###
### BEGIN GENTOO VER COMP HACKS
###

EAPI=6
function die() {
    fail "$*"
}

source "${portage_stable}/eclass/eapi7-ver.eclass"

function vercmp() {
    local -
    set +euo pipefail
    ver_test "${@}"
}

###
### END GENTOO VER COMP HACKS
###

function ver_min_max() {
    local vmm_min_var_name vmm_max_var_name min max v

    vmm_min_var_name=${1}; shift
    local -n vmm_min_var="${vmm_min_var_name}"
    vmm_max_var_name=${1}; shift
    local -n vmm_max_var="${vmm_max_var_name}"

    min=''
    max=''

    for v; do
        if [[ -z ${min} ]] || vercmp "${v}" -lt "${min}"; then
            min=${v}
        fi
        if [[ -z ${max} ]] || vercmp "${v}" -gt "${max}"; then
            max=${v}
        fi
    done
    vmm_min_var="${min}"
    vmm_max_var="${max}"
}

# cases: (replace sdk and board with amd64 and arm64 if you want)
# 0 in sdk, 0 in board - possibly unused package, or maybe arch specific stuff, ignore?
# 1 in sdk, 0 in board - SDK only package, oldest/newest version for arch from SDK
# 0 in sdk, 1 in board - board only package, oldest/newest version for arch from board
# 1 in sdk, 1 in board - common package
#                        if slots are equal, but not the versions, warn
#                        if slots are different, suspicious
#                        oldest/newest version from either
# X in sdk, 0 in board - one version per slot,
#                        if more versions per slot, warn
#                        multiple old/new versions
# 0 in sdk, X in board - same
# X in sdk, 1 in board - if board slot is also in SDK, but versions differ, warn
#                        if board slot is not in SDK, suspicious
#                        multiple old/mew versions
# 1 in sdk, X in board - if SDK slot is also in board, but versions differ, warn
#                        if SDK slot is not in board, suspicious
#                        multiple old/mew versions
# X in sdk, X in board - common slots should have the same version, otherwise warn
#                        slots only in SDK or only in board are suspicious
#                        multiple old/new versions
# function cc_0_1() {
#     local cc01_vs_var_name cc01_pkg_versions_var_name v s
#
#     cc01_vs_var_name=${1}; shift
#     local -n cc01_vs_var="${cc01_vs_var}"
#     cc01_pkg_versions_var_name=${1}; shift
#     local -n cc01_pkg_versions_var="${cc01_pkg_versions_var_name}"
#
#     v=${cc01_vs_var[0]%%:*}
#     s=${cc01_vs_var[0]##*:}
#     cc01_pkg_versions_var["${s}"]="${v}:${v}"
# }
#
# function cc_0_x() {
#     local cc0x_vs_var_name cc0x_pkg_versions_var_name vs v s cc0x_versions_array_name
#     local -a slots
#
#     cc0x_vs_var_name=${1}; shift
#     local -n cc0x_vs_var="${cc0x_vs_var_name}"
#     cc0x_pkg_versions_var_name=${1}; shift
#     local -n cc0x_pkg_versions_var="${cc0x_pkg_versions_var_name}"
#
#     mvm_declare cc0x_slot_map
#     slots=()
#     for vs in "${cc0x_vs_var[@]}"; do
#         v=${vs%%:*}
#         s=${vs##*:}
#         mvm_add cc0x_slot_map "${s}" "${v}"
#         slots+=( "${s}" )
#     done
#     for s in "${slots[@]}"; do
#         mvm_get cc0x_slot_map "${s}" cc0x_versions_array_name
#         local -n cc0x_versions_array="${cc0x_versions_array_name}"
#         if [[ ${#cc0x_versions_array[@]} -gt 1 ]]; then
#             local cc0x_min cc0x_max
#             ver_min_max cc0x_min cc0x_max "${cc0x_versions_array[@]}"
#             cc0x_pkg_versions_var["${s}"]="${cc0x_min}:${cc0x_max}"
#             # TODO: warn about many versions for one slot
#         else
#             v=${cc0x_versions_array[0]}
#             cc0x_pkg_versions_var["${s}"]="${v}:${v}"
#         fi
#         unset -n cc0x_versions_array
#     done
#     mvm_unset cc0x_slot_map
# }
#
# function cc_1_x() {
#     local only_verslot only_version only_slot cc1x_vs_var_name cc1x_pkg_versions_var_name vs v s slot_found cc1x_versions_array_name version_found cc1x_min cc1x_max
#     local -a slots
#
#     only_verslot=${1}; shift
#     only_version=${only_verslot%%:*}
#     only_slot=${only_verslot##*:}
#
#     cc1x_vs_var_name=${1}; shift
#     local -n cc1x_vs_var="${cc1x_vs_var_name}"
#     cc1x_pkg_versions_var_name=${1}; shift
#     local -n cc1x_pkg_versions_var="${cc1x_pkg_versions_var_name}"
#
#     mvm_declare cc1x_slot_map
#     slots=()
#     for vs in "${cc1x_vs_var[@]}"; do
#         v=${vs%%:*}
#         s=${vs##*:}
#         mvm_add cc1x_slot_map "${s}" "${v}"
#         slots+=( "${s}" )
#     done
#     slot_found=''
#     for s in "${slots[@]}"; do
#         mvm_get cc1x_slot_map "${s}" cc1x_versions_array_name
#         local -n cc1x_versions_array="${cc1x_versions_array_name}"
#         if [[ ${#cc1x_versions_array[@]} -gt 1 ]]; then
#             # TODO: warn about many versions for one slot
#             if [[ ${s} = ${only_slot} ]]; then
#                 version_found=''
#                 for v in "${cc1x_versions_array[@]}"; do
#                     if [[ ${v} = ${only_version} ]]; then
#                         version_found=x
#                         break
#                     fi
#                 done
#                 if [[ -z ${version_found} ]]; then
#                     # TODO: warn about version mismatch, the only version does not match any on the other side
#                 fi
#             fi
#         elif [[ ${s} = ${only_slot} ]] && [[ ${cc1x_versions_array[0]} != ${only_version} ]]; then
#             # TODO: warn about version mismatch, the only version does not match any on the other side
#         fi
#         if [[ ${s} = ${only_slot} ]]; then
#             slot_found=x
#             ver_min_max cc1x_min cc1x_max "${cc1x_versions_array[@]}" "${only_version}"
#         else
#             ver_min_max cc1x_min cc1x_max "${cc1x_versions_array[@]}"
#         fi
#         cc1x_pkg_versions_var["${s}"]="${cc1x_min}:${cc1x_max}"
#         unset -n cc1x_versions_array
#     done
#     if [[ -z ${slot_found} ]]; then
#         # TODO: the only slot is not present on other side, suspicious
#         cc1x_pkg_versions_var["${only_slot}"]="${only_version}:${only_version}"
#     fi
#     mvm_unset cc1x_slot_map
# }

# X in sdk, X in board - common slots should have the same version, otherwise warn
#                        slots only in SDK or only in board are suspicious
#                        multiple old/new versions
function cc_x_x() {
    local pkg ccxx_slot_version1_map_var_name ccxx_slot_version2_map_var_name ccxx_pkg_slot_minmax_var_name ccxx_pkg_slots_var_name s v1 v2 ccxx_min ccxx_max mm

    pkg=${1}; shift
    ccxx_slot_version1_map_var_name=${1}; shift
    local -n ccxx_slot_version1_map_var="${ccxx_slot_version1_map_var_name}"
    ccxx_slot_version2_map_var_name=${1}; shift
    local -n ccxx_slot_version2_map_var="${ccxx_slot_version2_map_var_name}"
    ccxx_pkg_slot_minmax_var_name=${1}; shift
    ccxx_pkg_slots_var_name=${1}; shift

    mvm_get "${ccxx_pkg_slots_var_name}" "${pkg}" ccxx_slots_name
    local -n slots="${cxx_slots_name}"
    for s in "${!slots[@]}"; do
        v1=${ccxx_slot_version1_map_var["${s}"]:-}
        v2=${ccxx_slot_version2_map_var["${s}"]:-}
        mm

        if [[ -n ${v1} ]] && [[ -n ${v2} ]]; then
            if [[ ${v1} != ${v2} ]]; then
                # TODO: warn about version mismatch for a slot in the package
            fi
            ver_min_max ccxx_min ccxx_max "${v1}" "${v2}"
            mm="${ccxx_min}:${ccxx_max}"
        elif [[ -n ${v1} ]]; then
            # only side1 has the slot
            if [[ ${#ccxx_slot_version2_map_var[@]} -gt 0 ]]; then
                # TODO: the slot is present only on one side, while
                # other side has other slots, suspicious
            fi
            mm="${v1}:${v1}"
        elif [[ -n ${v2} ]]; then
            # only side 2 has the slot
            if [[ ${#ccxx_slot_version1_map_var[@]} -gt 0 ]]; then
                # TODO: the slot is present only on other side, while
                # one side has other slots, suspicious
            fi
            mm="${v2}:${v2}"
        else
            continue
        fi

        mvm_add "${ccxx_pkg_slot_minmax_var_name}" "${pkg}" "${s}" "${mm}"
    done
}

function consistency_check_for_package() {
    local pkg pi1 pi2 ccfp_pkg_slot_minmax_var_name ccfp_pkg_slots_var_name ccfp_slot_version1_map_name ccfp_slot_version2_map_name

    pkg=${1}; shift
    pi1=${1}; shift
    pi2=${1}; shift
    ccfp_pkg_slot_minmax_var_name=${1}; shift
    ccfp_pkg_slots_var_name=${1}; shift

    mvm_get "${p1}" "${pkg}" ccfp_slot_version1_map_name
    mvm_get "${p2}" "${pkg}" ccfp_slot_version2_map_name

    if [[ -z ${ccfp_slot_version1_map_name} ]]; then
        local -A ccfp_slot_version_map1
        ccfp_slot_version_map1=()
    else
        local -n ccfp_slot_version_map1="${ccfp_slot_version1_map_name}"
    fi

    if [[ -z ${ccfp_slot_version2_map_name} ]]; then
        local -A ccfp_slot_version_map2
        ccfp_slot_version_map2=()
    else
        local -n ccfp_slot_version_map2="${ccfp_slot_version2_map_name}"
    fi

    cc_x_x "${pkg}" ccfp_slot_version_map1 ccfp_slot_version_map2 "${ccfp_pkg_slot_minmax_var_name}" "${ccfp_pkg_slots_var_name}"
}

# consistency checks between:
# not yet: amd64 sdk <-> arm64 sdk
# amd64 sdk <-> amd64 board
# not yet: arm64 sdk <-> arm64 board
# amd64 board <-> arm64 board
function consistency_checks() {
    local which cc_all_pkgs_var_name cc_pkg_slots_var_name cc_pkg_slot_minmax_versions_var_name cc_pi1_name cc_pi2_name pkg

    which=${1}; shift
    cc_all_pkgs_var_name=${1}; shift
    local -n cc_all_pkgs_var="${cc_all_pkgs_var_name}"
    cc_pkg_slots_var_name=${1}; shift
    cc_pkg_slot_minmax_versions_var_name=${1}; shift

    # amd64 sdk <-> amd64 board
    pkginfo_name "${which}" amd64 "${SDK_PKGS}" cc_pi1_name
    pkginfo_name "${which}" amd64 "${BOARD_PKGS}" cc_pi2_name
    mvm_declare amd64_sdk_board_pkg_slot_minmax mvm_mvc_map
    for pkg in "${cc_all_pkgs_var[@]}"; do
        consistency_check_for_package "${pkg}" "${cc_p1_name}" "${cc_pi2_name}" amd64_sdk_board_pkg_slot_minmax "${cc_pkg_slots_var_name}"
    done

    # amd64 board <-> arm64 board
    pkginfo_name "${which}" amd64 "${BOARD_PKGS}" cc_pi1_name
    pkginfo_name "${which}" arm64 "${BOARD_PKGS}" cc_pi2_name
    mvm_declare amd64_arm64_board_pkg_slot_minmax mvm_mvc_map
    for pkg in "${cc_all_pkgs_var[@]}"; do
        consistency_check_for_package "${pkg}" "${cc_p1_name}" "${cc_pi2_name}" amd64_arm64_board_pkg_slot_minmax "${cc_pkg_slots_var_name}"
    done

    local m1_name m2_name s mm1 mm2 cc_min cc_max mm cc_slots_name
    local -A empty
    empty=()
    for pkg in "${cc_all_pkgs_var[@]}"; do
        mvm_get amd64_sdk_board_pkg_slot_minmax "${pkg}" m1_name
        mvm_get amd64_arm64_board_pkg_slot_minmax "${pkg}" m2_name
        mvm_get "${cc_pkg_slots_var_name}" "${pkg}" cc_slots_name
        local -n m1="${m1_name:-empty}"
        local -n m2="${m2_name:-empty}"
        local -n all_slots="${cc_slots_name}"
        for s in "${!all_slots[@]}"; do
            mm1=${m1["${s}"]:-}
            mm2=${m2["${s}"]:-}
            if [[ -n "${mm1}" ]] && [[ -n "${mm2}" ]]; then
                ver_min_max \
                    cc_min cc_max \
                    "{mm1%%:*}" "${mm1##*:}" "{mm2%%:*}" "${mm2##*:}"
                mm="${cc_min}:${cc_max}"
            elif [[ -n "${mm1}" ]]; then
                mm="${mm1}"
            elif [[ -n "${mm2}" ]]; then
                mm="${mm2}"
            else
                continue
            fi
            mvm_add "${cc_pkg_slot_minmax_versions_var_name}" "${pkg}" "${S}" "${mm}"
        done
        unset -n all_slots m2 m1
    done
    mvm_unset amd64_arm64_board_pkg_slot_minmax
    mvm_unset amd64_sdk_board_pkg_slot_minmax
}

function stuff() {
    local -a all_pkgs

    mvm_declare pkg_slots_map mvm_mcv_set
    read_reports all_pkgs pkg_slots_map

    mvm_declare old_pkg_slot_minmax mvm_mvc_map
    mvm_declare new_pkg_slot_minmax mvm_mvc_map
    consistency_checks old all_pkgs pkg_slots_map old_pkg_slot_minmax
    consistency_checks new all_pkgs pkg_slots_map new_pkg_slot_minmax

    local pkg old_version new_version slots_set_name
    for pkg in "${all_pkgs[@]}"; do
        mvm_get pkg_slots_map "${pkg}" slots_set_name
        local -n slots="${slots_set_name}"

        for s in "${!slots[@]}"; do
            # TODO: get min version from old, get max version from new
            # and see if there's an update
        done
    done
}

function ajwaj() {
    local slot a_array_name

    slot=${1}; shift
    a_array_name=${1}; shift
    # rest are versions
    if [[ ${#} -gt 1 ]]; then
        # TODO: warning about two different versions of the package with the same slot on this arch
    fi
}

function process_reports_and_simplify() {
    local all_pkgs_var_name=${1}
    local report

    for report in sdk-pkgs board-pkgs; do
        pi_c_process_file "${report}" "${all_pkgs_var_name}"
    done
    mvm_c_iterate simplify
}

function simplify() {
    local pkg s_array_name

    pkg=${1}; shift
    s_array_name=${1}; shift
    # rest are version:slot items
    if [[ ${#} -lt 2 ]]; then
        return 0
    fi

    local version_slot
    local -A tmp_set
    tmp_set=()
    for version_slot; do
        tmp_set["${version_slot}"]=x
    done

    local -n s_array="${s_array_name}"
    s_array=( "${!tmp_set[@]}" )
}











# multi_*_versions are mapping of package name to array variable name
# containing most likely duplicated version:slot info
declare -A old_versions new_versions multi_old_version multi_new_versions pkg_tags
# array of all package names (from SDK and board)
declare -a all_pkgs

function multiversion_name() {
    local which=${1}; shift
    local arch=${1}; shift

    printf 'multi_versions_%s_%s' "${which}" "${arch}"
}

function init_multiversion() {
    local which=${1}; shift
    local arch=${1}; shift
}

function is_multiversion() {
    local which=${1}; shift
    local arch=${1}; shift
    local pkg=${1}; shift
    local -n multi="multi_${which}_versions"
    local var_name=${multi["${pkg}"]}

    [[ -n ${var_name} ]]
}

function get_and_inc_multiversion_counter() {
    local which=${1}; shift
    local value_var_name=${1}; shift
    local -n value_var="${value_var_name}"
    local multi_name="multi_${which}_versions"
    local -n multi="${multi_name}"
    local counter=${multi['##counter']:-}

    if [[ -z ${counter} ]]; then
        counter=0
    fi
    multi['##counter']=$((counter + 1))
    value_var=${counter}
}

function add_to_multiversion() {
    local which=${1}; shift
    local pkg=${1}; shift
    local version_slot=${1}; shift
    local multi_name="multi_${which}_versions"
    local -n multi="${multi_name}"
    local var_name=${multi["${pkg}"]:-}
    local index

    if [[ -n ${var_name} ]]; then
        local -n array_var="${var_name}"
        array_var+=( "${version_slot}" )
    else
        get_and_inc_multiversion_counter "${which}" index
        var_name="${multi_name}_array_${index}"
        declare -g -a "${var_name}"
        local -n array_var="${var_name}"
        array_var=( "${version_slot}" )
        multi["${pkg}"]=${var_name}
    fi
}

function process_package_info_file() {
    local which=${1}; shift
    local arch=${1}; shift
    local report=${1}; shift
    local pkg version_slot throw_away version old
    local file="${WORKDIR}/pkg-reports/${which}-${arch}/${report}"
    local -n versions="${which}_versions"

    while read -r pkg version_slot throw_away; do
        version=${version_slot%%:*}
        old=${versions["${pkg}"]:-}
        if is_multiversion old "${pkg}"; then
            add_to_multiversion old "${pkg}" "${version_slot}"
        elif [[ -n ${old} ]]; then
            if [[ ${old} = ${version} ]]; then
                continue
            fi
            unset old_versions["${pkg}"]
            add_to_multiversion old "${pkg}" "${version_slot}"
        else
            versions["${pkg}"]=${version_slot}
        fi
    done < <("${file}")
}

updated_pkgs=()
old_portage_stable="${old_state}/${portage_stable_suffix}"
for entry in "${updated[@]}"; do
    case "${entry}" in
        eclass/*)
            mkdir -p "${WORKDIR}/updates/eclass"
            { diff "${old_portage_stable}/${entry}" "${portage_stable}/${entry}" || : } >"${WORKDIR}/updates/${entry}"
            ;;
        profiles)
            # TODO: extract diffs of interesting parts to us (skip
            # irrelevant arches, for example)
            :
            ;;
        licenses)
            # TODO: diffstat (licenses removed, added or modified)
            :
            ;;
        scripts)
            :
            ;;
        *)
            :
            ;;
    esac
done

git -C "${scripts}" branch "${branch_name}" "${new_state_branch}"
