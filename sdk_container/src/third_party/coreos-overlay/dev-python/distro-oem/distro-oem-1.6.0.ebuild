# Copyright 2021 Microsoft Corporation
# Distributed under the terms of GNU General Public License v2

EAPI=7

MY_PN='distro'
MY_P="${MY_PN}-${PV}"

DESCRIPTION="OS platform information API"
HOMEPAGE="https://github.com/python-distro/distro"
SRC_URI="${HOMEPAGE}/releases/download/v${PV}/${MY_P}.tar.gz"

LICENSE="Apache-2.0"
KEYWORDS="amd64 arm64"

SLOT="0"
RDEPEND="dev-lang/python-oem"

S="${WORKDIR}/${MY_P}"

src_compile() {
    # nothing to do
    :
}

src_install() {
	# When updating python-oem, remember to update the path below.
	insinto "/usr/share/oem/python/$(get_libdir)/python3.6/site-packages"
	doins "${S}/distro.py"
}
