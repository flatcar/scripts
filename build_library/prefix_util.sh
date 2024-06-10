# Copyright (c) 2023 The Flatcar Maintainers. All rights reserved.
# Use of this source code is governed by the Apache 2.0 license.

DEFAULT_STAGING_ROOT="/build/"

function lineprepend() {
  awk -v msg="$*" '{ print msg ": " $0}'
}
# --

function set_prefix_vars() {
  local name="${1}"
  local prefix="${2}"

  EPREFIX="${prefix}"
  PREFIXNAME="${name}"
  STAGINGDIR="${FLAGS_staging_dir}"
  STAGINGROOT="${STAGINGDIR}/root"
  FINALDIR="${FLAGS_final_dir}"
  FINALROOT="${FINALDIR}/root"

  CB_ROOT="${FLAGS_cross_boss_root}"

  # the prefix profile enables unstable via MAKE_DEFAULTS; we don't want those.
  PREFIX_BOARD="${FLAGS_board}"
  case "${PREFIX_BOARD}" in
    amd64-usr)
      PREFIX_CHOST="x86_64-cros-linux-gnu"
      PREFIX_KEYWORDS="amd64 -~amd64"
      ;;
    arm64-usr)
      PREFIX_CHOST="aarch64-cros-linux-gnu"
      PREFIX_KEYWORDS="arm64 -~arm64"
      ;;
  esac

  export EPREFIX PREFIXNAME STAGINGDIR STAGINGROOT FINALDIR FINALROOT CB_ROOT \
          PREFIX_CHOST PREFIX_KEYWORDS PREFIX_BOARD
}
# --

function install_prereqs() {
  # Make sure cross-boss prerequisites are installed in the SDK
  local prefix_repo="${1}"

  sudo emerge --newuse sys-apps/bubblewrap
  sudo emerge --newuse -1 ">=dev-python/gpep517-15"

  # HACK ALERT: needed for cb-bootstrap to build the initial toolchain in staging.
  #             cb-bootstrap should be ported to use the prefix repos.conf instead.
  sudo cp -r "${prefix_repo}/skel/etc/portage/repos.conf" /usr/x86_64-cros-linux-gnu/etc/portage/
  sudo cp -r "${prefix_repo}/skel/etc/portage/repos.conf" /usr/aarch64-cros-linux-gnu/etc/portage/
}
# --

function setup_prefix_dirs() {
  local prefix_repo="${1}"
  sudo mkdir -v -p \
          "${STAGINGDIR}/logs" \
          "${STAGINGDIR}/pkgs" \
          "${STAGINGDIR}/tmp" \
          "${STAGINGROOT}${EPREFIX}/etc" \
          "${FINALDIR}/logs" \
          "${FINALDIR}/tmp" \
          "${FINALROOT}${EPREFIX}/etc"

  sudo cp -vR "${prefix_repo}/skel/etc/portage" "${STAGINGROOT}${EPREFIX}/etc/"
  sudo cp -vR "${prefix_repo}/skel/etc/portage" "${FINALROOT}${EPREFIX}/etc/"

  local profile="/mnt/host/source/src/third_party/portage-stable/profiles/default/linux"
  case "${PREFIX_BOARD}" in
    amd64-usr) profile="${profile}/amd64/17.1/no-multilib/prefix/kernel-3.2+";;
    arm64-usr) profile="${profile}/arm64/17.0/prefix/kernel-3.2+";;
  esac

  sudo ln -s "${profile}" "${STAGINGROOT}${EPREFIX}/etc/portage/make.profile"
  sudo ln -s "${profile}" "${FINALROOT}${EPREFIX}/etc/portage/make.profile"
}
# --

function extract_gcc_libs() {
  # GCC libs aren't available in a separate package but a full GCC install would make final too big
  # TODO: the below is effectively a copy of build_library/prod_image_util.sh::extract_prod_gcc()
  #       and should eventually be reconciled.
  gcc_ver="$(sudo -E PORTAGE_CONFIGROOT="${STAGINGROOT}${EPREFIX}" \
                     portageq best_visible "${STAGINGROOT}${EPREFIX}" installed sys-devel/gcc)"
  pkgdir="$(sudo -E PORTAGE_CONFIGROOT="${STAGINGROOT}${EPREFIX}" portageq pkgdir)"
  qtbz2 -O -t "$pkgdir/$gcc_ver".tbz2 \
          | sudo tar -v -C "${FINALROOT}" -xj \
                     --transform "s#.${EPREFIX}/usr/lib/.*/#.${EPREFIX}/usr/lib64/#" \
                     --wildcards ".${EPREFIX}/usr/lib/gcc/*.so*"
}
# --

