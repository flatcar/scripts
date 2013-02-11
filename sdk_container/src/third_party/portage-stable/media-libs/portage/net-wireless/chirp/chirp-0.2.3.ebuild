# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-wireless/chirp/chirp-0.2.3.ebuild,v 1.3 2012/11/30 17:20:08 zerochaos Exp $

EAPI=4
PYTHON_DEPEND="2:2.6"
SUPPORT_PYTHON_ABIS="1"
RESTRICT_PYTHON_ABIS="2.5 3.*"

if [[ ${PV} == "9999" ]] ; then
	SCM=mercurial
	EHG_REPO_URI="http://d-rats.com/hg/chirp.hg"
fi

inherit distutils ${SCM}

DESCRIPTION="Free open-source tool for programming your amateur radio"
HOMEPAGE="http://chirp.danplanet.com"

if [[ ${PV} == "9999" ]] ; then
	KEYWORDS=""
else
	KEYWORDS="~amd64 ~x86"
	SRC_URI="http://chirp.danplanet.com/download/${PV}/${P}.tar.gz"
fi
LICENSE="GPL-3"
SLOT="0"
IUSE=""

DEPEND="dev-python/pyserial
	dev-libs/libxml2[python]"
RDEPEND="${DEPEND}
	dev-python/pygtk"

src_prepare() {
	sed -i -e "/share\/doc\/chirp/d" setup.py || die
	distutils_src_prepare
}

src_test() {
	echo "No tests"
}
