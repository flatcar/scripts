# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libiec61883/libiec61883-1.1.0.ebuild,v 1.12 2012/05/05 08:02:39 jdhore Exp $

WANT_AUTOMAKE="latest"
WANT_AUTOCONF="latest"

inherit autotools eutils

DESCRIPTION="library for capturing video (dv or mpeg2) over the IEEE 1394 bus"
HOMEPAGE="http://www.linux1394.org"
#AFAIK, this isn't mirrored on sourceforge like libraw1394.
SRC_URI="http://www.linux1394.org/dl/${P}.tar.gz"

LICENSE="|| ( LGPL-2.1 GPL-2 )"
SLOT="0"
KEYWORDS="amd64 ppc ppc64 sparc x86"
IUSE="examples"

RDEPEND=">=sys-libs/libraw1394-1.2.1"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

src_unpack() {
	unpack ${A}
	cd ${S}

	if use examples
	then
		sed -i -e "s:noinst_PROGRAMS.*:noinst_PROGRAMS = :g" \
		-e "s:in_PROGRAMS.*:in_PROGRAMS = plugreport plugctl test-amdtp test-dv	test-mpeg2 test-plugs:g" \
		examples/Makefile.am || die "noinst patching failed"
	fi

	eautoreconf
}

src_install () {
		make DESTDIR="${D}" install || die "installation failed"
		dodoc AUTHORS ChangeLog NEWS README
}
