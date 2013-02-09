# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/imlib/imlib-1.9.15-r3.ebuild,v 1.7 2011/10/11 20:19:49 ssuominen Exp $

EAPI=2
inherit autotools eutils

PVP=(${PV//[-\._]/ })
DESCRIPTION="Image loading and rendering library"
HOMEPAGE="http://ftp.acc.umu.se/pub/GNOME/sources/imlib/1.9/"
SRC_URI="mirror://gnome/sources/${PN}/${PVP[0]}.${PVP[1]}/${P}.tar.bz2
	mirror://gentoo/gtk-1-for-imlib.m4.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 sh sparc x86 ~x86-fbsd"
IUSE="doc static-libs"

RDEPEND=">=media-libs/tiff-3.5.5
	>=media-libs/giflib-4.1.0
	>=media-libs/libpng-1.2.1
	virtual/jpeg
	x11-libs/libICE
	x11-libs/libSM
	x11-libs/libXext"
DEPEND="${RDEPEND}"

src_prepare() {
	# Fix aclocal underquoted definition warnings.
	# Conditionalize gdk functions for bug 40453.
	# Fix imlib-config for bug 3425.
	epatch "${FILESDIR}"/${P}.patch
	epatch "${FILESDIR}"/${PN}-security.patch #security #72681
	epatch "${FILESDIR}"/${P}-bpp16-CVE-2007-3568.patch # security #201887
	epatch "${FILESDIR}"/${P}-fix-rendering.patch #197489
	epatch "${FILESDIR}"/${P}-asneeded.patch #207638
	epatch "${FILESDIR}"/${P}-libpng15.patch #357167

	mkdir m4 && cp "${WORKDIR}"/gtk-1-for-imlib.m4 m4

	AT_M4DIR="m4" eautoreconf
}

src_configure() {
	econf \
		--sysconfdir=/etc/imlib \
		$(use_enable static-libs static) \
		--disable-gdk \
		--disable-gtktest
}

src_install() {
	emake DESTDIR="${D}" install || die

	dodoc AUTHORS ChangeLog README
	use doc && dohtml doc/*

	# Punt unused files
	rm -f "${D}"/usr/lib*/pkgconfig/imlibgdk.pc
	find "${D}" -name '*.la' -exec rm -f {} +
}
