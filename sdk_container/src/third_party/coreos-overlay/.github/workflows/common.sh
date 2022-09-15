#!/bin/bash

set -euo pipefail

readonly SDK_OUTER_TOPSCRIPTSDIR="${HOME}/flatcar-sdk/scripts"
readonly SDK_OUTER_TOPDIR="${SDK_OUTER_TOPSCRIPTSDIR}/sdk_container"
readonly SDK_OUTER_SRCDIR="${SDK_OUTER_TOPDIR}/src"
readonly SDK_INNER_SRCDIR="/mnt/host/source/src"

readonly BUILDBOT_USERNAME="Flatcar Buildbot"
readonly BUILDBOT_USEREMAIL="buildbot@flatcar-linux.org"

function enter() {
  ${SDK_OUTER_TOPSCRIPTSDIR}/run_sdk_container -n "${PACKAGES_CONTAINER}" \
    -C "${SDK_NAME}" "$@"
}

# Return a valid ebuild file name for ebuilds of the given category name,
# package name, and the old version. If the single ebuild file already exists,
# then simply return that. If the file does not exist, then we should fall back
# to a similar file including $VERSION_OLD.
# For example, if VERSION_OLD == 1.0 and 1.0.ebuild does not exist, but only
# 1.0-r1.ebuild is there, then we figure out its most similar valid name by
# running "ls -1 ...*.ebuild | sort -ruV | head -n1".
function get_ebuild_filename() {
  local CATEGORY_NAME=$1
  local PKGNAME_SIMPLE=$2
  local VERSION_OLD=$3
  local EBUILD_BASENAME="${CATEGORY_NAME}/${PKGNAME_SIMPLE}/${PKGNAME_SIMPLE}-${VERSION_OLD}"

  if [ -f "${EBUILD_BASENAME}.ebuild" ]; then
    echo "${EBUILD_BASENAME}.ebuild"
  else
    echo "$(ls -1 ${EBUILD_BASENAME}*.ebuild | sort -ruV | head -n1)"
  fi
}

function prepare_git_repo() {
  # the original coreos-overlay repo outside the SDK container
  git config user.name "${BUILDBOT_USERNAME}"
  git config user.email "${BUILDBOT_USEREMAIL}"
  git reset --hard HEAD
  git fetch origin

  git checkout -B "${BASE_BRANCH}" "origin/${BASE_BRANCH}"

  # inside the SDK container
  git -C "${SDK_OUTER_SRCDIR}/third_party/coreos-overlay" config \
    user.name "${BUILDBOT_USERNAME}"
  git -C "${SDK_OUTER_SRCDIR}/third_party/coreos-overlay" config \
    user.email "${BUILDBOT_USEREMAIL}"
}

# caller needs to set pass a parameter as a branch name to be created.
function checkout_branches() {
  TARGET_BRANCH=$1
  CHECKOUT_SCRIPTS=$2

  [[ -z "${TARGET_BRANCH}" ]] && echo "No target branch specified. exit." && return 1

  # Check out the scripts repo only if CHECKOUT_SCRIPTS == true, due to
  # a corner case of its LTS-2021 branch does not have run_sdk_container.
  if [[ "${CHECKOUT_SCRIPTS}" = true ]]; then
    git -C "${SDK_OUTER_TOPSCRIPTSDIR}" checkout -B "${BASE_BRANCH}" \
      "origin/${BASE_BRANCH}"
  fi

  # update submodules like portage-stable under the scripts directories
  git submodule update --init --recursive

  if git -C "${SDK_OUTER_SRCDIR}/third_party/coreos-overlay" show-ref "remotes/origin/${TARGET_BRANCH}"; then
    echo "Target branch already exists. exit.";
    return 1
  fi

  # Each submodule directory should be explicitly set from BASE_BRANCH,
  # as the submodule refs could be only updated during the night.
  git -C "${SDK_OUTER_SRCDIR}/third_party/coreos-overlay" checkout \
    -B "${TARGET_BRANCH}" "origin/${BASE_BRANCH}"
  git -C "${SDK_OUTER_SRCDIR}/third_party/portage-stable" checkout \
    -B "${TARGET_BRANCH}" "origin/${BASE_BRANCH}"
}

function regenerate_manifest() {
  CATEGORY_NAME=$1
  PKGNAME_SIMPLE=$2
  pushd "${SDK_OUTER_SRCDIR}/third_party/coreos-overlay" >/dev/null || exit
  enter ebuild "${SDK_INNER_SRCDIR}/third_party/coreos-overlay/${CATEGORY_NAME}/${PKGNAME_SIMPLE}/${PKGNAME_SIMPLE}-${VERSION_NEW}.ebuild" manifest --force
  popd || exit
}

function join_by() {
  local delimiter="${1-}"
  local first="${2-}"
  if shift 2; then
    printf '%s' "${first}" "${@/#/${delimiter}}";
  fi
}

function generate_update_changelog() {
  local NAME="${1}"
  local VERSION="${2}"
  local URL="${3}"
  local UPDATE_NAME="${4}"
  shift 4
  local file="changelog/updates/$(date '+%Y-%m-%d')-${UPDATE_NAME}-${VERSION}-update.md"
  local -a old_links

  pushd "${SDK_OUTER_SRCDIR}/third_party/coreos-overlay" >/dev/null || exit
  if [[ -d changelog/updates ]]; then
    printf '%s %s ([%s](%s)' '-' "${NAME}" "${VERSION}" "${URL}" > "${file}"
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
  popd >/dev/null || exit
}

function generate_patches() {
  CATEGORY_NAME=$1
  PKGNAME_SIMPLE=$2
  PKGNAME_DESC=$3
  shift 3
  local dir

  pushd "${SDK_OUTER_SRCDIR}/third_party/coreos-overlay" >/dev/null || exit

  enter ebuild "${SDK_INNER_SRCDIR}/third_party/coreos-overlay/${CATEGORY_NAME}/${PKGNAME_SIMPLE}/${PKGNAME_SIMPLE}-${VERSION_NEW}.ebuild" \
    manifest --force

  # We can only create the actual commit in the actual source directory, not under the SDK.
  # So create a format-patch, and apply to the actual source.
  git add ${CATEGORY_NAME}/${PKGNAME_SIMPLE}
  if [[ -d changelog ]]; then
      git add changelog
  fi
  for dir in "$@"; do
      git add "${dir}"
  done
  git commit -a -m "${CATEGORY_NAME}: Upgrade ${PKGNAME_DESC} ${VERSION_OLD} to ${VERSION_NEW}"

  # Create a patch for the main ebuilds.
  git format-patch --start-number "${START_NUMBER:-1}" -1 HEAD
  popd || exit
}

function apply_patches() {
  git am "${SDK_OUTER_SRCDIR}"/third_party/coreos-overlay/0*.patch
  rm -f "${SDK_OUTER_SRCDIR}"/third_party/coreos-overlay/0*.patch
}
