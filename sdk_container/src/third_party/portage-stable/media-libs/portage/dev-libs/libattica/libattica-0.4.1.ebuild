# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libattica/libattica-0.4.1.ebuild,v 1.8 2013/01/27 22:55:35 ago Exp $

EAPI=4

MY_P="${P#lib}"
MY_PN="${PN#lib}"

inherit cmake-utils

DESCRIPTION="A library providing access to Open Collaboration Services"
HOMEPAGE="http://www.kde.org/"
SRC_URI="mirror://kde/stable/${MY_PN}/${MY_P}.tar.bz2"

LICENSE="GPL-2 LGPL-2"
KEYWORDS="amd64 ~arm ppc x86 ~amd64-fbsd ~x86-fbsd ~amd64-linux ~x86-linux"
SLOT="0"
IUSE="debug test"

RDEPEND="x11-libs/qt-core:4"
DEPEND="${RDEPEND}
	test? (
		x11-libs/qt-gui:4
		x11-libs/qt-test:4
	)"

DOCS=( AUTHORS ChangeLog README )
PATCHES=(
	"${FILESDIR}/${P}-automagic.patch"
	"${FILESDIR}/${P}-qt5.patch"
)

S="${WORKDIR}/${MY_P}"

src_configure() {
	local mycmakeargs=(
		-DWITH_Qt5=OFF
		$(cmake-utils_use test ATTICA_ENABLE_TESTS)
	)
	cmake-utils_src_configure
}
