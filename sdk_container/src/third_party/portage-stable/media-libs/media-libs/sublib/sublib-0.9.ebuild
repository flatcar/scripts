# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/sublib/sublib-0.9.ebuild,v 1.5 2009/04/30 15:36:06 ranger Exp $

inherit mono

DESCRIPTION="SubLib is a library that eases the development of subtitling
applications. It supports the most common text-based subtitle formats and allows
for subtitle editing, conversion and synchronization."
HOMEPAGE="http://sublib.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}.zip"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ppc x86"
IUSE=""

DEPEND="dev-lang/mono"
RDEPEND="${DEPEND}
	app-arch/unzip"

src_install() {
	einstall || die "einstall failed"
}
