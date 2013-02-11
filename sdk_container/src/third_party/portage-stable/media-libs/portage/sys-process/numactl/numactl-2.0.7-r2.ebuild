# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-process/numactl/numactl-2.0.7-r2.ebuild,v 1.4 2012/06/29 07:15:55 jdhore Exp $

EAPI="4"

inherit eutils toolchain-funcs multilib

DESCRIPTION="Utilities and libraries for NUMA systems"
HOMEPAGE="http://oss.sgi.com/projects/libnuma/"
SRC_URI="ftp://oss.sgi.com/www/projects/libnuma/download/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ppc ~ppc64 x86 ~amd64-linux"
IUSE="perl static-libs"

RDEPEND="perl? ( dev-lang/perl )"

src_prepare() {
	echo "printf $(get_libdir)" > getlibdir
	epatch "${FILESDIR}"/${P}-static_libs.patch
}

src_compile() {
	emake CC="$(tc-getCC)" CFLAGS="${CFLAGS}" BENCH_CFLAGS="" \
		BUILD_STATIC=$(usex static-libs)
}

src_test() {
	if [ -d /sys/devices/system/node ]; then
		einfo "The only generically safe test is regress2."
		einfo "The other test cases require 2 NUMA nodes."
		cd test
		./regress2 || die "regress2 failed!"
	else
		ewarn "You do not have baseline NUMA support in your kernel, skipping tests."
	fi
}

src_install() {
	emake install prefix="${ED}/usr" BUILD_STATIC=$(usex static-libs)
	# delete man pages provided by the man-pages package #238805
	rm -rf "${ED}"/usr/share/man/man[25]
	doman *.8 # makefile doesnt get them all
	dodoc README TODO CHANGES DESIGN
	if ! use perl ; then
		rm "${ED}"/usr/bin/numastat "${ED}"/usr/share/man/man8/numastat.8 || die
	fi
}
