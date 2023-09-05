#!/bin/bash

##
## Used for syncing with gentoo. Needs to be called from the
## toplevel-directory of portage-stable. Expects the actual gentoo repo
## to be either in ../gentoo or ../../gentoo.
##
## Parameters:
## -h: this help
## -b: be brief, print only names of changed entries and errors
##
## Positional:
## 0: Gentoo repository
## #: Entries to update (can be a package name, eclass, category, some special
##    directories like profiles or . for everything)
##
## Example invocations:
##
## sync_with_gentoo -h
##
##   Print a help message.
##
## sync_with_gentoo dev-libs/nettle app-crypt/argon2
##
##   This will update the packages, each in a separate commit. The
##   commit message will contain the commit hash from gentoo repo.
##
## sync_with_gentoo dev-libs
##
##   This will update all the packages in dev-libs category. The
##   commit message will contain the commit hash from gentoo repo.
##

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/stuff.sh"

BRIEF=

while true; do
    case ${1} in
        -h)
            print_help
            exit 0
            ;;
        -b)
            BRIEF=x
            shift
            ;;
        --)
            shift
            break
            ;;
        -*)
            fail "unknown flag '${1}'"
            ;;
        *)
            break
            ;;
    esac
done

if [[ $# -lt 2 ]]; then
    fail 'expected at least two positional parameters: a Gentoo repository and at least one package'
fi

if [[ ! -e 'profiles/repo_name' ]]; then
    fail 'sync is only possible from ebuild packages top-level directory (a directory from which "./profiles/repo_name" is accessible)'
fi

function vcall() {
    if [[ -z ${BRIEF} ]]; then
        "${@}"
    fi
}

function bcall() {
    if [[ -n ${BRIEF} ]]; then
        "${@}"
    fi
}

GENTOO=$(realpath "${1}"); shift
# rest are package names

if [[ $(realpath '.') = "${GENTOO}" ]]; then
    fail 'trying to sync within a Gentoo repo?'
fi

# returns:
# - 0 (true) if there are changes
# - 1 (false) if there are no changes
function sync_git_prepare() {
    local path
    path=${1}; shift

    local gentoo_path
    gentoo_path="${GENTOO}/${path}"

    if [[ ! -e "${gentoo_path}" ]]; then
        info "no '${path}' in Gentoo repository"
        return 1
    fi

    rm -rf "${path}"
    local parent
    dirname_out "${path}" parent
    mkdir --parents "${parent}"
    cp --archive "${gentoo_path}" "${parent}"
    if [[ -n $(git status --porcelain -- "${path}") ]]; then
        bcall info "updated ${path}"
        git add "${path}"
        return 0
    fi
    return 1
}

function commit_with_gentoo_sha() {
    local path name sync
    path=${1}; shift
    name=${1}; shift
    sync=${1:-}; shift

    local commit commit_msg
    commit=$(git -C "${GENTOO}" log --pretty=oneline -1 -- "${path}" | cut -f1 -d' ')
    commit_msg="${name}: Add from Gentoo"
    if [[ -n "${sync}" ]]; then
        commit_msg="${name}: Sync with Gentoo"
    fi
    git commit --quiet --message "${commit_msg}" --message "It's from Gentoo commit ${commit}."
    GIT_PAGER='cat' vcall git show --stat
}

function path_sync() {
    local path name
    path=${1}; shift
    name=${1}; shift

    local sync
    sync=''
    if [[ -e "${path}" ]]; then
        sync='x'
    fi

    if sync_git_prepare "${path}"; then
        commit_with_gentoo_sha "${path}" "${name}" "${sync}"
    else
        vcall info "no changes in ${path}"
    fi
}

function prepare_dir() {
    local dir
    dir=${1}; shift

    local pkg mod
    for pkg in "${dir}/"*; do
        if sync_git_prepare "${pkg}"; then
            mod=x
        fi
    done
    if [[ -n ${mod} ]]; then
        return 0
    fi
    return 1
}

function category_sync() {
    local path
    path=${1}; shift

    if [[ ! -e "${path}" ]]; then
        if sync_git_prepare "${path}"; then
            commit_with_gentoo_sha "${path}" "${path}"
        fi
    else
        if prepare_dir "${path}"; then
            commit_with_gentoo_sha "${path}" "${path}" 'x'
        fi
    fi

}

function everything_sync() {
    local path mod

    for path in *; do
        case ${path} in
            licenses|eclass|profiles)
                if sync_git_prepare "${path}"; then
                    mod=x
                fi
                ;;
            scripts)
                # ignore for now
                :
                ;;
            metadata)
                # do only metadata updates
                if sync_git_prepare metadata/glsa; then
                    mod=x
                fi
                ;;
            virtual/*-*)
                if prepare_dir "${path}"; then
                    mod=x
                fi
                ;;
            *)
                # likely a changelog, README.md or somesuch, ignore
                :
                ;;
        esac
    done
    if [[ -n ${mod} ]]; then
        commit_with_gentoo_sha '.' '*' 'x'
    fi
}

shopt -s extglob

for cpn; do
    cpn=${cpn%%*(/)}
    case ${cpn} in
        .)
            everything_sync
            ;;
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
