# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-wireless/gr-osmosdr/gr-osmosdr-9999.ebuild,v 1.4 2012/06/11 23:59:41 chithanh Exp $

EAPI=4
PYTHON_DEPEND="2"

inherit cmake-utils git-2 python

DESCRIPTION="GNU Radio source block for OsmoSDR and rtlsdr"
HOMEPAGE="http://sdr.osmocom.org/"
SRC_URI=""
EGIT_REPO_URI="git://git.osmocom.org/${PN}.git"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS=""
IUSE=""

RDEPEND="dev-libs/boost
	net-wireless/gnuradio
	net-wireless/rtl-sdr"
DEPEND="${RDEPEND}
	dev-python/cheetah"

pkg_setup() {
	python_set_active_version 2
	python_pkg_setup
}

src_prepare() {
	python_convert_shebangs -q -r 2 "${S}"
}
