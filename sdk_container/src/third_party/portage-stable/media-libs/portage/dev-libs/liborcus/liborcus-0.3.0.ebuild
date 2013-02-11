# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/liborcus/liborcus-0.3.0.ebuild,v 1.4 2013/01/15 08:42:58 scarabeus Exp $

EAPI=4

EGIT_REPO_URI="git://gitorious.org/orcus/orcus.git"

[[ ${PV} == 9999 ]] && GITECLASS="git-2"
inherit autotools ${GITECLASS}
unset GITECLASS

DESCRIPTION="Standalone file import filter library for spreadsheet documents"
HOMEPAGE="http://gitorious.org/orcus/pages/Home"
[[ ${PV} == 9999 ]] || SRC_URI="http://kohei.us/files/orcus/src/${P/-/_}.tar.bz2"

LICENSE="MIT"
SLOT="0"
[[ ${PV} == 9999 ]] || \
KEYWORDS="~amd64 ~ppc ~x86"
IUSE="static-libs"

RDEPEND="
	>=dev-libs/boost-1.51.0
	dev-libs/libzip
"
DEPEND="${RDEPEND}
	>=dev-util/mdds-0.6.0
"

S="${WORKDIR}/${P/-/_}"

src_prepare() {
	sed -i \
		-e 's:<ostream>:<ostream>\n#include <boost/utility.hpp>:' \
		include/orcus/dom_tree.hpp || die

	eautoreconf
}

src_configure() {
	econf \
		--disable-werror \
		--disable-spreadsheet-model \
		$(use_enable static-libs static)
}

src_install() {
	default

	find "${ED}" -name '*.la' -exec rm -f {} +
}
