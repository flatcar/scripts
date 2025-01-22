#!/bin/bash

##
## Used for syncing with gentoo. Needs to be called from the
## toplevel-directory of portage-stable. If syncing everything or
## syncing metadata/glsa specifically, it is expected that the Gentoo
## repo will have the GLSA files stored in metadata/glsa too.
##
## Parameters:
## -h: this help
## -b: be brief, print only names of changed entries and errors
## -s: skip adding source git commit hash information to commits
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

source "$(dirname "${BASH_SOURCE[0]}")/util.sh"

BRIEF=
SKIP_GIT_INFO=

while true; do
    case ${1-} in
        -h)
            print_help
            exit 0
            ;;
        -b)
            BRIEF=x
            shift
            ;;
        -s)
            SKIP_GIT_INFO=x
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
    fail 'expected at least two positional parameters: a Gentoo repository and at least one package, use -h to print help'
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

if [[ -z ${SKIP_GIT_INFO} ]] && [[ ! -e ${GENTOO}/.git ]]; then
    info "Skipping adding source git commit hash information to commits, ${GENTOO@Q} is not a git repository"
    SKIP_GIT_INFO=x
fi

glsa_repo=${GENTOO}/metadata/glsa
if [[ -z ${SKIP_GIT_INFO} ]] && [[ -e ${glsa_repo} ]] && [[ ! -e ${glsa_repo}/.git ]] && [[ $(git -C "${GENTOO}" status --porcelain -- metadata/glsa) = '?? metadata/glsa' ]]; then
    info "Skipping adding source git commit hash information to commits, ${glsa_repo@Q} exists, but it is not a git repository and is not a part of Gentoo git repository"
    SKIP_GIT_INFO=x
fi
unset glsa_repo

# Synchronizes given path with its Gentoo counterpart. Returns true if
# there were changes.
#
# Params:
#
# 1 - path within ebuild repo
function sync_git_prepare() {
    local path
    path=${1}; shift

    local gentoo_path
    gentoo_path="${GENTOO}/${path}"

    if [[ ! -e "${gentoo_path}" ]]; then
        info "no ${path@Q} in Gentoo repository"
        if [[ ${path} = 'metadata/glsa' ]]; then
            info "did you forget to clone https://gitweb.gentoo.org/data/glsa.git/ into ${gentoo_path@Q}?"
        fi
        return 1
    fi

    local -a rsync_opts=( --archive --delete-before )

    case ${path} in
        profiles)
            rsync_opts+=( --exclude /profiles/repo_name )
            ;;
    esac

    local parent
    dirname_out "${path}" parent
    mkdir --parents "${parent}"
    rsync "${rsync_opts[@]}" "${gentoo_path}" "${parent}"
    if [[ -n $(git status --porcelain -- "${path}") ]]; then
        bcall info "updated ${path}"
        git add "${path}"
        return 0
    fi
    return 1
}

# Creates a git commit. If checking Gentoo commit ID is enabled the
# given path is used to get the ID of the commit with the last change
# in the path. Name parameter is used for denoting which part has
# changed, and sync parameter to denote if the commit is about adding
# new package or updating an existing one.
#
# Params:
#
# 1 - path
# 2 - name
# 3 - not empty if existing package was updated, or an empty string if
#     the package is new
function commit_with_gentoo_sha() {
    local path name sync
    path=${1}; shift
    name=${1}; shift
    sync=${1:-}; shift

    local -a commit_extra=()
    if [[ -z ${SKIP_GIT_INFO} ]]; then
        local commit

        commit=$(git -C "${GENTOO}" log --pretty=oneline -1 -- "${path}" | cut -f1 -d' ')
        commit_extra+=( --message "It's from Gentoo commit ${commit}." )
        unset commit
    fi
    commit_msg="${name}: Add from Gentoo"
    if [[ -n "${sync}" ]]; then
        commit_msg="${name}: Sync with Gentoo"
    fi
    git commit --quiet --message "${commit_msg}" "${commit_extra[@]}"
    GIT_PAGER='cat' vcall git show --stat
}

# Simple path sync and commit; takes the contents from Gentoo at the
# given path and puts it in the repo.
#
# 1 - path to sync
# 2 - name for commit message
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

# Goes over the given directory and syncs its subdirectories or
# files. No commit is created.
function prepare_dir() {
    local dir
    dir=${1}; shift

    local pkg mod=''
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

# Synces entire category of packages and creates a commit. Note that
# if the category already exists, no new packages will be added.
#
# Params:
#
# 1 - path to the category directory
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

# Synces entire repo. No new packages will be added.
function everything_sync() {
    local path mod

    for path in *; do
        case ${path} in
            licenses|profiles|scripts)
                if sync_git_prepare "${path}"; then
                    mod=x
                fi
                ;;
            metadata)
                # do only metadata updates
                if sync_git_prepare metadata/glsa; then
                    mod=x
                fi
                ;;
            eclass|virtual|*-*)
                if prepare_dir "${path}"; then
                    mod=x
                fi
                ;;
            changelog|*.md)
                # ignore those
                :
                ;;
            *)
                info "Unknown entry ${path@Q}, ignoring"
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
        licenses|profiles|scripts)
            path_sync "${cpn}" "${cpn}"
            ;;
        eclass/*.eclass)
            path_sync "${cpn}" "${cpn%.eclass}"
            ;;
        metadata/glsa)
            path_sync "${cpn}" "${cpn}"
            ;;
        metadata)
            fail "metadata directory can't be synced, did you mean metadata/glsa?"
            ;;
        virtual/*/*|*-*/*/*)
            fail "invalid thing to sync: ${cpn}"
            ;;
        virtual/*|*-*/*)
            path_sync "${cpn}" "${cpn}"
            ;;
        eclass|virtual|*-*)
            category_sync "${cpn}"
            ;;
        *)
            fail "invalid thing to sync: ${cpn}"
            ;;
    esac
done
