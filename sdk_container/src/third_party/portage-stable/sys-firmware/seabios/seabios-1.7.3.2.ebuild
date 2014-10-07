# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-firmware/seabios/seabios-1.7.3.2.ebuild,v 1.3 2014/04/30 21:17:26 vapier Exp $

EAPI=5

PYTHON_COMPAT=( python{2_6,2_7} )

inherit eutils toolchain-funcs python-any-r1

#BACKPORTS=1

# SeaBIOS maintainers sometimes don't release stable tarballs or stable
# binaries to generate the stable tarball the following is necessary:
# git clone git://git.seabios.org/seabios.git && cd seabios
# git archive --output seabios-${PV}.tar.gz --prefix seabios-${PV}/ rel-${PV}

if [[ ${PV} = *9999* || ! -z "${EGIT_COMMIT}" ]]; then
	EGIT_REPO_URI="git://git.seabios.org/seabios.git"
	inherit git-2
else
	KEYWORDS="~amd64 ~ppc ~ppc64 ~x86 ~amd64-fbsd ~x86-fbsd"
	SRC_URI="http://code.coreboot.org/p/seabios/downloads/get/${P}.tar.gz
	http://code.coreboot.org/p/seabios/downloads/get/bios.bin-${PV}.gz
	http://dev.gentoo.org/~cardoe/distfiles/${P}.tar.gz
	http://dev.gentoo.org/~cardoe/distfiles/bios.bin-${PV}.gz
	${BACKPORTS:+http://dev.gentoo.org/~cardoe/distfiles/${P}-${BACKPORTS}.tar.xz}"
fi

DESCRIPTION="Open Source implementation of a 16-bit x86 BIOS"
HOMEPAGE="http://www.seabios.org"

LICENSE="LGPL-3 GPL-3"
SLOT="0"
IUSE="+binary"

REQUIRED_USE="ppc? ( binary )
	ppc64? ( binary )"

DEPEND="
	!binary? (
		>=sys-power/iasl-20060912
		${PYTHON_DEPS}
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

	local myld=$(tc-getLD)

	${myld} -v | grep -q "GNU gold" && \
	ewarn "gold linker unable to handle 16-bit code using ld.bfd.  bug #438058"
}

pkg_setup() {
	use binary || python-any-r1_pkg_setup
}

src_prepare() {
	if [[ -z "${EGIT_COMMIT}" ]]; then
		sed -e "s/VERSION=.*/VERSION=${PV}/" \
			-i "${S}/Makefile"
	else
		sed -e "s/VERSION=.*/VERSION=${PV}_pre${EGIT_COMMIT}/" \
			-i "${S}/Makefile"
	fi

	epatch_user
}

src_configure() {
	:
}

src_compile() {
	if ! use binary ; then
		LANG=C emake \
			CC=$(tc-getCC) \
			LD="$(tc-getLD).bfd" \
			AR=$(tc-getAR) \
			OBJCOPY=$(tc-getOBJCOPY) \
			RANLIB=$(tc-getRANLIB) \
			OBJDUMP=$(tc-getPROG OBJDUMP objdump) \
			HOST_CC=$(tc-getBUILD_CC) \
			out/bios.bin
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
