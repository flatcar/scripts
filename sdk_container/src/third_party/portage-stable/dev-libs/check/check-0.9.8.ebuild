# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/check/check-0.9.8.ebuild,v 1.1 2009/11/15 21:11:47 eva Exp $

inherit eutils autotools

DESCRIPTION="A unit test framework for C"
HOMEPAGE="http://sourceforge.net/projects/check/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~x86-fbsd"
IUSE=""

RDEPEND=""
DEPEND=""

src_unpack() {
	unpack ${A}
	cd "${S}"
	epatch "${FILESDIR}"/${PN}-0.9.6-AM_PATH_CHECK.patch
	epatch "${FILESDIR}"/${PN}-0.9.6-64bitsafe.patch

	sed -i -e '/^docdir =/d' Makefile.am doc/Makefile.am \
		|| die "Unable to remove docdir references"

	eautoreconf
}

src_compile() {
	econf --docdir=/usr/share/doc/${PF}
	emake || die "emake failed"
}

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"
}
