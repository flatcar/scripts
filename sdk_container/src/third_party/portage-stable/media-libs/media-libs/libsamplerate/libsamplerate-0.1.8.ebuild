# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libsamplerate/libsamplerate-0.1.8.ebuild,v 1.3 2012/05/29 13:29:27 aballier Exp $

EAPI=4

inherit eutils autotools

DESCRIPTION="Secret Rabbit Code (aka libsamplerate) is a Sample Rate Converter for audio"
HOMEPAGE="http://www.mega-nerd.com/SRC/"
SRC_URI="http://www.mega-nerd.com/SRC/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~sh ~sparc ~x86 ~amd64-fbsd ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos"
IUSE="sndfile static-libs"

RDEPEND="sndfile? ( >=media-libs/libsndfile-1.0.2 )"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

src_prepare() {
	epatch "${FILESDIR}"/${PN}-0.1.3-dontbuild-tests-examples.patch \
		"${FILESDIR}"/${P}-lm.patch
	AT_M4DIR="M4" eautoreconf
}

src_configure() {
	econf \
		--disable-fftw \
		$(use_enable sndfile) \
		$(use_enable static-libs static)
}

src_install() {
	emake DESTDIR="${ED}" htmldocdir="${EPREFIX}/usr/share/doc/${PF}/html" install
	dodoc AUTHORS ChangeLog NEWS README
	find "${ED}" -name '*.la' -exec rm -f '{}' +
}
