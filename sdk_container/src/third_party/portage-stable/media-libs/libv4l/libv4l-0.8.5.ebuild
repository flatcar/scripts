# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libv4l/libv4l-0.8.5.ebuild,v 1.7 2011/12/30 13:14:33 ssuominen Exp $

EAPI=4
inherit linux-info multilib toolchain-funcs

MY_P=v4l-utils-${PV}

DESCRIPTION="Separate libraries ebuild from upstream v4l-utils package"
HOMEPAGE="http://git.linuxtv.org/v4l-utils.git"
SRC_URI="http://linuxtv.org/downloads/v4l-utils/${MY_P}.tar.bz2"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ppc ppc64 sparc x86 ~amd64-linux ~x86-linux"
IUSE=""

RDEPEND="virtual/jpeg"
DEPEND="${RDEPEND}
	>=sys-kernel/linux-headers-2.6.30-r1"

S=${WORKDIR}/${MY_P}

CONFIG_CHECK="~SHMEM"

src_compile() {
	tc-export CC
	pushd lib
	emake PREFIX="${EPREFIX}/usr" LIBDIR="${EPREFIX}/usr/$(get_libdir)" CFLAGS="${CFLAGS}"
	popd
}

src_install() {
	pushd lib
	emake DESTDIR="${D}" PREFIX="${EPREFIX}/usr" LIBDIR="${EPREFIX}/usr/$(get_libdir)" install
	popd
	dodoc ChangeLog README.lib* TODO
}
