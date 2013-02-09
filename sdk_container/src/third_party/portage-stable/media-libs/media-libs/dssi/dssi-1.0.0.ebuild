# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/dssi/dssi-1.0.0.ebuild,v 1.7 2012/05/05 08:02:30 jdhore Exp $

EAPI=2
inherit eutils libtool multilib

DESCRIPTION="Plugin API for software instruments with user interfaces"
HOMEPAGE="http://dssi.sourceforge.net/"
SRC_URI="mirror://sourceforge/dssi/${P}.tar.gz"

LICENSE="LGPL-2.1 BSD"
SLOT="0"
KEYWORDS="amd64 ppc ppc64 x86"
IUSE=""

RDEPEND="media-libs/alsa-lib
	>=media-libs/liblo-0.12
	>=media-sound/jack-audio-connection-kit-0.99.0-r1
	>=media-libs/ladspa-sdk-1.12-r2
	>=media-libs/libsndfile-1.0.11
	>=media-libs/libsamplerate-0.1.1-r1"
DEPEND="${RDEPEND}
	sys-apps/sed
	virtual/pkgconfig"

src_prepare() {
	sed -i \
		-e "s:libdir=.*:libdir=@libdir@:" \
		dssi.pc.in || die
	elibtoolize
}

src_configure() {
	QTDIR=/WONT_BE_FOUND
	econf \
		--disable-dependency-tracking
}

src_install() {
	emake DESTDIR="${D}" install || die
	dodoc README doc/TODO doc/*.txt
	find "${D}" -name '*.la' -delete
}
