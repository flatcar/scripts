# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-fs/btrfs-progs/btrfs-progs-0.20_rc1_p56.ebuild,v 1.1 2013/02/04 02:50:57 floppym Exp $

EAPI=4

inherit toolchain-funcs

if [[ ${PV} != 9999 ]]; then
	KEYWORDS="~alpha ~amd64 ~arm ~ia64 ~mips ~ppc ~ppc64 ~sparc ~x86"
	SRC_URI="http://dev.gentoo.org/~floppym/dist/${P}.tar.gz"
else
	inherit git-2
	EGIT_REPO_URI="git://git.kernel.org/pub/scm/linux/kernel/git/mason/btrfs-progs.git
		https://git.kernel.org/pub/scm/linux/kernel/git/mason/btrfs-progs.git"
fi

DESCRIPTION="Btrfs filesystem utilities"
HOMEPAGE="https://btrfs.wiki.kernel.org"

LICENSE="GPL-2"
SLOT="0"
IUSE=""

DEPEND="sys-libs/zlib
	sys-apps/acl
	sys-fs/e2fsprogs"
RDEPEND="${DEPEND}"

src_compile() {
	emake \
		CC="$(tc-getCC)" \
		AM_CFLAGS=-D_FILE_OFFSET_BITS=64 \
		CFLAGS="${CFLAGS}" \
		LDFLAGS="${LDFLAGS}"
}

src_install() {
	emake install \
		DESTDIR="${D}" \
		prefix=/usr \
		bindir=/sbin \
		mandir=/usr/share/man
}
