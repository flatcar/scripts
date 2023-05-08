#!/bin/bash

function fail() {
  echo "$*" >/dev/stderr
  exit 1
}

if [[ -z "${WORK_SCRIPTS_DIR:-}" ]]; then
  fail "WORK_SCRIPTS_DIR env var unset. It should point to the scripts repo which will be updated."
fi

if [[ ! -d "${WORK_SCRIPTS_DIR:-}" ]]; then
  fail "WORK_SCRIPTS_DIR env var does not point to a directory. It should point to the scripts repo which will be updated."
fi

readonly SDK_OUTER_TOPDIR="${WORK_SCRIPTS_DIR}"
readonly SDK_OUTER_OVERLAY="${SDK_OUTER_TOPDIR}/sdk_container/src/third_party/coreos-overlay"
readonly SDK_INNER_SRCDIR="/mnt/host/source/src"
readonly SDK_INNER_OVERLAY="${SDK_INNER_SRCDIR}/third_party/coreos-overlay"

readonly BUILDBOT_USERNAME="Flatcar Buildbot"
readonly BUILDBOT_USEREMAIL="buildbot@flatcar-linux.org"

# This enters the SDK container and executes the passed commands
# inside it. Requires PACKAGES_CONTAINER and SDK_NAME to be defined.
function enter() {
  if [[ -z "${PACKAGES_CONTAINER}" ]]; then
    fail "PACKAGES_CONTAINER env var unset. It should contain the name of the SDK container."
  fi
  if [[ -z "${SDK_NAME}" ]]; then
    fail "SDK_NAME env var unset. It should contain the name of the SDK docker image."
  fi
  "${SDK_OUTER_TOPDIR}/run_sdk_container" \
      -n "${PACKAGES_CONTAINER}" \
      -C "${SDK_NAME}" \
      "${@}"
}

# Return a valid ebuild file name for ebuilds of the given category name,
# package name, and the old version. If the single ebuild file already exists,
# then simply return that. If the file does not exist, then we should fall back
# to a similar file including $VERSION_OLD.
# For example, if VERSION_OLD == 1.0 and 1.0.ebuild does not exist, but only
# 1.0-r1.ebuild is there, then we figure out its most similar valid name by
# running "ls -1 ...*.ebuild | sort -ruV | head -n1".
function get_ebuild_filename() {
  local pkg="${1}"; shift
  local version="${1}"; shift
  local name="${pkg##*/}"
  local ebuild_basename="${pkg}/${name}-${version}"

  if [[ ! -d "${pkg}" ]]; then
    fail "No such package in '${PWD}': '${pkg}'"
  fi
  if [ -f "${ebuild_basename}.ebuild" ]; then
    echo "${ebuild_basename}.ebuild"
  else
    ls -1 "${ebuild_basename}"*.ebuild | sort --reverse --unique --version-sort | head --lines 1
  fi
}

function prepare_git_repo() {
  git -C "${SDK_OUTER_TOPDIR}" config user.name "${BUILDBOT_USERNAME}"
  git -C "${SDK_OUTER_TOPDIR}" config user.email "${BUILDBOT_USEREMAIL}"
}

function check_remote_branch() {
  local target_branch="${1}"
  if git -C "${SDK_OUTER_TOPDIR}" ls-remote --refs --heads --exit-code origin "${target_branch}" >/dev/null; then
    return 1
  fi
  return 0
}

# Regenerates a manifest file using an ebuild of a given package with
# a given version.
#
# Example:
#   regenerate_manifest dev-lang/go 1.20.2
function regenerate_manifest() {
  local pkg="${1}"; shift
  local version="${1}"; shift
  local name="${pkg##*/}"
  local ebuild_file

  ebuild_file="${SDK_INNER_OVERLAY}/${pkg}/${name}-${version}.ebuild"
  enter ebuild "${ebuild_file}" manifest --force
}

