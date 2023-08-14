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
## LISTINGS_DIR: Copy listings from that directory to worktree. If the
## variable is empty, or the directory does not exist, download them
## itself.
##

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
        updated+=("${package}")
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
# maps new name to old name
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

if [[ -n "${LISTINGS_DIR:-}" ]]; then
    cp -a "${LISTINGS_DIR}" "${WORKDIR}/listings"
else
    flatcar_version=$(source /usr/share/flatcar/os-release; echo "${VERSION}")
    "${this_dir}/download-listings.sh" "${flatcar_version}" "${WORKDIR}/listings"
fi
add_cleanup "rm -rf ${WORKDIR@Q}/listings"

declare -A state_map
declare -A profile_map
state_map=(
    ['old']="${old_state}"
    ['new']="${new_state}"
)
profile_map=(
    ['sdk']='coreos/@ARCH@/sdk'
    ['generic']='coreos/@ARCH@/generic'
)

function for_all_rootfses {
    local callback=${1}

    for state in old new; do
        for profile in sdk generic; do
            for arch in arm64 amd64; do
                rootfs="${WORKDIR}/rootfses/${state}-${profile}-${arch}"
                "${callback}" "${rootfs}" "${state}" "${profile}" "${arch}"
            done
        done
    done
}

function setup_rootfs {
    local rootfs=${1}; shift
    local state=${1}; shift
    local profile=${1}; shift
    local arch=${1}; shift

    mkdir "${WORKDIR}/rootfses/${rootfs}"
    add_cleanup "rmdir ${rootfs@Q}"
    mkdir -p "${rootfs}"{/etc/portage/repos.conf,stuff/{dist,logs/{emerge,portage},pkgs,tmp}}
    add_cleanup "rm -rf ${rootfs@Q}/stuff"/{dist,logs/{emerge,portage},pkgs,tmp}
    add_cleanup "rmdir ${rootfs@Q}"/{etc{/portage{/repos.conf,},},stuff{/logs,}}
    cat >"${rootfs}/etc/portage/make.conf" <<EOF
DISTDIR="${rootfs}/stuff/dist"
PKGDIR="${rootfs}/stuff/pkgs"
EMERGE_LOG_DIR="${rootfs}/stuff/logs/emerge"
PORTAGE_TMPDIR="${rootfs}/stuff/tmp"
PORTAGE_LOGDIR="${rootfs/stuff/logs/portage
EOF
    state_dir=${state_map["${state}"]}
    add_cleanup "rm -f ${rootfs@Q}/etc/portage/make.conf"
    profile_dir=${profile_map["${profile}"]//'@ARCH@'/"${arch}"}
    ln -sfTr "${state_dir}/sdk_container/src/third_party/coreos-overlay/profiles/${profile_dir}" "${rootfs}/etc/portage/make.profile"
    add_cleanup "rm -f ${rootfs@Q}/etc/portage/make.profile"
    cat >"${rootfs}/etc/portage/repos.conf/flatcar.conf" <<EOF
[DEFAULT]
main-repo = portage-stable

[coreos]
location = ${state_dir}/sdk_container/src/third_party/coreos-overlay

[portage-stable]
location = ${state_dir}/sdk_container/src/third_party/portage-stable
EOF
    add_cleanup "rm -f ${rootfs@Q}/etc/portage/repos.conf/flatcar.conf"
}

mkdir -p "${WORKDIR}/rootfses"
add_cleanup "rmdir ${WORKDIR@Q}/rootfses"
for_all_rootfses setup_rootfs

updated_pkgs=()
# collect old versions of packages:
for entry in "${updated[@]}"; do
    case "${package}" in
        eclass/*|profiles|licenses|scripts)
            :
            ;;
        *)
            updated_pkgs+=("${entry}")
            declare -A all_old_versions
            all_old_versions=()
            function get_version {
                local rootfs=${1}; shift
                local state=${1}; shift
                local profile=${1}; shift
                local arch=${1}; shift

                emerge --config-root="${rootfs}" --root="${rootfs}" --sysroot="${rootfs}" --oneshot --pretend --color n --columns --nodeps --nospinner "${entry}"
            }
            ;;
    esac
done

function get_old_versions {
    local rootfs=${1}; shift
    local state=${1}; shift
    local profile=${1}; shift
    local arch=${1}; shift
    local old_updated_pkgs=()
    local pkg old_name line

    for pkg in "${updated_pkgs[@]}"; do
        old_name=${renamed_map_n_o["${pkg}"]:-"${pkg}"}
        old_updated_pkgs+=("${old_name}")
    done

    while read -r line; do
        '  R    sys-libs/glibc 2.36-r5 to /build/amd64-usr/'
        ' N     app-portage/portage-utils 0.95 to /build/amd64-usr/'
        ' N     sys-apps/portage 3.0.44-r1 to /build/amd64-usr/'

    done < <(emerge --config-root="${rootfs}" --root="${rootfs}" --sysroot="${rootfs}" --oneshot --pretend --color n --columns --nodeps --nospinner --quiet "${old_updated_pkgs[@]}")
}

for_all_rootfses get_old_versions

old_portage_stable="${old_state}/${portage_stable_suffix}"
for entry in "${updated[@]}"; do
    case "${package}" in
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
            declare -A all_old_versions
            all_old_versions=()
            function get_version {
                local rootfs=${1}; shift
                local state=${1}; shift
                local profile=${1}; shift
                local arch=${1}; shift

                emerge --config-root="${rootfs}" --root="${rootfs}" --sysroot="${rootfs}" --oneshot --pretend --color n --columns --nodeps --nospinner "${entry}"
            }
            ;;
    esac
done

git -C "${scripts}" branch "${branch_name}" "${new_state_branch}"
