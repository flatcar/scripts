# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/glfw/glfw-2.6.ebuild,v 1.8 2012/11/14 23:31:43 hasufell Exp $

EAPI=2
inherit eutils multilib toolchain-funcs

DESCRIPTION="The Portable OpenGL FrameWork"
HOMEPAGE="http://glfw.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.bz2"

LICENSE="ZLIB"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE="examples"

DEPEND="x11-libs/libXrandr
	virtual/glu
	virtual/opengl"

S=${WORKDIR}/${PN}

src_prepare() {
	sed -i \
		-e "s:\"docs/:\"/usr/share/doc/${PF}/pdf/:" \
		readme.html \
		|| die "sed failed"

	# respect cflags
	sed -i \
		-e "/CFLAGS/s#-Os#${CFLAGS}#" \
		compile.sh \
		|| die "sed compile.sh failed"

	epatch "${FILESDIR}/${P}"-dyn.patch \
		"${FILESDIR}"/${P}-ldflags.patch

	# respect cflags in linking command as well
	sed -i \
		-e "/^libglfw.so/{n;s/\$(CC)/\$(CC) ${CFLAGS}/;}" \
		lib/x11/Makefile.x11.in \
		|| die "sed Makefile.x11.in failed"
}

src_configure() {
	sh ./compile.sh
}

src_compile() {
	emake -C lib/x11 AR=$(tc-getAR) CC=$(tc-getCC) PREFIX=/usr -f Makefile.x11 default libglfw.pc || die "emake failed"
}

src_install() {
	dolib.a lib/x11/libglfw.a || die "dolib.a failed"
	dolib.so lib/x11/libglfw.so.2.6 || die "dolib.so failed"
	dosym libglfw.so.2.6 /usr/$(get_libdir)/libglfw.so

	insinto /usr/$(get_libdir)/pkgconfig
	doins lib/x11/libglfw.pc || die "doins failed"
	insinto /usr/include/GL
	doins include/GL/glfw.h || die "doins failed"
	dohtml -r readme.html
	insinto /usr/share/doc/${PF}/html/images
	doins images/*
	insinto /usr/share/doc/${PF}/pdf
	doins docs/*.pdf

	if use examples; then
		local f
		local MY_EXAMPLES="boing gears keytest listmodes mipmaps
			mtbench mthello particles pong3d splitview
			triangle wave"
		local MY_PICS="mipmaps.tga pong3d_field.tga pong3d_instr.tga
			pong3d_menu.tga pong3d_title.tga
			pong3d_winner1.tga pong3d_winner2.tga"

		insinto /usr/share/doc/${PF}/examples

		doins examples/Makefile.x11
		for f in $MY_EXAMPLES; do
			doins examples/${f}.c
		done
		for f in $MY_PICS; do
			doins examples/${f}
		done

		insopts -m0755
		for f in $MY_EXAMPLES; do
			doins examples/${f}
		done
	fi
}
