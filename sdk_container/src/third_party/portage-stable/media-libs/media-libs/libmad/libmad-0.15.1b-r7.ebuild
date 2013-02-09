# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libmad/libmad-0.15.1b-r7.ebuild,v 1.9 2012/08/22 02:55:24 ottxor Exp $

EAPI=4

inherit eutils autotools libtool flag-o-matic

DESCRIPTION="\"M\"peg \"A\"udio \"D\"ecoder library"
HOMEPAGE="http://mad.sourceforge.net"
SRC_URI="mirror://sourceforge/mad/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 sh sparc x86 ~amd64-fbsd ~x86-fbsd ~ppc-aix ~x86-freebsd ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~x86-solaris"
IUSE="debug static-libs"

DEPEND=""
RDEPEND=""

DOCS="CHANGES CREDITS README TODO VERSION"

src_prepare() {
	epatch \
		"${FILESDIR}"/libmad-0.15.1b-cflags.patch \
		"${FILESDIR}"/libmad-0.15.1b-cflags-O2.patch \
		"${FILESDIR}"/libmad-0.15.1b-gcc44-mips-h-constraint-removal.patch

	eautoreconf

	elibtoolize
	epunt_cxx #74490
}

src_configure() {
	local myconf="--enable-accuracy"
	# --enable-speed		 optimize for speed over accuracy
	# --enable-accuracy		 optimize for accuracy over speed
	# --enable-experimental	 enable code using the EXPERIMENTAL
	#						 preprocessor define

	# Fix for b0rked sound on sparc64 (maybe also sparc32?)
	# default/approx is also possible, uses less cpu but sounds worse
	use sparc && myconf+=" --enable-fpm=64bit"

	[[ $(tc-arch) == "amd64" ]] && myconf+=" --enable-fpm=64bit"
	[[ $(tc-arch) == "x86" ]] && myconf+=" --enable-fpm=intel"
	[[ $(tc-arch) == "ppc" ]] && myconf+=" --enable-fpm=default"
	[[ $(tc-arch) == "ppc64" ]] && myconf+=" --enable-fpm=64bit"

	econf \
		$(use_enable debug debugging) \
		$(use_enable static-libs static) \
		${myconf}
}

src_install() {
	default

	# This file must be updated with each version update
	insinto /usr/$(get_libdir)/pkgconfig
	doins "${FILESDIR}"/mad.pc

	# Use correct libdir in pkgconfig file
	sed -i -e "s:^libdir.*:libdir=${EPREFIX}/usr/$(get_libdir):" \
		"${ED}"/usr/$(get_libdir)/pkgconfig/mad.pc

	find "${ED}" -name '*.la' -delete
}
