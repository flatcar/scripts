# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/lib3ds/lib3ds-1.3.0.ebuild,v 1.9 2012/12/01 18:30:57 blueness Exp $

DESCRIPTION="library for managing 3D-Studio Release 3 and 4 .3DS files"
HOMEPAGE="http://lib3ds.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}.zip"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="amd64 ppc ppc64 x86"
IUSE=""

RDEPEND="media-libs/freeglut
	virtual/opengl"
DEPEND="${RDEPEND}
	app-arch/unzip"

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"
	dodoc AUTHORS ChangeLog README
}
