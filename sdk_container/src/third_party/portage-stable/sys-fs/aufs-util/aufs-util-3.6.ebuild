# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-fs/aufs-util/aufs-util-3.6.ebuild,v 1.6 2013/05/27 11:20:55 jlec Exp $

EAPI=5

inherit flag-o-matic linux-info multilib toolchain-funcs

DESCRIPTION="Utilities are always necessary for aufs"
HOMEPAGE="http://aufs.sourceforge.net/"
SRC_URI="http://dev.gentoo.org/~jlec/distfiles/${P}.tar.xz"
# git archive -v --prefix=aufs-util-3.6/ \
# --remote=git://aufs.git.sourceforge.net/gitroot/aufs/aufs-util.git aufs3.0 \
# -o aufs-util-3.6.tar && xz -ve9 aufs-util-3.6.tar

SLOT="0"
LICENSE="GPL-2"
KEYWORDS="~amd64 ~x86"
IUSE=""

RDEPEND="
	!sys-fs/aufs2
	!sys-fs/aufs3
	sys-kernel/aufs-sources"
DEPEND="${RDEPEND}"

src_prepare() {
	[[ -e "${KERNEL_DIR}"/include/linux/aufs_type.h ]] || \
		die "Please select aufs-sources before building ${PN}"
	append-cppflags -I"${KERNEL_DIR}/include"
	sed \
		-e "/LDFLAGS += -static -s/d" \
		-e "/CFLAGS/s:-O::g" \
		-i Makefile || die
	sed \
		-e "s:m 644 -s:m 644:g" \
		-e "s:/usr/lib:/usr/$(get_libdir):g" \
		-i libau/Makefile || die

	tc-export CC AR
	export HOSTCC=$(tc-getCC)
}
