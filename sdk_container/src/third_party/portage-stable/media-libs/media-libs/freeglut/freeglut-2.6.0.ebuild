# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/freeglut/freeglut-2.6.0.ebuild,v 1.14 2011/04/04 18:46:24 scarabeus Exp $

EAPI=3

inherit eutils flag-o-matic libtool autotools

DESCRIPTION="A completely OpenSourced alternative to the OpenGL Utility Toolkit (GLUT) library"
HOMEPAGE="http://freeglut.sourceforge.net/"
SRC_URI="mirror://sourceforge/freeglut/${P/_/-}.tar.gz
	mpx? ( http://tisch.sourceforge.net/freeglut-2.6.0-mpx-r6.patch )"

LICENSE="MIT"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 sh sparc x86 ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos"
IUSE="debug mpx static-libs"

RDEPEND="
	virtual/opengl
	virtual/glu
	>=x11-libs/libXi-1.3
	x11-libs/libXxf86vm
"
DEPEND="${RDEPEND}"

S="${WORKDIR}/${P/_*/}"

src_prepare() {
	epatch "${FILESDIR}/${PV}-GFX_radeon.patch"

	use mpx && epatch "${DISTDIR}/${P}-mpx-r6.patch"

	# Please read the comments in the patch before thinking about dropping it
	# yet again...
	epatch "${FILESDIR}/${PN}-2.4.0-bsd-usb-joystick.patch"

	eautoreconf
	# Needed for sane .so versionning on bsd, please don't drop
	elibtoolize
}

src_configure() {
	econf \
		--disable-warnings \
		--disable-warnings-as-errors \
		--enable-replace-glut \
		$(use_enable static-libs static) \
		$(use_enable debug)
}

src_install() {
	emake DESTDIR="${D}" install || die "make install failed"
	dodoc AUTHORS ChangeLog NEWS README TODO || die "dodoc failed"
	dohtml -r doc/*.html doc/*.png || die "dohtml failed"
	find "${ED}" -name '*.la' -delete
}
