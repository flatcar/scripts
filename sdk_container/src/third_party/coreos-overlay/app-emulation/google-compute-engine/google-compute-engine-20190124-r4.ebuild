# Copyright (c) 2016-2018 CoreOS, Inc. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )
DISTUTILS_USE_PEP517=setuptools

inherit distutils-r1

DESCRIPTION="Linux Guest Environment for Google Compute Engine"
HOMEPAGE="https://github.com/GoogleCloudPlatform/compute-image-packages"
SRC_URI="https://github.com/GoogleCloudPlatform/compute-image-packages/archive/${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/compute-image-packages-${PV}"
LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64"

# These dependencies cover all commands called by the scripts.
RDEPEND="
	app-admin/sudo
	dev-python/boto[${PYTHON_USEDEP}]
	dev-python/distro[${PYTHON_USEDEP}]
	sys-apps/ethtool
	sys-apps/coreutils
	sys-apps/gawk
	sys-apps/grep
	sys-apps/iproute2
	sys-apps/shadow
"

src_install() {
	distutils-r1_src_install

	# Newer versions are installed by app-admin/google-guest-configs.
	rm -v "${ED}"/usr/bin/google_{optimize_local_ssd,set_multiqueue} || die
}
