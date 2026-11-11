#!/bin/bash
# SDK environment every hook needs: board variables, sandbox mounts and the
# build_library sources. Sourced once, also via emerge.sh and image.sh.
[[ -n "${_SDK_ENV_SOURCED:-}" ]] && return 0
_SDK_ENV_SOURCED=1

# Where common.sh would put it too.
SCRIPTS_DIR="/mnt/host/source/src/scripts"

# The toolchain and board config hardcode /build. A bind, not a symlink: the
# board's relative make.profile symlink only resolves at the original depth.
if [[ ! -e /build ]]; then
  mkdir -p /build
  mount --bind /work/src/build /build
fi

# The kernel config hardcodes MODULE_SIG_KEY at the SDK's key path, so the
# BuildSources= mount has to appear there too.
if [[ -n "${MODULE_SIGNING_KEY_DIR:-}" && -d /work/src/module-signing-keys ]] \
    && ! mountpoint -q "${MODULE_SIGNING_KEY_DIR}"; then
  mkdir -p "${MODULE_SIGNING_KEY_DIR}"
  mount --bind /work/src/module-signing-keys "${MODULE_SIGNING_KEY_DIR}"
fi

# mkosi's nsswitch.conf lacks `usrfiles`, which hides the baselayout users that
# source builds chown to.
if ! grep -q usrfiles /etc/nsswitch.conf 2>/dev/null; then
  mount --bind /usr/share/baselayout/nsswitch.conf /etc/nsswitch.conf
fi

export PATH="${PATH}:/usr/local/sbin/"
export BUILD_LIBRARY_DIR="${SCRIPTS_DIR}/build_library"
# mkosi's ARCHITECTURE to the Flatcar board name.
case "${ARCHITECTURE:?ARCHITECTURE must be set by mkosi}" in
  x86-64) export BOARD=amd64-usr ;;
  arm64)  export BOARD=arm64-usr ;;
  *) echo "ERROR: unsupported architecture ${ARCHITECTURE}" >&2; exit 1 ;;
esac
export BOARD_ROOT="/build/${BOARD}"
export FLAGS_version="$IMAGE_VERSION"
export FLAGS_output_root="${ARTIFACTDIR?ARTIFACTDIR must be set by mkosi}/"
export FLAGS_board="${BOARD}"
export FLAGS_group="$FLATCAR_UPDATE_GROUP"
# Not exported, like upstream: BUILD_DIR is also an ebuild variable, and ours
# would override it in ebuild phases.
BUILD_DIR="${FLAGS_output_root}/${BOARD}/${FLAGS_group}-${FLAGS_version}"

NUM_JOBS=0
GCLIENT_ROOT=''
COMMON_SH=''
# common.sh's tput colour probes fail under set -e without a capable TERM.
_sdk_errexit=+e; [[ $- == *e* ]] && _sdk_errexit=-e
set +eu
. "${SCRIPTS_DIR}/common.sh"
set -u "${_sdk_errexit}"
unset _sdk_errexit
# Order as in build_image: sbsign_util.sh needs toolchain_util.sh at load time.
. "${BUILD_LIBRARY_DIR}/toolchain_util.sh" # for get_board_arch, get_sdk_libdir
. "${BUILD_LIBRARY_DIR}/board_options.sh" # for pkg_version, pkg_use_enabled
. "${BUILD_LIBRARY_DIR}/build_image_util.sh"
. "${BUILD_LIBRARY_DIR}/prod_image_util.sh"
. "${BUILD_LIBRARY_DIR}/test_image_content.sh"
. "${BUILD_LIBRARY_DIR}/vm_image_util.sh" # for _write_qemu_uefi_conf

# After the sources, which reset DISTDIR to a host path not bound in the sandbox.
export DISTDIR="/work/src/distfiles"
export PORTAGE_DEPCACHEDIR="/work/src/edb-dep"

[[ "${MKOSI_DEBUG:-0}" == "1" ]] && set -x

die() {
  echo "ERROR: $*" >&2
  exit 1
}
