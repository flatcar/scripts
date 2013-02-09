# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/taglib/taglib-1.7.2.ebuild,v 1.9 2012/05/26 17:18:31 armin76 Exp $

EAPI=4
CMAKE_IN_SOURCE_BUILD=1
inherit cmake-utils

DESCRIPTION="A library for reading and editing audio meta data"
HOMEPAGE="http://developer.kde.org/~wheeler/taglib.html"
SRC_URI="http://developer.kde.org/~wheeler/files/src/${P}.tar.gz"

LICENSE="LGPL-2 MPL-1.1"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 sh sparc x86 ~x86-fbsd ~x86-freebsd ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x86-solaris"
SLOT="0"
IUSE="+asf debug examples +mp4 test"

RDEPEND="sys-libs/zlib"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	test? ( dev-util/cppunit )
"

PATCHES=(
	"${FILESDIR}"/${PN}-1.6.1-install-examples.patch
)

DOCS="AUTHORS NEWS"

src_configure() {
	mycmakeargs=(
		$(cmake-utils_use_build examples)
		$(cmake-utils_use_build test TESTS)
		$(cmake-utils_use_with asf)
		$(cmake-utils_use_with mp4)
	)

	cmake-utils_src_configure
}

src_test() {
	# ctest does not work
	default
}

pkg_postinst() {
	if ! use asf; then
		elog "You've chosen to disable the asf use flag, thus taglib won't include"
		elog "support for Microsoft's 'advanced systems format' media container"
	fi
	if ! use mp4; then
		elog "You've chosen to disable the mp4 use flag, thus taglib won't include"
		elog "support for the MPEG-4 part 14 / MP4 media container"
	fi
}
