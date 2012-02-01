# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-arch/pigz/pigz-2.1.6.ebuild,v 1.1 2010/01/17 23:24:19 spatz Exp $

EAPI="2"

inherit eutils toolchain-funcs

DESCRIPTION="A parallel implementation of gzip"
HOMEPAGE="http://www.zlib.net/pigz/"
SRC_URI="http://www.zlib.net/pigz/${P}.tar.gz"

LICENSE="PIGZ"
SLOT="0"
KEYWORDS="~amd64 ~sparc ~x86 ~amd64-linux ~sparc64-solaris"
IUSE="symlink test"

RDEPEND="sys-libs/zlib"
DEPEND="${RDEPEND}
	test? ( app-arch/ncompress )"

src_prepare() {
	sed -i -e '/^CFLAGS=/ d' -e '4s/cc/$(CC) $(LDFLAGS)/' "${S}/Makefile" || die
}

src_compile() {
	tc-export CC
	emake || die "make failed"
}

src_install() {
	dobin ${PN} || die "Failed to install"
	dosym /usr/bin/${PN} /usr/bin/un${PN} || die
	dodoc README || die
	doman ${PN}.1 || die

	if use symlink; then
		dosym /usr/bin/${PN} /usr/bin/gzip || die
		dosym /usr/bin/un${PN} /usr/bin/gunzip || die
	fi
}
