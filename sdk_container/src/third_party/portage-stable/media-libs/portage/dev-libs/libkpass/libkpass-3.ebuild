# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libkpass/libkpass-3.ebuild,v 1.3 2011/12/14 15:07:52 ssuominen Exp $

EAPI=4

DESCRIPTION="Libkpass is a from-scratch C implementation of accessing KeePass 1.x format password databases"
HOMEPAGE="http://libkpass.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"
IUSE="static-libs"

RDEPEND=">=dev-libs/openssl-1"
DEPEND="${RDEPEND}"

DOCS=( AUTHORS ChangeLog README TODO )

src_configure() {
	econf $(use_enable static-libs static)
}

src_install() {
	default
	use static-libs || rm -f "${ED}"/usr/lib*/${PN}.la
}
