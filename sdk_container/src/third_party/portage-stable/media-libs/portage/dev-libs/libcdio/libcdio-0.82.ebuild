# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libcdio/libcdio-0.82.ebuild,v 1.8 2012/05/04 18:35:49 jdhore Exp $

EAPI=2

inherit eutils libtool multilib autotools base

DESCRIPTION="A library to encapsulate CD-ROM reading and control"
HOMEPAGE="http://www.gnu.org/software/libcdio/"
SRC_URI="mirror://gnu/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ppc ppc64 sh sparc x86 ~sparc-fbsd ~x86-fbsd"
IUSE="cddb +cxx minimal static-libs"

RDEPEND="cddb? ( >=media-libs/libcddb-1.0.1 )
	virtual/libintl"
DEPEND="${RDEPEND}
	sys-devel/gettext
	virtual/pkgconfig"

PATCHES=(
	"${FILESDIR}"/${PN}-0.80-automagic-cddb.patch
)
DOCS=( AUTHORS ChangeLog NEWS README THANKS )

src_prepare() {
	base_src_prepare
	eautoreconf
	elibtoolize
}

src_configure() {
	econf \
		$(use_enable cddb) \
		$(use_enable static-libs static) \
		$(use_with !minimal cd-drive) \
		$(use_with !minimal cd-info) \
		$(use_with !minimal cd-paranoia) \
		$(use_with !minimal cdda-player) \
		$(use_with !minimal cd-read) \
		$(use_with !minimal iso-info) \
		$(use_with !minimal iso-read) \
		$(use_enable cxx) \
		--disable-example-progs --disable-cpp-progs \
		--with-cd-paranoia-name=libcdio-paranoia \
		--disable-vcd-info \
		--disable-dependency-tracking \
		--disable-maintainer-mode
}

src_install() {
	emake DESTDIR="${D}" install || die
	find "${D}" -name '*.la' -delete
}

pkg_postinst() {
	ewarn "If you've upgraded from a previous version of ${PN}, you may need to re-emerge"
	ewarn "packages that linked against ${PN} (vlc, vcdimager and more) by running:"
	ewarn "\trevdep-rebuild"
}
