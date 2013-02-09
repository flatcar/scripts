# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/lensfun/lensfun-0.2.5-r2.ebuild,v 1.13 2012/05/05 08:02:45 jdhore Exp $

EAPI=2
inherit eutils python toolchain-funcs

DESCRIPTION="lensfun: A library for rectifying and simulating photographic lens distortions"
HOMEPAGE="http://lensfun.berlios.de/"
SRC_URI="http://dev.gentoo.org/~dilfridge/distfiles/${P}.tar.bz2"

LICENSE="LGPL-3"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ppc ppc64 sh sparc x86"
IUSE="debug doc"

RDEPEND=">=dev-libs/glib-2
	>=media-libs/libpng-1.2"
DEPEND="${RDEPEND}
	|| ( dev-lang/python:2.7 dev-lang/python:2.6 )
	virtual/pkgconfig
	doc? ( >=app-doc/doxygen-1.5.0 )"

pkg_setup() {
	python_set_active_version 2
	python_pkg_setup
}

src_prepare() {
	# disable stripping, remove ricer CFLAGS
	sed -i \
		-e 's:-s -O3 -fomit-frame-pointer -funroll-loops::g' \
		-e 's:GCC.LDFLAGS.release = -s:GCC.LDFLAGS.release =:g' \
		build/tibs/compiler/gcc.mak || die

	epatch "${FILESDIR}"/${P}-libpng15.patch
}

src_configure() {
	tc-export CXX
	export LD="${CXX}"

	local myconf=""
	use debug && myconf="--mode=debug"
	# econf does NOT work
	./configure --prefix=/usr --docdir="/usr/share/doc/${PF}" --vectorization= ${myconf} || die
}

src_compile() {
	emake all V=1 || die
}

src_install() {
	emake DESTDIR="${D}" install || die
	# TODO remove docs if ! use doc
}
