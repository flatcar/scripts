# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/lcms/lcms-2.3.ebuild,v 1.6 2012/08/22 02:33:56 ottxor Exp $

EAPI=4

DESCRIPTION="A lightweight, speed optimized color management engine"
HOMEPAGE="http://www.littlecms.com/"
SRC_URI="mirror://sourceforge/${PN}/lcms2-${PV}.tar.gz"

LICENSE="MIT"
SLOT="2"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~amd64-fbsd ~sparc-fbsd ~x86-fbsd ~x86-freebsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~m68k-mint ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE="doc jpeg static-libs test tiff zlib"

RDEPEND="jpeg? ( virtual/jpeg )
	tiff? ( media-libs/tiff:0 )
	zlib? ( sys-libs/zlib )"
DEPEND="${RDEPEND}"

S=${WORKDIR}/lcms2-${PV}

src_configure() {
	econf \
		$(use_enable static-libs static) \
		$(use_with jpeg) \
		$(use_with tiff) \
		$(use_with zlib)
}

src_compile() {
	default

	if use test; then
		cd testbed
		emake testcms
	fi
}

src_test() {
	cd testbed
	./testcms || die
}

src_install() {
	default

	if use doc; then
		docinto pdf
		dodoc doc/*.pdf
	fi

	rm -f "${ED}"usr/lib*/liblcms2.la
}
