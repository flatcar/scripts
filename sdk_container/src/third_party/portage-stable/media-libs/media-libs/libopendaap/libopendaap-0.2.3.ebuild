# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libopendaap/libopendaap-0.2.3.ebuild,v 1.10 2010/01/16 22:18:59 ulm Exp $

inherit eutils

DESCRIPTION="libopendaap is a library which enables applications to discover and connect to iTunes(R) music shares"
SRC_URI="http://crazney.net/programs/itunes/files/${P}.tar.bz2"
HOMEPAGE="http://crazney.net/programs/itunes/libopendaap.html"

LICENSE="MIT APSL-2"
SLOT="0"
KEYWORDS="amd64 x86 ppc"
IUSE=""

src_unpack() {
	unpack ${A}
	cd "${S}"
	epatch "${FILESDIR}"/${P}-types.h
}

src_install() {
	make DESTDIR="${D}" install || die
	dodoc AUTHORS ChangeLog
}
