#!/bin/bash

set -euo pipefail

readonly SDK_OUTER_TOPDIR="${HOME}/flatcar-sdk"
readonly SDK_OUTER_SRCDIR="${SDK_OUTER_TOPDIR}/src"
readonly SDK_INNER_SRCDIR="/mnt/host/source/src"

readonly BUILDBOT_USERNAME="Flatcar Buildbot"
readonly BUILDBOT_USEREMAIL="buildbot@flatcar-linux.org"

function enter() ( cd ../../..; exec cork enter -- $@ )

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
  git config user.name "${BUILDBOT_USERNAME}"
  git config user.email "${BUILDBOT_USEREMAIL}"
  git reset --hard HEAD
  git fetch origin
  git checkout -B "${BASE_BRANCH}" "origin/${BASE_BRANCH}"
}

# caller needs to set pass a parameter as a branch name to be created.
function checkout_branches() {
  TARGET_BRANCH=$1

  [[ -z "${TARGET_BRANCH}" ]] && echo "No target branch specified. exit." && return 1

  git -C "${SDK_OUTER_SRCDIR}/scripts" checkout -B "${BASE_BRANCH}" "github/${BASE_BRANCH}"
  git -C "${SDK_OUTER_SRCDIR}/third_party/portage-stable" checkout -B "${BASE_BRANCH}" "github/${BASE_BRANCH}"

  if git -C "${SDK_OUTER_SRCDIR}/third_party/coreos-overlay" show-ref "remotes/github/${TARGET_BRANCH}"; then
    echo "Target branch already exists. exit.";
    return 1
  fi

  git -C "${SDK_OUTER_SRCDIR}/third_party/coreos-overlay" checkout -B "${TARGET_BRANCH}" "github/${BASE_BRANCH}"
}

function regenerate_manifest() {
  CATEGORY_NAME=$1
  PKGNAME_SIMPLE=$2
  pushd "${SDK_OUTER_SRCDIR}/third_party/coreos-overlay" >/dev/null || exit
  enter ebuild "${SDK_INNER_SRCDIR}/third_party/coreos-overlay/${CATEGORY_NAME}/${PKGNAME_SIMPLE}/${PKGNAME_SIMPLE}-${VERSION_NEW}.ebuild" manifest --force
  popd || exit
}

function generate_patches() {
  CATEGORY_NAME=$1
  PKGNAME_SIMPLE=$2
  PKGNAME_DESC=$3
  shift 3
  local dir

  pushd "${SDK_OUTER_SRCDIR}/third_party/coreos-overlay" >/dev/null || exit

  enter ebuild "${SDK_INNER_SRCDIR}/third_party/coreos-overlay/${CATEGORY_NAME}/${PKGNAME_SIMPLE}/${PKGNAME_SIMPLE}-${VERSION_NEW}.ebuild" manifest --force

  # We can only create the actual commit in the actual source directory, not under the SDK.
  # So create a format-patch, and apply to the actual source.
  git add ${CATEGORY_NAME}/${PKGNAME_SIMPLE}
  for dir in "$@"; do
      git add "${dir}"
  done
  git commit -a -m "${CATEGORY_NAME}: Upgrade ${PKGNAME_DESC} ${VERSION_OLD} to ${VERSION_NEW}"

  # Create a patch for the main ebuilds.
  git format-patch -1 HEAD
  popd || exit
}

function apply_patches() {
  git am "${SDK_OUTER_SRCDIR}"/third_party/coreos-overlay/0*.patch
  rm -f "${SDK_OUTER_SRCDIR}"/third_party/coreos-overlay/0*.patch
}
