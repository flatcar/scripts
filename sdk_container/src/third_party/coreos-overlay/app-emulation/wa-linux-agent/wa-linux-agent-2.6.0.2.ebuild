# Copyright (c) 2014 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Windows Azure Linux Agent"
HOMEPAGE="https://github.com/Azure/WALinuxAgent"
KEYWORDS="amd64 arm64"
SRC_URI="${HOMEPAGE}/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
IUSE=""

# Depending on specific version of python-oem allows us to notice when
# we update the major version of python and then to make sure that we
# install the package in correctly versioned site-packages directory.
DEP_PYVER="3.6"

RDEPEND="
dev-lang/python-oem:${DEP_PYVER}
dev-python/distro-oem
"

S="${WORKDIR}/WALinuxAgent-${PV}"

src_install() {
	into "/usr/share/oem"
	dobin "${S}/bin/waagent"

	insinto "/usr/share/oem/python/$(get_libdir)/python${DEP_PYVER}/site-packages"
	doins -r "${S}/azurelinuxagent/"

	insinto "/usr/share/oem"
	doins "${FILESDIR}/waagent.conf"
}
