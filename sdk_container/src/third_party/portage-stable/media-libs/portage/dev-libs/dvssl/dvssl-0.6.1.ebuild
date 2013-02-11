# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/dvssl/dvssl-0.6.1.ebuild,v 1.3 2012/03/21 10:21:29 ssuominen Exp $

EAPI=4

DESCRIPTION="Provides a simple interface to OpenSSL"
HOMEPAGE="http://tinf2.vub.ac.be/~dvermeir/software/dv/dvssl/html/"
SRC_URI="http://tinf2.vub.ac.be/~dvermeir/software/dv/${PN}/download/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"
IUSE="doc static-libs"

DEPEND="dev-libs/openssl:0
	>=dev-libs/dvnet-0.9.24
	>=dev-libs/dvutil-1.0.10-r2"
RDEPEND="${DEPEND}"

DOCS="AUTHORS ChangeLog" # NEWS and README are useless

src_prepare() {
	sed -e 's:libcrypto.a:libcrypto.so:' -e 's:libssl.a:libssl.so:' -i configure || die
	sed -e 's|^\(SUBDIRS =.*\)doc\(.*\)$|\1\2|' -i Makefile.in || die
}

src_configure() {
	econf $(use_enable static-libs static)
}

src_install() {
	default

	if use doc; then
		doman doc/man/*/*.[1-9]
		dohtml -r doc/html/*
	fi

	# Keeping .la files in purpose, see: http://bugs.gentoo.org/409125
	find "${ED}" -name '*.la' -exec sed -i -e "/^dependency_libs/s:=.*:='':" {} +
}
