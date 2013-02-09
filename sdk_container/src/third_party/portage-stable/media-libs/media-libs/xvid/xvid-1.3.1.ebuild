# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/xvid/xvid-1.3.1.ebuild,v 1.2 2011/04/25 14:20:04 ssuominen Exp $

EAPI=2
inherit flag-o-matic multilib

MY_PN=${PN}core
MY_P=${MY_PN}-${PV}

DESCRIPTION="XviD, a high performance/quality MPEG-4 video de-/encoding solution"
HOMEPAGE="http://www.xvid.org/"
SRC_URI="http://downloads.xvid.org/downloads/${MY_P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~sparc ~x86 ~x86-fbsd"
IUSE="examples pic"

NASM=">=dev-lang/nasm-2"
YASM=">=dev-lang/yasm-1"

DEPEND="amd64? ( || ( ${YASM} ${NASM} ) )
	x86? ( || ( ${YASM} ${NASM} ) )
	x86-fbsd? ( || ( ${YASM} ${NASM} ) )"
RDEPEND=""

S=${WORKDIR}/${MY_PN}/build/generic

src_configure() {
	use sparc && append-cflags -mno-vis #357149

	local myconf
	use pic && myconf="--disable-assembly"

	econf ${myconf}
}

src_install() {
	emake DESTDIR="${D}" install || die
	dodoc "${S}"/../../{AUTHORS,ChangeLog*,CodingStyle,README,TODO}

	local mylib=$(basename $(ls "${D}"/usr/$(get_libdir)/libxvidcore.so*))
	dosym ${mylib} /usr/$(get_libdir)/libxvidcore.so
	dosym ${mylib} /usr/$(get_libdir)/${mylib%.?}

	if use examples; then
		insinto /usr/share/${PN}
		doins -r "${S}"/../../examples
	fi
}
