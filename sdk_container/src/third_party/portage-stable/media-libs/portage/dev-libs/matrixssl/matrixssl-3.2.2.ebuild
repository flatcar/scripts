# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/matrixssl/matrixssl-3.2.2.ebuild,v 1.2 2012/03/21 06:06:22 ssuominen Exp $

EAPI=4
inherit toolchain-funcs

MY_P=${P//./-}-open

DESCRIPTION="embedded SSL implementation"
HOMEPAGE="http://www.matrixssl.org/"
SRC_URI="mirror://gentoo/${MY_P}.tgz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="doc examples static-libs"

S=${WORKDIR}/${MY_P}

src_compile() {
	local myconf=(
		CC="$(tc-getCC)"
		STRIP="true"
		AR="$(tc-getAR)"
		DFLAGS="${CFLAGS}"
		)

	if use static-libs; then
		emake "${myconf[@]}"
	else
		emake lib${PN}.so "${myconf[@]}"
	fi
}

src_install() {
	dolib.so libmatrixssl.so
	use static-libs && dolib.a libmatrixssl.a

	# API is exposed from matrixsslApi.h and rest is included recursively
	insinto /usr/include/matrixssl
	doins matrixssl/*.h

	local h1
	for h1 in core crypto; do
		insinto /usr/include/matrixssl/${h1}
		doins ${h1}/*.h
	done

	local h2
	for h2 in digest keyformat math prng pubkey symmetric; do
		insinto /usr/include/matrixssl/crypto/${h2}
		doins crypto/${h2}/*.h
	done

	if use doc; then
		insinto /usr/share/doc/${PF}/pdf
		doins doc/*.pdf
	fi

	if use examples; then
		insinto /usr/share/doc/${PF}/examples
		doins -r apps sampleCerts
	fi

	dodoc readme.txt
}
