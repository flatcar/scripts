# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libmodplug/libmodplug-0.8.8.4.ebuild,v 1.10 2012/05/15 13:12:50 aballier Exp $

EAPI=4
inherit autotools base

DESCRIPTION="Library for playing MOD-like music files"
SRC_URI="mirror://sourceforge/modplug-xmms/${P}.tar.gz"
HOMEPAGE="http://modplug-xmms.sourceforge.net/"

LICENSE="public-domain"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 sh sparc x86 ~amd64-fbsd ~x86-fbsd ~x86-freebsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~x86-solaris"
IUSE="static-libs"

RDEPEND=""
DEPEND="virtual/pkgconfig"

PATCHES=(  "${FILESDIR}/${PN}-0.8.4-timidity-patches.patch"
	   "${FILESDIR}/${P}-no-fast-math.patch" )

src_prepare() {
	base_src_prepare
	eautoreconf
}

src_configure() {
	econf \
		$(use_enable static-libs static)
}

src_install() {
	emake DESTDIR="${D}" install
	dodoc AUTHORS ChangeLog NEWS README TODO
	find "${D}" -name '*.la' -delete
}
