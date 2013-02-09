# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/quesoglc/quesoglc-0.7.2.ebuild,v 1.5 2012/05/05 08:02:43 jdhore Exp $

EAPI=2
DESCRIPTION="A free implementation of the OpenGL Character Renderer (GLC)"
HOMEPAGE="http://quesoglc.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}-free.tar.bz2"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="amd64 ppc sparc x86"
IUSE="doc examples"

RDEPEND="virtual/opengl
	virtual/glu
	media-libs/fontconfig
	media-libs/freetype:2
	dev-libs/fribidi"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	doc? ( app-doc/doxygen )"

src_prepare() {
	rm -rf src/fribidi
}

src_configure() {
	# Uses its own copy of media-libs/glew with GLEW_MX
	econf \
		--disable-dependency-tracking \
		--disable-executables \
		--with-fribidi \
		--without-glew
}

src_compile() {
	emake || die "emake failed"
	if use doc ; then
		cd docs
		doxygen -u Doxyfile && doxygen || die "doxygen failed"
	fi
}

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"
	dodoc AUTHORS ChangeLog README THANKS
	if use doc ; then
		dohtml docs/html/* || die "dohtml failed"
	fi
	if use examples ; then
		insinto /usr/share/doc/${PF}/examples
		doins examples/*.c || die "doins failed"
	fi
}