function join_by() {
  local delimiter="${1-}"
  local first="${2-}"
  if shift 2; then
    printf '%s' "${first}" "${@/#/${delimiter}}";
  fi
}

# Generates a changelog entry. Usually the changelog entry is in a
# following form:
#
# - <name> ([<version>](<url>))
#
# Thus first three parameters of this function should be the name,
# version and URL. The changelog entries are files, so the fourth
# parameter is a name that will be a part of the filename. It often is
# a lower-case variant of the first parameter.
#
# Example:
#   generate_update_changelog Go 1.20.2 'https://go.dev/doc/devel/release#go1.20.2' go
#
# Sometimes there's a bigger jump in versions, like from 1.19.1 to
# 1.19.4, so it is possible to pass extra version and URL pairs for
# the intermediate versions:
#
#  generate_update_changelog Go 1.19.4 'https://go.dev/doc/devel/release#go1.19.4' go \
#      1.19.2 'https://go.dev/doc/devel/release#go1.19.2' \
#      1.19.3 'https://go.dev/doc/devel/release#go1.19.3'
function generate_update_changelog() {
    local name="${1}"; shift
    local version="${1}"; shift
    local url="${1}"; shift
    local update_name="${1}"; shift
    # rest of parameters are version and link pairs for old versions
    local file
    local -a old_links

    file="changelog/updates/$(date '+%Y-%m-%d')-${update_name}-${version}-update.md"

    pushd "${SDK_OUTER_TOPDIR}"

    if [[ -d changelog/updates ]]; then
        printf '%s %s ([%s](%s)' '-' "${name}" "${version}" "${url}" > "${file}"
        if [[ $# -gt 0 ]]; then
            echo -n ' (includes ' >> "${file}"
            while [[ $# -gt 1 ]]; do
                old_links+=( "[${1}](${2})" )
                shift 2
            done
            printf '%s' "$(join_by ', ' "${old_links[@]}")" >> "${file}"
            echo -n ')' >> "${file}"
        fi
        echo ')' >> "${file}"
    fi

    popd
}

# Regenerates manifest for given package, and commits changes made for
# that package. If there are new entries in changelog directory, these
# are committed too. Another two parameters are old and new versions
# of the package.
#
# Example:
#   commit_changes dev-lang/go 1.19.1 1.19.4
#
# Sometimes more files need to be added to the commit. In such cases
# extra paths can be specified and those will be passed to "git
# add". If an extra path is relative, it will be relative the overlay
# directory in the scripts repo. In order to use globs, it better to
# make sure that that absolute path is passed.
#
#   commit_changes dev-lang/go 1.19.1 1.19.4 \
#           some/extra/directory \
#           some/file \
#           "${PWD}/some/globs"*'-suffix'
function commit_changes() {
  local pkg="${1}"; shift
  local old_version="${1}"; shift
  local new_version="${1}"; shift
  # rest of parameters are additional directories to add to the commit
  local name="${pkg##*/}"

  regenerate_manifest "${pkg}" "${new_version}"

  pushd "${SDK_OUTER_TOPDIR}"

  if [[ -d changelog ]]; then
    git add changelog
  fi

  popd

  pushd "${SDK_OUTER_OVERLAY}"

  git add "${pkg}"
  for dir; do
    git add "${dir}"
  done
  git commit -m "${pkg}: Update from ${old_version} to ${new_version}"

  popd
}

# Prints the status of the git repo and cleans it up - reverts
# uncommitted changes, removes untracked files. It's usually called at
# the end of a script making changes to the repository in order to
# avoid unwanted changes to be a part of a PR created by the
# peter-evans/create-pull-request action that follows up.
function cleanup_repo() {
    git -C "${SDK_OUTER_TOPDIR}" status
    git -C "${SDK_OUTER_TOPDIR}" reset --hard HEAD
    git -C "${SDK_OUTER_TOPDIR}" clean -ffdx
}
