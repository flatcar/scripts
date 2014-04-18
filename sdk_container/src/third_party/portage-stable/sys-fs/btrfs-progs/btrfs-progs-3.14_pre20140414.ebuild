# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-fs/btrfs-progs/btrfs-progs-3.14_pre20140414.ebuild,v 1.1 2014/04/14 20:26:56 slyfox Exp $

EAPI=5

inherit eutils multilib toolchain-funcs

libbtrfs_soname=0

if [[ ${PV} != 9999 ]]; then
	MY_PV=v${PV}
	KEYWORDS="~alpha ~amd64 ~arm ~ia64 ~mips ~ppc ~ppc64 ~sparc ~x86"
	#SRC_URI="https://www.kernel.org/pub/linux/kernel/people/mason/${PN}/${PN}-${MY_PV}.tar.xz"
	SRC_URI="https://dev.gentoo.org/~slyfox/distfiles/${PN}-${MY_PV}.tar.xz"
	S="${WORKDIR}"/${PN}-${MY_PV}
else
	inherit git-2
	EGIT_REPO_URI="git://git.kernel.org/pub/scm/linux/kernel/git/mason/btrfs-progs.git
		https://git.kernel.org/pub/scm/linux/kernel/git/mason/btrfs-progs.git"
fi

DESCRIPTION="Btrfs filesystem utilities"
HOMEPAGE="https://btrfs.wiki.kernel.org"

LICENSE="GPL-2"
SLOT="0/${libbtrfs_soname}"
IUSE=""

DEPEND="
	dev-libs/lzo
	sys-libs/zlib
	sys-apps/acl
	sys-fs/e2fsprogs
"
RDEPEND="${DEPEND}"

src_prepare() {
	epatch_user
}

src_compile() {
	emake \
		AR="$(tc-getAR)" \
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
