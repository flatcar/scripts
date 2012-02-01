# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libevent/libevent-1.4.13.ebuild,v 1.10 2010/02/25 21:11:26 grobian Exp $

inherit autotools

MY_P="${P}-stable"

DESCRIPTION="A library to execute a function when a specific event occurs on a file descriptor"
HOMEPAGE="http://monkey.org/~provos/libevent/"
SRC_URI="http://monkey.org/~provos/${MY_P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~sparc-fbsd ~x86-fbsd ~x86-freebsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~x64-solaris ~x86-solaris"
IUSE=""

DEPEND=""
RDEPEND="!dev-libs/9libs"

S=${WORKDIR}/${MY_P}

pkg_setup() {
	prevver=$(best_version ${CATEGORY}/${PN})
}

src_unpack() {
	unpack ${A}
	cd "${S}"
	# don't waste time building tests/samples
	sed -i \
		-e 's|^\(SUBDIRS =.*\)sample test\(.*\)$|\1\2|' \
		-e 's/libevent_extra_la_LIBADD =/& libevent.la/' \
		Makefile.am || die "sed Makefile.am failed"

	eautoreconf
}

src_test() {
	einfo "Building tests"
	cd test
	make test || die "failed to build tests"

	einfo "Running tests"
	./test.sh > "${T}"/tests
	cat "${T}"/tests
	grep FAILED "${T}"/tests &>/dev/null && die "1 or more tests failed"
}

src_install() {
	make DESTDIR="${D}" install || die "make install failed"
	dodoc README ChangeLog
}
