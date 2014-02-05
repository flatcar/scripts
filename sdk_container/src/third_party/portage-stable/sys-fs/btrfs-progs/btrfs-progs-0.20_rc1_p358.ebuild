# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-fs/btrfs-progs/btrfs-progs-0.20_rc1_p358.ebuild,v 1.2 2013/07/25 02:23:27 floppym Exp $

EAPI=5

inherit multilib toolchain-funcs

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

DEPEND="
	dev-libs/lzo
	sys-libs/zlib
	sys-apps/acl
	sys-fs/e2fsprogs
"
RDEPEND="${DEPEND}"

src_compile() {
	emake \
		CC="$(tc-getCC)" \
		CFLAGS="${CFLAGS}" \
		LDFLAGS="${LDFLAGS}" \
		BUILD_VERBOSE=1
}

src_install() {
	emake install \
		DESTDIR="${D}" \
		prefix=/usr \
		bindir=/sbin \
		libdir=/usr/$(get_libdir) \
		mandir=/usr/share/man
}
