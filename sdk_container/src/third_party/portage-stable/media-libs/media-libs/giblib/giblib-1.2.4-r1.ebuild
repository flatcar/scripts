# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/giblib/giblib-1.2.4-r1.ebuild,v 1.2 2013/01/04 15:26:42 ulm Exp $

EAPI="4"
inherit eutils

DESCRIPTION="a graphics library built on top of imlib2"
HOMEPAGE="http://freecode.com/projects/giblib http://www.linuxbrit.co.uk/giblib/"
SRC_URI="http://www.linuxbrit.co.uk/downloads/${P}.tar.gz"

LICENSE="feh"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ppc ~ppc64 ~sh ~sparc ~x86 ~x86-fbsd"
IUSE="static-libs"

RDEPEND=">=media-libs/imlib2-1.0.3[X]
	x11-libs/libX11
	x11-libs/libXext
	>=media-libs/freetype-2.0"
DEPEND="${RDEPEND}"

src_prepare() {
	sed -i 's:@LDFLAGS@::' giblib-config.in giblib.pc.in || die #430724
	sed -i "/^docsdir/s:=.*:= @datadir@/doc/${PF}:" Makefile.in || die
	epunt_cxx
}

src_configure() {
	econf $(use_enable static-libs static)
}
