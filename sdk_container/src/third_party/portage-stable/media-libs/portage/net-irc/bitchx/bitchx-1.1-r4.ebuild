# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-irc/bitchx/bitchx-1.1-r4.ebuild,v 1.6 2011/12/21 19:52:31 binki Exp $

inherit flag-o-matic eutils

MY_PN=ircii-pana
MY_P=${MY_PN}-${PV}-final
S=${WORKDIR}/BitchX
DESCRIPTION="An IRC Client"
HOMEPAGE="http://www.bitchx.org/"
SRC_URI="mirror://sourceforge/${PN}/${MY_PN}/${MY_PN}-${PV}/${MY_P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ~ia64 ppc sh sparc x86"
IUSE="cjk ipv6 ssl"

DEPEND=">=sys-libs/ncurses-5.1
	ssl? ( >=dev-libs/openssl-0.9.6 )"

src_unpack() {
	unpack ${A}
	cd "${S}"
	use cjk && epatch "${FILESDIR}"/${PV}/${P}-cjk.patch
	epatch "${FILESDIR}"/${PV}/${P}-pbxs.patch
	epatch "${FILESDIR}"/${PV}/${P}-hebrew.patch
	epatch "${FILESDIR}"/${PV}/${P}-freenode.patch
	epatch "${FILESDIR}"/${PV}/${P}-gcc34.patch
	epatch "${FILESDIR}"/${PV}/${P}-gcc41.patch
	epatch "${FILESDIR}"/${PV}/${P}-inline.patch
	epatch "${FILESDIR}"/${PV}/${P}-headers.patch
	epatch "${FILESDIR}"/${PV}/${P}-build.patch
	epatch "${FILESDIR}"/${PV}/${P}-open-mode.patch
	epatch "${FILESDIR}"/fPIC.patch
	epatch "${FILESDIR}"/BitchX-64bit.patch

	sed -i \
		-e "s/#undef LATIN1/#define LATIN1 ON/;" \
		include/config.h
}

src_compile() {
	replace-flags -O[3-9] -O2
	append-flags -fno-strict-aliasing

	# Disable CDROM or else it will take over your CDROM drive
	local myconf="--disable-cdrom --disable-sound --without-gtk"

	# lamer@gentoo.org BROKEN, will not work with our socks
	# implementations, is looking for a SOCKSConnect function that our
	# dante packages don't have :-(
	# use socks5 \
	#	&& myconf="${myconf} --with-socks=5" \
	#	|| myconf="${myconf} --without-socks"

	econf \
		--with-plugins \
		$(use_with ssl) \
		$(use_enable ipv6) \
		${myconf} || die

	emake || die "make failed"
	emake -C contrib vh1 || die "make vh1 failed"
}

src_install () {
	einstall || die
	dobin contrib/vh1 || die
	dosym BitchX-1.1-final /usr/bin/BitchX
	dosym BitchX-1.1-final /usr/bin/bitchx

	cd "${S}"
	dodoc bugs Changelog README* IPv6-support

	cd "${S}"/doc
	insinto /usr/include/X11/bitmaps
	doins BitchX.xpm || die
	dodoc README.* *.txt */*.txt tcl/*
	dohtml -r *

	cd "${S}"/dll
	docinto plugins
	dodoc nap/README.nap
	newdoc acro/README README.acro
	newdoc arcfour/README README.arcfour
	newdoc blowfish/README README.blowfish
	newdoc qbx/README README.qbx
}
