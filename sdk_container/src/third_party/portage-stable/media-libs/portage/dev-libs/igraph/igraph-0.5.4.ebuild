# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/igraph/igraph-0.5.4.ebuild,v 1.1 2011/11/13 20:48:46 vadimk Exp $

EAPI=4

DESCRIPTION="igraph is a free software package for creating and manipulating
undirected and directed graphs."
HOMEPAGE="http://igraph.sourceforge.net/index.html"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+arpack +blas debug gmp gprof +lapack static-libs"

DEPEND="
	gmp? ( dev-libs/gmp )
	dev-libs/libxml2
	arpack? ( sci-libs/arpack )
	blas? ( virtual/blas )
	lapack? ( virtual/lapack )
	"
RDEPEND="${DEPEND}"
src_configure() {
	econf \
		$(use_enable gmp) \
		$(use_enable gprof profiling) \
		$(use_enable debug) \
		--with-external-arpack \
		--with-external-blas \
		--with-external-lapack \
		$(use_enable static-libs static)
}

src_install() {
	default
	find "${ED}" -name '*.la' -delete
}
