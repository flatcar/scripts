# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-fs/squashfs-tools/squashfs-tools-4.2_p20140119.ebuild,v 1.1 2014/01/23 12:40:10 jer Exp $

EAPI=5
inherit eutils toolchain-funcs

DESCRIPTION="Tool for creating compressed filesystem type squashfs"
HOMEPAGE="http://squashfs.sourceforge.net"
SRC_URI="http://dev.gentoo.org/~jer/${P}.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~arm-linux ~x86-linux"
IUSE="+xz lzma lzo xattr"

RDEPEND="
	xattr? ( sys-apps/attr )
	sys-libs/zlib
	!xz? ( !lzo? ( sys-libs/zlib ) )
	lzma? ( app-arch/xz-utils )
	lzo? ( dev-libs/lzo )
	xz? ( app-arch/xz-utils )
"
DEPEND="${RDEPEND}"

S="${WORKDIR}/${P}/squashfs-tools"

src_configure() {
	# set up make command line variables in EMAKE_SQUASHFS_CONF
	EMAKE_SQUASHFS_CONF=(
		$(usex lzma LZMA_XZ_SUPPORT= LZMA_XS_SUPPORT= 1 0)
		$(usex lzo LZO_SUPPORT= LZO_SUPPORT= 1 0)
		$(usex xattr XATTR_SUPPORT= XATTR_SUPPORT= 1 0)
		$(usex xz XZ_SUPPORT= XZ_SUPPORT= 1 0)
	)

	tc-export CC
}

src_compile() {
	emake ${EMAKE_SQUASHFS_CONF[@]}
}

src_install() {
	dobin mksquashfs unsquashfs
	dodoc ../README
}

pkg_postinst() {
	ewarn "This version of mksquashfs requires a 2.6.29 kernel or better"
	use xz &&
		ewarn "XZ support requires a 2.6.38 kernel or better"
}
