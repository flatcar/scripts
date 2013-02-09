# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/gst-plugins-ugly/gst-plugins-ugly-1.0.5.ebuild,v 1.1 2013/01/22 22:36:57 eva Exp $

EAPI="5"

# order is important, gst-plugins10 after gst-plugins
inherit eutils flag-o-matic gst-plugins-ugly gst-plugins10

DESCRIPTION="Basepack of plugins for gstreamer"
HOMEPAGE="http://gstreamer.sourceforge.net"

LICENSE="GPL-2"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~sh ~sparc ~x86 ~amd64-fbsd ~x86-fbsd"
IUSE="+orc"

RDEPEND="
	>=dev-libs/glib-2.32:2
	>=media-libs/gstreamer-1:${SLOT}
	>=media-libs/gst-plugins-base-1:${SLOT}
	orc? ( >=dev-lang/orc-0.4.16 )
"
DEPEND="${RDEPEND}
	>=dev-util/gtk-doc-am-1.12
"

src_configure() {
	# gst doesnt handle optimisations well
	strip-flags
	replace-flags "-O3" "-O2"
	filter-flags "-fprefetch-loop-arrays" # see bug 22249

	gst-plugins10_src_configure
}

src_compile() {
	default
}

src_install() {
	DOCS="AUTHORS ChangeLog NEWS README RELEASE"
	default
	prune_libtool_files --modules
}
