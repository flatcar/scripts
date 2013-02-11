# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/gtk+extra/gtk+extra-3.0.1.ebuild,v 1.8 2012/05/05 03:52:24 jdhore Exp $

EAPI="4"

inherit autotools eutils

DESCRIPTION="Useful Additional GTK+ widgets"
HOMEPAGE="http://gtkextra.sourceforge.net"
SRC_URI="mirror://sourceforge/gtkextra/${P}.tar.gz
	mirror://gentoo/introspection.m4.bz2"

LICENSE="FDL-1.1 LGPL-2"
SLOT="0"
KEYWORDS="amd64 ~ia64 ppc ppc64 ~sparc x86"
IUSE="+introspection static-libs"

RDEPEND=">=x11-libs/gtk+-2.12.0:2
	dev-libs/glib:2
	introspection? ( >=dev-libs/gobject-introspection-0.6.14 )"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

src_prepare() {
	# Fix configure,
	# https://sourceforge.net/tracker/?func=detail&aid=3414011&group_id=11638&atid=111638
	epatch "${FILESDIR}/${P}-fix-configure.patch"

	# Upstream patch to fix building with >=glib-2.31
	epatch "${FILESDIR}/${P}-gunicode.h.patch"

	# eautoreconf needs introspection.m4
	cp "${WORKDIR}"/introspection.m4 . || die
	AT_M4DIR="." eautoreconf
}

src_configure() {
	econf \
		--disable-dependency-tracking \
		--enable-glade=no \
		--disable-man \
		$(use_enable introspection) \
		$(use_enable static-libs static) \
		--with-html-dir=/usr/share/doc/${PF}/html
}

src_install() {
	emake DESTDIR="${D}" install
	dodoc AUTHORS ChangeLog README
	find "${D}" -name '*.la' -exec rm -f '{}' +
}
