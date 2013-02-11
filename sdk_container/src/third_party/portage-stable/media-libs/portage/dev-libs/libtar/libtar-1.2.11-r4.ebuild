# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libtar/libtar-1.2.11-r4.ebuild,v 1.6 2012/05/29 13:40:21 aballier Exp $

EAPI=3
inherit autotools eutils multilib

p_level=6

DESCRIPTION="C library for manipulating tar archives"
HOMEPAGE="http://www.feep.net/libtar/ http://packages.qa.debian.org/libt/libtar.html"
SRC_URI="ftp://ftp.feep.net/pub/software/libtar/${P}.tar.gz
	mirror://debian/pool/main/libt/${PN}/${PN}_${PV}-${p_level}.diff.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ppc ppc64 ~sparc x86 ~amd64-fbsd ~amd64-linux ~x86-linux ~ppc-macos"
IUSE="static-libs zlib"

DEPEND="zlib? ( sys-libs/zlib )
	!zlib? ( app-arch/gzip )"

src_prepare() {
	epatch "${WORKDIR}"/${PN}_${PV}-${p_level}.diff \
		"${FILESDIR}"/${P}-f{ree,ortify}.patch

	sed -i \
		-e '/INSTALL_PROGRAM/s:-s::' \
		{doc,lib{,tar}}/Makefile.in || die

	sed -i -e "/\/usr\/share\/aclocal/s:/usr:$EPREFIX/usr:" aclocal.m4
	eautoreconf # reconf for missing config.sub
}

src_configure() {
	econf \
		$(use_enable static-libs static) \
		$(use_with zlib)
}

src_install() {
	emake DESTDIR="${D}" install || die

	dodoc ChangeLog* README TODO
	newdoc compat/README README.compat
	newdoc compat/TODO TODO.compat
	newdoc listhash/TODO TODO.listhash
	newdoc debian/changelog ChangeLog.debian

	rm -f "${ED}"/usr/$(get_libdir)/${PN}.la
}
