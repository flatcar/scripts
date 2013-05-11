# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-util/patchelf/patchelf-0.6-r1.ebuild,v 1.1 2013/02/04 15:59:31 jlec Exp $

EAPI=5

AUTOTOOLS_AUTORECONF=true

inherit autotools-utils

NUMBER="1524660"

DESCRIPTION="Small utility to modify the dynamic linker and RPATH of ELF executables."
HOMEPAGE="http://nixos.org/patchelf.html"
SRC_URI="http://hydra.nixos.org/build/${NUMBER}/download/2/${P}.tar.bz2"

SLOT="0"
KEYWORDS="~amd64 ~x86 ~amd64-linux ~x86-linux"
LICENSE="GPL-3"
IUSE=""

PATCHES=( "${FILESDIR}"/${P}-test-build.patch )

AUTOTOOLS_IN_SOURCE_BUILD=1

src_prepare() {
	rm src/elf.h || die
	autotools-utils_src_prepare
}

src_configure() {
	local myeconfargs=( --docdir="${EPREFIX}"/usr/share/doc/${PF} )
	autotools-utils_src_configure
}

src_test() {
	autotools-utils_src_test -j1
}
