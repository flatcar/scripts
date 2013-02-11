# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/gtkglext/gtkglext-1.2.0-r1.ebuild,v 1.2 2012/12/19 16:43:18 tetromino Exp $

EAPI="4"

GNOME2_LA_PUNT="yes"
inherit gnome2

DESCRIPTION="GL extensions for Gtk+ 2.0"
HOMEPAGE="http://gtkglext.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.bz2"

LICENSE="GPL-2 LGPL-2.1"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~ppc ~ppc64 ~sh ~sparc ~x86 ~x86-fbsd ~amd64-linux ~x86-linux"
IUSE=""

RDEPEND=">=dev-libs/glib-2:2
	>=x11-libs/gtk+-2:2
	>=x11-libs/pango-1[X]
	|| ( x11-libs/pangox-compat <x11-libs/pango-1.31[X] )
	x11-libs/libX11
	x11-libs/libXmu
	virtual/glu
	virtual/opengl"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

pkg_setup() {
	DOCS="AUTHORS ChangeLog* NEWS README TODO"
	G2CONF="${G2CONF} --disable-static"
}

src_prepare() {
	gnome2_src_prepare

	# Remove development knobs, bug #308973
	sed -i 's:-D\(G.*DISABLE_DEPRECATED\):-D__\1__:g' \
		examples/Makefile.am examples/Makefile.in \
		gdk/Makefile.am gdk/Makefile.in \
		gdk/win32/Makefile.am gdk/win32/Makefile.in \
		gdk/x11/Makefile.am gdk/x11/Makefile.in \
		gtk/Makefile.am gtk/Makefile.in \
		|| die "sed failed"
}
