# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/gst-plugins-base/gst-plugins-base-0.10.36.ebuild,v 1.10 2013/02/03 23:52:28 ago Exp $

EAPI="5"

inherit gst-plugins-base gst-plugins10

DESCRIPTION="Basepack of plugins for gstreamer"
HOMEPAGE="http://gstreamer.freedesktop.org/"

LICENSE="GPL-2+ LGPL-2+"
KEYWORDS="~alpha amd64 ~arm ~hppa ia64 ~mips ppc ppc64 ~sh ~sparc x86 ~amd64-fbsd ~x86-fbsd ~x86-freebsd ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE="+introspection nls +orc"

RDEPEND=">=dev-libs/glib-2.24:2
	>=media-libs/gstreamer-${PV}:0.10[introspection?]
	dev-libs/libxml2:2
	sys-libs/zlib
	app-text/iso-codes
	introspection? ( >=dev-libs/gobject-introspection-0.9.12 )
	orc? ( >=dev-lang/orc-0.4.11 )
"
DEPEND="${RDEPEND}
	>=dev-util/gtk-doc-am-1.3
"
RDEPEND="${RDEPEND}
	!<media-libs/gst-plugins-bad-0.10.10:0.10
"

src_prepare() {
	# The AC_PATH_XTRA macro unnecessarily pulls in libSM and libICE even
	# though they are not actually used. This needs to be fixed upstream by
	# replacing AC_PATH_XTRA with PKG_CONFIG calls.
	sed -i -e 's:X_PRE_LIBS -lSM -lICE:X_PRE_LIBS:' "${S}"/configure || die
}

src_configure() {
	gst-plugins10_src_configure \
		$(use_enable introspection) \
		$(use_enable nls) \
		$(use_enable orc) \
		--disable-examples \
		--disable-debug \
		--disable-static

	# bug #366931, flag-o-matic for the whole thing is overkill
	if [[ ${CHOST} == *86-*-darwin* ]] ; then
		sed -i \
			-e '/FLAGS = /s|-O[23]|-O1|g' \
			gst/audioconvert/Makefile \
			gst/volume/Makefile || die
	fi
}

src_compile() {
	default
}

src_install() {
	DOCS="AUTHORS NEWS README RELEASE"
	default
	prune_libtool_files --modules
}
