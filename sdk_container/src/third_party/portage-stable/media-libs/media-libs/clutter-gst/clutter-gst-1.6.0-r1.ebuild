# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/clutter-gst/clutter-gst-1.6.0-r1.ebuild,v 1.6 2013/02/02 22:46:17 ago Exp $

EAPI="5"
GCONF_DEBUG="yes"
CLUTTER_LA_PUNT="yes"

# inherit clutter after gnome2 so that defaults aren't overriden
# inherit gnome.org in the end so we use gnome mirrors and get the xz tarball
# no PYTHON_DEPEND, python2 is just a build-time dependency
inherit python gnome2 clutter gnome.org

DESCRIPTION="GStreamer integration library for Clutter"

SLOT="1.0"
KEYWORDS="~alpha ~amd64 ~arm ~ia64 ~ppc ~ppc64 ~sparc ~x86"
IUSE="examples +introspection"

# FIXME: Support for gstreamer-basevideo-0.10 (HW decoder support) is automagic
RDEPEND="
	>=dev-libs/glib-2.20:2
	>=media-libs/clutter-1.6.0:1.0=[introspection?]
	>=media-libs/cogl-1.8:1.0=[introspection?]
	>=media-libs/gstreamer-0.10.26:0.10[introspection?]
	>=media-libs/gst-plugins-bad-0.10.22:0.10
	media-libs/gst-plugins-base:0.10[introspection?]
	introspection? ( >=dev-libs/gobject-introspection-0.6.8 )"
DEPEND="${RDEPEND}
	=dev-lang/python-2*
	dev-util/gtk-doc-am
	virtual/pkgconfig"

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

	# bug #401383, https://bugzilla.gnome.org/show_bug.cgi?id=669054
	# FIXME: is this still needed? I don't think so, but not sure. ~nirbheek
	#eautoreconf

	# In 1.6.1
	epatch "${FILESDIR}/${P}-glint.patch"
	epatch "${FILESDIR}/${P}-doc-fixes.patch"
	# In 1.9.2
	epatch "${FILESDIR}/${PN}-1.6.0-gluint.patch"
	epatch "${FILESDIR}/${PN}-1.6.0-GL_TEXTURE_2D.patch"

	gnome2_src_prepare
}

src_compile() {
	# Clutter tries to access dri without userpriv, upstream bug #661873
	# Massive failure of a hack, see bug 360219, bug 360073, bug 363917
	unset DISPLAY
	default
}
