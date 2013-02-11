# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/libdrm-poulsbo/libdrm-poulsbo-2.3.0_p9-r1.ebuild,v 1.2 2012/05/21 23:22:20 vapier Exp $

EAPI="2"

WANT_AUTOMAKE="1.9"

inherit rpm autotools eutils

DESCRIPTION="libdrm for the intel gma500 (poulsbo)"
HOMEPAGE="http://www.happyassassin.net/2009/05/13/native-poulsbo-gma-500-graphics-driver-for-fedora-10/"
SRC_URI="http://adamwill.fedorapeople.org/poulsbo/src/libdrm-poulsbo-2.3.0-9.fc11.src.rpm"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86"
IUSE=""

DEPEND=""
RDEPEND=">=x11-libs/libdrm-2.3"

S=${WORKDIR}/libdrm-2.3.0

src_prepare() {
	epatch "${WORKDIR}/${PN}_configure_debian.patch"
	epatch "${WORKDIR}/${PN}_headers_debian.patch"
	epatch "${WORKDIR}/${PN}-relocate_headers.patch"

	mv "${WORKDIR}/*.h" "${S}/shared-core"
}

src_prepare() {
	eautoreconf
}

src_configure() {
	econf --libdir=/usr/lib/psb -includedir=/usr/include/psb
}

src_install() {
	emake install DESTDIR="${D}"
	insinto /usr/include/psb/drm
	doins "${WORKDIR}"/*.h
	dodir /usr/lib/pkgconfig
	mv "${D}/usr/lib/psb/pkgconfig/libdrm.pc" "${D}/usr/lib/pkgconfig/libdrm-poulsbo.pc"
	dodir /etc/env.d
	echo LDPATH=/usr/lib/psb > ${D}/etc/env.d/02psb
}
