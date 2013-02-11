# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libgee/libgee-0.8.3.ebuild,v 1.1 2012/12/24 12:45:32 pacho Exp $

EAPI="5"
GCONF_DEBUG="no"
VALA_MIN_API_VERSION="0.18"

inherit gnome2 multilib vala

DESCRIPTION="GObject-based interfaces and classes for commonly used data structures"
HOMEPAGE="https://live.gnome.org/Libgee"

LICENSE="LGPL-2.1+"
SLOT="0.8"
KEYWORDS="~alpha ~amd64 ~arm ~ia64 ~ppc ~ppc64 ~sh ~sparc ~x86 ~x86-linux"
IUSE="+introspection"

# FIXME: add doc support, requires valadoc
RDEPEND="
	>=dev-libs/glib-2.12:2
	introspection? ( >=dev-libs/gobject-introspection-0.9.6:= )"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	$(vala_depend)"

src_configure() {
	DOCS="AUTHORS ChangeLog* MAINTAINERS NEWS README"
	G2CONF+=" $(use_enable introspection)"
	gnome2_src_configure
}
