# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/ppl/ppl-0.10.2-r1.ebuild,v 1.14 2013/01/08 18:45:31 vapier Exp $

EAPI=2

inherit autotools eutils

DESCRIPTION="The Parma Polyhedra Library provides numerical abstractions for analysis of complex systems"
HOMEPAGE="http://www.cs.unipr.it/ppl/"
SRC_URI="http://www.cs.unipr.it/ppl/Download/ftp/releases/${PV}/${P}.tar.bz2
	mirror://gentoo/${P}-gmp-5-fix.patch.bz2"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~sparc-fbsd ~x86-fbsd"
IUSE="doc lpsol pch test watchdog"

RDEPEND=">=dev-libs/gmp-4.1.3[cxx]
	lpsol? ( sci-mathematics/glpk )"
DEPEND="${RDEPEND}
		sys-devel/m4"

pkg_setup() {
	if use test; then
		ewarn "The PPL testsuite will be run."
		ewarn "Note that this can take several hours to complete on a fast machine."
	fi
}

src_prepare() {
	epatch "${WORKDIR}"/${P}-gmp-5-fix.patch
	eautoreconf
}

src_configure() {
	# --disable-check doesn't work
	use test && want_check="--enable-check=quick"
	econf                                   \
		--docdir=/usr/share/doc/${PF}       \
		--disable-debugging                 \
		--disable-optimization              \
		$(use_enable lpsol ppl_lpsol)       \
		$(use_enable pch)                   \
		$(use_enable watchdog)              \
		--enable-interfaces="c cxx"         \
		${want_check}                       \
		|| die "configure failed"
}

src_test() {
	# default src_test runs with -j1, overriding it here saves about
	# 30 minutes and is recommended by upstream
	if emake -j1 check -n &> /dev/null; then
		emake check || die "tests failed"
	fi
}

src_install() {
	emake DESTDIR="${D}" install || die "install failed"

	if ! use doc; then
		rm -r "${D}"/usr/share/doc/${PF}/ppl-user*-html
		rm -r "${D}"/usr/share/doc/${PF}/pwl-user*-html
	fi

	cd "${S}"
	dodoc NEWS README README.configure STANDARDS TODO
}
