# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libmelf/libmelf-0.4.0-r1.ebuild,v 1.1 2010/06/01 03:48:20 robbat2 Exp $

EAPI=3
inherit eutils flag-o-matic toolchain-funcs

DESCRIPTION="libmelf is a library interface for manipulating ELF object files."
HOMEPAGE="http://www.hick.org/code/skape/libmelf/"
SRC_URI="http://www.hick.org/code/skape/${PN}/${P}.tar.gz"

LICENSE="Artistic"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}"

src_prepare() {
	# This patch was gained from the elfsign-0.2.2 release
	epatch "${FILESDIR}"/${PN}-0.4.1-unfinal-release.patch
	# Cleanup stuff
	epatch "${FILESDIR}"/${PN}-0.4.0-r1-gcc-makefile-cleanup.patch
}

src_compile() {
	append-flags -fPIC
	emake CC="$(tc-getCC)" OPTFLAGS="${CFLAGS}" || die "emake failed"
}

src_install() {
	into /usr
	dobin tools/elfres
	dolib.a libmelf.a
	dolib.so libmelf.so
	insinto /usr/include
	doins melf.h stdelf.h
	dodoc ChangeLog README
	dohtml -r docs/html
}
