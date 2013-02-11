# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/leveldb/leveldb-1.9.0-r1.ebuild,v 1.1 2013/01/31 03:33:43 patrick Exp $
EAPI=4

PYTHON_DEPEND="2:2.6"
inherit eutils multilib

DESCRIPTION="A fast key-value storage library written at Google"

HOMEPAGE="http://code.google.com/p/leveldb/"
SRC_URI="http://${PN}.googlecode.com/files/${P}.tar.gz"
LICENSE="BSD"
SLOT="0"
KEYWORDS="~x86 ~amd64"

IUSE=""

DEPEND=""
RDEPEND="${DEPEND}"

src_compile() {
	emake all || die
	emake libmemenv.a || die
}

src_install() {
	mkdir -p "${D}/usr/include"
	cp -r include/* "${D}/usr/include" || die
	dolib.so libleveldb.so.${PV/.0} || die
	dosym libleveldb$(get_libname ).1.9 /usr/$(get_libdir)/libleveldb$(get_libname ) || die
	dosym libleveldb$(get_libname ).1.9 /usr/$(get_libdir)/libleveldb$(get_libname ).1 || die
	dolib.a libleveldb.a || die
	dolib.a libmemenv.a || die
}
