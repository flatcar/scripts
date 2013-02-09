# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/liblqr/liblqr-0.4.1.ebuild,v 1.17 2012/05/09 17:32:37 aballier Exp $

EAPI="2"

DESCRIPTION="An easy to use C/C++ seam carving library"
HOMEPAGE="http://liblqr.wikidot.com/"
SRC_URI="http://liblqr.wikidot.com/local--files/en:download-page/${PN}-1-${PV}.tar.bz2"

LICENSE="|| ( GPL-3 LGPL-3 )"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ppc ppc64 x86 ~amd64-fbsd ~x86-fbsd"
IUSE="doc"

RDEPEND="dev-libs/glib"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

S=$WORKDIR/${PN}-1-${PV}

src_configure() {
	econf $(use_enable doc install-man)
}

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"
	dodoc AUTHORS ChangeLog NEWS README TODO || die "dodoc failed"
}
