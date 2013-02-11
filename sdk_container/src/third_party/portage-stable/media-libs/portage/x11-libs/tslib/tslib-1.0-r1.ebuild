# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/tslib/tslib-1.0-r1.ebuild,v 1.12 2010/02/08 20:16:54 solar Exp $

inherit eutils toolchain-funcs autotools

PATCH_VER=4
DESCRIPTION="Touchscreen Access Library"
HOMEPAGE="http://tslib.berlios.de/"
SRC_URI="mirror://berlios/${PN}/${PN}-${PV}.tar.bz2
	mirror://gentoo/${PN}-${PV}-patches-${PATCH_VER}.tar.bz2"

LICENSE="LGPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~m68k ~mips ppc ppc64 ~s390 sh sparc x86"
IUSE=""
#extras arctic2 collie corgi h3600 linear-h2200 mk712 ucb1x00"

src_unpack() {
	unpack ${A}
	cd "${S}"
	# patches come from buildroot + openembedded + suse
	EPATCH_SUFFIX=patch epatch "${WORKDIR}"/patch
	eautoreconf
}

src_compile() {
	# compile everything. INSTALL_MASK= what you don't want.
	econf \
		--enable-linear --enable-dejitter \
		--enable-variance --enable-pthres \
		--enable-input --enable-shared \
		--enable-arctic2 --enable-collie \
		--enable-corgi 	--enable-h3600 \
		--enable-linear-h2200 --enable-mk712 \
		--enable-ucb1x00 --disable-debug
	emake || die "emake failed"
}

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"
	dodoc AUTHORS NEWS README
}
