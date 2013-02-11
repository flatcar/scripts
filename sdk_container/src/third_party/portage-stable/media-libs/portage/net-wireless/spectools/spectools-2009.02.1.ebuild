# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-wireless/spectools/spectools-2009.02.1.ebuild,v 1.2 2012/12/11 17:47:41 axs Exp $

inherit eutils

MY_PN=${PN}
MY_PV=${PV/\./-}
MY_PV=${MY_PV/./-R}
MY_P="${MY_PN}-${MY_PV}"
S=${WORKDIR}/${MY_P}

DESCRIPTION="Tools for the MetaGeek Wi-Spy spectrum analyzer"
HOMEPAGE="http://www.kismetwireless.net/spectools/"
SRC_URI="http://www.kismetwireless.net/code/${MY_P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"
IUSE="debug gtk ncurses"

DEPEND="=virtual/libusb-0*
		ncurses? ( sys-libs/ncurses )
		gtk? ( =x11-libs/gtk+-2* )"
# Maemo: Add hildon and bbus
RDEPEND="${DEPEND}
		virtual/udev
		!<sys-fs/udev-114"

src_unpack() {
	unpack ${A}
	epatch "${FILESDIR}"/spectools-2009.02.1-udev-rules.patch
	epatch "${FILESDIR}"/spectools-2009.02.1-libusb-compat.patch
}

src_compile() {
	econf $(use_with gtk gtk-version 2) || die "econf failed"

	emake depend || die "emake depend failed"

	emake spectool_{raw,net} \
		|| die "emake spectool_{raw,net} failed"

	if use ncurses; then
		emake spectool_curses \
			|| die "emake spectool_curses failed"
	fi

	if use gtk; then
		emake spectool_gtk \
			|| die "emake spectool_gtk failed"
	fi

	#if use maemo; then
	#	emake spectool_hildon usbcontrol \
	#		|| die "emake spectool_hildon usbcontrol failed"
	#fi
}

src_install() {
	dobin spectool_raw spectool_net
	use ncurses && dobin spectool_curses
	use gtk && dobin spectool_gtk
	dodoc README

	insinto /etc/udev/rules.d/
	doins 99-wispy.rules

	#if use maemo; then
	#	dobin spectool_hildon
	#	dosbin usbcontrol
	#fi
}
