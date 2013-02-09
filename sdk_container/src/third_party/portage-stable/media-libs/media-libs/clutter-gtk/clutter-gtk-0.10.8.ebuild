# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/clutter-gtk/clutter-gtk-0.10.8.ebuild,v 1.14 2012/12/17 19:50:36 tetromino Exp $

EAPI="2"

# inherit clutter after gnome2 so that defaults aren't overriden
inherit autotools eutils gnome2 clutter

DESCRIPTION="Library for embedding a Clutter canvas (stage) in GTK+"
HOMEPAGE="http://live.gnome.org/Clutter"

SLOT="0.10"
KEYWORDS="amd64 ppc ppc64 x86"
IUSE="debug examples +introspection"

# XXX: Needs gtk with X support (!directfb)
RDEPEND="
	>=x11-libs/gtk+-2.19.5:2[introspection?]
	>=media-libs/clutter-1.2:1.0[introspection?]
	introspection? ( >=dev-libs/gobject-introspection-0.9.3 )"
DEPEND="${RDEPEND}
	>=dev-util/gtk-doc-am-1.14"
EXAMPLES="examples/{*.c,redhand.png}"

pkg_setup() {
	G2CONF="${G2CONF}
		--with-flavour=x11
		--enable-maintainer-flags=no
		$(use_enable introspection)"
}

src_prepare() {
	# Fix build with USE=introspection, bug #350061
	epatch "${FILESDIR}/${PN}-0.10.8-fix-introspection-build.patch"

	# Drop DEPRECATED flags, bug #387173
	sed -i -e 's:-D[A-Z_]*DISABLE_DEPRECATED:$(NULL):g' \
		clutter-gtk/Makefile.am || die

	# Fix underlinking problem with gold.ld
	epatch "${FILESDIR}"/${P}-gold.patch

	eautoreconf
	gnome2_src_prepare
}
