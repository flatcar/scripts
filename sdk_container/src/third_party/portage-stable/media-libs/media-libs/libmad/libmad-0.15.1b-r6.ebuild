# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libmad/libmad-0.15.1b-r6.ebuild,v 1.7 2010/10/26 09:12:43 jer Exp $

inherit eutils autotools libtool flag-o-matic

DESCRIPTION="\"M\"peg \"A\"udio \"D\"ecoder library"
HOMEPAGE="http://mad.sourceforge.net"
SRC_URI="mirror://sourceforge/mad/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 sh sparc x86 ~x86-fbsd"
IUSE="debug"

DEPEND=""

src_unpack() {
	unpack ${A}
	cd "${S}"

	epatch "${FILESDIR}"/libmad-0.15.1b-cflags.patch
	epatch "${FILESDIR}"/libmad-0.15.1b-cflags-O2.patch
	epatch "${FILESDIR}"/libmad-0.15.1b-gcc44-mips-h-constraint-removal.patch

	eautoreconf

	elibtoolize
	epunt_cxx #74490
}

src_compile() {
	local myconf="--enable-accuracy"
	# --enable-speed		 optimize for speed over accuracy
	# --enable-accuracy		 optimize for accuracy over speed
	# --enable-experimental	 enable code using the EXPERIMENTAL
	#						 preprocessor define

	# Fix for b0rked sound on sparc64 (maybe also sparc32?)
	# default/approx is also possible, uses less cpu but sounds worse
	use sparc && myconf="${myconf} --enable-fpm=64bit"

	[[ $(tc-arch) == "amd64" ]] && myconf="${myconf} --enable-fpm=64bit"
	[[ $(tc-arch) == "x86" ]] && myconf="${myconf} --enable-fpm=intel"
	[[ $(tc-arch) == "ppc" ]] && myconf="${myconf} --enable-fpm=ppc"
	[[ $(tc-arch) == "ppc64" ]] && myconf="${myconf} --enable-fpm=64bit"

	econf \
		$(use_enable debug debugging) \
		${myconf} || die "configure failed"
	emake || die "make failed"
}

src_install() {
	emake install DESTDIR="${D}" || die "make install failed"

	dodoc CHANGES CREDITS README TODO VERSION

	# This file must be updated with each version update
	insinto /usr/$(get_libdir)/pkgconfig
	doins "${FILESDIR}"/mad.pc

	# Use correct libdir in pkgconfig file
	dosed "s:^libdir.*:libdir=/usr/$(get_libdir):" \
		/usr/$(get_libdir)/pkgconfig/mad.pc

	find "${D}" -name '*.la' -delete
}
