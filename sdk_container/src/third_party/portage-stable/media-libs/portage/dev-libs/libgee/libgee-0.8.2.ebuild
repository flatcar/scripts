# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libgee/libgee-0.8.2.ebuild,v 1.1 2012/11/21 23:27:46 eva Exp $

EAPI="4"
GCONF_DEBUG="no"
GNOME2_LA_PUNT="yes"
VALA_MIN_API_VERSION="0.18"

inherit gnome2 multilib vala

DESCRIPTION="GObject-based interfaces and classes for commonly used data structures."
HOMEPAGE="http://live.gnome.org/Libgee"

LICENSE="LGPL-2.1+"
SLOT="0.8"
KEYWORDS="~alpha ~amd64 ~arm ~ia64 ~ppc ~ppc64 ~sh ~sparc ~x86 ~x86-linux"
IUSE="+introspection"

# FIXME: add doc support, requires valadoc
RDEPEND="
	>=dev-libs/glib-2.12:2
	introspection? ( >=dev-libs/gobject-introspection-0.9.6 )"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	>=dev-lang/vala-0.17.5
	$(vala_depend)"

DOCS="AUTHORS ChangeLog* MAINTAINERS NEWS README"

src_configure() {
	G2CONF="${G2CONF} $(use_enable introspection)"
	gnome2_src_configure
}

src_prepare() {
	vala_src_prepare
	gnome2_src_prepare
}
