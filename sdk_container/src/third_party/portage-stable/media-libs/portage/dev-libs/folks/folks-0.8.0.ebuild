# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/folks/folks-0.8.0.ebuild,v 1.5 2013/02/02 22:24:49 ago Exp $

EAPI="5"
GCONF_DEBUG="yes"
GNOME2_LA_PUNT="yes"
VALA_MIN_API_VERSION="0.18"
VALA_USE_DEPEND="vapigen"

inherit eutils gnome2 vala virtualx

DESCRIPTION="libfolks is a library that aggregates people from multiple sources"
HOMEPAGE="http://telepathy.freedesktop.org/wiki/Folks"

LICENSE="LGPL-2.1+"
SLOT="0/25" # subslot = libfolks soname version
KEYWORDS="~alpha ~amd64 ~arm ~ia64 ~ppc ~ppc64 ~sparc ~x86 ~x86-linux"
# TODO: --enable-profiling
IUSE="eds socialweb +telepathy test tracker utils vala"

COMMON_DEPEND="
	>=dev-libs/glib-2.32:2
	dev-libs/dbus-glib
	<dev-libs/libgee-0.7:0[introspection]
	dev-libs/libxml2
	sys-libs/ncurses:=
	sys-libs/readline:=

	eds? ( >=gnome-extra/evolution-data-server-3.5.4:= )
	socialweb? ( >=net-libs/libsocialweb-0.25.20 )
	telepathy? (
		>=dev-libs/libzeitgeist-0.3.14:=
		>=net-libs/telepathy-glib-0.19 )
	tracker? ( >=app-misc/tracker-0.14:= )
"
# telepathy-mission-control needed at runtime; it is used by the telepathy
# backend via telepathy-glib's AccountManager binding.
RDEPEND="${COMMON_DEPEND}
	net-im/telepathy-mission-control
"
# folks socialweb backend requires that libsocialweb be built with USE=vala,
# even when building folks with --disable-vala.
DEPEND="${COMMON_DEPEND}
	>=dev-libs/gobject-introspection-1.30
	>=dev-util/intltool-0.50.0
	sys-devel/gettext
	virtual/pkgconfig

	socialweb? ( >=net-libs/libsocialweb-0.25.15[vala] )
	test? ( sys-apps/dbus )
	vala? (
		$(vala_depend)
		>=net-libs/telepathy-glib-0.13.1[vala]
		eds? ( >=gnome-extra/evolution-data-server-3.5.4:=[vala] ) )
"
# the inspect tool requires --enable-vala
REQUIRED_USE="utils? ( vala )"

src_prepare() {
	local vala_version=$(vala_best_api_version)
	# Rebuilding docs needs valadoc, which has no release
	G2CONF="${G2CONF}
		$(use_enable eds eds-backend)
		$(use_enable socialweb libsocialweb-backend)
		$(use_enable telepathy telepathy-backend)
		$(use_enable tracker tracker-backend)
		$(use_enable utils inspect-tool)
		$(use_enable vala)
		$(use_enable test tests)
		--enable-import-tool
		--disable-docs
		--disable-fatal-warnings
		VALAC=$(type -p valac-${vala_version})
		VAPIGEN=$(type -p vapigen-${vala_version})"

	# We don't need vala_src_prepare
	gnome2_src_prepare
}

src_test() {
	# FIXME: eds tests often fails for no good reason
	#sed -e 's/check: .*/check: /' \
	#	-i tests/eds/Makefile || die "sed failed"
	dbus-launch Xemake check
}
