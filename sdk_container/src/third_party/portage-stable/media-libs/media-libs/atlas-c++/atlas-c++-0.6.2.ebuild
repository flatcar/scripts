# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/atlas-c++/atlas-c++-0.6.2.ebuild,v 1.7 2011/08/12 21:35:44 xarthisius Exp $
EAPI=2

inherit eutils autotools

MY_PN="Atlas-C++"
MY_P=${MY_PN}-${PV}
DESCRIPTION="Atlas protocol, used in role playing games at worldforge."
HOMEPAGE="http://www.worldforge.org/dev/eng/libraries/atlas_cpp"
SRC_URI="mirror://sourceforge/worldforge/${MY_P}.tar.bz2"

SLOT="0"
LICENSE="LGPL-2.1"
KEYWORDS="amd64 x86"
IUSE="doc"

RDEPEND=""
DEPEND="${RDEPEND}
	doc? ( app-doc/doxygen )"

S=${WORKDIR}/${MY_P}

src_prepare() {
	epatch "${FILESDIR}"/${P}-Werror.patch
	eautoreconf
}

src_compile() {
	emake || die "Error: emake failed!"
	if use doc; then
		emake docs ||  die "Error: emake docs failed!"
	fi
}

src_install() {
	emake DESTDIR="${D}" install || die "install failed"
	use doc && dohtml -r doc/html/*
	use doc && doman doc/man/man3/[^i]*
	dodoc AUTHORS ChangeLog HACKING NEWS README ROADMAP THANKS TODO
}
