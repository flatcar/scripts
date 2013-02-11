# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/fddl/fddl-20111124.ebuild,v 1.3 2012/12/25 04:10:41 jdhore Exp $

EAPI=4

CMAKE_IN_SOURCE_BUILD=1

inherit cmake-utils vcs-snapshot

DESCRIPTION="Free Decision Diagram Library"
HOMEPAGE="http://itval.sourceforge.net/ https://github.com/atomopawn/FDDL"
SRC_URI="http://dev.gentoo.org/~pinkbyte/distfiles/snapshots/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE=""

DOCS=( AUTHORS ChangeLog INSTALL RELEASE )

src_prepare() {
	# Remove references to files that were not shipped,
	# prefer dynamic linking
	sed -i  src/CMakeLists.txt \
		-e 's|unaryoperation.cpp||g' \
		-e 's|unaryoperation.h||g' \
		-e 's|binaryoperation.cpp||g' \
		-e 's|binaryoperation.h||g' \
		-e '/add_library/s/FDDL /FDDL SHARED /' \
		|| die
	# Do not build tests that depend on above files
	sed -i   \
		{,tests/}CMakeLists.txt \
		-e '/test_unaryop/d' \
		-e '/test_binaryop/d' \
		|| die
}
