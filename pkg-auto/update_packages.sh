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

set -euo pipefail

set -x

this=${0}
this_name=${this##*/}

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

function escape {
    local var what
    var=${1}
    what=${2}
    printf -v "${var}" '%q' "${what}"
}

# Escapes the value from the passed variable name and puts it into
# <variable_name>_esc.
#
# Example:
#   stuff='…'
#   esc stuff
#   echo ${stuff_esc}
function esc {
    local var_name_to_esc var_esc
    var_name_to_esc=${1}
    var_esc="${var_name_to_esc}_esc"
    escape "${var_esc}" "${!var_name_to_esc}"
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

esc scripts

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

esc WORKDIR
add_cleanup "rmdir ${WORKDIR_esc}"

bot_name='Flatcar Buildbot'
bot_email='buildbot@flatcar-linux.org'

old_state_branch="old-state-${RANDOM}"
old_state="${WORKDIR}/old_state"
new_state_branch="new-state-${RANDOM}"
new_state="${WORKDIR}/new_state"

esc old_state
esc new_state
esc old_state_branch
esc new_state_branch

git -C "${scripts}" worktree add -b "${old_state_branch}" "${old_state}" "${SCRIPTS_BASE}"
git -C "${scripts}" worktree add -b "${new_state_branch}" "${new_state}" "${SCRIPTS_BASE}"

add_cleanup \
    "git -C ${scripts_esc} worktree remove ${old_state_esc}" \
    "git -C ${scripts_esc} worktree remove ${new_state_esc}" \
    "git -C ${scripts_esc} branch -D ${old_state_branch}" \
    "git -C ${scripts_esc} branch -D ${new_state_branch}"

updated=()
missing_in_scripts=()
missing_in_gentoo=()

git -C "${new_state}" config user.name "${bot_name}"
git -C "${new_state}" config user.email "${bot_email}"

packages_list=$(realpath "${new_state}/.github/workflows/portage-stable-packages-list")
pushd "${new_state}/sdk_container/src/third_party/portage-stable"
sync_script="${new_state}/pkg-auto/sync-with-gentoo.sh"
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

git -C "${scripts}" branch "${branch_name}" "${new_state_branch}"
