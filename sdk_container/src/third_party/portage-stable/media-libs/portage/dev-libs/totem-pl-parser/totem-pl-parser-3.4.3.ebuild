# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/totem-pl-parser/totem-pl-parser-3.4.3.ebuild,v 1.3 2012/09/25 02:48:18 blueness Exp $

EAPI="4"
GCONF_DEBUG="no"
GNOME2_LA_PUNT="yes"

inherit gnome2

DESCRIPTION="Playlist parsing library"
HOMEPAGE="http://projects.gnome.org/totem/ http://developer.gnome.org/totem-pl-parser/stable/"

LICENSE="LGPL-2+"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~ia64 ~ppc ~ppc64 ~sparc ~x86 ~x86-fbsd"
IUSE="archive crypt doc +introspection +quvi test"

RDEPEND=">=dev-libs/glib-2.31:2
	dev-libs/gmime:2.4
	>=net-libs/libsoup-gnome-2.30:2.4
	archive? ( >=app-arch/libarchive-2.8.4 )
	crypt? ( dev-libs/libgcrypt )
	introspection? ( >=dev-libs/gobject-introspection-0.9.5 )
	quvi? ( >=media-libs/libquvi-0.2.15 )"
DEPEND="${RDEPEND}
	!<media-video/totem-2.21
	>=dev-util/intltool-0.35
	>=sys-devel/gettext-0.17
	virtual/pkgconfig
	doc? ( >=dev-util/gtk-doc-1.14 )
	test? (
		gnome-base/gvfs[http]
		sys-apps/dbus )"
# eautoreconf needs:
#	>=dev-util/gtk-doc-am-1.14

pkg_setup() {
	G2CONF="${G2CONF}
		--disable-static
		--disable-maintainer-mode
		$(use_enable archive libarchive)
		$(use_enable crypt libgcrypt)
		$(use_enable quvi)
		$(use_enable introspection)"
	DOCS="AUTHORS ChangeLog NEWS"
}

src_prepare() {
	# Avoid glib-2.34 dependency for now, bug #435408
	epatch "${FILESDIR}/${P}-no-g_clear_pointer.patch"

	gnome2_src_prepare

	# Disable tests requiring network access, bug #346127
	sed -e 's:\(g_test_add_func.*/parser/resolution.*\):/*\1*/:' \
		-e 's:\(g_test_add_func.*/parser/parsing/itms_link.*\):/*\1*/:' \
		-i plparse/tests/parser.c || die "sed failed"
}

src_test() {
	# This is required as told by upstream in bgo#629542
	GVFS_DISABLE_FUSE=1 dbus-launch emake check || die "emake check failed"
}
