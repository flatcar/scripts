# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-misc/bridge-utils/bridge-utils-1.5.ebuild,v 1.12 2013/09/14 07:42:52 ago Exp $

EAPI="5"

inherit autotools eutils linux-info toolchain-funcs

DESCRIPTION="Tools for configuring the Linux kernel 802.1d Ethernet Bridge"
HOMEPAGE="http://bridge.sourceforge.net/"
SRC_URI="mirror://sourceforge/bridge/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 arm hppa ia64 ~mips ppc ppc64 sparc x86"
IUSE=""

DEPEND="virtual/os-headers"
RDEPEND=""

CONFIG_CHECK="~BRIDGE"
WARNING_BRIDGE="CONFIG_BRIDGE is required to get bridge devices in the kernel"

get_headers() {
	CTARGET=${CTARGET:-${CHOST}}
	dir=/usr/include
	tc-is-cross-compiler && dir=/usr/${CTARGET}/usr/include
	echo "${dir}"
}

src_prepare() {
	epatch "${FILESDIR}"/${P}-linux-3.8.patch
	eautoreconf
}

src_configure() {
	# use santitized headers and not headers from /usr/src
	econf \
		--prefix=/ \
		--libdir=/usr/$(get_libdir) \
		--includedir=/usr/include \
		--with-linux-headers="$(get_headers)"
}

src_install () {
	emake install DESTDIR="${D}"
	dodoc AUTHORS ChangeLog README THANKS TODO \
		doc/{FAQ,FIREWALL,HOWTO,PROJECTS,RPM-GPG-KEY,SMPNOTES,WISHLIST}
	[ -f "${D}"/sbin/brctl ] || die "upstream makefile failed to install binary"
}
