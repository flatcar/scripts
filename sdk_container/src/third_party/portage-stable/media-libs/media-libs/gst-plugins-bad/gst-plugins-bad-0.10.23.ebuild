# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/gst-plugins-bad/gst-plugins-bad-0.10.23.ebuild,v 1.1 2012/12/02 17:30:57 eva Exp $

EAPI="5"

inherit eutils flag-o-matic gst-plugins-bad gst-plugins10

DESCRIPTION="Less plugins for GStreamer"
HOMEPAGE="http://gstreamer.freedesktop.org/"

LICENSE="LGPL-2"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~ppc ~ppc64 ~sparc ~x86 ~amd64-fbsd ~x86-fbsd ~amd64-linux ~x86-linux"
IUSE="+orc"

RDEPEND="
	>=dev-libs/glib-2.24:2
	>=media-libs/gst-plugins-base-0.10.36:${SLOT}
	>=media-libs/gstreamer-0.10.36:${SLOT}
	orc? ( >=dev-lang/orc-0.4.11 )
"
DEPEND="${RDEPEND}"
RDEPEND="${RDEPEND}
	!<media-plugins/gst-plugins-farsight-0.12.11:${SLOT}"

src_configure() {
	strip-flags
	replace-flags "-O3" "-O2"
	filter-flags "-fprefetch-loop-arrays" # (Bug #22249)

	gst-plugins10_src_configure \
		$(use_enable orc) \
		--disable-examples \
		--disable-debug
}

src_compile() {
	default
}

src_install() {
	DOCS="AUTHORS ChangeLog NEWS README RELEASE"
	default
	prune_libtool_files --modules
}
