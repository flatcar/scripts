# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/compface/compface-1.5.1.ebuild,v 1.13 2011/08/13 13:25:59 hattya Exp $

EAPI="4"

inherit autotools eutils

DESCRIPTION="Utilities and library to convert to/from X-Face format"
HOMEPAGE="http://www.xemacs.org/Download/optLibs.html"
SRC_URI="http://ftp.xemacs.org/pub/xemacs/aux/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="alpha amd64 hppa ia64 ppc ppc64 sparc x86"
IUSE=""

src_prepare() {
	sed -i "s:\r::" Makefile.in xbm2xface.pl
	epatch "${FILESDIR}"/${P}-destdir.diff
	eautoreconf
}

src_install() {
	dodir /usr/share/man/man{1,3} /usr/{bin,include,$(get_libdir)}
	emake DESTDIR="${D}" install
	dodoc ChangeLog README
	newbin xbm2xface{.pl,}
}
