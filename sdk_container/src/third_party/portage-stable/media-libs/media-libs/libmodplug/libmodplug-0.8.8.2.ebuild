# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libmodplug/libmodplug-0.8.8.2.ebuild,v 1.9 2012/05/05 08:02:32 jdhore Exp $

EAPI=2
inherit autotools eutils

DESCRIPTION="Library for playing MOD-like music files"
SRC_URI="mirror://sourceforge/modplug-xmms/${P}.tar.gz"
HOMEPAGE="http://modplug-xmms.sourceforge.net/"

LICENSE="public-domain"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 sh sparc x86 ~x86-fbsd ~x86-freebsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~x86-solaris"
IUSE="static-libs"

RDEPEND=""
DEPEND="virtual/pkgconfig"

src_prepare() {
	sed -i \
		-e '/CXXFLAGS/s:-ffast-math::' \
		configure.in || die

	epatch "${FILESDIR}"/${PN}-0.8.4-timidity-patches.patch

	eautoreconf
}

src_configure() {
	econf \
		--disable-dependency-tracking \
		$(use_enable static-libs static)
}

src_install() {
	emake DESTDIR="${D}" install || die
	dodoc AUTHORS ChangeLog NEWS README TODO

	find "${D}" -name '*.la' -delete
}
