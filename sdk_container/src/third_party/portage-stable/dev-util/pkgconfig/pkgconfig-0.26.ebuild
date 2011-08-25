# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-util/pkgconfig/pkgconfig-0.26.ebuild,v 1.7 2011/07/31 19:27:35 jer Exp $

EAPI=4
inherit flag-o-matic multilib

MY_P=pkg-config-${PV}

DESCRIPTION="Package config system that manages compile/link flags"
HOMEPAGE="http://pkgconfig.freedesktop.org/wiki/"
SRC_URI="http://pkgconfig.freedesktop.org/releases/${MY_P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~sparc-fbsd ~x86-fbsd"
IUSE="elibc_FreeBSD hardened"

RDEPEND="dev-libs/glib:2
	>=dev-libs/popt-1.15"
DEPEND="${RDEPEND}"

S=${WORKDIR}/${MY_P}

DOCS=( AUTHORS NEWS README )

src_configure() {
	if ! has_version dev-util/pkgconfig; then
		export GLIB_CFLAGS="-I/usr/include/glib-2.0 -I/usr/$(get_libdir)/glib-2.0/include"
		export GLIB_LIBS="-lglib-2.0"
	fi

	use ppc64 && use hardened && replace-flags -O[2-3] -O1

	# Force using all the requirements when linking, so that needed -pthread
	# lines are inherited between libraries
	local myconf
	use elibc_FreeBSD && myconf="--enable-indirect-deps"

	econf \
		--docdir=/usr/share/doc/${PF}/html \
		--with-installed-popt \
		${myconf}
}
