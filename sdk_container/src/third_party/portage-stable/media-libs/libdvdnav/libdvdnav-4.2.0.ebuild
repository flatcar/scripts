# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libdvdnav/libdvdnav-4.2.0.ebuild,v 1.6 2012/02/12 19:39:12 armin76 Exp $

EAPI=4
inherit autotools libtool

DESCRIPTION="Library for DVD navigation tools"
HOMEPAGE="http://dvdnav.mplayerhq.hu/"
SRC_URI="http://dvdnav.mplayerhq.hu/releases/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 sh sparc x86 ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~x86-solaris"
IUSE=""

RDEPEND=">=media-libs/libdvdread-${PV}"
DEPEND="${RDEPEND}"

DOCS=( AUTHORS ChangeLog DEVELOPMENT-POLICY.txt doc/dvd_structures NEWS README TODO )

src_prepare() {
	sed -i -e '/^CFLAGS/s:-O3::' configure.ac || die
	elibtoolize
	eautoreconf
}

src_install() {
	default
	rm -f "${ED}"usr/lib*/${PN}*.la
}
