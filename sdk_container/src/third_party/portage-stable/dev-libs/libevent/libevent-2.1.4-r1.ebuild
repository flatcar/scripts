# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libevent/libevent-2.1.4-r1.ebuild,v 1.4 2014/06/18 19:13:25 mgorny Exp $

EAPI=5
inherit eutils libtool multilib-minimal

MY_P="${P}-alpha"

DESCRIPTION="A library to execute a function when a specific event occurs on a file descriptor"
HOMEPAGE="http://libevent.org/"
SRC_URI="mirror://sourceforge/levent/files/${MY_P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS=""
IUSE="debug +ssl static-libs test +threads"

DEPEND="ssl? ( >=dev-libs/openssl-1.0.1h-r2[${MULTILIB_USEDEP}] )"
RDEPEND="
	${DEPEND}
	!<=dev-libs/9libs-1.0
"

MULTILIB_WRAPPED_HEADERS=(
	/usr/include/event2/event-config.h
)

S=${WORKDIR}/${MY_P}

src_prepare() {
	elibtoolize
	# don't waste time building tests
	# https://github.com/libevent/libevent/pull/144
	sed -i -e '/^all:/s|tests||g' Makefile.nmake || die
}

multilib_src_configure() {
	# fix out-of-source builds
	mkdir -p test || die

	ECONF_SOURCE="${S}" \
	econf \
		$(use_enable debug debug-mode) \
		$(use_enable debug malloc-replacement) \
		$(use_enable ssl openssl) \
		$(use_enable static-libs static) \
		$(use_enable threads thread-support)
}

src_test() {
	# The test suite doesn't quite work (see bug #406801 for the latest
	# installment in a riveting series of reports).
	:
	# emake -C test check | tee "${T}"/tests
}

DOCS=( ChangeLog{,-1.4,-2.0} )

multilib_src_install_all() {
	einstalldocs
	prune_libtool_files
}
