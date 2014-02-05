# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-fs/btrfs-progs/btrfs-progs-0.20_rc1.ebuild,v 1.4 2013/01/06 11:11:29 ago Exp $

EAPI=4

MY_PV=${PV/_rc/-rc}

#inherit git-2 toolchain-funcs
inherit toolchain-funcs

DESCRIPTION="Btrfs filesystem utilities"
HOMEPAGE="https://btrfs.wiki.kernel.org"
# tarballed out of v0.20-rc1 tag in btrfs-progs repo
SRC_URI="http://dev.gentoo.org/~slyfox/${PN}-${MY_PV}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~ia64 ~mips ~ppc ~ppc64 ~sparc ~x86"
IUSE=""

DEPEND="sys-libs/zlib
	sys-apps/acl
	sys-fs/e2fsprogs"
RDEPEND="${DEPEND}"

S="${WORKDIR}/${PN}-${MY_PV}"

#EGIT_REPO_URI="git://git.kernel.org/pub/scm/linux/kernel/git/mason/btrfs-progs.git
#	https://git.kernel.org/pub/scm/linux/kernel/git/mason/btrfs-progs.git"
#EGIT_COMMIT="89fe5b5f666c247aa3173745fb87c710f3a71a4a"

src_prepare() {
	# upstream didn't bump program version
	sed -i -e "s:Btrfs v0\.19:v${MY_PV}:" version.sh || die
}

src_compile() {
	emake CC="$(tc-getCC)" CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}"
}

src_install() {
	emake DESTDIR="${D}" prefix=/usr bindir=/sbin mandir=/usr/share/man install
}

pkg_postinst() {
	ewarn "WARNING: This version of btrfs-progs corresponds to and should only"
	ewarn "         be used with the version of btrfs included in the"
	ewarn "         Linux kernel (2.6.31 and above)."
	ewarn ""
	ewarn "         This version should NOT be used with earlier versions"
	ewarn "         of the standalone btrfs module!"
}
