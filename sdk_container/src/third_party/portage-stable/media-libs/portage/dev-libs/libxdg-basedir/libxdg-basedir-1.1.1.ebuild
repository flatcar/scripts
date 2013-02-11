# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libxdg-basedir/libxdg-basedir-1.1.1.ebuild,v 1.10 2012/07/26 19:59:03 grobian Exp $

EAPI=2
inherit libtool

DESCRIPTION="Small library to access XDG Base Directories Specification paths"
HOMEPAGE="http://n.ethz.ch/student/nevillm/download/libxdg-basedir/"
SRC_URI="http://n.ethz.ch/student/nevillm/download/libxdg-basedir/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 ~arm hppa ppc ppc64 x86 ~x86-fbsd ~amd64-linux ~x64-macos ~x86-solaris"
IUSE="doc static-libs"

RDEPEND=""
DEPEND="doc? ( app-doc/doxygen )"

src_prepare() {
	elibtoolize
}

src_configure() {
	econf \
		--disable-dependency-tracking \
		$(use_enable static-libs static) \
		$(use_enable doc doxygen-html)
}

src_compile() {
	emake || die

	if use doc; then
		emake doxygen-doc || die
	fi
}

src_install() {
	emake DESTDIR="${D}" install || die

	if use doc; then
		dohtml -r doc/html/*
	fi

	find "${D}" -name '*.la' -delete
}
