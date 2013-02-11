# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libmirage/libmirage-1.5.0-r1.ebuild,v 1.6 2013/01/28 00:21:01 tetromino Exp $

EAPI="4"

inherit autotools eutils

DESCRIPTION="CD and DVD image access library"
HOMEPAGE="http://cdemu.org"
SRC_URI="mirror://sourceforge/cdemu/${P}.tar.bz2"

LICENSE="GPL-2+"
SLOT="0"
KEYWORDS="amd64 ~hppa x86"
IUSE="static-libs"

RDEPEND=">=dev-libs/glib-2.28:2
	>=media-libs/libsndfile-1.0
	sys-libs/zlib"
DEPEND="${RDEPEND}
	dev-util/gtk-doc-am
	virtual/pkgconfig"
# eautoreconf needs dev-util/gtk-doc-am

src_prepare() {
	# In next release, prevents mirage_session_add_language() crash
	epatch "${FILESDIR}/${P}-session-initialize-language.patch"

	# bug #399701, https://sourceforge.net/tracker/?func=detail&aid=3479700&group_id=93175&atid=603423
	epatch "${FILESDIR}/${P}-gtk-doc.patch"
	eautoreconf
}

src_configure() {
	econf \
		$(use_enable static-libs static)
}

src_install() {
	default
	find "${D}" -name '*.la' -exec rm -f {} +
}
