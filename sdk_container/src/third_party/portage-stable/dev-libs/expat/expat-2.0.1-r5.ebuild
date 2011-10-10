# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/expat/expat-2.0.1-r5.ebuild,v 1.6 2011/10/05 05:55:18 maekke Exp $

EAPI=4
inherit eutils libtool toolchain-funcs

DESCRIPTION="XML parsing libraries"
HOMEPAGE="http://expat.sourceforge.net/"
SRC_URI="mirror://sourceforge/expat/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~alpha amd64 arm hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc x86 ~sparc-fbsd ~x86-fbsd"
IUSE="elibc_FreeBSD examples static-libs"

src_prepare() {
	epatch \
		"${FILESDIR}"/${P}-check_stopped_parser.patch \
		"${FILESDIR}"/${P}-fix_bug_1990430.patch \
		"${FILESDIR}"/${P}-CVE-2009-3560-revised.patch

	elibtoolize
	epunt_cxx

	mkdir "${S}"-build{,u,w} || die
}

src_configure() {
	local myconf="$(use_enable static-libs static)"

	local d
	for d in build buildu buildw; do
		pushd "${S}"-${d}
		[[ ${d} == buildu ]] && export GENTOO_CPPFLAGS="-UXML_UNICODE"
		[[ ${d} == buildw ]] && export GENTOO_CPPFLAGS="-UXML_UNICODE -DXML_UNICODE_WCHAR_T"
		CPPFLAGS="${CPPFLAGS} ${GENTOO_CPPFLAGS}" ECONF_SOURCE="${S}" econf ${myconf}
		popd
	done
}

src_compile() {
	cd "${S}"-build
	emake
	cd "${S}"-buildu
	emake buildlib LIBRARY=libexpatu.la
	cd "${S}"-buildw
	emake buildlib LIBRARY=libexpatw.la
}

src_install() {
	dodoc Changes README
	dohtml doc/*

	if use examples; then
		insinto /usr/share/doc/${PF}/examples
		doins examples/*.c
	fi

	cd "${S}"-build
	emake install DESTDIR="${D}"
	cd "${S}"-buildu
	emake installlib DESTDIR="${D}" LIBRARY=libexpatu.la
	cd "${S}"-buildw
	emake installlib DESTDIR="${D}" LIBRARY=libexpatw.la

	use static-libs || rm -f "${D}"usr/lib*/libexpat{,u,w}.la

	# libgeom in /lib and ifconfig in /sbin require it on FreeBSD since we
	# stripped the libbsdxml copy starting from freebsd-lib-8.2-r1
	use elibc_FreeBSD && gen_usr_ldscript -a expat{,u,w}
}
