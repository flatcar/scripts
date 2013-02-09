# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libemf/libemf-1.0.4.ebuild,v 1.10 2012/05/09 18:00:30 aballier Exp $

EAPI=4

AUTOTOOLS_AUTORECONF=true

inherit autotools-utils

MY_P="${P/emf/EMF}"
DESCRIPTION="Library implementation of ECMA-234 API for the generation of enhanced metafiles."
HOMEPAGE="http://libemf.sourceforge.net/"
SRC_URI="mirror://sourceforge/libemf/${MY_P}.tar.gz"

LICENSE="LGPL-2.1 GPL-2"
SLOT="0"
KEYWORDS="amd64 ppc ppc64 sparc x86 ~amd64-fbsd ~x86-fbsd ~amd64-linux ~x86-linux"
IUSE="doc static-libs"

S=${WORKDIR}/${MY_P}

PATCHES=( "${FILESDIR}"/${P}-amd64-alpha.patch )

src_configure() {
	local myeconfargs=( --enable-editing )
	autotools-utils_src_configure
}

src_install() {
	autotools-utils_src_install
	use doc && dohtml doc/html/*
}
