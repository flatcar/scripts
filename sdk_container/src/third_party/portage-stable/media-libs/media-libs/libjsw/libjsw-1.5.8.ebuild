# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libjsw/libjsw-1.5.8.ebuild,v 1.6 2010/07/15 09:04:12 fauli Exp $
EAPI=2

inherit eutils multilib

DESCRIPTION="provide a uniform API and user configuration for joysticks and game controllers"
HOMEPAGE="http://freshmeat.net/projects/libjsw/"
SRC_URI="http://wolfsinger.com/~wolfpack/packages/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ppc ~ppc64 x86"
IUSE=""

DEPEND=""

src_prepare() {
	cp include/jsw.h libjsw/
	epatch "${FILESDIR}"/${P}-build.patch
	bunzip2 libjsw/man/* jscalibrator/jscalibrator.1.bz2 || die "bunzip failed"
}

src_compile() {
	cd libjsw
	emake || die "main build failed"
	ln -s libjsw.so.${PV} libjsw.so
}

src_install() {
	insinto /usr/include
	doins include/jsw.h || die "doins jsw.h failed"

	dodoc README
	docinto jswdemos
	dodoc jswdemos/*

	cd "${S}"/libjsw
	dolib.so libjsw.so.${PV} || die "dolib.so"
	dosym libjsw.so.${PV} /usr/$(get_libdir)/libjsw.so
	doman man/*
}
