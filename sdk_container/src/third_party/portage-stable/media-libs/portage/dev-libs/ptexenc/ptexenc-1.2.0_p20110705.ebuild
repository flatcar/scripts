# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/ptexenc/ptexenc-1.2.0_p20110705.ebuild,v 1.12 2012/05/09 12:52:27 aballier Exp $

EAPI=3

DESCRIPTION="Library for Japanese pTeX providing a better way of handling character encodings"
HOMEPAGE="http://tutimura.ath.cx/ptexlive/?ptexenc"
SRC_URI="mirror://gentoo/texlive-${PV#*_p}-source.tar.xz"
# http://tutimura.ath.cx/~nob/tex/ptexlive/ptexenc/${P}.tar.xz

LICENSE="BSD"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~amd64-fbsd ~x86-fbsd ~ppc-macos ~x86-macos"
IUSE="iconv static-libs"

DEPEND="iconv? ( virtual/libiconv )
	dev-libs/kpathsea"
RDEPEND="${DEPEND}"

S=${WORKDIR}/texlive-${PV#*_p}-source/texk/${PN}
#S=${WORKDIR}/texlive-${PV#*_p}-source/texk/${P}
#src_unpack() {
#	unpack ${A}
#	mv "${WORKDIR}/${P}" "${S}"
#}

src_prepare() {
	default

	# https://bugs.gentoo.org/show_bug.cgi?id=377141
	sed -i '/^LIBS/s:@LIBS@:@LIBS@ @KPATHSEA_LIBS@:' "${S}"/Makefile.in || die
}

src_configure() {
	econf \
		--with-system-kpathsea \
		$(use_enable static-libs static) \
		$(use_enable iconv kanji-iconv)
}

src_install() {
	emake DESTDIR="${D}" install || die
	find "${D}" -name '*.la' -delete

	dodoc ChangeLog README || die
}
