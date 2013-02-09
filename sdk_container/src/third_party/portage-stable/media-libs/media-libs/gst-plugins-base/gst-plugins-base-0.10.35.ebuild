# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/gst-plugins-base/gst-plugins-base-0.10.35.ebuild,v 1.18 2012/12/02 23:04:05 eva Exp $

EAPI="3"
GCONF_DEBUG="no"

# order is important, gnome2 after gst-plugins
inherit gst-plugins-base gst-plugins10 gnome2 eutils
# libtool

DESCRIPTION="Basepack of plugins for gstreamer"
HOMEPAGE="http://gstreamer.freedesktop.org/"
SRC_URI="http://gstreamer.freedesktop.org/src/${PN}/${P}.tar.bz2"

LICENSE="GPL-2+ LGPL-2+"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 sh sparc x86 ~amd64-fbsd ~x86-fbsd ~x86-freebsd ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE="+introspection nls +orc"

RDEPEND=">=dev-libs/glib-2.22:2
	>=media-libs/gstreamer-0.10.34:0.10[introspection?]
	dev-libs/libxml2:2
	app-text/iso-codes
	introspection? ( >=dev-libs/gobject-introspection-0.9.12 )
	orc? ( >=dev-lang/orc-0.4.11 )
	!<media-libs/gst-plugins-bad-0.10.10:0.10"
DEPEND="${RDEPEND}
	nls? ( >=sys-devel/gettext-0.11.5 )
	virtual/pkgconfig"
	# Only if running eautoreconf: dev-util/gtk-doc-am

GST_PLUGINS_BUILD=""

DOCS="AUTHORS NEWS README RELEASE"

src_configure() {
	gst-plugins10_src_configure \
		$(use_enable introspection) \
		$(use_enable nls) \
		$(use_enable orc) \
		--disable-examples \
		--disable-debug

	# bug #366931, flag-o-matic for the whole thing is overkill
	if [[ ${CHOST} == *86-*-darwin* ]] ; then
		sed -i \
			-e '/FLAGS = /s|-O[23]|-O1|g' \
			gst/audioconvert/Makefile \
			gst/volume/Makefile || die
	fi
}

src_install() {
	gnome2_src_install
}
