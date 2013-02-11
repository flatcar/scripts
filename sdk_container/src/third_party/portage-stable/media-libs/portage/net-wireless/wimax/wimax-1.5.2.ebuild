# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-wireless/wimax/wimax-1.5.2.ebuild,v 1.3 2012/02/25 17:13:18 jer Exp $

EAPI="3"

inherit linux-info base autotools

DESCRIPTION="Intel WiMAX daemon used to interface to the hardware"
HOMEPAGE="http://www.linuxwimax.org/"
SRC_URI="http://www.linuxwimax.org/Download?action=AttachFile&do=get&target=${P}.tar.gz -> ${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND="dev-libs/libnl:1.1
		>=sys-kernel/linux-headers-2.6.34"
RDEPEND="${DEPEND}
		net-wireless/wimax-tools
		net-wireless/wpa_supplicant[wimax]"

src_configure() {
	econf \
		--with-libwimaxll=/usr/$(get_libdir) \
		--localstatedir=/var \
		--with-i2400m=/usr || die "econf failed"
}

src_install() {
	emake DESTDIR="${D}" install || die "Install failed"
	doinitd "${FILESDIR}"/wimax || die "failed to place the init daemon"
	sed -e "s:/usr/lib/libeap.so.0:/usr/$(get_libdir)/libeap.so.0:g" \
		-e "s:<GetDeviceTraces>3</GetDeviceTraces>:<GetDeviceTraces>0</GetDeviceTraces>:g" \
		-e "s:<OutputTarget>console</OutputTarget>:<OutputTarget>daemon</OutputTarget>:g" \
		-e "s:<IPRenew>1</IPRenew>:<IPRenew>0</IPRenew>:g" \
		-i "${D}/etc/wimax/config.xml" || die "Fixing config failed"
	# Drop udev rusles for now
	rm -rf  "${D}/etc/udev"
}
