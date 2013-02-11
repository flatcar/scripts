# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/maloc/maloc-1.5.ebuild,v 1.3 2012/05/02 10:38:42 jlec Exp $

EAPI=4

AUTOTOOLS_AUTORECONF=yes

inherit autotools-utils

DESCRIPTION="Minimal Abstraction Layer for Object-oriented C/C++ programs"
HOMEPAGE="http://www.fetk.org/codes/maloc/index.html"
SRC_URI="http://www.fetk.org/codes/download/${P}.tar.gz"

SLOT="0"
LICENSE="GPL-2"
IUSE="doc mpi static-libs"
KEYWORDS="~amd64 ~ppc ~x86 ~amd64-linux ~x86-linux"

RDEPEND="
	sys-libs/readline
	mpi? ( virtual/mpi )"
DEPEND="${RDEPEND}
	doc? (
		media-gfx/graphviz
		app-doc/doxygen )"

S="${WORKDIR}/${PN}"

PATCHES=(
	"${FILESDIR}"/1.4-mpi.patch
	"${FILESDIR}"/1.4-asneeded.patch
	"${FILESDIR}"/1.4-doc.patch
	)

src_configure() {
	local myeconfargs
	use mpi && export CC="mpicc"
	use doc || myeconfargs+=( --with-doxygen= --with-dot= )

	myeconfargs+=(
		--docdir="${EPREFIX}"/usr/share/doc/${PF}
		$(use_enable mpi)
		--disable-triplet
		)
	autotools-utils_src_configure
}

src_install() {
	autotools-utils_src_install

	# install doc
	dohtml doc/index.html
}
