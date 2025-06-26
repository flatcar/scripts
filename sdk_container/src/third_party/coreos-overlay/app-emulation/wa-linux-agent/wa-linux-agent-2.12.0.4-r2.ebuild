# Copyright (c) 2014 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..13} )
DISTUTILS_USE_PEP517=setuptools

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
	"${FILESDIR}/0002-prevent-ssh-public-key-override.patch"
)

# All the stuff is installed inside the site-packages directory, even executables that ought to be in /sbin or config that ought to be in /etc. Move them.
python_install() {
	distutils-r1_python_install
	local d
	for d in /etc /usr; do
		cp -a "${ED}$(python_get_sitedir)${d}" "${ED}" || die
		rm -rf "${ED}$(python_get_sitedir)${d}" || die
	done
}
