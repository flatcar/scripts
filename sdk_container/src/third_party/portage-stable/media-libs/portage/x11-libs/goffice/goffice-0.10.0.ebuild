# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/goffice/goffice-0.10.0.ebuild,v 1.1 2012/12/24 10:05:09 pacho Exp $

EAPI="5"
GCONF_DEBUG="no"
GNOME2_LA_PUNT="yes"

inherit gnome2 flag-o-matic

DESCRIPTION="A library of document-centric objects and utilities"
HOMEPAGE="http://git.gnome.org/browse/goffice/"

LICENSE="GPL-2"
SLOT="0.10"
KEYWORDS="~alpha ~amd64 ~arm ~ia64 ~ppc ~ppc64 ~sparc ~x86 ~x86-fbsd ~amd64-linux ~x86-linux ~x64-solaris"
IUSE="+introspection"

# Build fails with -gtk
# FIXME: add lasem to tree
RDEPEND=">=app-text/libspectre-0.2.6:=
	>=dev-libs/glib-2.28.0:2
	>=gnome-base/librsvg-2.22.0:2
	>=gnome-extra/libgsf-1.14.9:=
	>=dev-libs/libxml2-2.4.12:2
	>=x11-libs/pango-1.24.0:=
	>=x11-libs/cairo-1.10.0:=[svg]
	x11-libs/libXext:=
	x11-libs/libXrender:=
	>=x11-libs/gdk-pixbuf-2.22.0:2
	>=x11-libs/gtk+-3.0.0:3
	introspection? ( >=dev-libs/gobject-introspection-1.0.0:=
			>=gnome-extra/libgsf-1.14.23:= )
"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	>=dev-util/intltool-0.35
	>=dev-util/gtk-doc-am-1.12"
#	gnome-base/gnome-common"
# eautoreconf requires: gnome-common

src_prepare() {
	G2CONF+="
		--without-lasem
		--with-gtk
		--with-config-backend=gsettings
		$(use_enable introspection)"
	filter-flags -ffast-math
}
