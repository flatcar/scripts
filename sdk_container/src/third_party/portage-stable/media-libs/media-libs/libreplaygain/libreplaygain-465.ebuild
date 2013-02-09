# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libreplaygain/libreplaygain-465.ebuild,v 1.9 2011/08/17 17:01:35 chithanh Exp $

EAPI=3
inherit cmake-utils

# svn export http://svn.musepack.net/libreplaygain libreplaygain-${PV}
# tar -cjf libreplaygain-${PV}.tar.bz2 libreplaygain-${PV}

DESCRIPTION="Replay Gain library from Musepack"
HOMEPAGE="http://www.musepack.net"
SRC_URI="mirror://gentoo/${P}.tar.bz2"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="alpha amd64 hppa ppc ppc64 x86 ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~sparc-solaris ~x86-solaris"
IUSE=""

src_prepare() {
	sed -i \
		-e '/CMAKE_C_FLAGS/d' \
		CMakeLists.txt || die
}

src_install() {
	cmake-utils_src_install
	insinto /usr/include
	doins -r include/replaygain || die
}
