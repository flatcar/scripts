# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-util/patchelf/patchelf-0.6.ebuild,v 1.3 2013/01/30 15:48:37 ago Exp $

EAPI=4

NUMBER="1524660"

DESCRIPTION="Small utility to modify the dynamic linker and RPATH of ELF executables."
HOMEPAGE="http://nixos.org/patchelf.html"
SRC_URI="http://hydra.nixos.org/build/${NUMBER}/download/2/${P}.tar.bz2"

SLOT="0"
KEYWORDS="amd64 x86 ~amd64-linux ~x86-linux"
LICENSE="GPL-3"
IUSE=""

src_configure() {
	econf \
		--docdir="${EPREFIX}"/usr/share/doc/${PF}
}
