# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/qof/qof-0.8.1.ebuild,v 1.7 2012/05/04 18:35:45 jdhore Exp $

EAPI=2

inherit eutils

DESCRIPTION="A Query Object Framework"
HOMEPAGE="http://qof.alioth.debian.org/"
SRC_URI="https://alioth.debian.org/frs/download.php/3059/${P}.tar.gz"
LICENSE="GPL-2"

SLOT="2"

KEYWORDS="amd64 ~ppc ~ppc64 sparc x86"

IUSE="doc nls sqlite"

RDEPEND="dev-libs/libxml2
	dev-libs/glib:2
	sqlite? ( >=dev-db/sqlite-2.8.0:0 )"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	!dev-libs/qof:0
	doc? ( app-doc/doxygen
		dev-texlive/texlive-latex )"

src_prepare() {
	# Upstream not willing to remove those stupid flags...
	epatch "${FILESDIR}/${PN}-0.8.0-remove_spurious_CFLAGS.patch"
}

src_configure() {
	econf $(use_enable doc html-docs) --disable-error-on-warning \
		$(use_enable nls) $(use_enable sqlite)  $(use_enable doc doxygen) \
		$(use_enable doc latex-docs) --disable-gdabackend --disable-gdasql \
		--disable-deprecated-glib --disable-dot \
		|| die
}
src_compile() {
	emake -j1 || die
}

src_install() {
	emake -j1 DESTDIR="${D}" install || die
}
