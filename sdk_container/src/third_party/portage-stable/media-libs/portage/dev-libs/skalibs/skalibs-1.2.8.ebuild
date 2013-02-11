# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/skalibs/skalibs-1.2.8.ebuild,v 1.1 2012/06/22 07:25:28 xmw Exp $

EAPI=4

inherit multilib toolchain-funcs

DESCRIPTION="development files used for building software at skarnet.org: essentially general-purpose libraries"
HOMEPAGE="http://www.skarnet.org/software/skalibs/index.html"
SRC_URI="http://www.skarnet.org/software/${PN}/${P}.tar.gz"

LICENSE="ISC"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="doc static-libs"

DEPEND=""
RDEPEND=""

S=${WORKDIR}/prog/${P}

src_configure() {
	echo $(tc-getCC) ${CFLAGS} > conf-compile/conf-cc
	echo $(tc-getCC) ${LDFLAGS} > conf-compile/conf-dynld
	echo $(tc-getCC) ${LDFLAGS} > conf-compile/conf-ld
}

src_compile() {
	emake -j1
}

src_install() {
	insinto /etc
	doins etc/leapsecs.dat

	insinto /usr/include/${PN}
	doins include/*

	insopts -m0755
	insinto /usr/$(get_libdir)/${PN}
	doins library.so/*
	if use static-libs ; then
		doins library/*
	fi

	dodir /etc/ld.so.conf.d/
	echo "/usr/$(get_libdir)/${PN}" > ${ED}/etc/ld.so.conf.d/10${PN}.conf || die

	cd doc || die
	for f in $(find . -type f ! -name "*.html" ! -name "COPYING") ; do
		docinto $(dirname f)
		dodoc $f
	done
	docinto html
	use doc && dohtml -r .
}
