# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libchamplain/libchamplain-0.10.1.ebuild,v 1.5 2012/11/01 10:32:18 jlec Exp $

EAPI=4

GCONF_DEBUG=no
GNOME2_LA_PUNT=yes
GNOME_TARBALL_SUFFIX=bz2

inherit eutils gnome2

DESCRIPTION="Clutter based world map renderer"
HOMEPAGE="http://projects.gnome.org/libchamplain/"

SLOT="0.10"
LICENSE="LGPL-2"
KEYWORDS="~amd64 ~x86"
IUSE="debug doc +gtk +introspection vala"

REQUIRED_USE="vala? ( introspection )"

RDEPEND="
	dev-db/sqlite:3
	dev-libs/glib:2
	media-libs/clutter:1.0[introspection?]
	media-libs/memphis:0.2[introspection?]
	net-libs/libsoup-gnome:2.4
	x11-libs/cairo
	gtk? (
		x11-libs/gtk+:3[introspection?]
		media-libs/clutter-gtk:1.0 )
	introspection? ( dev-libs/gobject-introspection )"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	doc? ( dev-util/gtk-doc )
	vala? ( dev-lang/vala:0.14[vapigen] )"

src_prepare() {
	DOCS="AUTHORS ChangeLog NEWS README"
	# Vala demos are only built, so just disable them
	G2CONF="${G2CONF}
		--disable-maintainer-mode
		--disable-static
		--disable-maemo
		--disable-vala-demos
		--enable-memphis
		VAPIGEN=$(type -p vapigen-0.14)
		$(use_enable debug)
		$(use_enable gtk)
		$(use_enable introspection)
		$(use_enable vala)"

	# Fix documentation slotability
	sed \
		-e "s/^DOC_MODULE.*/DOC_MODULE = ${PN}-${SLOT}/" \
		-i docs/reference/Makefile.{am,in} || die "sed (1) failed"
	sed \
		-e "s/^DOC_MODULE.*/DOC_MODULE = ${PN}-gtk-${SLOT}/" \
		-i docs/reference-gtk/Makefile.{am,in} || die "sed (2) failed"
	mv "${S}"/docs/reference/${PN}{,-${SLOT}}-docs.sgml || die "mv (1) failed"
	mv "${S}"/docs/reference-gtk/${PN}-gtk{,-${SLOT}}-docs.sgml || die "mv (2) failed"

	epatch "${FILESDIR}"/${PN}-gthread.patch

	gnome2_src_prepare
}
