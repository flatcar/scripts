# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-cpp/gtest/gtest-1.4.0.ebuild,v 1.1 2011/11/11 20:09:57 vapier Exp $

EAPI="2"
inherit autotools eutils

DESCRIPTION="Google C++ Testing Framework"
HOMEPAGE="http://code.google.com/p/googletest/"
SRC_URI="http://googletest.googlecode.com/files/${P}.tar.bz2"

LICENSE="BSD"
SLOT="0"
KEYWORDS="amd64 arm x86"
IUSE="examples static-libs"

DEPEND="dev-lang/python"
RDEPEND=""

src_prepare() {
	sed -i -e "s|/tmp|${T}|g" test/gtest-filepath_test.cc || die "sed failed"

	epatch "${FILESDIR}/${P}-asneeded.patch"
	eautoreconf
}

src_configure() {
	econf \
		$(use_enable static-libs static)
}

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"

	dodoc CHANGES CONTRIBUTORS README

	use static-libs || rm "${D}"/usr/lib*/*.la

	if use examples ; then
		insinto /usr/share/doc/${PF}/examples
		doins samples/*.{cc,h}
	fi
}
