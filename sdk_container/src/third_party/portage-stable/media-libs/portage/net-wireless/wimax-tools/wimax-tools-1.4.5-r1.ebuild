# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-wireless/wimax-tools/wimax-tools-1.4.5-r1.ebuild,v 1.11 2013/01/06 10:06:33 ago Exp $

EAPI=4

inherit base linux-info multilib

DESCRIPTION="Tools to use Intel's WiMax cards"
HOMEPAGE="http://www.linuxwimax.org"
SRC_URI="http://linuxwimax.org/Download?action=AttachFile&do=get&target=${P}.tar.gz -> ${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~alpha amd64 ~ia64 ppc ppc64 ~sparc x86"
IUSE="static-libs"

DEPEND="
		virtual/pkgconfig
		>=sys-kernel/linux-headers-2.6.34
		>=dev-libs/libnl-1.0:1.1"
RDEPEND=""

src_configure() {
	econf \
		$(use_enable static-libs static)
}

src_install() {
	default
	use static-libs || find "${ED}" -name '*.*a' -exec rm {} +
}
