# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libopendaap/libopendaap-0.4.0.ebuild,v 1.13 2010/01/16 22:18:59 ulm Exp $

inherit eutils

DESCRIPTION="libopendaap is a library which enables applications to discover and connect to iTunes(R) music shares"
SRC_URI="http://crazney.net/programs/itunes/files/${P}.tar.bz2"
HOMEPAGE="http://crazney.net/programs/itunes/libopendaap.html"

LICENSE="MIT"
SLOT="0"
KEYWORDS="alpha amd64 ppc ppc64 sparc x86"
IUSE=""

src_unpack() {
	unpack ${A}
	cd "${S}"

	epatch "${FILESDIR}"/${P}-freebsd.patch
}

src_install() {
	make DESTDIR="${D}" install || die
	dodoc AUTHORS ChangeLog
}
