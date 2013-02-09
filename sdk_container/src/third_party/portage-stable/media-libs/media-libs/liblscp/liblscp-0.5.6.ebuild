# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/liblscp/liblscp-0.5.6.ebuild,v 1.1 2009/10/18 17:13:08 aballier Exp $

DESCRIPTION="a C++ library for the Linux Sampler control protocol."
HOMEPAGE="http://www.linuxsampler.org"
SRC_URI="http://download.linuxsampler.org/packages/${P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"
IUSE="doc"

RDEPEND=""
DEPEND="doc? ( app-doc/doxygen )"

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed."
	dodoc AUTHORS ChangeLog TODO NEWS README

	if use doc; then
		dohtml -r doc/html/*
	fi
}
