# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/clutter-gst/clutter-gst-1.9.92.ebuild,v 1.6 2013/02/02 22:46:17 ago Exp $

EAPI="5"
GCONF_DEBUG="yes"
CLUTTER_LA_PUNT="yes"

# inherit clutter after gnome2 so that defaults aren't overriden
# inherit gnome.org in the end so we use gnome mirrors and get the xz tarball
# no PYTHON_DEPEND, python2 is just a build-time dependency
inherit python gnome2 clutter gnome.org

DESCRIPTION="GStreamer integration library for Clutter"

SLOT="2.0"
KEYWORDS="~alpha ~amd64 ~arm ~ia64 ~ppc ~ppc64 ~sparc ~x86"
IUSE="examples +introspection"

# FIXME: Support for gstreamer-basevideo-0.10 (HW decoder support) is automagic
RDEPEND="
	>=dev-libs/glib-2.20:2
	>=media-libs/clutter-1.6.0:1.0=[introspection?]
	>=media-libs/cogl-1.8:1.0=[introspection?]
	media-libs/gstreamer:1.0[introspection?]
	media-libs/gst-plugins-bad:1.0
	media-libs/gst-plugins-base:1.0[introspection?]
	introspection? ( >=dev-libs/gobject-introspection-0.6.8 )
"
DEPEND="${RDEPEND}
	>=dev-util/gtk-doc-am-1.8
	=dev-lang/python-2*
	virtual/pkgconfig
"

pkg_setup() {
	python_set_active_version 2
	python_pkg_setup
}

src_prepare() {
	DOCS="AUTHORS NEWS README"
	EXAMPLES="examples/{*.c,*.png,README}"
	G2CONF="${G2CONF}
		--disable-maintainer-flags
		$(use_enable introspection)"

	# Make doc parallel installable
	cd "${S}"/doc/reference
	sed -e "s/\(DOC_MODULE.*=\).*/\1${PN}-${SLOT}/" \
		-e "s/\(DOC_MAIN_SGML_FILE.*=\).*/\1${PN}-docs-${SLOT}.sgml/" \
		-i Makefile.am Makefile.in || die
	sed -e "s/\(<book.*name=\"\)clutter-gst/\1${PN}-${SLOT}/" \
		-i html/clutter-gst.devhelp2 || die
	mv clutter-gst-docs{,-${SLOT}}.sgml || die
	mv clutter-gst-overrides{,-${SLOT}}.txt || die
	mv clutter-gst-sections{,-${SLOT}}.txt || die
	mv clutter-gst{,-${SLOT}}.types || die
	mv html/clutter-gst{,-${SLOT}}.devhelp2

	cd "${S}"
	gnome2_src_prepare
}

src_compile() {
	# Clutter tries to access dri without userpriv, upstream bug #661873
	# Massive failure of a hack, see bug 360219, bug 360073, bug 363917
	unset DISPLAY
	default
}
