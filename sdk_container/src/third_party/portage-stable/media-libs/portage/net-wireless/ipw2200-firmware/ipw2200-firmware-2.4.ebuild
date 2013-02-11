# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-wireless/ipw2200-firmware/ipw2200-firmware-2.4.ebuild,v 1.8 2013/01/21 22:33:11 ssuominen Exp $

inherit bsdmk

MY_P=${P/firmware/fw}
S=${WORKDIR}

DESCRIPTION="Firmware for the Intel PRO/Wireless 2200BG/2915ABG miniPCI and 2225BG PCI adapters"

HOMEPAGE="http://ipw2200.sourceforge.net/"
SRC_URI="http://www.bughost.org/firmware/${MY_P}.tgz"

LICENSE="ipw2200-fw"
SLOT="0"
KEYWORDS="~amd64 x86 ~x86-fbsd"

IUSE="kernel_linux kernel_FreeBSD"
DEPEND="kernel_FreeBSD? ( >=sys-freebsd/freebsd-sources-6.2 )"
RDEPEND="kernel_linux? ( virtual/udev )"

src_unpack() {
	unpack ${A}

	if use kernel_FreeBSD ; then
		# We create a Makefile for each firmware file
		# and get FreeBSD to make each kernel module
		local fw fwname kmod d mfile
		for fw in "boot:boot" "bss:bss" "bss_ucode:ucode_bss" \
			"ibss:ibss" "ibss_ucode:ucode_ibss" \
			"sniffer:monitor" "sniffer_ucode:ucode_monitor"; do
			fwname="ipw-${PV}-${fw%%:*}.fw"
			kmod="iwi_${fw#*:}"
			d="${S}/${kmod}"
			mkdir "${d}" || die
			echo "LDFLAGS=" > "${d}/Makefile" || die
			echo "KMOD=${kmod}" >> "${d}/Makefile" || die
			echo "FIRMWS=${fwname}:${kmod}:${PV}" \
				>> "${d}/Makefile" || die
			echo ".include <bsd.kmod.mk>" >> "${d}/Makefile" || die
			mv "${S}/${fwname}" "${d}" || die
		done
	fi
}

src_compile() {
	if use kernel_FreeBSD ; then
		local kmod
		for kmod in boot bss ucode_bss ibss ucode_ibss \
		monitor ucode_monitor; do
			cd "${S}/iwi_${kmod}"; mkmake all || die
		done
	fi
}

src_install() {
	dodoc LICENSE

	if use kernel_linux ; then
		insinto /lib/firmware
		doins *.fw
	fi

	if use kernel_FreeBSD ; then
		mkdir -p "${D}/boot/kernel"
		local kmod
		for kmod in boot bss ucode_bss ibss ucode_ibss monitor ucode_monitor; do
			cd "${S}/iwi_${kmod}"; mkmake DESTDIR="${D}" install || die
		done

		# We never want to own this file
		rm "${D}/boot/kernel/linker.hints"
	fi
}

pkg_postinst() {
	if use kernel_FreeBSD ; then
		# Rebuild the linker.hints
		kldxref "${ROOT}/boot/kernel"
	fi
}
