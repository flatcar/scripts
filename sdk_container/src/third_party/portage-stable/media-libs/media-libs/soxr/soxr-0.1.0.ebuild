# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/soxr/soxr-0.1.0.ebuild,v 1.1 2013/01/25 10:34:21 aballier Exp $

EAPI=4

inherit cmake-utils

MY_P=${P}-Source
DESCRIPTION="The SoX Resampler library"
HOMEPAGE="https://sourceforge.net/p/soxr/wiki/Home/"
SRC_URI="mirror://sourceforge/soxr/${MY_P}.tar.xz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64"
IUSE="examples"

DEPEND=""
RDEPEND="${DEPEND}"

S="${WORKDIR}/${MY_P}"
DOCS=( "README" "TODO" "NEWS" "AUTHORS" )
PATCHES=(
	"${FILESDIR}/libsuffix.patch"
	"${FILESDIR}/nodoc.patch"
	"${FILESDIR}/noexamples.patch"
	)

src_install() {
	cmake-utils_src_install
	if use examples ; then
		insinto /usr/share/doc/${PF}/examples
		doins examples/*.[cCh] examples/README
	fi
}