function create_make_conf() {
  local which="${1}" \
        filepath \
        dir \
        portage_profile \
        emerge_opts

  case "${which}" in
    staging)
      filepath="${STAGINGROOT}${EPREFIX}/etc/portage/make.conf"
      dir="${STAGINGDIR}"
      emerge_opts="--buildpkg"
      ;;
    final)
      filepath="${FINALROOT}${EPREFIX}/etc/portage/make.conf"
      dir="${FINALDIR}"
      emerge_opts="--root-deps=rdeps --usepkgonly"
      ;;
  esac

sudo_clobber "${filepath}" <<EOF
DISTDIR="/mnt/host/source/.cache/distfiles"
PKGDIR=${STAGINGDIR@Q}/pkgs
PORT_LOGDIR=${dir@Q}/logs
PORTAGE_TMPDIR=${dir@Q}/tmp
PORTAGE_BINHOST=""
PORTAGE_USERNAME="sdk"
MAKEOPTS="--jobs=4"
CHOST=${PREFIX_CHOST@Q}

ACCEPT_KEYWORDS=${PREFIX_KEYWORDS@Q}

EMERGE_DEFAULT_OPTS=${emerge_opts@Q}

USE="
-desktop
-installkernel
-llvm
-nls
-openmp
-udev
-wayland
-X
"
EOF
}
# --

function emerge_name() {
  local path=""
  if [ "${1:-}" = "with-path" ] ; then
    path="/usr/local/bin/"
  fi

  echo "${path}emerge-prefix-${PREFIXNAME}-${PREFIX_BOARD}"
}
# --

function create_emerge_wrapper() {
  local filename="$(emerge_name with-path)"
  sudo_clobber "${filename}" <<EOF
#!/bin/bash

# emerge comfort wrapper for emerging prefix packages.
# The wrapper will build packages and dependencies in staging
#   and then install binpkgs in prefix.

set -euo pipefail

PREFIXNAME=${PREFIXNAME@Q}
EPREFIX=${EPREFIX@Q}
STAGINGROOT=${STAGINGROOT@Q}
FINALROOT=${FINALROOT@Q}
CB_ROOT=${CB_ROOT@Q}

EOF

  sudo_append "${filename}" <<'EOF'
if [ "${1}" = "--help" ] ; then
    echo "$0 : emerge prefix wrapper for prefix '${PREFIXNAME}'"
    echo "Usage:"
    echo "  $0 [--install|--stage] <emerge-opts>"
    echo "                          Builds packages in prefix' staging and installs w/ runtime dependencies"
    echo "                           to prefix' final root."
    echo "             --stage      Build binpkg in staging but don't install."
    echo "             --install    Skip build, just install. Binpkg must exist in staging."
    echo
    echo "      Prefix configuration:"
    echo "        PREFIXNAME=${PREFIXNAME@Q}"
    echo "        EPREFIX=${EPREFIX@Q}"
    echo "        STAGINGROOT=${STAGINGROOT@Q}"
    echo "        FINALROOT=${FINALROOT@Q}"
    echo "        CB_ROOT=${CB_ROOT@Q}"
    exit
fi

skip_build="false"
skip_install="false"

case "${1}" in
    --install) skip_build="true"; shift;;
    --stage) skip_install="true"; shift;;
esac

if [ "${skip_build}" = "true" ]  ; then
    echo "Skipping build into staging as requested."
    echo "NOTE that install into final will fail if binpkgs are missing."
else
    echo "Building in staging..."
    sudo -E EPREFIX="${EPREFIX}" "${CB_ROOT}/bin/cb-emerge" "${STAGINGROOT}" "$@"
fi

if [ "${skip_install}" = "true" ]  ; then
    echo "Skipping install into final as requested."
else
    echo "Installing..."
    sudo -E EPREFIX="${EPREFIX}" \
            ROOT="${FINALROOT}" \
            PORTAGE_CONFIGROOT="${FINALROOT}${EPREFIX}" emerge "$@"
fi
EOF

  sudo chmod 755 "${filename}"
}
# --
