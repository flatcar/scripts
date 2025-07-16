# Copyright 2025 The Flatcar Container Linux Maintainers
# Distributed under the terms of the Apache License 2.0

EAPI=8
inherit git-r3 go-module systemd tmpfiles

DESCRIPTION="A production-ready remote container image format (overlaybd) and snapshotter based on block-device."
HOMEPAGE="https://containerd.github.io/overlaybd"

EGIT_REPO_URI="https://github.com/containerd/accelerated-container-image.git"

if [[ "${PV}" == 9999 ]]; then
  KEYWORDS="~amd64 ~arm64"
else
  EGIT_COMMIT="v${PV}"
  KEYWORDS="amd64 arm64"
fi

LICENSE="Apache-2.0"
SLOT="0"


BDEPEND="
"

RDEPEND="
  sys-fs/overlaybd
"

DEPEND="
  ${RDEPEND}
"

src_unpack() {
  git-r3_fetch
  git-r3_checkout
  go-module_src_unpack
}

src_install() {
  # sys-fs/overlaybd tmpfiles will take care of symlinking 
  #    /opt/overlaybd/ -> /usr/local/overlaybd
  # so we can put our binaries in a slightly saner path than /opt
  emake DESTDIR="${ED}" \
        SN_DESTDIR="${ED}/usr/local/overlaybd/snapshotter" \
        SN_CFGDIR="${ED}/usr/local/overlaybd/snapshotter/etc" \
                 install

  sed -i 's,/opt/overlaybd,/usr/local/overlaybd,' \
    "${ED}/usr/local/overlaybd/snapshotter/overlaybd-snapshotter.service" || die

  dotmpfiles "${FILESDIR}/10-overlaybd-snapshotter.conf"

  systemd_dounit "${ED}/usr/local/overlaybd/snapshotter/overlaybd-snapshotter.service"
  systemd_enable_service "multi-user.target" "overlaybd-snapshotter.service"
}
