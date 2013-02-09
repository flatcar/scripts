# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libiec61883/libiec61883-1.2.0.ebuild,v 1.1 2012/10/07 11:23:09 pacho Exp $

EAPI=4
inherit autotools eutils unpacker

DESCRIPTION="Library for capturing video (dv or mpeg2) over the IEEE 1394 bus"
HOMEPAGE="http://dennedy.org/cgi-bin/gitweb.cgi?p=dennedy.org/libiec61883.git"
SRC_URI="mirror://kernel/linux/libs/ieee1394/${P}.tar.xz"

LICENSE="|| ( LGPL-2.1 GPL-2 )"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~ppc64 ~sparc ~x86"
IUSE="examples"

RDEPEND=">=sys-libs/libraw1394-1.2.1"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

src_prepare() {
	if use examples; then
		sed -i -e "s:noinst_PROGRAMS.*:noinst_PROGRAMS = :g" \
		-e "s:in_PROGRAMS.*:in_PROGRAMS = plugreport plugctl test-amdtp test-dv	test-mpeg2 test-plugs:g" \
		examples/Makefile.am || die "noinst patching failed"
		eautoreconf
	fi
}

src_configure() {
	econf --disable-static
}

src_install() {
	default
	prune_libtool_files
}
