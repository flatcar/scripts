#!/bin/bash

# Used for syncing with gentoo. Needs to be called from the
# toplevel-directory of portage-stable. Expects the actual gentoo repo
# to be either in ../gentoo or ../../gentoo.
#
# Example invocations:
#
# sync-with-gentoo --help
#
#   Print a help message.
#
# sync-with-gentoo dev-libs/nettle app-crypt/argon2
#
#   This will update the packages, each in a separate commit. The
#   commit message will contain the commit hash from gentoo repo.
#
# sync-with-gentoo dev-libs
#
#   This will update all the packages in dev-libs category.
#

set -euo pipefail

fail() {
    printf '%s\n' "$*" >&2
    exit 1
}

declare -a GLOBAL_extra_git_commit_options=()
GLOBAL_single_commit=''
declare -a GLOBAL_obsolete_packages=()
GLOBAL_gentoo_repo="${GENTOO_REPO:-../gentoo}"
GLOBAL_amend_mode=''

while true; do
    case "${1}" in
        '--help'|'-h')
            echo "${0} [OPTIONS] CATEGORY[/PACKAGE_NAME] [CATEGORY[/PACKAGE_NAME] […]]"
            echo 'OPTIONS:'
            echo '  --help|-h: Print this help and quit'
            echo '  --message|-m: Additional messages for commits, will be passed to git commit --message, can be specified many times'
            echo '  --amend-mode|-a: Updates commit message to use the new used hash sum of the commit.'
            echo '  --single-commit: Lump all the changes under a single commit'
            echo
            echo 'ENVIRONMENT VARIABLES:'
            echo '  GENTOO_REPO: Path to the Gentoo repo, from which the script syncs stuff.'
            echo
            exit 0
            ;;
        '--message'|'-m')
            GLOBAL_extra_git_commit_options+=(--message "${2}")
            shift 2
            ;;
        '--amend-mode'|'-a')
            GLOBAL_amend_mode=1
            shift
            ;;
        '--single-commit'|'-s')
            GLOBAL_single_commit='x'
            shift
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
        git commit \
            --quiet \
            "${@}" \
            "${GLOBAL_extra_git_commit_options[@]}"
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
    mkdir --parents "$(dirname ${path})"
    cp --archive "${gentoo_path}" "$(dirname ${path})"
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

    if [[ -z "${GLOBAL_single_commit}" ]]; then
        local do_amend=''
        local do_add=''
        if [[ -n "${GLOBAL_amend_mode}" ]]; then
            local subject

            subject="$(git log -1 --pretty=format:%s)"
            if [[ "${subject}" = "${name}:"* ]]; then
                do_amend=1
            fi
            if [[ "${subject}" = *'Add from Gentoo'* ]]; then
                do_add=1
            fi
        fi
        local commit=''
        local commit_msg=''
        local amend_args=()
        if [[ -n "${do_amend}" ]]; then
            amend_args+=(--amend --no-edit)
        fi
        commit=$(git -C "${GLOBAL_gentoo_repo}" log --pretty=oneline -1 -- "${path}" | cut -f1 -d' ')
        commit_msg="${name}: Add from Gentoo"
        if [[ -n "${sync}" ]] && [[ -z "${do_add}" ]]; then
            commit_msg="${name}: Sync with Gentoo"
        fi
        if ! commit_and_show \
             "${amend_args[@]}" \
             --message "${commit_msg}" \
             --message "It's from Gentoo commit ${commit}."; then
            echo "no changes in ${path}"
        fi
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

if [[ -n "${GLOBAL_single_commit}" ]]; then
    if ! commit_and_show \
         --message '*: Sync with Gentoo'; then
        echo 'no changes made'
    fi
fi

if [[ ${#GLOBAL_obsolete_packages[@]} -gt 0 ]]; then
    echo
    echo 'the following packages are obsolete (not found in gentoo repo):'
    printf '  %s\n' "${GLOBAL_obsolete_packages[@]}"
    echo
fi

echo
echo 'done'
echo
