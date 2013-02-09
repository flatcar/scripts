# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libmnote/libmnote-0.5.6.ebuild,v 1.12 2012/05/05 08:02:29 jdhore Exp $

DESCRIPTION="libmnote is a library for parsing, editing, and saving MakerNote-EXIF-tags."
HOMEPAGE="http://libexif.sf.net"
SRC_URI="mirror://sourceforge/libexif/${P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="alpha ppc ~sparc x86"
IUSE="nls"

RDEPEND=">=media-libs/libexif-0.5.9"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

src_compile() {
	local myconf
	use nls || myconf="${myconf} --disable-nls"
	econf ${myconf} || die "econf failed"
	emake || die
}

src_install() {
	dodir /usr/lib
	dodir /usr/include/libmnote
	dodir /usr/share/locale
	dodir /usr/lib/pkgconfig
	einstall || die
}
