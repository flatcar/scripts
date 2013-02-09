# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libvisual/libvisual-0.4.0-r2.ebuild,v 1.14 2013/02/02 22:51:26 ago Exp $

EAPI=4
inherit eutils libtool

DESCRIPTION="Libvisual is an abstraction library that comes between applications and audio visualisation plugins."
HOMEPAGE="http://libvisual.sourceforge.net"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0.4"
KEYWORDS="~alpha amd64 ~arm hppa ~ia64 ~mips ppc ppc64 ~sparc x86 ~amd64-fbsd ~x86-fbsd"
IUSE="debug nls static-libs threads"

RDEPEND="threads? ( dev-libs/glib:2 )"
DEPEND="${RDEPEND}
	nls? ( sys-devel/gettext )
	virtual/pkgconfig"

DOCS=( AUTHORS ChangeLog NEWS README TODO )

src_prepare() {
	epatch \
		"${FILESDIR}"/${P}-better-altivec-detection.patch \
		"${FILESDIR}"/${P}-inlinedefineconflict.patch
	elibtoolize #sane .so versionning on fbsd and .so -> .so.version symlink
}

src_configure() {
	econf \
		$(use_enable static-libs static) \
		--enable-shared \
		$(use_enable nls) \
		$(use_enable threads) \
		$(use_enable debug)
}

src_install() {
	default
	find "${D}" -name '*.la' -exec rm -f {} +
}
