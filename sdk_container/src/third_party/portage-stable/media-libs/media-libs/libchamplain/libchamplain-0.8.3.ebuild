# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libchamplain/libchamplain-0.8.3.ebuild,v 1.9 2012/11/01 10:32:18 jlec Exp $

EAPI=3

GCONF_DEBUG=no

inherit eutils gnome2

DESCRIPTION="Clutter based world map renderer"
HOMEPAGE="http://projects.gnome.org/libchamplain/"

SLOT="0.8"
LICENSE="LGPL-2"
KEYWORDS="amd64 x86"
IUSE="debug doc gtk +introspection"

RDEPEND="
	dev-db/sqlite:3
	dev-libs/glib:2
	media-libs/clutter:1.0[introspection?]
	media-libs/memphis:0.2[introspection?]
	net-libs/libsoup-gnome:2.4
	x11-libs/cairo
	gtk? (
		x11-libs/gtk+:2[introspection?]
		media-libs/memphis:0.2[introspection?]
		media-libs/clutter-gtk:0.10 )"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	doc? ( dev-util/gtk-doc )
	introspection? ( dev-libs/gobject-introspection )"

src_prepare() {
	DOCS="AUTHORS ChangeLog NEWS README"
	G2CONF="${G2CONF}
		--disable-static
		--enable-memphis
		$(use_enable debug)
		$(use_enable gtk)
		$(use_enable introspection)"

	# Drop DEPRECATED flags, bug #387335
	sed \
		-e 's:-D[A-Z_]*DISABLE_DEPRECATED:$(NULL):g' \
		-i tidy/Makefile.am tidy/Makefile.in || die

	epatch "${FILESDIR}"/${P}-gthread.patch

	gnome2_src_prepare
}
