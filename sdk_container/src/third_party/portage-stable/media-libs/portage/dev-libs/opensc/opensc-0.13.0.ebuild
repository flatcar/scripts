# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/opensc/opensc-0.13.0.ebuild,v 1.1 2013/01/01 23:18:01 alonbl Exp $

EAPI=4

DESCRIPTION="Libraries and applications to access smartcards"
HOMEPAGE="http://www.opensc-project.org/opensc/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86"
IUSE="doc +pcsc-lite openct ctapi readline ssl zlib"

RDEPEND="zlib? ( sys-libs/zlib )
	readline? ( sys-libs/readline )
	ssl? ( dev-libs/openssl )
	openct? ( >=dev-libs/openct-0.5.0 )
	pcsc-lite? ( >=sys-apps/pcsc-lite-1.3.0 )"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	app-text/docbook-xsl-stylesheets
	dev-libs/libxslt"

REQUIRED_USE="
	pcsc-lite? ( !openct !ctapi )
	openct? ( !pcsc-lite !ctapi )
	ctapi? ( !pcsc-lite !openct )
	|| ( pcsc-lite openct ctapi )"

src_configure() {
	econf \
		--docdir="/usr/share/doc/${PF}" \
		--htmldir='$(docdir)/html' \
		--disable-static \
		$(use_enable doc) \
		$(use_enable openct) \
		$(use_enable readline) \
		$(use_enable zlib) \
		$(use_enable ssl openssl) \
		$(use_enable pcsc-lite pcsc) \
		$(use_enable openct) \
		$(use_enable ctapi)
}

src_install() {
	default
	find "${ED}"/usr -name '*.la' -delete
}
