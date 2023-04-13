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

# Depending on specific version of python-oem allows us to notice when
# we update the major version of python and then to make sure that we
# install the package in correctly versioned site-packages directory.
DEP_PYVER="3.6"

SLOT="0"
RDEPEND="dev-lang/python-oem:${DEP_PYVER}"

S="${WORKDIR}/${MY_P}"

src_compile() {
    # nothing to do
    :
}

src_install() {
	insinto "/usr/share/oem/python/$(get_libdir)/python${DEP_PYVER}/site-packages"
	doins "${S}/distro.py"
}
