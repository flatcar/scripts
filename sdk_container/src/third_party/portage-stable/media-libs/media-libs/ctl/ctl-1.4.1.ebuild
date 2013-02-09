# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/ctl/ctl-1.4.1.ebuild,v 1.13 2012/05/05 08:02:44 jdhore Exp $

EAPI=2
inherit eutils libtool

DESCRIPTION="AMPAS' Color Transformation Language"
HOMEPAGE="http://sourceforge.net/projects/ampasctl"
SRC_URI="mirror://sourceforge/ampasctl/${P}.tar.gz"

LICENSE="AMPAS"
SLOT="0"
KEYWORDS="alpha amd64 hppa ia64 ppc ppc64 sparc x86 ~x86-fbsd"
IUSE="static-libs"

RDEPEND="media-libs/ilmbase"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

src_prepare() {
	epatch "${FILESDIR}"/${P}-gcc43.patch
	elibtoolize
}

src_configure() {
	econf \
		--disable-dependency-tracking \
		$(use_enable static-libs static)
}

src_install() {
	emake DESTDIR="${D}" docdir=/usr/share/doc/${PF} install || die
	dodoc AUTHORS ChangeLog NEWS README

	find "${D}" -name '*.la' -exec rm -f '{}' +
}
