# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/sg/sg-1.4.ebuild,v 1.6 2012/10/24 19:14:28 ulm Exp $

EAPI="3"

inherit autotools eutils multilib

DESCRIPTION="Socket Graphics tool for displaying polygons"
HOMEPAGE="http://fetk.org/codes/sg/index.html"
SRC_URI="http://www.fetk.org/codes/download/${P}.tar.gz"

SLOT="0"
KEYWORDS="~amd64 ~x86 ~amd64-linux ~x86-linux"
LICENSE="GPL-2"
IUSE="doc opengl"

RDEPEND="
	dev-libs/maloc
	x11-libs/libXaw
	x11-libs/motif
	opengl? (
		|| (
			<media-libs/mesa-8[motif]
			( media-libs/mesa x11-libs/libGLw )
			media-libs/opengl-apple )
	)"
DEPEND="
	${RDEPEND}
	doc? (
		media-gfx/graphviz
		app-doc/doxygen )"

S="${WORKDIR}"/${PN}

src_prepare() {
	rm src/{gl,glu,glw} -rf
	epatch \
		"${FILESDIR}"/${PV}-opengl.patch \
		"${FILESDIR}"/${PV}-doc.patch
	eautoreconf
}

src_configure() {
	local sg_include
	local sg_lib
	local myconf

	sg_include="${EPREFIX}"/usr/include
	sg_lib="${EPREFIX}"/usr/$(get_libdir)
	export FETK_LIBRARY="${sg_lib}"
	export FETK_MOTIF_LIBRARY="${sg_lib}"
	export FETK_GL_LIBRARY="${sg_lib}"
	export FETK_GLU_LIBRARY="${sg_lib}"
	export FETK_GLW_LIBRARY="${sg_lib}"
	export FETK_INCLUDE="${sg_include}"
	export FETK_GLW_INCLUDE="${sg_include}"
	export FETK_GLU_INCLUDE="${sg_include}"
	export FETK_GL_INCLUDE="${sg_include}"/GL
	export FETK_MOTIF_INCLUDE="${sg_include}"

	use doc || myconf="${myconf} --with-doxygen= --with-dot="

	use opengl && myconf="${myconf} --enable-glforce --enable-gluforce --enable-glwforce"

	econf \
		--docdir="${EPREFIX}"/usr/share/doc/${PF} \
		--disable-triplet \
		--enable-shared \
		${myconf}
}

src_install() {
	emake DESTDIR="${D}" install || die
}
