# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-irc/cwirc/cwirc-2.0.0.ebuild,v 1.7 2012/05/03 06:27:15 jdhore Exp $

EAPI=2
inherit eutils multilib toolchain-funcs

DESCRIPTION="An X-chat plugin for sending and receiving raw morse code over IRC"
HOMEPAGE="http://myspace.voo.be/pcoupard/cwirc/"
SRC_URI="http://myspace.voo.be/pcoupard/cwirc/download/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ~ppc x86"
IUSE=""

RDEPEND="x11-libs/gtk+:2
	>=net-irc/xchat-2.0.1"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

src_prepare() {
	epatch "${FILESDIR}"/cwirc-1.7.1-gentoo.patch \
		"${FILESDIR}"/${P}-asneeded.patch
}

src_compile() {
	emake STRIP="true" CC="$(tc-getCC)" CFLAGS="${CFLAGS} -DLINUX" || die
}

src_install() {
	emake DESTDIR="${D}" LIBDIR="/usr/$(get_libdir)" install || die

	dodoc README RELEASE_NOTES Changelog
	docinto schematics
	dodoc schematics/*
}
