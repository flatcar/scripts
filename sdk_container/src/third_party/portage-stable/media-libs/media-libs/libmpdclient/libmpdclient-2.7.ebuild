# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libmpdclient/libmpdclient-2.7.ebuild,v 1.8 2012/07/29 16:02:32 armin76 Exp $

EAPI=4

DESCRIPTION="A library for interfacing Music Player Daemon (media-sound/mpd)"
HOMEPAGE="http://www.musicpd.org"
SRC_URI="mirror://sourceforge/musicpd/${PN}/${PV}/${P}.tar.bz2"

LICENSE="BSD"
SLOT="0"
KEYWORDS="amd64 arm hppa ppc ppc64 sparc x86"
IUSE="doc examples static-libs"

RDEPEND=""
DEPEND="doc? ( app-doc/doxygen )"

src_prepare() {
	sed -e "s:@top_srcdir@:.:" -i doc/doxygen.conf.in
}

src_configure() {
	econf \
		--docdir="${EPREFIX}"/usr/share/doc/${PF} \
		$(use_enable static-libs static)
}

src_install() {
	default
	use examples && dodoc src/example.c
	use doc || rm -rf "${ED}"/usr/share/doc/${PF}/html
	find "${ED}" -name "*.la" -exec rm -rf {} + || die "failed to delete .la files"
}
