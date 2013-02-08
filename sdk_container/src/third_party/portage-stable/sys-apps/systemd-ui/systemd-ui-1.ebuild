# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/systemd-ui/systemd-ui-1.ebuild,v 1.1 2012/03/31 11:52:03 mgorny Exp $

EAPI=4

inherit autotools-utils

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
	dev-libs/libgee:0
	sys-apps/dbus
	x11-libs/gtk+:2
	>=x11-libs/libnotify-0.7"

DEPEND="${RDEPEND}
	app-arch/xz-utils
	dev-lang/vala:${VALASLOT}"

# Due to vala being broken.
AUTOTOOLS_IN_SOURCE_BUILD=1

src_prepare() {
	# Force the rebuild of .vala sources
	touch src/*.vala || die

	# Fix hardcoded path in .vala.
	sed -i -e 's:/lib/systemd:/usr/lib/systemd:g' src/*.vala || die

	autotools-utils_src_prepare
}

src_configure() {
	export VALAC="$(type -p valac-${VALASLOT})"
	autotools-utils_src_configure
}
