# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-wireless/multimode/multimode-1.00.ebuild,v 1.1 2012/09/13 23:40:07 zerochaos Exp $

EAPI=4
PYTHON_DEPEND="2:2.6"

inherit python

DESCRIPTION="multimode radio decoder for rtl-sdr devices using gnuradio"
HOMEPAGE="https://www.cgran.org/browser/projects/multimode/trunk"
LICENSE="BSD"
SLOT="0"
IUSE=""

if [[ ${PV} == "9999" ]] ; then
	ESVN_REPO_URI="https://www.cgran.org/svn/projects/multimode/trunk"
	inherit subversion
	KEYWORDS=""
else
	SRC_URI="http://www.sbrac.org/files/${PN}-r${PV}.tar.gz"
	#KEYWORDS="~amd64 ~x86" <-- this is my target
	S="${WORKDIR}"
fi

DEPEND=""
RDEPEND="${DEPEND}
	=net-wireless/gr-osmosdr-9999
	>=net-wireless/gnuradio-3.6.1
	=net-wireless/rtl-sdr-9999"

pkg_setup() {
	python_set_active_version 2
	python_pkg_setup
}

src_install() {
	python_convert_shebangs $(python_get_version) ${PN}.py
	newbin ${PN}.py ${PN}
	insinto $(python_get_sitedir)
	doins ${PN}_helper.py
	insinto /usr/share/${PN}
	doins ${PN}.grc
}
