# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/xmlwrapp/xmlwrapp-0.6.2.ebuild,v 1.1 2010/06/20 12:24:17 hwoarang Exp $

EAPI="2"
inherit base eutils toolchain-funcs

DESCRIPTION="modern style C++ library that provides a simple and easy interface to libxml2"
HOMEPAGE="http://sourceforge.net/projects/xmlwrapp/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~x86-fbsd"
IUSE=""

RDEPEND="dev-libs/libxml2
	dev-libs/libxslt"
DEPEND="${RDEPEND}"

DOCS=( "AUTHORS"
	"NEWS"
	"README"
)

src_configure() {
	econf --docdir=/usr/share/doc/${PF}
}
