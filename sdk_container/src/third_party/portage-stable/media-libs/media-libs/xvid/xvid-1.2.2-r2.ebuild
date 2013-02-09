# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/xvid/xvid-1.2.2-r2.ebuild,v 1.9 2010/10/30 15:48:30 ssuominen Exp $

EAPI=2
inherit eutils multilib

MY_PN=${PN}core
MY_P=${MY_PN}-${PV}

DESCRIPTION="XviD, a high performance/quality MPEG-4 video de-/encoding solution"
HOMEPAGE="http://www.xvid.org"
SRC_URI="http://downloads.xvid.org/downloads/${MY_P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 sparc x86 ~x86-fbsd"
IUSE="examples pic"

NASM=">=dev-lang/nasm-2.05.01"
YASM=">=dev-lang/yasm-0.8.0"

DEPEND="amd64? ( || ( ${YASM} ${NASM} ) )
	x86? ( || ( ${YASM} ${NASM} ) )
	x86-fbsd? ( || ( ${YASM} ${NASM} ) )"
RDEPEND=""

S=${WORKDIR}/${MY_PN}/build/generic

src_prepare() {
	cd "${WORKDIR}"
	epatch "${FILESDIR}"/${P}-noexecstack.patch

	sed -i \
		-e '/^minimum_yasm_minor_version/s:=.*:=0:' \
		"${S}"/configure || die
}

src_configure() {
	local myconf

	if use pic; then
		myconf="--disable-assembly"
	fi

	econf ${myconf}
}

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"
	dodoc "${S}"/../../{AUTHORS,ChangeLog*,CodingStyle,README,TODO}

	local mylib=$(basename $(ls "${D}"/usr/$(get_libdir)/libxvidcore.so*))
	dosym ${mylib} /usr/$(get_libdir)/libxvidcore.so
	dosym ${mylib} /usr/$(get_libdir)/${mylib%.?}

	if use examples; then
		insinto /usr/share/${PN}
		doins -r "${S}"/../../examples
	fi
}
