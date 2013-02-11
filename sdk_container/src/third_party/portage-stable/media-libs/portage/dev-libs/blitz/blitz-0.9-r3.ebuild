# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/blitz/blitz-0.9-r3.ebuild,v 1.7 2012/10/19 10:33:28 jlec Exp $

EAPI=3

inherit eutils fortran-2

DESCRIPTION="High-performance C++ numeric library"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"
HOMEPAGE="http://www.oonumerics.org/blitz"

SLOT="0"
LICENSE="|| ( GPL-2 Blitz-Artistic )"
KEYWORDS="~amd64 ~ppc ~x86 ~ppc-macos ~x86-macos"
IUSE="debug doc examples"

DEPEND="
	doc? ( app-doc/doxygen )"
RDEPEND=""

src_prepare() {
	# remove examples compiling
	sed -i \
		-e 's/blitz-uninstalled.pc//' \
		-e 's/examples//g' \
		Makefile.in || die "sed failed"
	epatch "${FILESDIR}"/${P}-gcc-4.3-missing-includes.patch
}

src_configure() {
	# blas and fortran are only useful for benchmarks
	econf \
		--enable-shared \
		--disable-cxx-flags-preset \
		--disable-fortran \
		--without-blas \
		$(use_enable doc doxygen) \
		$(use_enable doc html-docs) \
		$(use_enable debug)
}

src_compile() {
	emake \
		LDFLAGS="${LDFLAGS}" \
		lib || die "emake lib failed"
}

src_test() {
	# exprctor fails if BZ_DEBUG flag is not set
	# CXXFLAGS gets overwritten
	emake AM_CXXFLAGS="-DBZ_DEBUG" check-testsuite || die "selftest failed"
}

src_install () {
	dodir /usr/share/doc/${PF}/html
	emake \
		DESTDIR="${D}" \
		docdir="${EPREFIX}"/usr/share/doc/${PF}/html \
		install || die "emake install failed"
	dodoc ChangeLog ChangeLog.1 README README.binutils TODO AUTHORS NEWS || die

	if use examples; then
		insinto /usr/share/doc/${PF}/examples
		doins examples/*.cpp || die
	fi
}
