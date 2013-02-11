# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/seed/seed-3.2.0-r1.ebuild,v 1.8 2013/02/02 22:27:32 ago Exp $

EAPI="4"
WANT_AUTOMAKE="1.11"
GNOME2_LA_PUNT="yes"

inherit autotools eutils gnome2 virtualx

DESCRIPTION="Javascript bindings for Webkit-GTK and GNOME libraries"
HOMEPAGE="http://live.gnome.org/Seed"

LICENSE="LGPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~ia64 ~ppc ~ppc64 ~sparc ~x86"
IUSE="debug doc profile test"

RDEPEND="
	>=dev-libs/gobject-introspection-1

	dev-libs/glib:2
	virtual/libffi
	x11-libs/cairo
	x11-libs/gtk+:3[introspection]
	net-libs/webkit-gtk:3
	gnome-base/gnome-js-common
	dev-db/sqlite:3
	dev-libs/dbus-glib
	dev-libs/mpfr
	dev-libs/libxml2:2
	sys-apps/dbus
	sys-libs/readline"
DEPEND="${RDEPEND}
	sys-devel/gettext
	virtual/pkgconfig
	>=dev-util/intltool-0.35
	doc? ( >=dev-util/gtk-doc-0.9 )
	profile? ( sys-devel/gcc )"

DOCS="AUTHORS ChangeLog NEWS README"

# Lots of tests fail: https://bugzilla.gnome.org/show_bug.cgi?id=660644
RESTRICT="test"

pkg_setup() {
	G2CONF="${G2CONF}
		--disable-static
		--with-webkit=3.0
		--enable-readline-module
		--enable-os-module
		--enable-ffi-module
		--enable-gtkbuilder-module
		--enable-cairo-module
		--enable-gettext-module
		--enable-dbus-module
		--enable-mpfr-module
		--enable-sqlite-module
		--enable-libxml-module
		--docdir=${EPREFIX}/usr/share/doc/${PF}/html"

	# configure behaves very strangely and enables profiling if we pass either
	# --disable-profile or --enable-profile
	if use profile; then
		G2CONF="${G2CONF}
			--enable-profile
			--enable-profile-modules"
		if ! use debug; then
			elog "USE=profile needs debug, auto-enabling..."
			G2CONF="${G2CONF} --enable-debug"
		fi
	fi

	if use profile && has ccache ${FEATURES}; then
		ewarn "USE=profile behaves very badly with ccache; it tries to create"
		ewarn "profiling data in CCACHE_DIR. Please disable one of them!"
	fi
}

src_prepare() {
	# Upstream patch to fix linking with libgio; will be in next release
	epatch "${FILESDIR}/${P}-gio-libs.patch"
	eautoreconf

	gnome2_src_prepare
}

src_test() {
	Xemake check
}

src_install() {
	gnome2_src_install
	# Don't install two copies of standard doc files
	rm "${ED}/usr/share/doc/${PF}/html/"{AUTHORS,ChangeLog,COPYING,INSTALL,README} || die
}
