# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libcuefile/libcuefile-444.ebuild,v 1.14 2009/10/01 16:08:30 klausman Exp $

inherit cmake-utils

# svn co http://svn.musepack.net/libcuefile/trunk libcuefile-${PV}
# tar -cjf libcuefile-${PV}.tar.bz2 libcuefile-${PV}

DESCRIPTION="Cue File library from Musepack"
HOMEPAGE="http://www.musepack.net"
SRC_URI="mirror://gentoo/${P}.tar.bz2"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="alpha amd64 hppa ppc ppc64 x86 ~x86-fbsd"
IUSE=""

PATCHES=( "${FILESDIR}/${P}-multilib_and_shared.patch" )

pkg_setup() {
	mycmakeargs="-DSHARED=ON"
}

src_install() {
	cmake-utils_src_install
	# Forgot to remove .svn directories from snapshot.
	rm -rf "${D}"/usr/include/cuetools/.svn || die "rm -rf failed"
}
