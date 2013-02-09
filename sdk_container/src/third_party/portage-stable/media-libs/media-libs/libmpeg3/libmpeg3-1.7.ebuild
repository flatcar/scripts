# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libmpeg3/libmpeg3-1.7.ebuild,v 1.21 2010/11/11 10:18:47 ssuominen Exp $

EAPI=2
inherit eutils autotools toolchain-funcs

PATCHLEVEL="1"
DESCRIPTION="An mpeg library for linux"
HOMEPAGE="http://heroinewarrior.com/libmpeg3.php"
SRC_URI="mirror://sourceforge/heroines/${P}-src.tar.bz2
	mirror://gentoo/${P}-gentoo.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ppc ppc64 sh sparc x86"
IUSE="mmx"

RDEPEND="sys-libs/zlib
	virtual/jpeg
	media-libs/a52dec"
DEPEND="${RDEPEND}
	mmx? ( dev-lang/nasm )"

src_prepare() {
	epatch "${WORKDIR}"/${P}-mpeg3split.patch
	epatch "${WORKDIR}"/${P}-textrel.patch
	epatch "${WORKDIR}"/${P}-gnustack.patch
	epatch "${WORKDIR}"/${P}-a52.patch
	epatch "${WORKDIR}"/${P}-all_gcc4.patch
	epatch "${WORKDIR}"/${P}-all_pthread.patch

	# warning: incompatible implicit declaration of built-in function memcpy
	epatch "${FILESDIR}"/${P}-memcpy.patch

	cp -rf "${WORKDIR}"/${PV}/* .
	eautoreconf
}

src_configure() {
	#disabling css since it's a fake one.
	#One can find in the sources this message :
	#  Stubs for deCSS which can't be distributed in source form

	econf \
		$(use_enable mmx) \
		--disable-css
}

src_install() {
	emake DESTDIR="${D}" install || die
	dohtml -r docs
	# This is a workaround, it wants to rebuild
	# everything if the headers	 have changed
	# So we patch them after install...
	cd "${D}/usr/include/libmpeg3"
	# This patch patches the .h files that get installed into /usr/include
	# to show the correct include syntax '<>' instead of '""'  This patch
	# was also generated using info from SF's src.rpm
	epatch "${WORKDIR}"/gentoo-p2.patch

	find "${D}" -name '*.la' -exec rm -f '{}' +
}
