# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/systemd-ui/systemd-ui-2.ebuild,v 1.2 2013/03/29 14:16:34 mgorny Exp $

EAPI=4

VALA_MIN_API_VERSION=0.14
VALA_MAX_API_VERSION=0.20

inherit autotools-utils vala

DESCRIPTION="System and service manager for Linux"
HOMEPAGE="http://www.freedesktop.org/wiki/Software/systemd"
SRC_URI="http://www.freedesktop.org/software/systemd/${P}.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

VALASLOT="0.14"

RDEPEND="!sys-apps/systemd[gtk]
	>=dev-libs/glib-2.26
	dev-libs/libgee:0.8
	sys-apps/dbus
	x11-libs/gtk+:2
	>=x11-libs/libnotify-0.7"

DEPEND="${RDEPEND}
	app-arch/xz-utils
	$(vala_depend)"

# Due to vala being broken.
AUTOTOOLS_IN_SOURCE_BUILD=1

src_prepare() {
	# Force the rebuild of .vala sources
	touch src/*.vala || die

	# Fix hardcoded path in .vala.
	sed -i -e 's:/lib/systemd:/usr&:g' src/*.vala || die

	autotools-utils_src_prepare
}

src_configure() {
	vala_src_prepare
	autotools-utils_src_configure
}
