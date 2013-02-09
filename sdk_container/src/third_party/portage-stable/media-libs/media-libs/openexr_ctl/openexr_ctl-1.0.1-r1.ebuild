# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/openexr_ctl/openexr_ctl-1.0.1-r1.ebuild,v 1.10 2012/05/05 08:02:27 jdhore Exp $

EAPI=2
inherit autotools eutils

DESCRIPTION="OpenEXR CTL libraries"
HOMEPAGE="http://sourceforge.net/projects/ampasctl"
SRC_URI="mirror://sourceforge/ampasctl/${P}.tar.gz"

LICENSE="AMPAS"
SLOT="0"
KEYWORDS="alpha amd64 hppa ia64 ppc ppc64 sparc x86 ~x86-fbsd"
IUSE=""

RDEPEND="media-libs/ilmbase
	media-libs/openexr
	media-libs/ctl"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

src_prepare() {
	epatch "${FILESDIR}"/${P}-gcc43.patch \
		"${FILESDIR}"/${P}-configure_gcc43.patch \
		"${FILESDIR}"/${P}-pkgconfig.patch \
		"${FILESDIR}"/${P}-gcc44.patch
	eautoreconf
}

src_install() {
	emake DESTDIR="${D}" install || die
	dodoc AUTHORS ChangeLog NEWS README
}
