# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-firmware/sgabios/sgabios-0.1_pre8.ebuild,v 1.5 2014/04/30 21:07:36 vapier Exp $

EAPI=4

inherit eutils toolchain-funcs

DESCRIPTION="serial graphics adapter bios option rom for x86"
HOMEPAGE="http://code.google.com/p/sgabios/"
SRC_URI="mirror://gentoo/${P}.tar.xz
	http://dev.gentoo.org/~cardoe/distfiles/${P}.tar.xz
	http://dev.gentoo.org/~cardoe/distfiles/${P}-bins.tar.xz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64 ~ppc ~ppc64 x86"
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}"

pkg_setup() {
	local myld=$(tc-getLD)

	${myld} -v | grep -q "GNU gold" && \
	ewarn "gold linker unable to handle 16-bit code using ld.bfd. bug #438058"
}

src_prepare() {
	epatch "${FILESDIR}"/${P}-makefile.patch
	epatch_user
}

src_compile() {
	if use amd64 || use x86 ; then
		emake CC=$(tc-getCC) LD="$(tc-getLD).bfd" AR=$(tc-getAR) \
			OBJCOPY=$(tc-getOBJCOPY)
	fi
}

src_install() {
	insinto /usr/share/sgabios

	if use amd64 || use x86 ; then
		doins sgabios.bin
	else
		doins bins/sgabios.bin
	fi
}
