# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libev/libev-4.15.ebuild,v 1.11 2014/06/10 00:05:24 vapier Exp $

EAPI=5

inherit autotools eutils multilib

DESCRIPTION="A high-performance event loop/event model with lots of feature"
HOMEPAGE="http://software.schmorp.de/pkg/libev.html"
SRC_URI="http://dist.schmorp.de/libev/${P}.tar.gz
	http://dist.schmorp.de/libev/Attic/${P}.tar.gz"

LICENSE="|| ( BSD GPL-2 )"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 hppa ~ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~amd64-fbsd ~x86-fbsd ~x86-freebsd ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos"
IUSE="elibc_glibc static-libs"

# Bug #283558
DEPEND="elibc_glibc? ( >=sys-libs/glibc-2.9_p20081201 )"
RDEPEND="${DEPEND}"

DOCS=( Changes README )

src_prepare() {
	sed -i -e "/^include_HEADERS/s/ event.h//" Makefile.am || die

	# bug #411847
	epatch "${FILESDIR}/${PN}-pc.patch"
	# bug #493050
	epatch "${FILESDIR}/${P}-automake-1.14.patch"

	epatch_user
	eautoreconf
}

src_configure() {
	econf \
		--disable-maintainer-mode \
		$(use_enable static-libs static)
}

src_install() {
	default
	use static-libs || prune_libtool_files
}

pkg_preinst() {
	preserve_old_lib /usr/$(get_libdir)/libev.so.3.0.0
}

pkg_postinst() {
	preserve_old_lib_notify /usr/$(get_libdir)/libev.so.3.0.0
}
