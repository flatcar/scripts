# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/folks/folks-0.4.3.ebuild,v 1.8 2012/05/04 18:35:44 jdhore Exp $

EAPI="3"
GCONF_DEBUG="yes"

inherit gnome2

DESCRIPTION="libfolks is a library that aggregates people from multiple sources"
HOMEPAGE="http://telepathy.freedesktop.org/wiki/Folks"

LICENSE="LGPL-2"
SLOT="0"
KEYWORDS="alpha amd64 ia64 ppc sparc x86 ~x86-linux"
IUSE=""

# FIXME: links against system libfolks instead of the built one
RDEPEND=">=dev-libs/glib-2.24:2
	>=net-libs/telepathy-glib-0.13.1[vala]
	dev-libs/dbus-glib
	<dev-libs/libgee-0.7:0
	dev-libs/libxml2
	sys-libs/ncurses
	sys-libs/readline
"
DEPEND="${RDEPEND}
	>=dev-util/intltool-0.35.0
	virtual/pkgconfig
	>=dev-lang/vala-0.11.6:0.12[vapigen]
	>=dev-libs/gobject-introspection-0.9.12
	sys-devel/gettext
"

pkg_setup() {
	DOCS="AUTHORS ChangeLog NEWS README"
	G2CONF="${G2CONF}
		--enable-import-tool
		--enable-inspect-tool
		--enable-vala
		VALAC=$(type -p valac-0.12)
		VAPIGEN=$(type -p vapigen-0.12)
		--disable-docs
		--disable-Werror"
	# Rebuilding docs needs valadoc, which has no release
}

src_install() {
	gnome2_src_install
	find "${ED}" -name "*.la" -delete || die "la files removal failed"
}
