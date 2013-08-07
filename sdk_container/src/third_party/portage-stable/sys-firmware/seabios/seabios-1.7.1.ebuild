# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-firmware/seabios/seabios-1.7.1.ebuild,v 1.6 2013/03/17 03:14:42 cardoe Exp $

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
	SRC_URI="http://code.coreboot.org/p/seabios/downloads/get/${P}.tar.gz
	http://code.coreboot.org/p/seabios/downloads/get/bios.bin-${PV}.gz
	${BACKPORTS:+http://dev.gentoo.org/~cardoe/distfiles/${P}-bp-${BACKPORTS}.tar.bz2}"
fi

DESCRIPTION="Open Source implementation of a 16-bit x86 BIOS"
HOMEPAGE="http://www.seabios.org"

LICENSE="LGPL-3 GPL-3"
SLOT="0"
IUSE="+binary"

REQUIRED_USE="ppc? ( binary )
	ppc64? ( binary )"

DEPEND="!binary? (
		>=sys-power/iasl-20060912
		<sys-power/iasl-20130117
		)"
RDEPEND=""

pkg_pretend() {
	if ! use binary; then
		ewarn "You have decided to compile your own SeaBIOS. This is not"
		ewarn "supported by upstream unless you use their recommended"
		ewarn "toolchain (which you are not)."
		elog
		ewarn "If you are intending to use this build with QEMU, realize"
		ewarn "you will not receive any support if you have compiled your"
		ewarn "own SeaBIOS. Virtual machines subtly fail based on changes"
		ewarn "in SeaBIOS."
	fi
}

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
	if ! use binary ; then
		LANG=C emake out/bios.bin
	fi
}

src_install() {
	insinto /usr/share/seabios
	if ! use binary ; then
		doins out/bios.bin
	else
		newins ../bios.bin-${PV} bios.bin
	fi
}
