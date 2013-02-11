# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libbsd/libbsd-0.4.2.ebuild,v 1.3 2012/07/02 08:25:53 jdhore Exp $

EAPI=4
inherit eutils multilib

DESCRIPTION="An library to provide useful functions commonly found on BSD systems"
HOMEPAGE="http://libbsd.freedesktop.org/wiki/"
SRC_URI="http://${PN}.freedesktop.org/releases/${P}.tar.gz"

LICENSE="BSD BSD-2 BSD-4 ISC"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE="static-libs"

DOCS="ChangeLog README TODO"

pkg_setup() {
	local f="${ROOT}/usr/$(get_libdir)/${PN}.a"
	local m="You need to remove ${f} by hand or re-emerge sys-libs/glibc first."
	if ! has_version ${CATEGORY}/${PN}; then
		if [[ -e ${f} ]]; then
			eerror "${m}"
			die "${m}"
		fi
	fi
}

src_configure() {
	econf \
		--disable-silent-rules \
		$(use_enable static-libs static)
}

src_install() {
	default
	prune_libtool_files
}
