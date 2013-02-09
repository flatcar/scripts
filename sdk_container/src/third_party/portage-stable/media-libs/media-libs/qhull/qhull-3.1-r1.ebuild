# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/qhull/qhull-3.1-r1.ebuild,v 1.17 2013/01/02 11:44:32 jer Exp $

inherit eutils

MY_P="${PN}${PV}"
DESCRIPTION="Geometry library"
HOMEPAGE="http://www.qhull.org"
SRC_URI="http://www.geom.umn.edu/software/qhull/${MY_P}.tgz"

SLOT="0"
LICENSE="BSD"
KEYWORDS="amd64 ppc x86"
IUSE=""

S="${WORKDIR}/${MY_P}"

src_unpack() {
	unpack ${A}
	cd "${S}"/src
	mv Makefile.txt Makefile
	# Replaced sed/echo hacks by a clean patch. Fix build error on -fPIC archs
	# BUG #82646
	# Danny van Dyk <kugelfang@gentoo.org> 2005/02/22
	epatch "${FILESDIR}"/${P}-makefile.patch
}

src_compile() {
	cd src
	emake CCOPTS1="${CFLAGS}" || die "emake failed"
}

src_install() {
	cd src

	dolib libqhull.a || die "dolib failed"
	dolib.so libqhull.so || die "dolib.so failed"
	dobin qconvex qdelaunay qhalf qhull qvoronoi rbox || die "dobin failed"

	insinto /usr/include/qhull
	doins *.h

	cd "${S}"
	dodoc Announce.txt COPYING.txt File_id.diz README.txt REGISTER.txt
	cd html
	dohtml *
	dodoc *.txt
	for m in *man
	do
		newman ${m} ${m/.man/.1}
	done
}
