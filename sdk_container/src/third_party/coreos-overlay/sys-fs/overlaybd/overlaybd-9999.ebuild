# Copyright 2025 The Flatcar Container Linux Maintainers
# Distributed under the terms of the Apache License 2.0

EAPI=8

inherit cmake git-r3 toolchain-funcs systemd tmpfiles

DESCRIPTION="Overlaybd is a novel layering block-level image format for containers."
HOMEPAGE="https://containerd.github.io/overlaybd"

EGIT_REPO_URI="https://github.com/containerd/overlaybd.git"

if [[ "${PV}" == 9999 ]]; then
  KEYWORDS="~amd64 ~arm64"
else
  EGIT_COMMIT="v${PV}"
  KEYWORDS="amd64 arm64"
fi

SLOT="0"
LICENSE="Apache-2.0"

BDEPEND="
  app-arch/zstd
  >=dev-build/cmake-3.14
  >=sys-devel/gcc-7
  >=dev-libs/glib-2
  dev-libs/libaio
  dev-libs/libnl
  dev-libs/openssl
  net-misc/curl
  sys-fs/e2fsprogs
"

RDEPEND="
  dev-libs/libaio
  dev-libs/libnl
  dev-libs/openssl
  net-misc/curl
  sys-fs/e2fsprogs
"

DEPEND="
  ${RDEPEND}
"

# Upstream uses 'make' based build as per their build instructions: https://github.com/containerd/overlaybd/tree/v1.0.15?tab=readme-ov-file#build
# Gentoo cmake defaults to [e]ninja, which will break the build because source dependencies fail to build.
CMAKE_MAKEFILE_GENERATOR=emake

src_prepare() {
  cmake_src_prepare
}

src_configure() {
  local mycmakeargs=()

  case tc-arch in
    amd64) mycmakeargs+=( -D ENABLE_ISAL=1 ) ;;
  esac

  cmake_src_configure
}

src_compile() {
  cmake_src_compile
}

src_install() {
  cmake_src_install
  
  # We want to ship our binaries in /usr/local (so we're sysext compatible) but upstream has hard-wired everything to /opt/overlaybd.
  mkdir -p "${ED}/usr/local" || die
  mv "${ED}/opt/overlaybd/" "${ED}/usr/local/" || die

  mkdir "${ED}/usr/local/overlaybd/etc" || die
  mv "${ED}/etc/overlaybd/*" "${ED}/usr/local/overlaybd/etc/" || die

  sed -i 's,/opt/overlaybd,/usr/local/overlaybd,' \
    "${ED}/usr/local/overlaybd/overlaybd-tcmu.service" || die

  # This takes care of symlinking /opt/overlaybd/ -> /usr/local/overlaybd
  #  and of installing overlaybd.json to /etc.
  dotmpfiles "${FILESDIR}/10-overlaybd.conf"

  systemd_dounit "${ED}/usr/local/overlaybd/overlaybd-tcmu.service"
  systemd_enable_service "multi-user.target" "overlaybd-tcmu.service"
}
