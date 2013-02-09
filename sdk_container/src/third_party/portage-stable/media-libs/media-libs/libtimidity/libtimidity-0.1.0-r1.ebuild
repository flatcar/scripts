# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libtimidity/libtimidity-0.1.0-r1.ebuild,v 1.10 2012/05/05 08:02:40 jdhore Exp $

EAPI=2
inherit autotools eutils

DESCRIPTION="MIDI to WAVE converter library"
HOMEPAGE="http://libtimidity.sourceforge.net"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.bz2"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="amd64 hppa ppc ppc64 sparc x86"
IUSE="ao debug"

RDEPEND="ao? ( media-libs/libao )"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

RESTRICT="test"

src_prepare() {
	epatch "${FILESDIR}"/${P}-newlen-overflow.patch \
		"${FILESDIR}"/${P}-automagic.patch
	eautoreconf
}

src_configure() {
	econf \
		--disable-static \
		$(use_enable ao) \
		$(use_enable debug)
}

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"
	dodoc AUTHORS ChangeLog CHANGES NEWS TODO README*
}
