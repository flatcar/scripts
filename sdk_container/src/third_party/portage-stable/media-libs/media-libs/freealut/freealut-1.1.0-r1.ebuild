# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/freealut/freealut-1.1.0-r1.ebuild,v 1.2 2010/04/30 10:46:48 ssuominen Exp $

EAPI=2
inherit autotools eutils

DESCRIPTION="The OpenAL Utility Toolkit"
HOMEPAGE="http://www.openal.org/"
SRC_URI="http://connect.creativelabs.com/openal/Downloads/ALUT/${P}.tar.gz"

LICENSE="LGPL-2"
SLOT="0"
KEYWORDS="alpha amd64 hppa ia64 ppc ppc64 sparc x86 ~x86-fbsd"
IUSE=""

DEPEND="media-libs/openal"

src_prepare() {
	# Link against openal and pthread
	sed -i -e 's/libalut_la_LIBADD = .*/& -lopenal -lpthread/' src/Makefile.am
	AT_M4DIR="${S}/admin/autotools/m4" eautoreconf
}

src_configure() {
	econf \
		--libdir=/usr/$(get_libdir)
}

src_compile() {
	emake all || die
}

src_install() {
	emake DESTDIR="${D}" install || die
	dodoc AUTHORS ChangeLog NEWS README
	dohtml doc/*
}
