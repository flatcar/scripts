# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-fs/btrfs-progs/btrfs-progs-0.19.11.ebuild,v 1.6 2012/10/17 03:34:08 phajdan.jr Exp $

EAPI=4

# Note: leaving commented-out references to using git downloading, since
#       upstream does not produce tarballs for the versions we need.
#       We, for now, are using the git hash and subversion used by Fedora.

#inherit git-2 toolchain-funcs
inherit toolchain-funcs

DESCRIPTION="Btrfs filesystem utilities"
HOMEPAGE="https://btrfs.wiki.kernel.org"
SRC_URI="mirror://gentoo/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 arm ~mips ppc ppc64 x86"
IUSE=""

DEPEND="sys-libs/zlib
	sys-apps/acl
	sys-fs/e2fsprogs"
RDEPEND="${DEPEND}"

#EGIT_REPO_URI="git://git.kernel.org/pub/scm/linux/kernel/git/mason/btrfs-progs.git
#	https://git.kernel.org/pub/scm/linux/kernel/git/mason/btrfs-progs.git"
#EGIT_COMMIT="1957076ab4fefa47b6efed3da541bc974c83eed7"

src_prepare() {
	# Fix hardcoded "gcc" and "make"
	sed -i -e 's:gcc $(CFLAGS):$(CC) $(CFLAGS):' Makefile || die
	sed -i -e 's:make:$(MAKE):' Makefile || die
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
