# Copyright (c) 2015 CoreOS Inc.
# Copyright (c) 2024 The Flatcar Maintainers.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Flatcar Secure Boot keys"
HOMEPAGE=""
SRC_URI=""
LICENSE="BSD"
SLOT="0"
KEYWORDS="amd64 arm64"
IUSE=""

S="${WORKDIR}"

src_install() {
  insinto /usr/share/sb_keys
  newins "${FILESDIR}/DB.key" DB.key
  newins "${FILESDIR}/DB.crt" DB.crt

  # shim keys
  newins "${FILESDIR}/shim.key" shim.key
  newins "${FILESDIR}/shim.der" shim.der
  newins "${FILESDIR}/shim.pem" shim.pem
}
