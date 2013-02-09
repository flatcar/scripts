# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libjackasyn/libjackasyn-0.10.ebuild,v 1.12 2012/06/09 00:02:31 zmedico Exp $

IUSE=""

inherit eutils multilib

DESCRIPTION="An application/library for connecting OSS apps to Jackit."
HOMEPAGE="http://gige.xdv.org/soft/libjackasyn"
SRC_URI="http://gige.xdv.org/soft/libjackasyn/download/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 sparc x86"

DEPEND="media-sound/jack-audio-connection-kit
	media-libs/libsamplerate"

src_unpack() {
	unpack ${A}
	cd ${S}
	epatch ${FILESDIR}/${P}-destdir.patch
}

src_compile() {
	econf || die
	emake -j1 || die
}

src_install() {
	dodir /usr/bin
	dodir /usr/$(get_libdir)
	dodir /usr/include

	make DESTDIR="${D}" libdir="/usr/$(get_libdir)" install || die
	dodoc AUTHORS CHANGELOG WORKING TODO
}
