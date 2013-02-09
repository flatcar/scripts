# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libofa/libofa-0.9.3.ebuild,v 1.25 2012/06/04 12:51:28 jlec Exp $

EAPI=2

inherit base eutils flag-o-matic

DESCRIPTION="Open Fingerprint Architecture"
HOMEPAGE="http://code.google.com/p/musicip-libofa/"
SRC_URI="http://musicip-libofa.googlecode.com/files/${P}.tar.gz"

LICENSE="|| ( APL-1.0 GPL-2 )"
SLOT="0"
KEYWORDS="alpha amd64 hppa ppc ppc64 sparc x86 ~amd64-linux ~x86-linux"
IUSE=""

RDEPEND="dev-libs/expat
	net-misc/curl
	>=sci-libs/fftw-3"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

PATCHES=(
	"${FILESDIR}"/${P}-gcc-4.patch
	"${FILESDIR}"/${P}-gcc-4.3.patch
	"${FILESDIR}"/${P}-gcc-4.4.patch
	"${FILESDIR}"/${P}-gcc-4.7.patch
	"${FILESDIR}"/${P}-curl-7.21.patch
)

pkg_setup() {
	is-flag -ffast-math && append-flags -fno-fast-math
}

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed."
	dodoc AUTHORS README
}
