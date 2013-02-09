# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/emfengine/emfengine-0.8.ebuild,v 1.3 2012/07/26 15:35:42 kensington Exp $

EAPI="3"

inherit eutils qt4-r2

MY_PN="EmfEngine"

DESCRIPTION="Native vector graphics file format on Windows"
HOMEPAGE="http://soft.proindependent.com/emf/index.html"
SRC_URI="mirror://berlios/qtiplot/${MY_PN}-${PV}-opensource.zip"

SLOT="0"
KEYWORDS="~amd64 ~x86 ~amd64-linux ~x86-linux"
LICENSE="GPL-3"
IUSE=""

RDEPEND="
	x11-libs/qt-gui:4
	media-libs/libpng
	media-libs/libemf"
DEPEND="${RDEPEND}
	app-arch/unzip"

S="${WORKDIR}"/${MY_PN}

PATCHES=(
	"${FILESDIR}/0.7-config.patch"
	"${FILESDIR}/0.7-header.patch"
	"${FILESDIR}"/${PV}-example.patch
	)

src_prepare() {
	edos2unix EmfEngine.pro
	qt4-r2_src_prepare
	sed \
		-e "s:/usr/local/lib/libEMF.a:-lEMF:g" \
		-e "s:/usr/local/include:${EPREFIX}/usr/include/:g" \
		-i src/src.pro example/example.pro || die
}

src_install() {
	dolib.so libEmfEngine.so* || die
	insinto /usr/include
	doins src/*.h* || die
}
