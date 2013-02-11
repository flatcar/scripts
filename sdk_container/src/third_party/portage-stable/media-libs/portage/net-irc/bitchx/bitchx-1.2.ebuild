# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-irc/bitchx/bitchx-1.2.ebuild,v 1.3 2013/01/28 19:32:19 jer Exp $

EAPI=4

inherit autotools eutils flag-o-matic

MY_PN=BitchX
MY_P=${MY_PN}-${PV}-final
S=${WORKDIR}/${MY_PN}-${PV}
DESCRIPTION="An IRC Client"
HOMEPAGE="http://www.bitchx.ca/"
SRC_URI="http://bitchx.ca/${MY_P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~ppc ~sh ~sparc ~x86"
IUSE="ipv6 ssl"

DEPEND="sys-libs/ncurses
	ssl? ( dev-libs/openssl )"
RDEPEND="${DEPEND}"

src_prepare() {
	sed -i \
		-e "s/#undef LATIN1/#define LATIN1 ON/;" \
		include/config.h || die

	epatch "${FILESDIR}"/${P}-build.patch
	# Do epatch_user since even BX-1.2 has A LOT of patches and A LOT
	# of behaviour controlled by manually editing config.h
	epatch_user

	sed -i \
		-e 's|$(SHLIB_LD)|& $(LDFLAGS)|g' \
		dll/*/Makefile.in || die
	eautoreconf
}

src_configure() {
	# Disable CDROM or else it will take over your CDROM drive
	local myconf="--disable-cdrom --disable-sound --without-gtk"

	econf \
		--with-plugins \
		$(use_with ssl) \
		$(use_enable ipv6) \
		${myconf}
}

src_compile() {
	replace-flags -O[3-9] -O2
	append-flags -fno-strict-aliasing

	emake
	emake -C contrib vh1
}

src_install () {
	einstall
	dobin contrib/vh1
	dosym BitchX /usr/bin/bitchx

	cd "${S}"
	dodoc bugs Changelog README* IPv6-support

	cd "${S}"/doc
	insinto /usr/include/X11/bitmaps
	doins BitchX.xpm
	dodoc *.txt */*.txt
	dohtml -r *

	cd "${S}"/dll
	docinto plugins
	dodoc nap/README.nap
	newdoc acro/README README.acro
	newdoc arcfour/README README.arcfour
	newdoc blowfish/README README.blowfish
	newdoc qbx/README README.qbx
}
