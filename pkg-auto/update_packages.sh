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
##

# TODO:
#
# - Split downloading and the rest into separate scripts, this will
#   allow downloading things once and rerunning the rest. Another
#   option is checking if download happened and skip the step, which
#   would make the update script quicker. But the split would allow us
#   to specify how to handle created docker images in the download
#   script.

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/stuff.sh"

if [[ ${#} -eq 1 ]] && [[ ${1} = '-h' ]]; then
    print_help
    exit 0
fi

if [[ ${#} -ne 3 ]]; then
    fail 'Expected three parameters: a scripts directory, a Gentoo directory and a result branch name'
fi

scripts=$(realpath "${1}"); shift
gentoo=$(realpath "${1}"); shift
branch_name=${1}; shift

: "${WORKDIR:=}"
: "${NO_CLEANUP:=}"
: "${SCRIPTS_BASE:=origin/main}"

if [[ -n "${NO_CLEANUP}" ]]; then
    ignore_cleanups
fi

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
sync_script="${THIS_DIR}/pkg-auto/sync-with-gentoo.sh"
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

packages_list_sort="${THIS_DIR}/sort_packages_list.py"
# Remove missing in scripts entries from package automation
if [[ ${#missing_in_scripts[@]} -gt 0 ]]; then
    join_by missing_re '\|' "${missing_in_scripts[@]}"
    missing_re
    grep --invert-match --line-regexp --regexp="${missing_re}" "${packages_list}" >"${WORKDIR}/pkg-list"
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

function lines_to_file() {
    printf '%s\n' "${@:2}" >>"${1}"
}

function manual() {
    lines_to_file "${WORKDIR}/manual-work-needed" "${@}"
}

function pkg_warn() {
    lines_to_file "${WORKDIR}/warnings" "${@}"
}

function devel_warn() {
    lines_to_file "${WORKDIR}/developer-warnings" "${@}"
}

for missing in "${missing_in_gentoo[@]}"; do
    new_name=$({ grep --recursive --regexp="^move ${missing} " "${portage_stable}/profiles/updates/" || :; } | cut -d' ' -f3)
    if [[ -z "${new_name}" ]]; then
        manual "- package ${missing} is gone from Gentoo and no rename found"
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
    join_by renamed_re '\|' "${renamed_from[@]}"
    {
        grep --invert-match --line-regexp --regexp="${renamed_re}" "${packages_list}"
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

ARCHES=(amd64 arm64)
WHICH=(old new)
SDK_PKGS=sdk-pkgs
BOARD_PKGS=board-pkgs
REPORTS=("${SDK_PKGS}" "${BOARD_PKGS}")

last_nightly_version_id=$(source "${new_state}/sdk_container/.repo/manifests/version.txt"; printf '%s' "${FLATCAR_VERSION_ID}")
last_nightly_build_id=$(source "${new_state}/sdk_container/.repo/manifests/version.txt"; printf '%s' "${FLATCAR_BUILD_ID}")
for arch in "${ARCHES[@]}"; do
    packages_image_var_name="${arch^^}_PACKAGES_IMAGE"
    packages_image_name="flatcar-packages-${arch}:${last_nightly_version_id}-${last_nightly_build_id}"
    declare -n packages_image_ref="${packages_image_var_name}"
    if [[ -n "${packages_image_ref:-}" ]]; then
        packages_image_name=${packages_image_ref}
        if ! docker images --format '{{.Repository}}:{{.Tag}}' | grep -q -x -F "${packages_image_name}"; then
            fail "No SDK image named '${packages_image_name}' available locally, pull it before running this script"
        fi
    elif ! docker images --format '{{.Repository}}:{{.Tag}}' | grep -q -x -F "${packages_image_name}"; then
        download "https://bincache.flatcar-linux.net/containers/${last_nightly_version_id}-${last_nightly_build_id}/flatcar-packages-${arch}-${last_nightly_version_id}-${last_nightly_build_id}.tar.zst" "${WORKDIR}/sdk-images/sdk-${arch}.tar.zst"
        add_cleanup "rm -f ${WORKDIR@Q}/sdk-images/sdk-${arch}.tar.zst"
        zstd -d -c "${WORKDIR}/sdk-images/sdk-${arch}.tar.zst" | docker load
        add_cleanup "docker rmi ${packages_image_name@Q}"
    fi
    unset -n packages_image_ref
    declare -A kinds
    kinds=(
        [prod]=flatcar_production_image_packages.txt
        [dev]=flatcar_developer_container_packages.txt
    )
    for kind in "${!kinds[@]}"; do
        listing_var_name="${arch^^}_${kind^^}_LISTING"
        listing_name=${kinds["${kind}"]}
        listing="${WORKDIR}/listings/${arch}-${kind}"
        declare -n listing_ref="${listing_var_name}"
        if [[ -n "${listing_ref:-}" ]]; then
            if [[ "${listing_ref}" =~ /^[a-z+-]+:\/\// ]]; then
                download "${listing_ref}" "${listing}"
            else
                cp -a "${listing_ref}" "${listing}"
            fi
        elif [[ -n "${LISTINGS_DIR}" ]]; then
            cp -a "${LISTINGS_DIR}/${listing_name}" "${listing}"
        else
            download "https://bincache.flatcar-linux.net/images/${arch}/${last_nightly_version_id}+${last_nightly_build_id}/${listing_name}" "${listing}"
        fi
        unset -n listing_ref
    done
done

for arch in "${ARCHES[@]}"; do
    for sdk_run_kind in "${WHICH[@]}"; do
        state_var_name="${sdk_run_kind}_state"
        sdk_run_state="${!state_var_name}_sdk_run"
        state_branch_var_name="${sdk_run_kind}_state_branch"
        sdk_run_state_branch="${!state_branch_var_name}-sdk-run"

        git -C "${scripts}" \
            worktree add -b "${sdk_run_state_branch}" "${sdk_run_state}" "${!state_branch_var_name}"
        add_cleanup \
            "git -C ${scripts@Q} worktree remove ${sdk_run_state@Q}" \
            "git -C ${scripts@Q} branch -D ${sdk_run_state_branch@Q}"
        cp -a "${THIS_DIR}/pkg-auto/inside_sdk_container.sh" "${sdk_run_state}"
        cp -a "${THIS_DIR}/pkg-auto/stuff.sh" "${sdk_run_state}"
        cp -a "${THIS_DIR}/pkg-auto/print-profile-tree.sh" "${sdk_run_state}"
        add_cleanup \
            "rm -f ${sdk_run_state@Q}/inside_sdk_container.sh" \
            "rm -f ${sdk_run_state@Q}/stuff.sh" \
            "rm -f ${sdk_run_state@Q}/print-profile-tree.sh"
        (
            cd "${sdk_run_state}"
            ./run_sdk_container -C "${packages_image_name}" -n "pkg-${sdk_run_kind}-${arch}" --rm ./inside-sdk-container.sh "${arch}" pkg-reports
        )
        mv "${sdk_run_state}/pkg-reports" "${WORKDIR}/pkg-reports/${sdk_run_kind}-${arch}"
    done
done

# TODO: report bdeps missing from SDK

source "${THIS_DIR}/mvm.sh"

# pkginfo: map[pkg]map[slot]version
function pkginfo_name() {
    local which arch report pi_name_var_name

    which=${1}; shift
    arch=${1}; shift
    report=${1}; shift
    pi_name_var_name=${1}; shift
    local -n pi_name_ref="${pi_name_var_name}"

    pi_name_ref="pkginfo_mvm_${which}_${arch}_${report//-/_}"
}

function pkginfo_constructor() {
    mvm_mvc_map_constructor "${@}"
}

function pkginfo_destructor() {
    mvm_mvc_map_destructor "${@}"
}

function pkginfo_adder() {
    local mark
    local -n map_ref="${1}"; shift
    while [[ ${#} -gt 1 ]]; do
        mark=${map_ref["${1}"]:-}
        if [[ -n "${mark}" ]]; then
            fail "multiple versions for a single slot for a package in a single report"
        fi
        map_ref["${1}"]=${2}
        shift 2
    done
}

function pkginfo_declare() {
    local which arch report pi_name_var_name
    local -a extras

    which=${1}; shift
    arch=${1}; shift
    report=${1}; shift
    pi_name_var_name=${1}; shift

    pkginfo_name "${which}" "${arch}" "${report}" "${pi_name_var_name}"
    extras=(
        'which' "${which}"
        'arch' "${arch}"
        'report' "${report}"
    )

    mvm_declare "${!pi_name_var_name}" pkginfo -- "${extras[@]}"
}

function pkginfo_process_file() {
    mvm_call "${1}" pkginfo_c_process_file "${@:2}"
}

function pkginfo_c_process_file() {
    local pkg_set_var_name pkg_slots_mvm_var_name
    pkg_set_var_name=${1}; shift
    local -n pkg_set_ref="${pkg_set_var_name}"
    pkg_slots_mvm_var_name=${1}; shift

    local which arch report
    mvm_c_get_extra 'which' which
    mvm_c_get_extra 'arch' arch
    mvm_c_get_extra 'report' report

    local pkg version_slot throw_away v s
    while read -r pkg version_slot throw_away; do
        v=${version_slot%%:*}
        s=${version_slot##*:}
        mvm_c_add "${pkg}" "${s}" "${v}"
        pkg_set_ref["${pkg}"]='x'
        mvm_add "${pkg_slots_mvm_var_name}" "${pkg}" "${s}"
    done < <("${WORKDIR}/pkg-reports/${which}-${arch}/${report}")
}

function pkginfo_profile() {
    mvm_call "${1}" pkginfo_c_profile "${@:2}"
}

function pkginfo_c_profile() {
    local profile_var_name
    profile_var_name=${1}; shift

    local which arch report
    mvm_c_get_extra 'which' which
    mvm_c_get_extra 'arch' arch
    mvm_c_get_extra 'report' report

    printf -v "${profile_var_name}" '%s-%s-%s' "${which}" "${arch}" "${report}"
}

function read_reports() {
    local all_pkgs_var_name pkg_slots_mvm_var_name

    all_pkgs_var_name=${1}; shift
    pkg_slots_mvm_var_name=${1}; shift

    local arch which report rr_pi_name
    local -A all_packages_set
    all_packages_set=()
    for arch in "${ARCHES[@]}"; do
        for which in "${WHICH[@]}"; do
            for report in "${REPORTS[@]}"; do
                pkginfo_declare "${which}" "${arch}" "${report}" rr_pi_name
                pkginfo_process_file "${rr_pi_name}" all_packages_set "${pkg_slots_mvm_var_name}"
            done
        done
    done
    local -n all_pkgs_ref="${all_pkgs_var_name}"
    all_pkgs_ref=( "${!all_packages_set[@]}" )
}

###
### BEGIN GENTOO VER COMP HACKS
###

EAPI=6
function die() {
    fail "$*"
}

source "${THIS_DIR}/../${portage_stable_suffix}/eclass/eapi7-ver.eclass"

unset EAPI

function gentoo_ver_test_out() {
    local v1 op v2 out_var_name
    v1=${1}; shift
    op=${1}; shift
    v2=${1}; shift
    out_var_name=${1}; shift
    local -n out_ref="${out_var_name}"

    local -
    set +e
    ver_test "${v1}" "${op}" "${v2}"
    out_ref=${?}
    return 0
}

function gentoo_ver_test() {
    local v1 op v2
    v1=${1}; shift
    op=${1}; shift
    v2=${1}; shift

    local gvt_retval
    gentoo_ver_test_out "${v1}" "${op}" "${v2}" gvt_retval
    return ${gvt_retval}
}

# symbolic names for use with gentoo_ver_cmp
GV_LT=1
GV_EQ=2
GV_GT=3

# 1 - version 1
# 2 - version 2
# 3 - name of variable to store the result in (1 when v1 < v2, 2 when v1 == v2, 3 when v1 > v2)
function gentoo_ver_cmp_out() {
    local v1 v2 out_var_name
    v1=${1}; shift
    v2=${1}; shift
    out_var_name=${1}; shift
    local -n out_ref="${out_var_name}"

    local -
    set +e
    _ver_compare "${v1}" "${v2}"
    out_ref=${?}
    case ${out_ref} in
        1|2|3)
            return 0
            ;;
        *)
            fail "unexpected return value ${out_ref} from _ver_compare for ${v1} and ${v2}"
            ;;
    esac
}

# 1 - version 1
# 2 - version 2
function gentoo_ver_cmp() {
    local v1 v2 out_var_name
    v1=${1}; shift
    v2=${1}; shift

    local gvc_retval
    gentoo_ver_cmp_out "${v11}" "${v2}" gvc_retval
    return ${gvc_retval}
}

###
### END GENTOO VER COMP HACKS
###

function ver_min_max() {
    local min_var_name max_var_name
    min_var_name=${1}; shift
    local -n min_ref="${min_var_name}"
    max_var_name=${1}; shift
    local -n max_ref="${max_var_name}"

    local min max v
    min=''
    max=''
    for v; do
        if [[ -z ${min} ]] || gentoo_ver_test "${v}" -lt "${min}"; then
            min=${v}
        fi
        if [[ -z ${max} ]] || gentoo_ver_test "${v}" -gt "${max}"; then
            max=${v}
        fi
    done
    min_ref="${min}"
    max_ref="${max}"
}

# 1 - package
# 2 - name of the package info mvm for profile 1
# 3 - name of the package info mvm for profile 2
# 4 - name of the pkg to slots to version mvm
# 5 - name of the pkg to all slots mvm
function consistency_check_for_package() {
    local pkg pi1_mvm_var_name pi2_mvm_var_name pkg_slot_verminmax_mvm_var_name pkg_slots_mvm_var_name
    pkg=${1}; shift
    pi1_mvm_var_name=${1}; shift
    pi2_mvm_var_name=${1}; shift
    pkg_slot_verminmax_mvm_var_name=${1}; shift
    pkg_slots_mvm_var_name=${1}; shift

    local ccfp_slot_version1_map_name ccfp_slot_version2_map_name
    mvm_get "${pi1_mvm_var_name}" "${pkg}" ccfp_slot_version1_map_name
    mvm_get "${pi2_mvm_var_name}" "${pkg}" ccfp_slot_version2_map_name

    local -A empty_map
    empty_map=()

    local -n slot_version1_map="${ccfp_slot_version1_map_name:-empty_map}"
    local -n slot_version2_map="${ccfp_slot_version2_map_name:-empty_map}"

    local ccfp_slots_set_name
    mvm_get "${pkg_slots_mvm_var_name}" "${pkg}" ccfp_slots_set_name
    local -n slots_set_ref="${ccfp_slots_set_name}"

    local -a profile_1_slots profile_2_slots common_slots
    profile_1_slots=()
    profile_2_slots=()
    common_slots=()

    local ccfp_profile_1 ccfp_profile_2
    pkginfo_profile "${pi1_mvm_var_name}" ccfp_profile_1
    pkginfo_profile "${pi2_mvm_var_name}" ccfp_profile_2

    local s v1 v2 ccfp_min ccfp_max mm ccfp_slots_name
    for s in "${!slots_set_ref[@]}"; do
        v1=${slot_version1_map["${s}"]:-}
        v2=${slot_version2_map["${s}"]:-}
        mm

        if [[ -n ${v1} ]] && [[ -n ${v2} ]]; then
            common_slots+=( "${s}" )
            if [[ ${v1} != ${v2} ]]; then
                pkg_warn \
                    "- version mismatch:" \
                    "  - package ${pkg}" \
                    "  - slot ${s}" \
                    "  - profile 1: ${ccfp_profile_1}" \
                    "    - version: ${v1}" \
                    "  - profile 1: ${ccfp_profile_2}" \
                    "    - version: ${v2}"
            fi
            ver_min_max ccfp_min ccfp_max "${v1}" "${v2}"
            mm="${ccfp_min}:${ccfp_max}"
        elif [[ -n ${v1} ]]; then
            # only side1 has the slot
            profile_1_slots+=( "${s}" )
            mm="${v1}:${v1}"
        elif [[ -n ${v2} ]]; then
            # only side 2 has the slot
            profile_2_slots+=( "${s}" )
            mm="${v2}:${v2}"
        else
            continue
        fi

        mvm_add "${pkg_slot_verminmax_mvm_var_name}" "${pkg}" "${s}" "${mm}"
    done
    if [[ ${#common_slots[@]} -gt 0 ]]; then
        if [[ ${#profile_1_slots[@]} -gt 0 ]] || [[ ${#profile_2_slots[@]} -gt 0 ]]; then
            pkg_warn \
                "- suspicious:" \
                "  - package ${pkg}" \
                "  - profile 1: ${ccfp_profile_1}" \
                "  - profile 2: ${ccfp_profile_2}" \
                "  - common slots: ${common_slots[*]}" \
                "  - slots only in profile 1: ${profile_1_slots[*]}" \
                "  - slots only in profile 2: ${profile_2_slots[*]}" \
                "  - what: there are slots that exist only on one profile while both profiles also have some common slots"
        fi
    fi
}

# consistency checks between:
# not yet: amd64 sdk <-> arm64 sdk
# amd64 sdk <-> amd64 board
# not yet: arm64 sdk <-> arm64 board
# amd64 board <-> arm64 board
function consistency_checks() {
    local which all_pkgs_var_name pkg_slots_mvm_var_name pkg_slot_verminmax_mvm_var_name
    which=${1}; shift
    all_pkgs_var_name=${1}; shift
    local -n all_pkgs_ref="${all_pkgs_var_name}"
    pkg_slots_mvm_var_name=${1}; shift
    pkg_slot_verminmax_mvm_var_name=${1}; shift

    local cc_pi1_name cc_pi2_name pkg

    # amd64 sdk <-> amd64 board
    pkginfo_name "${which}" amd64 "${SDK_PKGS}" cc_pi1_name
    pkginfo_name "${which}" amd64 "${BOARD_PKGS}" cc_pi2_name
    mvm_declare cc_amd64_sdk_board_pkg_slot_verminmax mvm_mvc_map
    for pkg in "${all_pkgs_ref[@]}"; do
        consistency_check_for_package "${pkg}" "${cc_p1_name}" "${cc_pi2_name}" cc_amd64_sdk_board_pkg_slot_verminmax "${pkg_slots_mvm_var_name}"
    done

    # amd64 board <-> arm64 board
    pkginfo_name "${which}" amd64 "${BOARD_PKGS}" cc_pi1_name
    pkginfo_name "${which}" arm64 "${BOARD_PKGS}" cc_pi2_name
    mvm_declare cc_amd64_arm64_board_pkg_slot_verminmax mvm_mvc_map
    for pkg in "${all_pkgs_ref[@]}"; do
        consistency_check_for_package "${pkg}" "${cc_p1_name}" "${cc_pi2_name}" cc_amd64_arm64_board_pkg_slot_verminmax "${pkg_slots_mvm_var_name}"
    done

    local cc_slot_verminmax1_map_name cc_slot_verminmax2_map_name
    local cc_slots_set_name s verminmax1 verminmax2 cc_min cc_max verminmax
    local -A empty_map
    empty_map=()
    for pkg in "${all_pkgs_ref[@]}"; do
        mvm_get cc_amd64_sdk_board_pkg_slot_verminmax "${pkg}" cc_slot_verminmax1_map_name
        mvm_get cc_amd64_arm64_board_pkg_slot_verminmax "${pkg}" cc_slot_verminmax2_map_name
        mvm_get "${pkg_slots_mvm_var_name}" "${pkg}" cc_slots_set_name
        local -n slot_verminmax1_map_ref="${cc_slot_verminmax1_map_name:-empty_map}"
        local -n slot_verminmax2_map_ref="${cc_slot_verminmax2_map_name:-empty_map}"
        local -n slots_set_ref="${cc_slots_set_name}"
        for s in "${!slots_set_ref[@]}"; do
            verminmax1=${slot_verminmax1_map_ref["${s}"]:-}
            verminmax2=${slot_verminmax2_map_ref["${s}"]:-}
            if [[ -n "${verminmax1}" ]] && [[ -n "${verminmax2}" ]]; then
                ver_min_max \
                    cc_min cc_max \
                    "{verminmax1%%:*}" "${verminmax1##*:}" "{verminmax2%%:*}" "${verminmax2##*:}"
                verminmax="${cc_min}:${cc_max}"
            elif [[ -n "${verminmax1}" ]]; then
                verminmax="${verminmax1}"
            elif [[ -n "${verminmax2}" ]]; then
                verminmax="${verminmax2}"
            else
                continue
            fi
            mvm_add "${pkg_slot_verminmax_mvm_var_name}" "${pkg}" "${S}" "${verminmax}"
        done
        unset -n slots_set_ref slot_verminmax2_map_ref slot_verminmax1_map_ref
    done
    mvm_unset cc_amd64_arm64_board_pkg_slot_verminmax
    mvm_unset cc_amd64_sdk_board_pkg_slot_verminmax
}

function handle_package_changes() {
    local changed_packages_set_var_name
    changed_packages_set_var_name=${1}; shift
    local -n changed_packages_set_ref="${changed_packages_set_var_name}"

    local -a hpc_all_pkgs

    mvm_declare hpc_pkg_slots_mvm mvm_mcv_set
    read_reports hpc_all_pkgs hpc_pkg_slots_mvm

    mvm_declare hpc_old_pkg_slot_verminmax_mvm mvm_mvc_map
    mvm_declare hpc_new_pkg_slot_verminmax_mvm mvm_mvc_map
    consistency_checks old hpc_all_pkgs hpc_pkg_slots_mvm hpc_old_pkg_slot_verminmax_mvm
    consistency_checks new hpc_all_pkgs hpc_pkg_slots_mvm hpc_new_pkg_slot_verminmax_mvm

    # TODO: renamed_map_o_n and renamed_map_n_o, globals?
    local pkg other
    local -a old_pkgs new_pkgs
    old_pkgs=()
    new_pkgs=()
    for pkg in "${hpc_all_pkgs[@]}"; do
        other=${renamed_map_o_n["${pkg}"]:-}
        if [[ -n "${other}" ]]; then
            old_pkgs+=("${pkg}")
            new_pkgs+=("${other}")
            continue
        fi
        other=${renamed_map_n_o["${pkg}"]:-}
        if [[ -n "${other}" ]]; then
            continue
        fi
        old_pkgs+=("${pkg}")
        new_pkgs+=("${pkg}")
    done

    local pkg_idx
    pkg_idx=0

    local old_name new_name
    local hpc_old_slots_set_name hpc_new_slots_set_name
    local hpc_old_slot_verminmax_map_name hpc_new_slot_verminmax_map_name
    local s hpc_old_s hpc_new_s
    local old_verminmax new_verminmax
    local old_version new_version
    local hpc_cmp_result
    local -A hpc_only_old_slots_set hpc_only_new_slots_set hpc_common_slots_set
    local -a lines
    while [[ ${pkg_idx} -lt ${#old_pkgs[@]} ]]; do
        old_name=${old_pkgs["${pkg_idx}"]}
        new_name=${new_pkgs["${pkg_idx}"]}
        mvm_get hpc_pkg_slots_mvm "${old_name}" hpc_old_slots_set_name
        mvm_get hpc_pkg_slots_mvm "${new_name}" hpc_new_slots_set_name
        local -n hpc_old_slots_set_ref="${hpc_old_slots_set_name}"
        local -n hpc_new_slots_set_ref="${hpc_new_slots_set_name}"
        mvm_get hpc_old_pkg_slot_verminmax_mvm "${old_name}" hpc_old_slot_verminmax_map_name
        mvm_get hpc_new_pkg_slot_verminmax_mvm "${new_name}" hpc_new_slot_verminmax_map_name
        local -n old_slot_verminmax_map_ref="${hpc_old_slot_verminmax_map_name}"
        local -n new_slot_verminmax_map_ref="${hpc_new_slot_verminmax_map_name}"
        hpc_only_old_slots_set=()
        hpc_only_new_slots_set=()
        hpc_common_slots_set=()
        sets_split \
            hpc_old_slots_set_ref hpc_new_slots_set_ref \
            hpc_only_old_slots_set hpc_only_new_slots_set hpc_common_slots_set
        for s in "${!hpc_common_slots_set[@]}"; do
            old_verminmax=${old_slot_verminmax_map_ref["${s}"]:-}
            new_verminmax=${new_slot_verminmax_map_ref["${s}"]:-}
            if [[ -z "${old_verminmax}" ]] || [[ -z "${new_verminmax}" ]]; then
                devel_warn \
                    "- no minmax info available for old and/or new:" \
                    "  - old package: ${old_name}" \
                    "    - slot: ${s}" \
                    "    - minmax: ${old_verminmax}" \
                    "  - new package: ${new_name}" \
                    "    - slot: ${s}" \
                    "    - minmax: ${new_verminmax}"
                continue
            fi
            old_version=${old_verminmax%%:*}
            new_version=${new_verminmax##*:}
            gentoo_ver_cmp_out "${new_version}" "${old_version}" hpc_cmp_result
            case ${hpc_cmp_result} in
                ${GV_GT})
                    handle_pkg_update "${old_name}" "${new_name}" "${s}" "${s}" "${old_version}" "${new_version}"
                    ;;
                ${GV_EQ})
                    handle_pkg_as_is "${old_name}" "${new_name}" "${s}" "${s}" "${old_version}"
                    ;;
                ${GV_LT})
                    handle_pkg_downgrade "${old_name}" "${new_name}" "${s}" "${s}" "${old_version}" "${new_version}"
                    ;;
            esac
            if [[ ${hpc_cmp_result} != ${GV_EQ} ]]; then
                changed_packages_set_ref["${pkg}"]=x
            fi
        done
        if [[ ${#hpc_only_old_slots_set[@]} -eq 1 ]] && [[ ${#hpc_only_new_slots_set[@]} -eq 1 ]]; then
            get_nth_from_set 0 hpc_only_old_slots_set hpc_old_s
            old_verminmax=${old_slot_verminmax_map_ref["${hpc_old_s}"]:-}
            get_nth_from_set 0 hpc_only_new_slots_set hpc_new_s
            new_verminmax=${new_slot_verminmax_map_ref["${hpc_new_s}"]:-}
            if [[ -z "${old_verminmax}" ]] || [[ -z "${new_verminmax}" ]]; then
                devel_warn \
                    "- no verminmax info available for old and/or new:" \
                    "  - old package: ${old_name}" \
                    "    - slot: ${hpc_old_s}" \
                    "    - minmax: ${old_verminmax}" \
                    "  - new package: ${new_name}" \
                    "    - slot: ${hpc_new_s}" \
                    "    - minmax: ${new_verminmax}"
                continue
            fi
            old_version=${old_verminmax%%:*}
            new_version=${new_verminmax##*:}
            gentoo_ver_cmp_out "${new_version}" "${old_version}" hpc_cmp_result
            case ${hpc_cmp_result} in
                ${GV_GT})
                    handle_pkg_update "${old_name}" "${new_name}" "${hpc_old_s}" "${hpc_new_s}" "${old_version}" "${new_version}"
                    ;;
                ${GV_EQ})
                    handle_pkg_as_is "${old_name}" "${new_name}" "${hpc_old_s}" "${hpc_new_s}" "${old_version}"
                    ;;
                ${GV_LT})
                    handle_pkg_downgrade "${old_name}" "${new_name}" "${hpc_old_s}" "${hpc_new_s}" "${old_version}" "${new_version}"
                    ;;
            esac
            if [[ ${hpc_cmp_result} != ${GV_EQ} ]]; then
                changed_packages_set_ref["${pkg}"]=x
            fi
        else
            lines=(
                '- handle package update:'
                '  - old package name:'
                "    - name: ${old_name}"
                '    - slots:'
            )
            for s in "${!hpc_old_slots_set_ref[@]}"; do
                old_verminmax=${old_slot_verminmax_map_ref["${s}"]:-}
                lines+=("      - ${s}, minmax: ${old_verminmax}")
            done
            lines+=(
                '  - new package name:'
                "    - name: ${new_name}"
                '    - slots:'
            for s in "${!hpc_new_slots_set_ref[@]}"; do
                new_verminmax=${new_slot_verminmax_map_ref["${s}"]:-}
                lines+=("      - ${s}, minmax: ${new_verminmax}")
            done
            manual "${lines[@]}"
        fi
        unset -n new_slot_verminmax_map_ref old_slot_verminmax_map_ref hpc_new_slots_set_ref hpc_old_slots_set_ref
    done
}

function get_nth_from_set() {
    local idx set_name return_var_name
    idx=${1}; shift
    set_var_name=${1}; shift
    local -n set_ref="${set_var_name}"
    return_var_name=${1}; shift
    local -n return_ref="${return_var_name}"

    local iter item
    iter=0
    for item in "${!set_ref[@]}"; do
        if [[ ${iter} -eq ${idx} ]]; then
            return_ref=${item}
            return 0
        fi
        iter=$((iter + 1))
    done
    return_ref=''
}

function sets_split() {
    local first_set_var_name second_set_var_name only_in_first_set_var_name only_in_second_set_var_name common_set_var_name
    first_set_var_name=${1}; shift
    local -n first_set_ref="${first_set_var_name}"
    second_set_var_name=${1}; shift
    local -n second_set_ref="${second_set_var_name}"
    only_in_first_set_var_name=${1}; shift
    local -n only_in_first_set_ref="${only_in_first_set_var_name}"
    only_in_second_set_var_name=${1}; shift
    local -n only_in_second_set_ref="${only_in_second_set_var_name}"
    common_set_var_name=${1}; shift
    local -n common_set_ref="${common_set_var_name}"

    only_in_first_set_ref=()
    only_in_second_set_ref=()
    common_set_ref=()

    local item mark

    for item in "${!first_set_ref[@]}"; do
        mark=${second_set_ref["${item}"]:-}
        if [[ -z "${mark}" ]]; then
            only_in_first_set_ref["${item}"]=x
        else
            common_set_ref["${item}"]=x
        fi
    done

    for item in "${!second_set_ref[@]}"; do
        mark=${first_set_ref["${item}"]:-}
        if [[ -z "${mark}" ]]; then
            only_in_second_set_ref["${item}"]=x
        fi
    done
}

function handle_pkg_update() {
    local old_pkg new_pkg old_s new_s old new
    old_pkg=${1}; shift
    new_pkg=${1}; shift
    old_s=${1}; shift
    new_s=${1}; shift
    old=${1}; shift
    new=${1}; shift

    local old_no_r new_no_r
    old_no_r=${old%-r+([0-9])}
    new_no_r=${new%-r+([0-9])}

    local pkg_name
    pkg_name=${new_pkg#/}
    local -a lines
    lines=( "from ${old} to ${new}")
    if [[ ${old_pkg} != ${new_pkg} ]]; then
        lines+=( "renamed from ${old_pkg}" )
    fi
    # TODO: old_portage_stable and portage_stable should be globals
    generate_ebuild_diff "${old_portage_stable}" "${portage_stable}" "${old_pkg}" "${new_pkg}" "${old_s}" "${new_s}" "${old}" "${new}"
    local hpu_update_dir
    update_dir "${new_pkg}" "${old_s}" "${new_s}" hpu_update_dir
    if [[ ! -s "${hpu_update_dir}/diff" ]]; then
        lines+=( 'no changes in ebuild' )
    fi
    if gentoo_ver_test "${new_no_r}" -gt "${old_no_r}"; then
        # version bump
        generate_changelog_entry_stub "${pkg_name}" "${new_no_r}"
        lines+=( 'release notes: TODO' )
    fi

    local -a tags
    tags=()
    tags_for_pkg "${new_pkg}" tags
    generate_summary_stub "${new_pkg}" "${tags[@]}" -- "${lines[@]}"

    # TODO: new state should be a global?
    generate_package_report "${new_state}" "${old_pkg}" "${new_pkg}" "${old_s}" "${new_s}"
}

function handle_pkg_as_is() {
    local old_pkg new_pkg old_s new_s v
    old_pkg=${1}; shift
    new_pkg=${1}; shift
    old_s=${1}; shift
    new_s=${1}; shift
    v=${1}; shift

    local pkg_name
    pkg_name=${new_pkg#/}
    local -a lines
    lines=( "still at ${v}" )
    if [[ ${old_pkg} != ${new_pkg} ]]; then
        lines+=( "renamed from ${old_pkg}" )
    fi
    # TODO: old_portage_stable and portage_stable should be globals
    generate_ebuild_diff "${old_portage_stable}" "${portage_stable}" "${old_pkg}" "${new_pkg}" "${old_s}" "${new_s}" "${v}" "${v}"
    local hpai_update_dir
    update_dir "${new_pkg}" "${old_s}" "${new_s}" hpai_update_dir
    if [[ ! -s "${hpai_update_dir}/diff" ]]; then
        lines+=( 'no changes in ebuild' )
    fi

    local -a tags
    tags=()
    tags_for_pkg "${pkg}" tags
    generate_summary_stub "${new_pkg}" "${tags[@]}" -- "${lines[@]}"

    # TODO: new state should be a global?
    generate_package_report "${new_state}" "${old_pkg}" "${new_pkg}" "${old_s}" "${new_s}"
}

function handle_pkg_downgrade() {
    local old_pkg new_pkg old_s new_s old new
    old_pkg=${1}; shift
    new_pkg=${1}; shift
    old_s=${1}; shift
    new_s=${1}; shift
    old=${1}; shift
    new=${1}; shift

    local old_no_r new_no_r
    old_no_r=${old%-r+([0-9])}
    new_no_r=${new%-r+([0-9])}

    local pkg_name
    pkg_name=${new_pkg#/}
    local -a lines
    lines=( "downgraded from ${old} to ${new}" )
    if [[ ${old_pkg} != ${new_pkg} ]]; then
        lines+=( "renamed from ${old_pkg}" )
    fi
    # TODO: old_portage_stable and portage_stable should be globals
    generate_ebuild_diff "${old_portage_stable}" "${portage_stable}" "${old_pkg}" "${new_pkg}" "${old_s}" "${new_s}" "${old}" "${new}"
    local hpd_update_dir
    update_dir "${new_pkg}" "${old_s}" "${new_s}" hpd_update_dir
    if [[ ! -s "${hpd_update_dir}/diff" ]]; then
        lines+=( 'no changes in ebuild' )
    fi
    if gentoo_ver_test "${new_no_r}" -lt "${old_no_r}"; then
        # version bump
        generate_changelog_entry_stub "${pkg_name}" "${new_no_r}"
        lines+=( "release notes: TODO" )
    fi

    local -a tags
    tags=()
    tags_for_pkg "${new_pkg}" tags
    generate_summary_stub "${new_pkg}" "${tags[@]}" -- "${lines[@]}"

    # TODO: new state should be a global?
    generate_package_report "${new_state}" "${old_pkg}" "${new_pkg}" "${old_s}" "${new_s}"
}

function tags_for_pkg() {
    # TODO
}

function generate_changelog_entry_stub() {
    local pkg_name v
    pkg_name=${1}
    v=${1}

    printf '- %s ([%s](TODO))\n' "${pkg_name}" "${v}" >>"${WORKDIR}/updates/changelog_stubs"
}

function generate_summary_stub() {
    local pkg
    pkg=${1}; shift

    local -a tags
    tags=()
    while [[ ${#} -gt 0 ]]; do
        if [[ ${1} = '--' ]]; then
            shift
            break
        fi
        tags+=( "${1}" )
        shift
    done
    # rest are lines

    {
        printf '- %s:' "{pkg}"
        printf ' [%s]' "${tags[@]}"
        printf '\n'
        printf '  - %s\n' "${@}"
        printf '\n'
    } >>"${WORKDIR}/updates/summary_stubs"
}

function generate_ebuild_diff() {
    local old_ps new_ps old_pkg new_pkg old_s new_s old new
    old_ps=${1}; shift
    new_ps=${1}; shift
    old_pkg=${1}; shift
    new_pkg=${1}; shift
    old_s=${1}; shift
    new_s=${1}; shift
    old=${1}; shift
    new=${1}; shift

    local old_pkg_name new_pkg_name
    old_pkg_name=${old_pkg#/}
    new_pkg_name=${new_pkg#/}

    local old_path new_path
    old_path="${old_ps}/${old_pkg}/${old_pkg_name}-${old}.ebuild"
    new_path="${new_ps}/${new_pkg}/${new_pkg_name}-${new}.ebuild"

    local ged_update_dir
    update_dir "${new_pkg}" "${old_s}" "${new_s}" ged_update_dir
    xdiff "${old_path}" "${new_path}" >"${ged_update_dir}/diff"
}

function generate_package_report() {
    local scripts old_pkg new_pkg old_s new_s
    scripts=${1}; shift
    old_pkg=${1}; shift
    new_pkg=${1}; shift
    old_s=${1}; shift
    new_s=${1}; shift

    local gpr_update_dir
    update_dir "${new_pkg}" "${old_s}" "${new_s}" gpr_update_dir

    generate_package_report_at_location "${scripts}" "${new_pkg}" "${gpr_update_dir}/occurences"

    if [[ ${old_pkg} != ${new_pkg} ]]; then
        generate_package_report_at_location "${scripts}" "${old_pkg}" "${gpr_update_dir}/occurences-for-old-name"
    fi
}

function generate_package_report_at_location() {
    local scripts old_pkg new_pkg
    scripts=${1}; shift
    pkg=${1}; shift
    report=${1}; shift

    local ps co
    ps='sdk_container/src/third_party/portage-stable'
    co='sdk_container/src/third_party/coreos-overlay'

    yell "${pkg} in overlay profiles"
    grep_pkg "${scripts}" "${pkg}" "${co}/profiles"

    yell "${pkg} in gentoo profiles"
    grep_pkg "${scripts}" "${pkg}" "${ps}/profiles"

    yell "${pkg} in env overrides"
    (
        shopt -s nullglob
        cd "${scripts}/${co}"
        cat_entries "sdk_container/src/third_party/coreos-overlay/coreos/config/env/${pkg}"?(-+([0-9])*)
    )

    yell "${pkg} in user patches"
    (
        shopt -s nullglob
        cd "${scripts}/${co}"
        for dir in "sdk_container/src/third_party/coreos-overlay/coreos/user-patches/${pkg}"?(-+([0-9])*); do
            echo "BEGIN DIRECTORY: ${dir}"
            cat_entries "${dir}"/*
            echo "END DIRECTORY: ${dir}"
        done
    )

    yell "${pkg} in overlay (outside profiles)"
    grep_pkg "${scripts}" "${pkg}" "${ps}" ":(exclude)${ps}/profiles"

    yell "${pkg} in gentoo (outside profiles)"
    grep_pkg "${scripts}" "${pkg}" "${co}" ":(exclude)${co}/profiles"

    yell "${pkg} in scripts"
    grep_pkg "${scripts}" "${pkg}" ":(exclude)${ps}/profiles" ":(exclude)${co}/profiles"
}

function update_dir() {
    local pkg old_s new_s dir_var_name
    pkg=${1}; shift
    old_s=${1}; shift
    new_s=${1}; shift
    dir_var_name=${1}; shift
    local -n dir_ref="${dir_var_name}"

    # slots may have slashes in them - replace them with "-slash-"
    local slot_dir
    if [[ ${old_s} = ${new_s} ]]; then
        slot_dir="${old_s//\//-slash-}"
    else
        slot_dir="${old_s//\//-slash-}-to-${new_s//\//-slash-}"
    fi
    dir_ref="${WORKDIR}/updates/${pkg}/${slot_dir}"
}

function grep_pkg() {
    local scripts pkg
    scripts=${1}; shift
    pkg=${1}; shift
    # rest are directories

    git -C "${scripts}" grep "${pkg}"'\(-[0-9]\|[^-]\|$\)' -- "${@}"
}

function cat_entries() {
    for entry; do
        echo "BEGIN ENTRY: ${entry}"
        cat "${entry}"
        echo "END ENTRY: ${entry}"
    done
}

handle_package_changes

old_portage_stable="${old_state}/${portage_stable_suffix}"
for entry in "${updated[@]}"; do
    case "${entry}" in
        eclass/*)
            mkdir -p "${WORKDIR}/updates/${entry}"
            diff "${old_portage_stable}/${entry}" "${portage_stable}/${entry}" >"${WORKDIR}/updates/${entry}/diff"
            ;;
        profiles)
            handle_profiles
            ;;
        licenses)
            dropped=()
            added=()
            changed=()
            # Only in move-openssh/sdk_container/src/third_party/portage-stable/licenses: BSL-1.1
            # Files move-openssh/sdk_container/src/third_party/portage-stable/licenses/BSL-1.1 and main/sdk_container/src/third_party/portage-stable/licenses/BSL-1.1 differ
            while read -r line; do
                if [[ ${line} = 'Only in '* ]]; then
                    if [[ ${line} = *"${old_state}"* ]]; then
                        dropped+=( "${line##*:}" )
                    elif [[ ${line} = *"${new_state}"* ]]; then
                        added+=( "${line##*:}" )
                    else
                        devel_warn "- unhandled license change: ${line}"
                    fi
                elif [[ ${line} = 'Files '*' differ' ]]; then
                    line=${line##"Files ${old_portage_stable}/licenses/"}
                    line=${line%% *}
                    changed+=( "${line}" )
                fi
            done < <(xdiff --brief --recursive "${old_portage_stable}/licenses" "${portage_stable}/licenses")
            ;;
        scripts)
            mkdir -p "${WORKDIR}/updates/scripts"
            xdiff --unified --recursive "${old_portage_stable}/scripts" "${portage_stable}/scripts" >"${WORKDIR}/updates/scripts/diff"
            ;;
        metadata)
            fail "not handling metadata updates"
        *)
            :
            ;;
    esac
done

function handle_profiles() {
    local arch which report line
    local -a files
    files=()
    for arch in "${ARCHES[@]}"; do
        for which in "${WHICH[@]}"; do
            for report in sdk-profiles board-profiles; do
                files+=("${WORKDIR}/pkg-reports/${which}-${arch}/${report}")
            done
        done
    done
    local line
    local -A profile_dirs
    profile_dirs_set=()
    while read -r line; do
        profile_dirs_set["${line}"]=x
    done < <(grep --no-filename '^portage-stable:' "${files[@]}" | cut -d: -f2-)

    local -a diff_opts
    diff_opts=(
        --recursive
        --unified
        --new-file  # treat absent files as empty
    )
    local out_dir
    out_dir "${WORKDIR}/updates/profiles"
    mkdir -p "${out_dir}"
    xdiff "${diff_opts[@]}" \
         "${old_portage_stable}/profiles" "${portage_stable}/profiles" >"${out_dir}/full-diff"
    local path dir file mark local relevant
    local -a relevant_lines possibly_irrelevant_files
    relevant=''
    relevant_lines=()
    possibly_irrelevant_files=()
    while read -r line; do
        if [[ ${line} = "diff ${diff_opts[*]} "* ]]; then
            path=${line##*"${portage_stable}/profiles/"}
            dirname_out "${path}" dir
            relevant=''
            mark=${profile_dirs_set["${dir}"]}
            if [[ -n "${mark}" ]]; then
                relevant=x
            else
                case ${dir} in
                    .|desc|desc/*|updates|updates/*)
                        relevant=x
                        ;;
                esac
            fi
            if [[ -z ${relevant} ]]; then
                possibly_irrelevant_files+=( "profiles/${path}" )
            fi
        fi
        if [[ -n ${relevant} ]]; then
            relevant_lines+=( "${line}" )
        fi
    done
    lines_to_file "${out_dir}/relevant-diff" "${relevant_lines[@]}"
    lines_to_file "${out_dir}/possibly-irrelevant-files" "${possibly_irrelevant_files}"
}

function xdiff() {
    diff "${@}" || :
}

git -C "${scripts}" branch "${branch_name}" "${new_state_branch}"
