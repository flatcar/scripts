# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/schroedinger/schroedinger-1.0.8.ebuild,v 1.16 2012/05/05 08:02:26 jdhore Exp $

EAPI=3
inherit libtool

DESCRIPTION="C-based libraries for the Dirac video codec"
HOMEPAGE="http://www.diracvideo.org/"
SRC_URI="http://www.diracvideo.org/download/${PN}/${P}.tar.gz"

LICENSE="GPL-2 LGPL-2 MIT MPL-1.1"
SLOT="0"
KEYWORDS="amd64 hppa ppc x86 ~x86-fbsd ~x86-freebsd ~amd64-linux ~ia64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~x86-solaris"
IUSE=""

RDEPEND=">=dev-libs/liboil-0.3.16"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

src_prepare() {
	elibtoolize
}

src_configure() {
	econf \
		--disable-dependency-tracking \
		--with-html-dir="${EPREFIX}/usr/share/doc/${PF}/html"
}

src_install() {
	emake DESTDIR="${D}" install || die
	dodoc AUTHORS NEWS TODO
}
