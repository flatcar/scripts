# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/gmetadom/gmetadom-0.2.6.ebuild,v 1.9 2012/05/04 18:35:48 jdhore Exp $

WANT_AUTOCONF=latest
WANT_AUTOMAKE=latest

inherit autotools flag-o-matic eutils

DESCRIPTION="A library providing bindings for multiple languages of multiple C DOM implementations"
HOMEPAGE="http://gmetadom.sourceforge.net/"
SRC_URI="mirror://sourceforge/gmetadom/${P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="alpha amd64 hppa ia64 ppc ppc64 sparc x86"
IUSE="ocaml"

RDEPEND="dev-libs/glib
	>=dev-libs/gdome2-0.8.0
	>=dev-libs/libxslt-1.0.0"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	ocaml? (
		>=dev-lang/ocaml-3.05
		>=dev-ml/findlib-0.8
	)"

src_unpack() {
	unpack ${A}
	cd "${S}"

	epatch "${FILESDIR}"/${P}-gentoo.patch
	epatch "${FILESDIR}"/${P}-gcc43.patch
	eautoreconf
}

src_compile() {
	local mymod="gdome_cpp_smart"

	# Unconditonal use of -fPIC (#55238).
	append-flags -fPIC
	use ocaml && mymod="${mymod} gdome_caml"

	econf --with-modules="${mymod}" || die
	# parallel b0rks
	emake -j1 || die
}

src_install() {
	emake -j1 DESTDIR="${D}" install || die

	dodoc AUTHORS BUGS ChangeLog HISTORY NEWS README
}
