# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/flac/flac-1.2.1-r4.ebuild,v 1.3 2012/05/15 13:39:06 aballier Exp $

EAPI=2
inherit autotools eutils

DESCRIPTION="free lossless audio encoder and decoder"
HOMEPAGE="http://flac.sourceforge.net"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz
	mirror://gentoo/${P}-embedded-m4.tar.bz2"

LICENSE="BSD FDL-1.2 GPL-2 LGPL-2.1"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~sh ~sparc ~x86 ~amd64-fbsd ~x86-fbsd"
IUSE="3dnow altivec +cxx debug ogg sse static-libs"

RDEPEND="ogg? ( >=media-libs/libogg-1.1.3 )"
DEPEND="${RDEPEND}
	x86? ( dev-lang/nasm )
	!elibc_uclibc? ( sys-devel/gettext )
	virtual/pkgconfig"

src_prepare() {
	epatch \
		"${FILESDIR}"/${P}-asneeded.patch \
		"${FILESDIR}"/${P}-cflags.patch \
		"${FILESDIR}"/${P}-asm.patch \
		"${FILESDIR}"/${P}-dontbuild-tests.patch \
		"${FILESDIR}"/${P}-dontbuild-examples.patch \
		"${FILESDIR}"/${P}-gcc-4.3-includes.patch \
		"${FILESDIR}"/${P}-ogg-m4.patch

	cp "${WORKDIR}"/*.m4 m4 || die

	AT_M4DIR="m4" eautoreconf
}

src_configure() {
	econf \
		$(use_enable static-libs static) \
		--disable-dependency-tracking \
		$(use_enable debug) \
		$(use_enable sse) \
		$(use_enable 3dnow) \
		$(use_enable altivec) \
		--disable-doxygen-docs \
		--disable-xmms-plugin \
		$(use_enable cxx cpplibs) \
		$(use_enable ogg) \
		--disable-examples
}

src_test() {
	if [ $UID != 0 ]; then
		emake check || die
	else
		ewarn "Tests will fail if ran as root, skipping."
	fi
}

src_install() {
	emake DESTDIR="${D}" install || die

	rm -rf "${D}"/usr/share/doc/${P}
	dodoc AUTHORS README
	dohtml -r doc/html/*

	find "${D}" -name '*.la' -exec rm -f '{}' +
}
