# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libsamplerate/libsamplerate-0.1.7.ebuild,v 1.11 2012/05/05 08:02:31 jdhore Exp $

inherit eutils autotools

DESCRIPTION="Secret Rabbit Code (aka libsamplerate) is a Sample Rate Converter for audio"
HOMEPAGE="http://www.mega-nerd.com/SRC/"
SRC_URI="http://www.mega-nerd.com/SRC/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 sh sparc x86 ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos"
IUSE="sndfile"

RDEPEND="sndfile? ( >=media-libs/libsndfile-1.0.2 )"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

src_unpack() {
	unpack ${A}
	cd "${S}"
	epatch "${FILESDIR}"/${PN}-0.1.3-dontbuild-tests-examples.patch
	epatch "${FILESDIR}"/${P}-macro-quoting.patch
	epatch "${FILESDIR}"/${P}-tests.patch
	eautoreconf
}

src_compile() {
	econf \
		--disable-fftw \
		$(use_enable sndfile) \
		--disable-dependency-tracking
	emake || die
}

src_install() {
	emake DESTDIR="${D}" install || die "make install failed"
	dodoc AUTHORS ChangeLog NEWS README
	dohtml doc/*.html doc/*.css doc/*.png
}
