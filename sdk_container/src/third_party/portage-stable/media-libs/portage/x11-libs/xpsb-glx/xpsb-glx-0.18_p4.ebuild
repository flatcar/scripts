# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/xpsb-glx/xpsb-glx-0.18_p4.ebuild,v 1.1 2009/09/13 20:09:12 patrick Exp $

EAPI="2"

inherit rpm

DESCRIPTION="glx for the intel gma500 (poulsbo)"
HOMEPAGE="http://www.happyassassin.net/2009/05/13/native-poulsbo-gma-500-graphics-driver-for-fedora-10/"
SRC_URI="http://adamwill.fedorapeople.org/poulsbo/src/xpsb-glx-0.18-4.fc11.src.rpm"

LICENSE="intel-psb"
SLOT="0"
KEYWORDS="~x86"
IUSE=""

DEPEND=""
RDEPEND=""

S="${WORKDIR}/${PN}"

src_install() {
	insopts -m0755

	insinto /usr/lib/dri
	doins dri/psb_dri.so

	insinto /usr/lib/va/drivers
	doins dri/psb_drv_video.la
	doins dri/psb_drv_video.so

	insinto /usr/lib/xorg/modules/drivers
	doins drivers/Xpsb.la
	doins drivers/Xpsb.so
}
