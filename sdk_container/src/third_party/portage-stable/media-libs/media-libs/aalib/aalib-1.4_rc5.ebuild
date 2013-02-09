# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/aalib/aalib-1.4_rc5.ebuild,v 1.26 2011/02/06 12:08:49 leio Exp $

inherit eutils libtool toolchain-funcs autotools

MY_P="${P/_/}"
S="${WORKDIR}/${PN}-1.4.0"

DESCRIPTION="A ASCII-Graphics Library"
HOMEPAGE="http://aa-project.sourceforge.net/aalib/"
SRC_URI="mirror://sourceforge/aa-project/${MY_P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~x86-fbsd"
IUSE="X slang gpm"

RDEPEND="X? ( x11-libs/libX11 )
	slang? ( >=sys-libs/slang-1.4.2 )"
DEPEND="${RDEPEND}
	>=sys-libs/ncurses-5.1
	X? ( x11-proto/xproto )
	gpm? ( sys-libs/gpm )"

src_unpack() {
	unpack ${A}
	cd "${S}"
	epatch "${FILESDIR}"/${PN}-1.4_rc4-gentoo.patch
	epatch "${FILESDIR}"/${PN}-1.4_rc4-m4.patch

	sed -i -e 's:#include <malloc.h>:#include <stdlib.h>:g' "${S}"/src/*.c

	# Fix bug #165617.
	use gpm && sed -i \
		's/gpm_mousedriver_test=yes/gpm_mousedriver_test=no/' "${S}/configure.in"

	eautoreconf
}

src_compile() {
	econf \
		$(use_with slang slang-driver) \
		$(use_with X x11-driver) \
		|| die
	emake CC="$(tc-getCC)" || die
}

src_install() {
	emake DESTDIR="${D}" install || die
	dodoc ANNOUNCE AUTHORS ChangeLog NEWS README*
}
