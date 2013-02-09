# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libdvdcss/libdvdcss-1.2.12.ebuild,v 1.9 2012/08/05 18:07:21 armin76 Exp $

EAPI=4
inherit autotools

DESCRIPTION="A portable abstraction library for DVD decryption"
HOMEPAGE="http://www.videolan.org/developers/libdvdcss.html"
SRC_URI="http://www.videolan.org/pub/${PN}/${PV}/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="1.2"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 sh sparc x86 ~amd64-fbsd ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~x86-solaris"
IUSE="doc static-libs"

RDEPEND=""
DEPEND="${RDEPEND}
	doc? (
		app-doc/doxygen
		virtual/latex-base
		dev-tex/xcolor
		dev-texlive/texlive-latexextra
		)"

DOCS="AUTHORS ChangeLog NEWS README"

src_prepare() {
	sed -i -e 's:noinst_PROGRAMS:check_PROGRAMS:' test/Makefile.am || die
	eautoreconf
}

src_configure() {
	# See bug #98854, requires access to fonts cache for TeX
	# No need to use addwrite, just set TeX font cache in the sandbox
	use doc && export VARTEXFONTS="${T}/fonts"

	econf \
		--enable-shared \
		$(use_enable static-libs static) \
		$(use_enable doc)
}

src_install() {
	default

	find "${ED}" -name '*.la' -exec rm -f {} +

	use doc && dohtml doc/html/*
	use doc && dodoc doc/latex/refman.ps
}
