# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/link-grammar/link-grammar-4.7.4.ebuild,v 1.7 2012/11/30 19:28:09 ulm Exp $

EAPI="3"

inherit java-pkg-opt-2

DESCRIPTION="Link Grammar Parser is a syntactic English parser based on
link grammar."
HOMEPAGE="http://www.abisource.com/projects/link-grammar/ http://www.link.cs.cmu.edu/link/"
SRC_URI="http://www.abisource.com/downloads/${PN}/${PV}/${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="alpha amd64 hppa ia64 ppc ppc64 sparc x86"

# Set the same default as used in app-text/enchant
IUSE="aspell +hunspell java static-libs threads"

DEPEND="aspell? ( app-text/aspell )
	hunspell? ( app-text/hunspell )
	java? ( >=virtual/jdk-1.5 )"
RDEPEND="${DEPEND}"

pkg_setup() {
	java-pkg-opt-2_pkg_setup
	if use aspell && use hunspell; then
		ewarn "You have enabled 'aspell' and 'hunspell' support, but both cannot coexist,"
		ewarn "only aspell will be build. Press Ctrl+C and set only 'hunspell' USE flag if"
		ewarn "you want hunspell support."
	fi
}

src_configure() {
	local myconf

	use hunspell && myconf="${myconf} --with-hunspell-dictdir=/usr/share/myspell"
	econf \
		--enable-shared \
		$(use_enable aspell) \
		$(use_enable hunspell) \
		$(use_enable java java-bindings) \
		$(use_enable static-libs static) \
		$(use_enable threads pthreads) \
		${myconf}
}

src_install() {
	emake DESTDIR="${D}" install || die "install failed"
	dodoc AUTHORS ChangeLog README || die
}
