# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/adplug/adplug-2.2.ebuild,v 1.3 2012/05/05 08:02:27 jdhore Exp $

inherit eutils

DESCRIPTION="A free, cross-platform, hardware independent AdLib sound player library"
HOMEPAGE="http://adplug.sourceforge.net"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.bz2"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"
IUSE="debug"

RDEPEND=">=dev-cpp/libbinio-1.4"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

src_compile() {
	econf --disable-dependency-tracking $(use_enable debug)
	emake || die "emake failed."
}

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed."
	dodoc AUTHORS BUGS ChangeLog NEWS README TODO
}
