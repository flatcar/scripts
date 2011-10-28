# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-embedded/openocd/openocd-0.4.0.ebuild,v 1.2 2011/10/10 20:23:06 hwoarang Exp $

EGIT_REPO_URI="git://${PN}.git.sourceforge.net/gitroot/${PN}/${PN}"
inherit eutils
if [[ ${PV} == "9999" ]] ; then
	inherit git-2 autotools
	#KEYWORDS=""
	SRC_URI=""
else
	KEYWORDS="~amd64 ~x86"
	SRC_URI="mirror://berlios/${PN}/${P}.tar.gz"
fi

DESCRIPTION="OpenOCD - Open On-Chip Debugger"
HOMEPAGE="http://openocd.sourceforge.net"

LICENSE="GPL-2"
SLOT="0"
IUSE="ftd2xx ftdi parport presto usb"
RESTRICT="strip" # includes non-native binaries

# libftd2xx is the default because it is reported to work better.
DEPEND="usb? ( dev-libs/libusb )
	presto? ( dev-embedded/libftd2xx )
	ftd2xx? ( dev-embedded/libftd2xx )
	ftdi? ( dev-embedded/libftdi )"
RDEPEND="${DEPEND}"

pkg_setup() {
	if use ftdi && use ftd2xx ; then
		ewarn "You can only use one FTDI library at a time, so picking"
		ewarn "USE=ftdi (open source) over USE=ftd2xx (closed source)"
	fi
}

src_unpack() {
	if [[ ${PV} == "9999" ]] ; then
		git-2_src_unpack
		cd "${S}"
		eautoreconf
	else
		unpack ${A}
	fi
}

src_compile() {
	if [[ ${PV} == "9999" ]] ; then
		myconf="${myconf} --enable-maintainer-mode"
	fi
	if use usb;then
		myconf="${myconf} --enable-usbprog --enable-jlink --enable-rlink \
			--enable-vsllink --enable-arm-jtag-ew"
	fi
	# add explicitely the path to libftd2xx
	use ftd2xx && ! use ftdi && LDFLAGS="${LDFLAGS} -L/opt/$(get_libdir)"
	econf \
		--disable-werror \
		--enable-amtjtagaccel \
		--enable-ep93xx \
		--enable-at91rm9200 \
		--enable-gw16012 \
		--enable-oocd_trace \
		$(use_enable parport) \
		$(use_enable presto presto_ftd2xx) \
		$(use_enable ftdi ft2232_libftdi) \
		$(use ftdi || use_enable ftd2xx ft2232_ftd2xx) \
		${myconf}
	emake || die "Error in emake!"
}

src_install() {
	emake DESTDIR="${D}" install || die
	dodoc AUTHORS ChangeLog NEWS README TODO
	prepstrip "${D}"/usr/bin
}
