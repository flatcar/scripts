# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libcdio/libcdio-0.90.ebuild,v 1.1 2013/01/15 18:41:48 ssuominen Exp $

EAPI=5
inherit eutils

DESCRIPTION="A library to encapsulate CD-ROM reading and control"
HOMEPAGE="http://www.gnu.org/software/libcdio/"
SRC_URI="mirror://gnu/${PN}/${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~ppc ~ppc64 ~sh ~sparc ~x86 ~amd64-fbsd ~sparc-fbsd ~x86-fbsd ~x86-freebsd ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~x86-solaris"
IUSE="cddb +cxx minimal static-libs test"

RDEPEND="cddb? ( >=media-libs/libcddb-1.3.2 )
	!minimal? ( >=sys-libs/ncurses-5.7-r7 )
	virtual/libintl"
DEPEND="${RDEPEND}
	sys-apps/sed
	sys-devel/gettext
	virtual/pkgconfig
	test? ( dev-lang/perl )"

src_configure() {
	econf \
		--disable-maintainer-mode \
		$(use_enable cxx) \
		--disable-cpp-progs \
		--disable-example-progs \
		$(use_enable static-libs static) \
		$(use_enable cddb) \
		--disable-vcd-info \
		$(use_with !minimal cd-drive) \
		$(use_with !minimal cd-info) \
		$(use_with !minimal cdda-player) \
		$(use_with !minimal cd-read) \
		$(use_with !minimal iso-info) \
		$(use_with !minimal iso-read)
}

src_install() {
	emake DESTDIR="${D}" install
	dodoc AUTHORS ChangeLog NEWS README* THANKS TODO
	prune_libtool_files
}
