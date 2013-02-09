# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/clutter/clutter-1.8.4.ebuild,v 1.9 2012/12/05 23:12:48 tetromino Exp $

EAPI="5"
CLUTTER_LA_PUNT="yes"
WANT_AUTOMAKE="1.11"

# Inherit gnome2 after clutter to download sources from gnome.org
# since clutter-project.org doesn't provide .xz tarballs
inherit clutter gnome2

DESCRIPTION="Clutter is a library for creating graphical user interfaces"

SLOT="1.0"
IUSE="debug doc +introspection"
KEYWORDS="~alpha amd64 ~mips ppc ppc64 x86"

# NOTE: glx flavour uses libdrm + >=mesa-7.3
# XXX: uprof needed for profiling
# >=libX11-1.3.1 needed for X Generic Event support
RDEPEND="
	>=dev-libs/glib-2.28:2
	>=dev-libs/atk-2.1.5[introspection?]
	>=dev-libs/json-glib-0.12[introspection?]
	>=media-libs/cogl-1.8.0:1.0=[introspection?,pango]
	<=media-libs/cogl-1.9.2:1.0
	media-libs/fontconfig
	>=x11-libs/cairo-1.10[glib]
	>=x11-libs/pango-1.20[introspection?]

	virtual/opengl
	x11-libs/libdrm
	>=x11-libs/libX11-1.3.1
	x11-libs/libXext
	x11-libs/libXdamage
	x11-proto/inputproto
	>=x11-libs/libXi-1.3
	>=x11-libs/libXfixes-3
	>=x11-libs/libXcomposite-0.4

	introspection? ( >=dev-libs/gobject-introspection-0.9.6 )"
DEPEND="${RDEPEND}
	sys-devel/gettext
	virtual/pkgconfig
	>=dev-util/gtk-doc-am-1.13
	doc? (
		>=dev-util/gtk-doc-1.13
		>=app-text/docbook-sgml-utils-0.6.14[jadetex]
		dev-libs/libxslt )"

src_prepare() {
	DOCS="README NEWS ChangeLog*"

	# XXX: Conformance test suite (and clutter itself) does not work under Xvfb
	# XXX: Profiling, coverage disabled for now
	# XXX: What about eglx/eglnative/opengl-egl-xlib/osx/wayland/etc flavours?
	#      Uses gudev-1.0 and libxkbcommon for eglnative/cex1000
	myconf="--enable-debug=minimum"
	use debug && myconf="--enable-debug=yes"
	G2CONF="${G2CONF} ${myconf}
		--enable-conformance=no
		--disable-gcov
		--enable-profile=no
		--enable-maintainer-flags=no
		--enable-xinput
		--with-flavour=glx
		$(use_enable introspection)
		$(use_enable doc docs)"

	gnome2_src_prepare

	# We only need conformance tests, the rest are useless for us
	sed -e 's/^\(SUBDIRS =\).*/\1/g' \
		-i tests/Makefile.am || die "am tests sed failed"
	sed -e 's/^\(SUBDIRS =\)[^\]*/\1/g' \
		-i tests/Makefile.in || die "in tests sed failed"
}

src_install() {
	clutter_src_install
}
