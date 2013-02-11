# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/ppl/ppl-0.11.2-r1.ebuild,v 1.9 2013/01/08 18:45:31 vapier Exp $

EAPI="3"

inherit eutils

DESCRIPTION="The Parma Polyhedra Library provides numerical abstractions for analysis of complex systems"
HOMEPAGE="http://www.cs.unipr.it/ppl/"
SRC_URI="http://www.cs.unipr.it/ppl/Download/ftp/releases/${PV}/${P}.tar.bz2"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~sparc-fbsd ~x86-fbsd ~amd64-linux ~sparc-solaris"
IUSE="doc lpsol pch static-libs test watchdog"

RDEPEND=">=dev-libs/gmp-4.1.3[cxx]
	lpsol? ( sci-mathematics/glpk )
	!<dev-libs/cloog-ppl-0.15.10"
DEPEND="${RDEPEND}
	sys-devel/m4"

pkg_setup() {
	if use test; then
		ewarn "The PPL testsuite will be run."
		ewarn "Note that this can take several hours to complete on a fast machine."
	fi
}

src_configure() {
	# --disable-check doesn't work
	use test && want_check="--enable-check=quick"
	econf \
		--docdir="${EPREFIX}"/usr/share/doc/${PF} \
		--disable-debugging \
		--disable-optimization \
		$(use_enable lpsol ppl_lpsol) \
		$(use_enable pch) \
		$(use_enable static-libs static) \
		$(use_enable watchdog) \
		--enable-interfaces="c cxx" \
		$(use test && echo --enable-check=quick)
}

src_test() {
	# default src_test runs with -j1, overriding it here saves about
	# 30 minutes and is recommended by upstream
	if emake -j1 check -n &> /dev/null; then
		emake check || die "tests failed"
	fi
}

src_install() {
	emake DESTDIR="${D}" install || die
	use static-libs || rm -f "${D}"/usr/lib*/libppl*.la

	local docsdir="${ED}/usr/share/doc/${PF}"
	rm "${docsdir}"/gpl* "${docsdir}"/fdl* || die

	if ! use doc; then
		rm -r "${docsdir}"/*-html/ || die
	fi

	dodoc NEWS README* STANDARDS TODO
}

pkg_postinst() {
	echo
	ewarn "After an upgrade of PPL it is important that you rebuild"
	ewarn "dev-libs/cloog-ppl."
	ewarn
	ewarn "If you use gcc-config to switch to an older compiler version than"
	ewarn "the one PPL was built with, PPL must be rebuilt with that version."
	ewarn
	ewarn "In both cases failure to do this will get you this error when"
	ewarn "graphite flags are used:"
	ewarn
	ewarn "    sorry, unimplemented: Graphite loop optimizations cannot be used"
	ewarn
	echo
}
