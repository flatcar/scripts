# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-irc/ezbounce/ezbounce-1.99.14.ebuild,v 1.5 2011/07/06 16:56:46 ssuominen Exp $

EAPI=4
inherit eutils

DESCRIPTION="a small IRC bouncer"
HOMEPAGE="http://www.linuxftw.com/ezbounce/"
SRC_URI="http://www.linuxftw.com/${PN}/files/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"
IUSE="ssl boost"

RDEPEND=">=net-misc/mdidentd-1.04c
	ssl? ( dev-libs/openssl )
	boost? ( dev-libs/boost )"
DEPEND="${RDEPEND}"

RESTRICT="test"

src_prepare() {
	epatch "${FILESDIR}"/${P}-build.patch #251445
	epatch "${FILESDIR}"/${P}-asneeded.patch
	epatch "${FILESDIR}"/${P}+glibc-2.10.patch
	epatch "${FILESDIR}"/${P}-ldflags.patch
}

src_configure() {
	econf \
		$(use_with ssl) \
		$(use_with boost)
}

src_compile() {
	emake CXX_OPTIMIZATIONS="${CXXFLAGS}"
}

src_install() {
	dobin ezbounce
	dosym ezbounce /usr/bin/ezb

	echo '.so ezbounce.1' > ${T}/ezb.1
	doman docs/ezbounce.1 "${T}"/ezb.1

	dodoc CHANGES README TODO ezb.conf sample.conf
	docinto docs
	dodoc docs/{FAQ,README,REPORTING-BUGS,worklog,*.txt}
}
