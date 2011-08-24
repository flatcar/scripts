# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-power/powertop/powertop-1.98.ebuild,v 1.1 2011/08/23 22:14:16 vapier Exp $

EAPI="4"

inherit eutils toolchain-funcs
if [[ ${PV} == "9999" ]] ; then
	EGIT_REPO_URI="git://git.kernel.org/pub/scm/status/powertop/powertop.git"
	inherit git-2
	SRC_URI=""
else
	SRC_URI="mirror://kernel/linux/status/${PN}/${P}.tar.bz2"
	KEYWORDS="~amd64 ~x86 ~amd64-linux ~x86-linux"
fi

DESCRIPTION="tool that helps you find what software is using the most power"
HOMEPAGE="http://www.lesswatts.org/projects/powertop/"

LICENSE="GPL-2"
SLOT="0"
IUSE="unicode"

DEPEND="
	dev-libs/libnl
	sys-apps/pciutils
	sys-devel/gettext
	sys-libs/ncurses[unicode?]
	sys-libs/zlib
"
RDEPEND="
	${DEPEND}
	net-wireless/bluez
	x11-apps/xset
"

DOCS=( TODO README )

src_prepare() {
	use unicode || sed -i 's:-lncursesw:-lncurses:' Makefile
	epatch "${FILESDIR}"/${PN}-1.98-build.patch
	epatch "${FILESDIR}"/${PN}-1.98-build-cc.patch
	sed -i -r \
		-e '/FLAGS/s: (-O2|-g|-fno-omit-frame-pointer|-fstack-protector|-D_FORTIFY_SOURCE=2)\>: :g' \
		-e '/@\$\(CC\)/s:@::' \
		Makefile || die
}

src_configure() {
	tc-export BUILD_CC CC CXX
	CFLAGS+=" ${CPPFLAGS}" # blah!
}

src_install() {
	default
	keepdir /var/cache/powertop
}

pkg_postinst() {
	echo
	einfo "For PowerTOP to work best, use a Linux kernel with the"
	einfo "tickless idle (NO_HZ) feature enabled (version 2.6.21 or later)"
	echo
}
