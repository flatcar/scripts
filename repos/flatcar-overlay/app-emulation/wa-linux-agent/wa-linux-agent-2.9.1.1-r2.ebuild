# Copyright (c) 2014 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# Don't use DISTUTILS_USE_PEP517=setuptools because this installs
# everything inside /usr/lib/pythonX_Y/site-packages, even files that
# ought to be put into /etc or /sbin.
PYTHON_COMPAT=( python3_{9..11} )

inherit distutils-r1

DESCRIPTION="Windows Azure Linux Agent"
HOMEPAGE="https://github.com/Azure/WALinuxAgent"
SRC_URI="${HOMEPAGE}/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="Apache-2.0"
KEYWORDS="amd64 arm64"
SLOT="0"
IUSE=""
RESTRICT=""

BDEPEND="
	dev-python/distro
"
RDEPEND="${BDEPEND}
"

S="${WORKDIR}/WALinuxAgent-${PV}"

PATCHES=(
    "${FILESDIR}/0001-flatcar-changes.patch"
)
