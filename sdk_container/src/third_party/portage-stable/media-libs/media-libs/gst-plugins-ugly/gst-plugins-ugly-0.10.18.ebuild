# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/gst-plugins-ugly/gst-plugins-ugly-0.10.18.ebuild,v 1.11 2012/12/02 22:53:18 eva Exp $

EAPI="3"

# order is important, gst-plugins10 after gst-plugins
inherit eutils flag-o-matic gst-plugins-ugly gst-plugins10

DESCRIPTION="Basepack of plugins for gstreamer"
HOMEPAGE="http://gstreamer.sourceforge.net"

LICENSE="GPL-2"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 sh sparc x86 ~amd64-fbsd ~x86-fbsd"
IUSE=""

RDEPEND="
	>=dev-libs/glib-2.20:2
	>=media-libs/gstreamer-0.10.26:${SLOT}
	>=media-libs/gst-plugins-base-0.10.26:${SLOT}
"
DEPEND="${RDEPEND}
	>=dev-util/gtk-doc-am-1.3
"
RDEPEND="${RDEPEND}
	!<media-libs/gst-plugins-bad-0.10.13"

src_configure() {
	# gst doesnt handle optimisations well
	strip-flags
	replace-flags "-O3" "-O2"
	filter-flags "-fprefetch-loop-arrays" # see bug 22249

	gst-plugins10_src_configure
}

src_compile() {
	emake || die
}

src_install() {
	emake install DESTDIR="${D}" || die
	dodoc AUTHORS ChangeLog NEWS README RELEASE || die
	prune_libtool_files --modules
}
