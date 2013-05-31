# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/gptfdisk/gptfdisk-0.8.6.ebuild,v 1.11 2013/05/22 21:35:43 floppym Exp $

EAPI=5

inherit flag-o-matic toolchain-funcs

DESCRIPTION="GPT partition table manipulator for Linux"
HOMEPAGE="http://www.rodsbooks.com/gdisk/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm ~ia64 ~mips ppc ppc64 sparc x86 ~amd64-linux ~arm-linux ~x86-linux"
IUSE="+icu kernel_linux ncurses static"

LIB_DEPEND="dev-libs/popt[static-libs(+)]
	ncurses? ( >=sys-libs/ncurses-5.7-r7[static-libs(+)] )
	icu? ( dev-libs/icu:=[static-libs(+)] )
	kernel_linux? ( sys-apps/util-linux[static-libs(+)] )" # libuuid
RDEPEND="!static? ( ${LIB_DEPEND//\[static-libs(+)]} )"
DEPEND="${RDEPEND}
	static? ( ${LIB_DEPEND} )
	virtual/pkgconfig"

src_prepare() {
	tc-export CXX PKG_CONFIG

	if use icu; then
		append-cxxflags $(${PKG_CONFIG} --variable=CXXFLAGS icu-io icu-uc)
	else
		sed \
			-e 's:-licuio::g' \
			-e 's:-licuuc::g' \
			-e 's:-D USE_UTF16::g' \
			-i Makefile || die
	fi

	if ! use ncurses; then
		sed -i \
			-e '/^all:/s:cgdisk::' \
			Makefile || die
	fi

	sed \
		-e '/g++/s:=:?=:g' \
		-e "s:-lncurses:$(${PKG_CONFIG} --libs ncurses):g" \
		-i Makefile || die

	use static && append-ldflags -static
}

src_install() {
	dosbin gdisk sgdisk $(usex ncurses cgdisk '') fixparts
	doman *.8
	dodoc NEWS README
}
