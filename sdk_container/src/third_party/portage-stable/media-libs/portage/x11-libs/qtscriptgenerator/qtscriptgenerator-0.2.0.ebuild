# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/qtscriptgenerator/qtscriptgenerator-0.2.0.ebuild,v 1.5 2012/12/30 14:04:37 kensington Exp $

EAPI=4

MY_PN="${PN}-src"
MY_P="${MY_PN}-${PV}"

inherit eutils multilib qt4-r2

DESCRIPTION="Tool for generating Qt bindings for Qt Script"
HOMEPAGE="http://code.google.com/p/qtscriptgenerator/"
SRC_URI="http://qtscriptgenerator.googlecode.com/files/${MY_P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ppc ~ppc64 x86"
IUSE="debug kde"

DEPEND="
	x11-libs/qt-core:4
	x11-libs/qt-gui:4
	x11-libs/qt-opengl:4
	!kde? ( || (
		x11-libs/qt-phonon:4
		media-libs/phonon
	) )
	kde? ( media-libs/phonon )
	x11-libs/qt-script:4
	x11-libs/qt-sql:4
	x11-libs/qt-svg:4
	x11-libs/qt-webkit:4
	x11-libs/qt-xmlpatterns:4
"
RDEPEND="${DEPEND}"

PLUGINS="core gui network opengl sql svg uitools webkit xml xmlpatterns"

S="${WORKDIR}/${MY_P}"

src_prepare() {
	# remove phonon
	sed -i "/typesystem_phonon.xml/d" generator/generator.qrc || die "sed failed"
	sed -i "/qtscript_phonon/d" qtbindings/qtbindings.pro || die "sed failed"

	use arm && epatch "${FILESDIR}"/${P}-arm.patch

	qt4-r2_src_prepare
}

src_configure() {
	cd "${S}"/generator
	eqmake4 generator.pro
	cd "${S}"/qtbindings
	eqmake4 qtbindings.pro
}

src_compile() {
	cd "${S}"/generator
	emake
	./generator --include-paths="/usr/include/qt4/" || die "running generator failed"

	cd "${S}"/qtbindings
	emake
}

src_install() {
	insinto /usr/$(get_libdir)/qt4/plugins/script/
	insopts -m0755
	doins -r "${S}"/plugins/script/*
}
