# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-firmware/seabios/seabios-1.6.3.ebuild,v 1.4 2014/04/30 21:15:33 vapier Exp $

EAPI=4

PYTHON_DEPEND="2"

#BACKPORTS=1

if [[ ${PV} = *9999* || ! -z "${EGIT_COMMIT}" ]]; then
	EGIT_REPO_URI="git://git.seabios.org/seabios.git"
	GIT_ECLASS="git-2"
else
	SRC_URI="http://www.linuxtogo.org/~kevin/SeaBIOS/${P}.tar.gz
	${BACKPORTS:+http://dev.gentoo.org/~cardoe/distfiles/${P}-bp-${BACKPORTS}.tar.bz2}"
fi

inherit ${GIT_ECLASS} python

if [[ ${PV} != *9999* ]]; then
	KEYWORDS="amd64 x86"
fi

DESCRIPTION="Open Source implementation of a 16-bit x86 BIOS"
HOMEPAGE="http://www.seabios.org"

LICENSE="LGPL-3 GPL-3"
SLOT="0"
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}"

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
	emake out/bios.bin
#	emake out/vgabios.bin
}

src_install() {
	insinto /usr/share/seabios
	doins out/bios.bin
#	doins out/vgabios.bin
}
