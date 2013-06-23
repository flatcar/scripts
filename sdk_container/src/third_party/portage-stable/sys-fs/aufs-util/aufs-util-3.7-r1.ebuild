# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-fs/aufs-util/aufs-util-3.7-r1.ebuild,v 1.3 2013/05/27 11:20:55 jlec Exp $

EAPI=5

inherit flag-o-matic linux-info multilib toolchain-funcs

AUFS_VERSION=3.7.3
AUFS_TARBALL="aufs-sources-${AUFS_VERSION}.tar.xz"
AUFS_URI="http://dev.gentoo.org/~jlec/distfiles/${AUFS_TARBALL}"

DESCRIPTION="Utilities are always necessary for aufs"
HOMEPAGE="http://aufs.sourceforge.net/"
SRC_URI="
	${AUFS_URI}
	http://dev.gentoo.org/~jlec/distfiles/${P}.tar.xz"
# git archive -v --prefix=aufs-util-3.7/ \
# --remote=git://aufs.git.sourceforge.net/gitroot/aufs/aufs-util.git aufs3.0 \
# -o aufs-util-3.7.tar && xz -ve9 aufs-util-3.7.tar

SLOT="0"
LICENSE="GPL-2"
KEYWORDS="~amd64 ~x86"
IUSE=""

RDEPEND="
	!sys-fs/aufs2
	!sys-fs/aufs3"
DEPEND="${RDEPEND}"

src_prepare() {
	append-cppflags -I"${WORKDIR}/include"
	sed \
		-e "/LDFLAGS += -static -s/d" \
		-e "/CFLAGS/s:-O::g" \
		-i Makefile || die
	sed \
		-e "s:m 644 -s:m 644:g" \
		-e "s:/usr/lib:/usr/$(get_libdir):g" \
		-i libau/Makefile || die

	sed -i "s:__user::g" "${WORKDIR}"/include/uapi/linux/aufs_type.h || die

	tc-export CC AR
	export HOSTCC=$(tc-getCC)
}
