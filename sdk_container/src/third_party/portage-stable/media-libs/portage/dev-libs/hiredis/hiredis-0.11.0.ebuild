# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/hiredis/hiredis-0.11.0.ebuild,v 1.1 2013/02/01 00:06:49 neurogeek Exp $

EAPI=4

inherit eutils

DESCRIPTION="Minimalistic C client library for the Redis database"
HOMEPAGE="http://github.com/redis/hiredis"
SRC_URI="http://github.com/redis/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="debug"

DEPEND=""
RDEPEND="${DEPEND}"

DOCS="CHANGELOG.md README.md"

src_prepare() {
	epatch "${FILESDIR}/${P}-disable-network-tests.patch"
}

src_compile() {

	if ! use debug; then
		emake CC="$(tc-getCC)" ARCH= DEBUG=
	else
		emake CC="$(tc-getCC)" ARCH=
	fi
}

src_test() {
	emake test
}

src_install() {
	emake PREFIX="${ED}/usr" install
	dodoc ${DOCS}
}
