# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/dvnet/dvnet-0.9.24.ebuild,v 1.3 2012/03/21 10:09:44 ssuominen Exp $

EAPI=4

DESCRIPTION="Provides an interface wrapping sockets into streams"
HOMEPAGE="http://tinf2.vub.ac.be/~dvermeir/software/dv/dvnet/html/"
SRC_URI="http://tinf2.vub.ac.be/~dvermeir/software/dv/${PN}/download/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"
IUSE="doc static-libs"

RDEPEND=">=dev-libs/dvutil-1.0.10-r2"
DEPEND="${RDEPEND}"

DOCS="AUTHORS ChangeLog" # NEWS and README are useless

src_prepare() {
	sed -i -e 's/^\(SUBDIRS =.*\)doc\(.*\)$/\1\2/' Makefile.in || die
}

src_configure() {
	econf $(use_enable static-libs static)
}

src_install() {
	default
	use doc && dohtml doc/html/*

	# Keeping .la files in purpose, see: http://bugs.gentoo.org/409125
	find "${ED}" -name '*.la' -exec sed -i -e "/^dependency_libs/s:=.*:='':" {} +
}
