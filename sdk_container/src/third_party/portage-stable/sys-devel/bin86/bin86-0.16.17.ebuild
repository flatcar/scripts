# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/bin86/bin86-0.16.17.ebuild,v 1.7 2009/10/05 23:26:10 vapier Exp $

inherit toolchain-funcs eutils

DESCRIPTION="Assembler and loader used to create kernel bootsector"
HOMEPAGE="http://www.debath.co.uk/"
SRC_URI="http://www.debath.co.uk/dev86/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="-* amd64 x86"
IUSE=""

src_unpack() {
	unpack ${A}
	cd "${S}"
	sed -i \
		-e 's:/man/man1:/share/man/man1:' \
		-e '/^INSTALL_OPTS/s:-s::' \
		Makefile || die "sed"

	# This should make it built on other archictectures as well
	use amd64 && epatch "${FILESDIR}"/${P}-amd64-build.patch
}

src_compile() {
	emake \
		PREFIX="/usr" \
		CC="$(tc-getCC)" \
		CFLAGS="${CFLAGS} -D_POSIX_SOURCE ${CPPFLAGS}" \
		LDFLAGS="${LDFLAGS}" \
		|| die
}

src_install() {
	dodir /usr/bin /usr/share/man/man1
	emake install PREFIX="${D}/usr" || die "install"
	dodoc README* ChangeLog
}
