# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/jthread/jthread-1.3.0.ebuild,v 1.1 2012/11/27 13:19:59 pinkbyte Exp $

EAPI=4

inherit cmake-utils

DESCRIPTION="JThread provides some classes to make use of threads easy on different platforms."
HOMEPAGE="http://research.edm.uhasselt.be/~jori/page/index.php?n=CS.Jthread"
SRC_URI="http://research.edm.uhasselt.be/jori/${PN}/${P}.tar.bz2"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="static-libs"

DOCS=( ChangeLog README.TXT TODO doc/manual.tex )

src_prepare() {
	# do not build static library, if it is not requested
	if ! use static-libs; then
		sed -i -e '/jthread-static/d' src/CMakeLists.txt || die 'sed on src/CMakeLists.txt failed'
	fi
}
