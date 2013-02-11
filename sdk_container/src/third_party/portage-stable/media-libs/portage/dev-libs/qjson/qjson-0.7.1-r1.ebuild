# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/qjson/qjson-0.7.1-r1.ebuild,v 1.9 2012/05/17 13:14:52 aballier Exp $

EAPI="2"

inherit cmake-utils

DESCRIPTION="A library for mapping JSON data to QVariant objects"
HOMEPAGE="http://qjson.sourceforge.net"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.bz2"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="amd64 ~arm hppa ppc ~ppc64 x86 ~amd64-fbsd"
IUSE="debug doc test"

RDEPEND="x11-libs/qt-core:4"
DEPEND="${RDEPEND}
	doc? ( app-doc/doxygen )
	test? ( x11-libs/qt-test:4 )"

S="${WORKDIR}/${PN}"
DOCS=( "${S}/README" )

src_configure() {
	mycmakeargs="${mycmakeargs}
		$(cmake-utils_use test QJSON_BUILD_TESTS)"

	cmake-utils_src_configure
}

src_install() {
	if use doc; then
		cd "${S}/doc"
		doxygen Doxyfile || die "Generating documentation failed"
		HTML_DOCS=( "${S}/doc/html/" )
	fi

	cmake-utils_src_install
}
