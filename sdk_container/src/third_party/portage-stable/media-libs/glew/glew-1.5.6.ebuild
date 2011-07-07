# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/glew/glew-1.5.6.ebuild,v 1.8 2010/10/29 05:41:52 jer Exp $

EAPI=3
inherit multilib toolchain-funcs

DESCRIPTION="The OpenGL Extension Wrangler Library"
HOMEPAGE="http://glew.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tgz"

LICENSE="BSD MIT"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 sh sparc x86 ~x86-fbsd ~x86-freebsd ~amd64-linux ~ia64-linux ~x86-linux ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE=""

RDEPEND="x11-libs/libXmu
	x11-libs/libXi
	virtual/glu
	virtual/opengl
	x11-libs/libXext
	x11-libs/libX11"
DEPEND="${RDEPEND}"

pkg_setup() {
	myglewopts=(
		GLEW_DEST="${ED}/usr"
		LIBDIR="${ED}/usr/$(get_libdir)"
		AR="$(tc-getAR)"
		STRIP="true"
		CC="$(tc-getCC)"
		LD="$(tc-getCC) ${LDFLAGS}"
		M_ARCH=""
		LDFLAGS.EXTRA=""
		POPT="${CFLAGS}"
		)
}

src_prepare() {
	sed -i \
		-e '/INSTALL/s:-s::' \
		-e '/$(CC) $(CFLAGS) -o/s:$(CFLAGS):$(CFLAGS) $(LDFLAGS):' \
		Makefile || die

	# don't do stupid Solaris specific stuff that won't work in Prefix
	cp config/Makefile.linux config/Makefile.solaris || die
}

src_compile(){
	emake "${myglewopts[@]}" || die
}

src_install() {
	emake "${myglewopts[@]}" install || die
	dodoc doc/*.txt README.txt TODO.txt || die
	dohtml doc/*.{css,html,jpg,png} || die
}
