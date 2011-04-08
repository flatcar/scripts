# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-i18n/zinnia/zinnia-0.06-r1.ebuild,v 1.2 2011/04/07 23:02:45 flameeyes Exp $

EAPI="3"

inherit perl-module flag-o-matic toolchain-funcs autotools

DESCRIPTION="Online hand recognition system with machine learning"
HOMEPAGE="http://zinnia.sourceforge.net/"
SRC_URI="mirror://sourceforge/zinnia/${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86"
#IUSE="perl python ruby"
IUSE="perl"

src_prepare() {
	epatch "${FILESDIR}/${P}-ricedown.patch"
	epatch "${FILESDIR}/${P}-perl.patch"
	eautoreconf

	if use perl ; then
		(
			cd "${S}/perl"
			perl-module_src_prepare
		)
	fi
}

src_configure() {
	econf
}

src_compile() {
	base_src_compile

	if use perl ; then
		(
			cd "${S}/perl"

			# We need to run this here as otherwise it won't pick up the
			# just-built -lzinnia and cause the extension to have
			# undefined symbols.
			perl-module_src_configure

			append-cppflags "-I${S}"
			append-ldflags "-L${S}/.libs"

			emake \
				LDDLFLAGS="-shared" \
				OTHERLDFLAGS="${LDFLAGS}" \
				CC="$(tc-getCXX)" LD="$(tc-getCXX)" \
				OPTIMIZE="${CPPFLAGS} ${CXXFLAGS}" \
				|| die
		)
	fi
}

# no tests present
src_test() { :; }

src_install() {
	emake DESTDIR="${D}" install || die
	find "${D}" -name '*.la' -delete

	if use perl ; then
		(
			cd "${S}/perl"
			perl-module_src_install
		)
	fi

	dodoc AUTHORS ChangeLog NEWS README || die
	dohtml doc/*.html doc/*.css || die
}
