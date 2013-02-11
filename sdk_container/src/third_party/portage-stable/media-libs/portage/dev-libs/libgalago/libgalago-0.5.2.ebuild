# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libgalago/libgalago-0.5.2.ebuild,v 1.16 2012/05/04 18:35:48 jdhore Exp $

inherit eutils autotools

DESCRIPTION="Galago - desktop presence framework"
HOMEPAGE="http://www.galago-project.org/"
SRC_URI="http://www.galago-project.org/files/releases/source/${PN}/${P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="alpha amd64 hppa ia64 ppc ppc64 x86 ~x86-fbsd"
IUSE="test"

RDEPEND=">=dev-libs/glib-2.8
	>=dev-libs/dbus-glib-0.71"
DEPEND="${RDEPEND}
		>=sys-devel/gettext-0.10.40
		virtual/pkgconfig
		test? ( dev-libs/check )"
PDEPEND=">=sys-apps/galago-daemon-0.5.1"

src_compile() {
	econf $(use_enable test tests) || die "configure failed"
	emake || die "make failed"
}

src_install() {
	make DESTDIR="${D}" install || die "install failed"
	dodoc AUTHORS ChangeLog NEWS
}
