# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/xforms/xforms-1.0.93_p1.ebuild,v 1.2 2011/02/26 22:40:48 signals Exp $

EAPI="2"

inherit autotools versionator

MY_PV="$(replace_version_separator _ s)"
MY_P="${PN}-${MY_PV}"

DESCRIPTION="A graphical user interface toolkit for X"
HOMEPAGE="http://www.nongnu.org/xforms/"
SRC_URI="http://savannah.nongnu.org/download/xforms/${MY_P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64 ~arm ~ppc ~ppc64 ~sh ~sparc ~x86 ~amd64-linux ~x86-linux ~ppc-macos ~sparc-solaris"
IUSE="doc opengl"

RDEPEND="
	virtual/jpeg
	x11-libs/libSM
	x11-libs/libX11
	x11-libs/libXpm
	opengl? ( virtual/opengl )"
DEPEND="
	${RDEPEND}
	x11-proto/xproto"

S="${WORKDIR}"/${MY_P}

src_prepare() {
	rm "${S}"/config/libtool.m4 "${S}"/acinclude.m4
	AT_M4DIR=config eautoreconf
}

src_configure() {
	local myopts
	use opengl || myopts="--disable-gl"
	use doc && myopts="${myopts} --enable-docs"

	econf ${myopts} || die "econf failed"
}

src_install () {
	emake DESTDIR="${D}" install || die
	dodoc ChangeLog NEWS README
}
