# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/clutter-gtk/clutter-gtk-1.4.2.ebuild,v 1.4 2013/02/02 22:46:40 ago Exp $

EAPI="5"
GCONF_DEBUG="yes"
CLUTTER_LA_PUNT="yes"

# inherit clutter after gnome2 so that defaults aren't overriden
inherit gnome2 clutter gnome.org

DESCRIPTION="Library for embedding a Clutter canvas (stage) in GTK+"
HOMEPAGE="http://live.gnome.org/Clutter"

SLOT="1.0"
KEYWORDS="~alpha ~amd64 ~arm ~ia64 ~mips ~ppc ~ppc64 ~sparc ~x86"
IUSE="examples +introspection"

RDEPEND="
	>=x11-libs/gtk+-3.2.0:3[introspection?]
	>=media-libs/clutter-1.9.16:1.0[introspection?]
	media-libs/cogl:1.0=[introspection?]
	introspection? ( >=dev-libs/gobject-introspection-0.9.12 )"
DEPEND="${RDEPEND}
	dev-util/gtk-doc-am
	>=sys-devel/gettext-0.18
	virtual/pkgconfig"

src_prepare() {
	DOCS="NEWS README"
	EXAMPLES="examples/{*.c,redhand.png}"
	G2CONF="${G2CONF}
		--disable-maintainer-flags
		--enable-deprecated
		$(use_enable introspection)"
	gnome2_src_prepare
}
