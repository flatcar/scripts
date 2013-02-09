# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/opus/opus-1.0.1.ebuild,v 1.9 2013/02/03 14:01:37 ago Exp $

EAPI=4

if [[ ${PV} == *9999 ]] ; then
	SCM="git-2"
	EGIT_REPO_URI="git://git.opus-codec.org/opus.git"
fi

inherit autotools ${SCM}

MY_P=${P/_/-}
DESCRIPTION="Open versatile codec designed for interactive speech and audio transmission over the internet"
HOMEPAGE="http://opus-codec.org/"
SRC_URI="http://downloads.xiph.org/releases/opus/${P}.tar.gz"
if [[ ${PV} == *9999 ]] ; then
	SRC_URI=""
elif [[ ${PV%_p*} != ${PV} ]] ; then # Gentoo snapshot
	SRC_URI="http://dev.gentoo.org/~lu_zero/${PN}/${P}.tar.xz"
else # Official release
	SRC_URI="http://downloads.xiph.org/releases/${PN}/${MY_P}.tar.gz"
fi

LICENSE="BSD-2"
SLOT="0"
KEYWORDS="~alpha amd64 arm ~hppa ~ia64 ppc ppc64 x86 ~amd64-fbsd"
IUSE="doc static-libs"

DEPEND="doc? ( app-doc/doxygen )"

S=${WORKDIR}/${MY_P}

src_prepare() {
	[[ ${PV} == *9999 ]] && eautoreconf
}

src_configure() {
	econf $(use_enable doc) $(use_enable static-libs static) --enable-custom-modes
}

src_compile() {
	default
}

src_install() {
	default
	find "${D}" -name '*.la' -delete
	rm -fR "${D}/usr/share/doc/opus"
	use doc && dohtml -r doc/html/*
}
