#!/bin/bash
# Portage configroot and emerge helpers for the prepare hooks.
. "${SRCDIR}/lib/sdk-env.sh"

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
  emerge_to_buildroot --nodeps --oneshot --update sys-apps/baselayout

  # We need the libc ASAP to execute binaries from the ROOT at install time, but
  # the dependency is implicit, so explicitly install.
  emerge_to_buildroot --oneshot --update virtual/libc

  # Set /etc/lsb-release on the image.
  "${BUILD_LIBRARY_DIR}/set_lsb_release" \
    --root="${BUILDROOT}" \
    --group="${update_group}" \
    --board="${BOARD}"
}

# Install the board's binpkgs into $BUILDROOT with emerge_to_image()'s flags.
# Portage's sandboxes are off: hooks already run in mkosi's.
emerge_to_buildroot() {
    local config_args
    # Not emerge-${BOARD}: it forces PORTAGE_CONFIGROOT to the board root.
    # Image: prod configroot (emerge_to_image); sysext: board config (build_sysext).
    if [[ "$(jq -r .Format "${MKOSI_CONFIG}")" == sysext ]]; then
        config_args=(--config-root="${BOARD_ROOT}" --sysroot="${BOARD_ROOT}")
    else
        config_args=(--config-root="${BUILD_DIR}/configroot")
    fi

    "${MKOSI_ENV_SCRUB[@]}" \
    ROOT="${BUILDROOT:?BUILDROOT must be set by mkosi}" \
    PATH="$(path_without_mkosi_scripts)" \
    FEATURES="-ebuild-locks -merge-wait -sandbox -usersandbox -network-sandbox -pid-sandbox -ipc-sandbox" \
        emerge --root="${BUILDROOT}" "${config_args[@]}" \
            --usepkgonly --binpkg-respect-use=y --jobs="${NUM_JOBS}" --verbose "$@"
}

# mkosi's /scripts groupadd/useradd shims add --root, which clashes with the
# acct-* eclasses' own --prefix.
path_without_mkosi_scripts() {
  printf '%s' "${PATH}" | tr ':' '\n' | grep -vx '/scripts' | paste -sd: -
}

# mkosi's script variables break ebuild phases (SRCDIR breaks vim's configure).
MKOSI_ENV_SCRUB=(env -u SRCDIR -u CHROOT_SRCDIR -u DESTDIR -u CHROOT_DESTDIR
               -u PACKAGEDIR -u ARTIFACTDIR)

# Build into the board sysroot as build_packages does (its flags), leaving
# binpkgs for emerge_to_buildroot. The board's FEATURES already include buildpkg.
# An edited ebuild needs an -rN bump to be rebuilt.
emerge_to_board() {
    local binpkg_args=()
    if [ "${FLATCAR_ALLOW_REMOTE_BINPKGS:-1}" = 1 ]; then
        binpkg_args=(--getbinpkg)
    fi

    # build_packages: never rebuild the toolchain behind a source build.
    local binonly_args
    read -r -a binonly_args <<<"$(get_binonly_args)"

    "${MKOSI_ENV_SCRUB[@]}" \
    DISTDIR="${DISTDIR}" \
    PATH="$(path_without_mkosi_scripts)" \
    KBUILD_BUILD_USER="${BUILD_USER:-build}" \
    KBUILD_BUILD_HOST="${BUILD_HOST:-pony-truck.infra.kinvolk.io}" \
    FEATURES="-ebuild-locks -merge-wait -sandbox -usersandbox -network-sandbox -pid-sandbox -ipc-sandbox${FEATURES:+ ${FEATURES}}" \
        "emerge-${BOARD}" \
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
