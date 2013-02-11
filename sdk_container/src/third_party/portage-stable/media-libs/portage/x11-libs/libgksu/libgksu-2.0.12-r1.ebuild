# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/libgksu/libgksu-2.0.12-r1.ebuild,v 1.15 2012/05/05 03:52:30 jdhore Exp $

EAPI="3"
GCONF_DEBUG="no"

inherit autotools eutils gnome2

DESCRIPTION="A library for integration of su into applications"
HOMEPAGE="http://www.nongnu.org/gksu/"
SRC_URI="http://people.debian.org/~kov/gksu/${P}.tar.gz"

LICENSE="LGPL-2"
SLOT="2"
KEYWORDS="alpha amd64 arm ia64 ~mips ppc ppc64 sh sparc x86 ~x86-fbsd"
IUSE="nls doc static-libs"

BOTH=">=x11-libs/gtk+-2.12:2
	>=gnome-base/gconf-2
	gnome-base/libgnome-keyring
	x11-libs/startup-notification
	>=gnome-base/libgtop-2
	nls? ( >=sys-devel/gettext-0.14.1 )"

DEPEND="${BOTH}
	doc? ( >=dev-util/gtk-doc-1.2-r1 )
	dev-util/gtk-doc-am
	>=dev-util/intltool-0.35.5
	virtual/pkgconfig"

RDEPEND="${BOTH}
	app-admin/sudo"

pkg_setup() {
	DOCS="AUTHORS ChangeLog"
	G2CONF="${G2CONF} $(use_enable nls) $(use_enable static-libs static)"
}

src_prepare() {
	# Fix compilation on bsd
	epatch "${FILESDIR}"/${PN}-2.0.0-fbsd.patch

	# Fix wrong usage of LDFLAGS, bug #226837
	epatch "${FILESDIR}/${PN}-2.0.7-libs.patch"

	# Use po/LINGUAS
	epatch "${FILESDIR}/${PN}-2.0.7-polinguas.patch"

	# Don't forkpty; bug #298289
	epatch "${FILESDIR}/${P}-revert-forkpty.patch"

	# Make this gmake-3.82 compliant, bug #333961
	epatch "${FILESDIR}/${P}-fix-make-3.82.patch"

	# Do not build test programs that are never executed; also fixes bug
	# #367397 (underlinking issues).
	epatch "${FILESDIR}/${P}-notests.patch"

	# Fix automake-1.11.2 compatibility, bug #397411
	epatch "${FILESDIR}/${P}-automake-1.11.2.patch"

	intltoolize --force --copy --automake || die "intltoolize failed"
	eautoreconf
	gnome2_src_prepare
}

src_install() {
	gnome2_src_install

	find "${ED}" -name '*.la' -exec rm -f {} +
}
