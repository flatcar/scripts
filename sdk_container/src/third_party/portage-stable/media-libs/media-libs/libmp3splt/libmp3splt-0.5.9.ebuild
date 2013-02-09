# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libmp3splt/libmp3splt-0.5.9.ebuild,v 1.5 2012/05/21 19:08:12 xarthisius Exp $

EAPI=2
inherit multilib

DESCRIPTION="a library for mp3splt to split mp3 and ogg files without decoding."
HOMEPAGE="http://mp3splt.sourceforge.net"
SRC_URI="mirror://sourceforge/mp3splt/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 ~hppa ~ppc ~ppc64 sparc x86"
IUSE=""

RDEPEND="media-libs/libmad
	media-libs/libvorbis
	media-libs/libogg
	media-libs/libid3tag"
DEPEND="${RDEPEND}
	sys-apps/findutils"

src_configure() {
	econf \
		--disable-dependency-tracking \
		--disable-static
}

src_install() {
	emake DESTDIR="${D}" install || die
	dodoc AUTHORS ChangeLog LIMITS NEWS README TODO || die
	find "${D}"/usr -name '*.la' -delete
}
