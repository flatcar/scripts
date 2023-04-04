# Copyright 2021-2022 Microsoft Corporation
# Distributed under the terms of GNU General Public License v2

EAPI=8

MY_PN='distro'
MY_P="${MY_PN}-${PV}"

DESCRIPTION="Reliable machine-readable Linux distribution information for Python"
HOMEPAGE="
	https://distro.readthedocs.io/en/latest/
	https://pypi.org/project/distro/
	https://github.com/python-distro/distro/"
SRC_URI="mirror://pypi/${MY_PN:0:1}/${MY_PN}/${MY_P}.tar.gz"

LICENSE="Apache-2.0"
KEYWORDS="amd64 arm64"

# Depending on specific version of python-oem allows us to notice when
# we update the major version of python and then to make sure that we
# install the package in correctly versioned site-packages directory.
DEP_PYVER="3.10"

SLOT="0"
RDEPEND="dev-lang/python-oem:${DEP_PYVER}"

S="${WORKDIR}/${MY_P}"

src_compile() {
    # nothing to do
    :
}

src_install() {
	insinto "/oem/python/$(get_libdir)/python${DEP_PYVER}/site-packages"
	local ssd="${S}/src/distro"
	doins "${ssd}/distro.py"
	doins "${ssd}/__init__.py"
	doins "${ssd}/__main__.py"
	doins "${ssd}/py.typed"
}
