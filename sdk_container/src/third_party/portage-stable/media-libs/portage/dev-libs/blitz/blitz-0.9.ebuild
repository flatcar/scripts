# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/blitz/blitz-0.9.ebuild,v 1.15 2012/10/19 10:33:28 jlec Exp $

inherit eutils fortran-2 toolchain-funcs

DESCRIPTION="High-performance C++ numeric library"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"
HOMEPAGE="http://www.oonumerics.org/blitz"

SLOT="0"
LICENSE="GPL-2"
KEYWORDS="~amd64 ppc x86"
IUSE="doc"

DEPEND="
	doc? ( app-doc/doxygen )"
RDEPEND=""

src_unpack() {
	unpack ${A}
	cd "${S}"
	epatch "${FILESDIR}"/${P}-gcc-4.3-missing-includes.patch
}

src_compile() {
	local myconf
	# ICC: if we've got it, use it
	[[ $(tc-getCXX) = ic*c ]] && myconf="--with-cxx=icc" || myconf="--with-cxx=gcc"
	#use doc && myconf="$myconf --enable-latex-docs"
	myconf="${myconf} --enable-maintainer-mode --disable-doxygen --disable-dot"
	myconf="${myconf} --enable-shared"

	export CC=$(tc-getCC) CXX=$(tc-getCXX) FC=$(tc-getFC)
	econf ${myconf}
}

src_test() {
	# exprctor fails if BZ_DEBUG flag is not set
	# CXXFLAGS gets overwritten
	emake AM_CXXFLAGS="-DBZ_DEBUG" check-testsuite || die "selftest failed"
}

src_install () {
	dodir /usr/share/doc/${PF}
	emake DESTDIR="${D}" docdir=/usr/share/doc/${PF} install || die
	dodoc ChangeLog ChangeLog.1 README README.binutils \
		  TODO AUTHORS NEWS || die
}
