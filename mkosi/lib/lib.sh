#!/bin/bash
# Sourced by every hook. Strict mode covers only this file: the caller's options
# are restored at the end, since some build_library functions fail under -u.
# $- rather than "$(set +o)": command substitution reports -e as unset.
__libsh_caller_opts="$-"
__libsh_caller_pipefail="$(shopt -po pipefail)"
set -euo pipefail

# mkosi's ARCHITECTURE to the Flatcar board name.
sdk_board() {
  local arch="${ARCHITECTURE:?ARCHITECTURE must be set by mkosi}"
  case "${arch}" in
    x86-64|x86_64|amd64) echo "amd64-usr" ;;
    arm64|aarch64)       echo "arm64-usr" ;;
    *) echo "unsupported architecture: ${arch}" >&2; exit 1 ;;
  esac
}

export SDK_SCRIPTS="/mnt/host/source/src/scripts"

# build_image's --base_sysexts default, one "name|pkg[&pkg...]" per line.
# build_image refuses root, so read its --help as nobody (the SDK has no runuser).
sdk_base_sysexts() {
  local help list
  help="$(cd "${SDK_SCRIPTS}" && chroot --userspec=nobody:nobody --skip-chdir / ./build_image --help 2>&1)"
  list="$(sed -n "/--base_sysexts:/,/(default:/ s/.*(default: '\(.*\)')\$/\1/p" <<<"${help}")"
  [[ -n "${list}" ]] || die "No --base_sysexts default in '${SDK_SCRIPTS}/build_image --help' output"
  tr ',' '\n' <<<"${list}"
}

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
export BUILD_LIBRARY_DIR="${SDK_SCRIPTS}/build_library"
export BOARD="$(sdk_board)"
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
. "${SDK_SCRIPTS}/common.sh"
set -u "${_sdk_errexit}"
unset _sdk_errexit
# Order as in build_image: sbsign_util.sh needs toolchain_util.sh at load time.
. "${SDK_SCRIPTS}/build_library/toolchain_util.sh" # for get_board_arch, get_sdk_libdir
. "${SDK_SCRIPTS}/build_library/board_options.sh" # for pkg_version, pkg_use_enabled
. "${SDK_SCRIPTS}/build_library/build_image_util.sh"
. "${SDK_SCRIPTS}/build_library/prod_image_util.sh"
. "${SDK_SCRIPTS}/build_library/test_image_content.sh"
. "${SDK_SCRIPTS}/build_library/vm_image_util.sh" # for _write_qemu_uefi_conf

# After the sources, which reset DISTDIR to a host path not bound in the sandbox.
export DISTDIR="/work/src/distfiles"
export PORTAGE_DEPCACHEDIR="/work/src/edb-dep"

[[ "${MKOSI_DEBUG:-0}" == "1" ]] && set -x

die() {
  echo "ERROR: $*" >&2
  exit 1
}

# The image's portage configroot, as start_image() sets it up. BUILD_DIR is per
# mkosi run, so hooks that run without the prepare step (cached base) need it too.
setup_configroot() {
  mkdir -p "${BUILD_DIR}"/configroot/etc/portage/profile
  ln -sfn "${BOARD_ROOT}"/etc/portage/make.* \
      "${BOARD_ROOT}"/etc/portage/package.* \
      "${BOARD_ROOT}"/etc/portage/patches \
      "${BOARD_ROOT}"/etc/portage/repos.conf \
      "${BUILD_DIR}"/configroot/etc/portage/

  set_image_profile "${FLATCAR_IMAGE_PROFILE}"
}

create_configroot() {
  update_group="$1"
  # build_image_util.sh start_image()

  setup_configroot

  # First thing first, install baselayout to create a working filesystem.
  mkosi-install --nodeps --oneshot --update sys-apps/baselayout

  # We need the libc ASAP to execute binaries from the ROOT at install time, but
  # the dependency is implicit, so explicitly install.
  mkosi-install --oneshot --update virtual/libc

  # Set /etc/lsb-release on the image.
  "${BUILD_LIBRARY_DIR}/set_lsb_release" \
    --root="${BUILDROOT}" \
    --group="${update_group}" \
    --board="${BOARD}"
}

# Install the board's binpkgs into $BUILDROOT, like emerge_to_image. Portage's
# sandboxes are off: hooks already run in mkosi's.
sdk_emerge() {
    local board config_args
    board="$(sdk_board)"
    root="${BUILDROOT:?BUILDROOT must be set by mkosi}"
    # Not emerge-${board}: it forces PORTAGE_CONFIGROOT to the board root.
    # Image: prod configroot (emerge_to_image); sysext: board config (build_sysext).
    if [[ "$(jq -r .Format "${MKOSI_CONFIG}")" == sysext ]]; then
        config_args=(--config-root="/build/${board}" --sysroot="/build/${board}")
    else
        config_args=(--config-root="${BUILD_DIR}/configroot")
    fi

    # Drop mkosi's /scripts shims from PATH (see sdk_clean_path).
    local clean_path
    clean_path="$(sdk_clean_path)"

    "${SDK_ENV_SCRUB[@]}" \
    ROOT="${BUILDROOT}" \
    PATH="${clean_path}" \
    FEATURES="-ebuild-locks -merge-wait -sandbox -usersandbox -network-sandbox -pid-sandbox -ipc-sandbox" \
        emerge --root="${BUILDROOT}" "${config_args[@]}" "$@"
}

# emerge_to_image()'s flags, for the tools/bin/mkosi-* helpers.
sdk_emerge_binpkg() {
    sdk_emerge --usepkgonly --binpkg-respect-use=y --jobs="${NUM_JOBS}" --verbose "$@"
}

# mkosi's /scripts groupadd/useradd shims add --root, which clashes with the
# acct-* eclasses' own --prefix.
sdk_clean_path() {
  printf '%s' "${PATH}" | tr ':' '\n' | grep -vx '/scripts' | paste -sd: -
}

# mkosi's script variables break ebuild phases (SRCDIR breaks vim's configure).
SDK_ENV_SCRUB=(env -u SRCDIR -u CHROOT_SRCDIR -u DESTDIR -u CHROOT_DESTDIR
               -u PACKAGEDIR -u ARTIFACTDIR)

# Build into the board sysroot as build_packages does (its flags), leaving
# binpkgs for sdk_emerge. The board's FEATURES already include buildpkg.
# An edited ebuild needs an -rN bump to be rebuilt.
emerge_from_source() {
    local board
    board="$(sdk_board)"

    local binpkg_args=()
    if [ "${FLATCAR_ALLOW_REMOTE_BINPKGS:-1}" = 1 ]; then
        binpkg_args=(--getbinpkg)
    fi

    # build_packages: never rebuild the toolchain behind a source build.
    local binonly_args
    read -r -a binonly_args <<<"$(get_binonly_args)"

    "${SDK_ENV_SCRUB[@]}" \
    DISTDIR="${DISTDIR}" \
    PATH="$(sdk_clean_path)" \
    KBUILD_BUILD_USER="${BUILD_USER:-build}" \
    KBUILD_BUILD_HOST="${BUILD_HOST:-pony-truck.infra.kinvolk.io}" \
    FEATURES="-ebuild-locks -merge-wait -sandbox -usersandbox -network-sandbox -pid-sandbox -ipc-sandbox${FEATURES:+ ${FEATURES}}" \
        "emerge-${board}" \
        "--update" \
        "--deep" \
        "--newuse" \
        "--verbose" \
        "--backtrack=30" \
        "--select" \
        "--usepkg" \
        "--with-bdeps=n" \
        "${binonly_args[@]}" \
        "${binpkg_args[@]}" \
        "--jobs=22" \
        "$@"
}

eval "${__libsh_caller_pipefail}"
set +eu
if [[ ${__libsh_caller_opts} == *e* ]]; then set -e; fi
if [[ ${__libsh_caller_opts} == *u* ]]; then set -u; fi
unset __libsh_caller_opts __libsh_caller_pipefail
