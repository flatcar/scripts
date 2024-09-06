# Copyright (c) 2024 The Flatcar Maintainers.
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Signed UEFI Shim loader"
HOMEPAGE="https://github.com/rhboot/shim"
SRC_URI="https://mirror.release.flatcar-linux.net/coreos/shimx64.efi.signed"
KEYWORDS="amd64 arm64"

LICENSE="BSD"
SLOT="0"
IUSE=""

RDEPEND=""

S=${WORKDIR}

src_install() {
  insinto /usr/lib/shim
  doins "${DISTDIR}"/shimx64.efi.signed
}
