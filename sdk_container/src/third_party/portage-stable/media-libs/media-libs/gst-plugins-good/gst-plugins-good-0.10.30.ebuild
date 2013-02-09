# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/gst-plugins-good/gst-plugins-good-0.10.30.ebuild,v 1.12 2012/12/02 23:00:27 eva Exp $

EAPI="3"

# order is important, gst-plugins10 after gst-plugins-good
inherit eutils flag-o-matic gst-plugins-good gst-plugins10

DESCRIPTION="Basepack of plugins for gstreamer"
HOMEPAGE="http://gstreamer.freedesktop.org/"

LICENSE="LGPL-2.1+"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 sh sparc x86 ~amd64-fbsd ~x86-fbsd"
IUSE="+orc"

RDEPEND="
	>=dev-libs/glib-2.22:2
	>=media-libs/gstreamer-0.10.33:${SLOT}
	>=media-libs/gst-plugins-base-0.10.33:${SLOT}
	app-arch/bzip2
	sys-libs/zlib
	orc? ( >=dev-lang/orc-0.4.11 )
"
DEPEND="${RDEPEND}
	>=dev-util/gtk-doc-am-1.12
	!<media-libs/gst-plugins-bad-0.10.22:${SLOT}
"
# audioparsers and qtmux moves

src_configure() {
	# gst doesnt handle optimisations well
	strip-flags
	replace-flags "-O3" "-O2"
	filter-flags "-fprefetch-loop-arrays" # see bug 22249

	# Always enable optional bz2 support for matroska
	# Always enable optional zlib support for qtdemux and matroska
	# Many media files require these to work, as some container headers are often
	# compressed, bug #291154
	gst-plugins10_src_configure \
		--enable-bz2 \
		--enable-zlib \
		--disable-examples \
		--with-default-audiosink=autoaudiosink \
		--with-default-visualizer=goom
}

src_compile() {
	emake || die
}

src_install() {
	emake install DESTDIR="${D}"|| die
	dodoc AUTHORS ChangeLog NEWS README RELEASE || die
	prune_libtool_files --modules
}
