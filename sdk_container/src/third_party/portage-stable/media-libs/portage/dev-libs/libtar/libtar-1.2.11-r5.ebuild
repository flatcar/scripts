# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libtar/libtar-1.2.11-r5.ebuild,v 1.6 2012/06/29 12:57:41 ranger Exp $

EAPI=4
inherit autotools eutils multilib

p_level=8

DESCRIPTION="C library for manipulating tar archives"
HOMEPAGE="http://www.feep.net/libtar/ http://packages.qa.debian.org/libt/libtar.html"
SRC_URI="ftp://ftp.feep.net/pub/software/libtar/${P}.tar.gz
	mirror://debian/pool/main/libt/${PN}/${PN}_${PV}-${p_level}.debian.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ppc ppc64 ~sparc x86 ~amd64-fbsd ~amd64-linux ~x86-linux ~ppc-macos"
IUSE="static-libs zlib"

DEPEND="zlib? ( sys-libs/zlib )
	!zlib? ( app-arch/gzip )"

src_prepare() {
	local d="${WORKDIR}"/debian/patches
	sed -i -e '/#/d' "${d}"/series || die
	EPATCH_SOURCE="${d}" epatch $(<"${d}"/series)

	epatch \
		"${FILESDIR}"/${P}-f{ree,ortify}.patch \
		"${FILESDIR}"/${P}-impl-dec.patch

	sed -i \
		-e '/INSTALL_PROGRAM/s:-s::' \
		{doc,lib{,tar}}/Makefile.in || die

	sed -i -e "/\/usr\/share\/aclocal/s:/usr:$EPREFIX/usr:" aclocal.m4
	eautoreconf # reconf for missing config.sub
}

src_configure() {
	econf \
		--disable-encap \
		--disable-epkg-install \
		$(use_enable static-libs static) \
		$(use_with zlib)
}

src_install() {
	emake DESTDIR="${D}" install

	dodoc ChangeLog* README TODO
	newdoc compat/README README.compat
	newdoc compat/TODO TODO.compat
	newdoc listhash/TODO TODO.listhash
	newdoc "${WORKDIR}"/debian/changelog ChangeLog.debian

	prune_libtool_files
}
