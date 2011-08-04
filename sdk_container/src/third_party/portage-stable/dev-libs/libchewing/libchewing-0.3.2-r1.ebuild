# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libchewing/libchewing-0.3.2-r1.ebuild,v 1.2 2011/01/19 15:41:31 flameeyes Exp $

EAPI=2

inherit multilib eutils autotools toolchain-funcs

DESCRIPTION="Library for Chinese Phonetic input method"
HOMEPAGE="http://chewing.csie.net/"
SRC_URI="http://chewing.csie.net/download/libchewing/${P}.tar.bz2"

SLOT="0"
LICENSE="GPL-2"
KEYWORDS="~amd64 ~ppc ~x86"
IUSE="debug test static-libs"

RDEPEND=""
DEPEND="${RDEPEND}
	dev-util/pkgconfig
	test? (
		sys-libs/ncurses[unicode]
		>=dev-libs/check-0.9.4
	)"

src_prepare() {
	epatch "${FILESDIR}"/0.3.2-fix-chewing-zuin-String.patch
	epatch "${FILESDIR}"/0.3.2-fix-crosscompile.patch

	eautoreconf
}

src_configure() {
	export CC_FOR_BUILD="$(tc-getBUILD_CC)"
	econf $(use_enable debug) \
		$(use_enable static-libs static) || die
}

src_test() {
	# test subdirectory is not enabled by default; this means that we
	# have to make it explicit.
	emake -C test check || die "emake check failed"
}

src_install() {
	emake DESTDIR="${D}" install || die

	find "${D}"/usr/$(get_libdir) -name '*.la' -delete || die

	dodoc AUTHORS ChangeLog NEWS README TODO || die
}
