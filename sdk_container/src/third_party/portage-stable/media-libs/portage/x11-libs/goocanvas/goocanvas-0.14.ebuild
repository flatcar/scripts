# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/goocanvas/goocanvas-0.14.ebuild,v 1.10 2012/05/05 03:52:27 jdhore Exp $

EAPI="2"

GCONF_DEBUG="no"

inherit gnome2 libtool

DESCRIPTION="Canvas widget for GTK+ using the cairo 2D library for drawing"
HOMEPAGE="http://live.gnome.org/GooCanvas"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 ia64 ppc ppc64 sparc x86 ~x86-fbsd"
IUSE="doc examples"

RDEPEND=">=x11-libs/gtk+-2.12:2
	>=dev-libs/glib-2.10:2
	>=x11-libs/cairo-1.4"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	doc? ( >=dev-util/gtk-doc-1.8 )"

DOCS="AUTHORS ChangeLog NEWS README TODO"

pkg_setup() {
	G2CONF="${G2CONF} --disable-rebuilds --disable-static"
}

src_prepare() {
	# Fails to build with recent GTK+
	sed -e "s/-D.*_DISABLE_DEPRECATED//g" \
		-i src/Makefile.am src/Makefile.in demo/Makefile.am demo/Makefile.in \
		|| die "sed 1 failed"

	sed -e 's/^\(SUBDIRS =.*\)demo\(.*\)$/\1\2/' \
		-i Makefile.am Makefile.in || die "sed 2 failed"

	# Needed for FreeBSD - Please do not remove
	elibtoolize
}

src_install() {
	gnome2_src_install

	if use examples; then
		insinto /usr/share/doc/${P}/examples/
		doins demo/*.c demo/flower.png demo/toroid.png
	fi
}
