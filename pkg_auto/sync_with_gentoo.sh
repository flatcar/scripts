#!/bin/bash

# Used for syncing with gentoo. Needs to be called from the
# toplevel-directory of portage-stable. Expects the actual gentoo repo
# to be either in ../gentoo or ../../gentoo.
#
# Example invocations:
#
# sync_with_gentoo --help
#
#   Print a help message.
#
# sync_with_gentoo dev-libs/nettle app-crypt/argon2
#
#   This will update the packages, each in a separate commit. The
#   commit message will contain the commit hash from gentoo repo.
#
# sync_with_gentoo dev-libs
#
#   This will update all the packages in dev-libs category.
#

set -euo pipefail

fail() {
    printf '%s\n' "$*" >&2
    exit 1
}

declare -a GLOBAL_obsolete_packages=()
GLOBAL_gentoo_repo="${GENTOO_REPO:-../gentoo}"

while true; do
    case "${1}" in
        '--help'|'-h')
            echo "${0} [OPTIONS] CATEGORY[/PACKAGE_NAME] [CATEGORY[/PACKAGE_NAME] […]]"
            echo 'OPTIONS:'
            echo '  --help|-h: Print this help and quit'
            echo
            echo 'ENVIRONMENT VARIABLES:'
            echo '  GENTOO_REPO: Path to the Gentoo repo, from which the script syncs stuff.'
            echo
            exit 0
            ;;
        *)
            break
            ;;
    esac
done

if [[ $# -lt 1 ]]; then
    fail 'expected at least one package, try --help or -h'
fi

if [[ ! -e 'profiles/repo_name' ]]; then
    fail 'sync is only possible from ebuild packages top-level directory (a directory from which "./profiles/repo_name" is accessible)'
fi

if [[ ! -d "${GLOBAL_gentoo_repo}" ]]; then
    gentoo_repo_tmp='../../gentoo'
    if [[ ! -d "${gentoo_repo_tmp}" ]]; then
        fail "can't find Gentoo repo (tried ${GLOBAL_gentoo_repo} and ${gentoo_repo_tmp}), try using GENTOO_REPO environment variable"
    fi
    GLOBAL_gentoo_repo="${gentoo_repo_tmp}"
    unset -v gentoo_repo_tmp
fi

if [[ $(realpath '.') = $(realpath "${GLOBAL_gentoo_repo}") ]]; then
    fail 'trying to sync within a Gentoo repo?'
fi

echo "using Gentoo repo at ${GLOBAL_gentoo_repo}"

commit_and_show() {
    if [[ -n "$(git status --porcelain | grep -v '^ ')" ]]; then
        git commit --quiet "${@}"
        GIT_PAGER=cat git show --stat
        return 0
    fi
    return 1
}

sync_git_prepare() {
    local path="${1}"
    local sync=''
    local gentoo_path="${GLOBAL_gentoo_repo}/${path}"

    if [[ ! -e "${gentoo_path}" ]]; then
        GLOBAL_obsolete_packages+=("${path}")
        return 0
    fi

    if [[ -d "${path}" ]]; then
        git rm -r --force --quiet "${path}"
        sync='x'
    elif [[ -e "${path}" ]]; then
        git rm --force --quiet "${path}"
        sync='x'
    fi
    local parent
    parent=$(dirname ${path})
    mkdir --parents "${parent}"
    cp --archive "${gentoo_path}" "${parent}"
    git add "${path}"
    if [[ -n "${sync}" ]]; then
        return 1
    fi
    return 0
}

maybe_commit_with_gentoo_sha() {
    local path="${1}"
    local name="${2}"
    local sync="${3}"

    local commit=''
    local commit_msg=''
    commit=$(git -C "${GLOBAL_gentoo_repo}" log --pretty=oneline -1 -- "${path}" | cut -f1 -d' ')
    commit_msg="${name}: Add from Gentoo"
    if [[ -n "${sync}" ]]; then
        commit_msg="${name}: Sync with Gentoo"
    fi
    if ! commit_and_show \
         --message "${commit_msg}" \
         --message "It's from Gentoo commit ${commit}."; then
        echo "no changes in ${path}"
    fi
}

path_sync() {
    local path="${1}"
    local name="${2}"
    local sync=''

    if ! sync_git_prepare "${path}"; then
        sync='x'
    fi

    maybe_commit_with_gentoo_sha "${path}" "${name}" "${sync}"
}

category_sync() {
    local path="${1}"
    local sync=''

    if [[ ! -e "${path}" ]]; then
        sync_git_prepare "${path}" || :
    else
        local pkg=''
        for pkg in "${path}"/*; do
            sync_git_prepare "${pkg}" || :
        done
        sync='x'
    fi

    maybe_commit_with_gentoo_sha "${path}" "${path}" "${sync}"
}

for cpn; do
    while [[ "${cpn}" != "${cpn%/}" ]]; do
        cpn="${cpn%/}"
    done
    case "${cpn}" in
        licenses|eclass/tests|eclass|profiles|scripts)
            path_sync "${cpn}" "${cpn}"
            ;;
        eclass/*.eclass)
            path_sync "${cpn}" "${cpn%.eclass}"
            ;;
        metadata/glsa)
            path_sync "${cpn}" "${cpn}"
            ;;
        metadata)
            fail "metadata directory can't be synced"
            ;;
        virtual/*/*|*-*/*/*)
            fail "invalid thing to sync: ${cpn}"
            ;;
        virtual/*|*-*/*)
            path_sync "${cpn}" "${cpn}"
            ;;
        virtual|*-*)
            category_sync "${cpn}"
            ;;
        *)
            fail "invalid thing to sync: ${cpn}"
            ;;
    esac
done

if [[ ${#GLOBAL_obsolete_packages[@]} -gt 0 ]]; then
    echo
    echo 'the following packages are obsolete (not found in gentoo repo):'
    printf '  %s\n' "${GLOBAL_obsolete_packages[@]}"
    echo
fi

echo
echo 'done'
echo
