# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-firmware/seabios/seabios-1.7.0.ebuild,v 1.5 2012/10/17 03:39:28 cardoe Exp $

EAPI=4

PYTHON_DEPEND="2"

inherit python

#BACKPORTS=1

if [[ ${PV} = *9999* || ! -z "${EGIT_COMMIT}" ]]; then
	EGIT_REPO_URI="git://git.seabios.org/seabios.git"
	inherit git-2
	KEYWORDS=""
	SRC_URI=""
else
	KEYWORDS="amd64 ~ppc ~ppc64 x86 ~amd64-fbsd ~x86-fbsd"
	SRC_URI="http://www.linuxtogo.org/~kevin/SeaBIOS/${P}.tar.gz
	http://dev.gentoo.org/~cardoe/distfiles/${P}-bins.tar.xz
	${BACKPORTS:+http://dev.gentoo.org/~cardoe/distfiles/${P}-bp-${BACKPORTS}.tar.bz2}"
fi

DESCRIPTION="Open Source implementation of a 16-bit x86 BIOS"
HOMEPAGE="http://www.seabios.org"

LICENSE="LGPL-3 GPL-3"
SLOT="0"
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}"

pkg_setup() {
	python_set_active_version 2
}

src_prepare() {
	if [[ -z "${EGIT_COMMIT}" ]]; then
		sed -e "s/VERSION=.*/VERSION=${PV}/" \
			-i "${S}/Makefile"
	else
		sed -e "s/VERSION=.*/VERSION=${PV}_pre${EGIT_COMMIT}/" \
			-i "${S}/Makefile"
	fi
}

src_configure() {
	:
}

src_compile() {
	if use amd64 || use x86 ; then
		LANG=C emake out/bios.bin
	fi
}

src_install() {
	insinto /usr/share/seabios
	if use amd64 || use x86 ; then
		doins out/bios.bin
	else
		doins bins/bios.bin
	fi
}
