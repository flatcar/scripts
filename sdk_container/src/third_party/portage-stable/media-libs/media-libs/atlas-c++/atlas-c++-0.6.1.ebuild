# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/atlas-c++/atlas-c++-0.6.1.ebuild,v 1.7 2011/08/12 21:35:44 xarthisius Exp $

inherit eutils autotools

MY_PN="Atlas-C++"
MY_P=${MY_PN}-${PV}
DESCRIPTION="Atlas protocol, used in role playing games at worldforge."
HOMEPAGE="http://www.worldforge.org/dev/eng/libraries/atlas_cpp"
SRC_URI="mirror://sourceforge/worldforge/${MY_P}.tar.bz2"

SLOT="0"
LICENSE="LGPL-2.1"
KEYWORDS="amd64 x86"
IUSE="bzip2 doc zlib"

RDEPEND=""
DEPEND="${RDEPEND}
	doc? ( app-doc/doxygen )"

S=${WORKDIR}/${MY_P}

src_unpack() {
	unpack ${A}
	cd "${S}"
	epatch "${FILESDIR}"/${P}-strict-aliasing.patch \
		"${FILESDIR}"/${P}-gcc-4.3.patch
	eautoreconf
}

src_compile() {
	econf \
	    $(use_enable zlib) \
	    $(use_enable bzip2 bzlib) \
	    || die "Error: econf failed!"
	emake || die "Error: emake failed!"
	if use doc; then
		emake docs ||  die "Error: emake failed!"
	fi
}

src_install() {
	emake DESTDIR="${D}" install || die "install failed"
	use doc && dohtml -r doc/html/*
	use doc && doman doc/man/*
	dodoc AUTHORS ChangeLog HACKING NEWS README ROADMAP THANKS TODO
}
