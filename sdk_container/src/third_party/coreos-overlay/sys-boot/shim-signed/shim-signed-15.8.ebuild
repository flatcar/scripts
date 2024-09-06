# Copyright (c) 2024 The Flatcar Maintainers.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Signed UEFI Shim loader"
HOMEPAGE="https://github.com/rhboot/shim"
SRC_URI="amd64? ( https://mirror.release.flatcar-linux.net/coreos/shimx64-${PV}.efi.signed )"
KEYWORDS="amd64 arm64"

LICENSE="BSD"
SLOT="0"

src_install() {
  insinto /usr/lib/shim
  newins "${DISTDIR}/shimx64-${PV}.efi.signed" shimx64.efi.signed
}
