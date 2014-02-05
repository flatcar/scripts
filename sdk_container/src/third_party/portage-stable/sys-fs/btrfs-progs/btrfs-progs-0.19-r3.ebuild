# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-fs/btrfs-progs/btrfs-progs-0.19-r3.ebuild,v 1.9 2012/05/11 14:15:00 lavajoe Exp $

inherit eutils

DESCRIPTION="Btrfs filesystem utilities"
HOMEPAGE="https://btrfs.wiki.kernel.org"
SRC_URI="mirror://gentoo/${P}.tar.bz2
	mirror://gentoo/${P}-redhat.patch.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ~arm ~mips ~ppc ~ppc64 x86"
IUSE="acl debug-utils"

DEPEND="sys-libs/zlib
	debug-utils? ( dev-python/matplotlib )
	acl? (
			sys-apps/acl
			sys-fs/e2fsprogs
	)"
RDEPEND="${DEPEND}"

src_unpack() {
	unpack ${A}
	cd "${S}"

	# Apply patch from Josef Bacik (btrfs developer at RedHat)
	# that brings version 0.19 up to the version used in RedHat/Fedora.
	# Includes the previous convert-remove-used-space-update patch.
	# Also includes the "-D" option in btrfsctl (bug #331121).
	epatch "${WORKDIR}"/${P}-redhat.patch

	epatch "${FILESDIR}"/${P}-glibc212.patch

	# Fix underlinking (bug #369451): add -lcom_err when linking "convert"
	epatch "${FILESDIR}"/${P}-fix-underlinking.patch

	# Fix hardcoded "gcc" and "make"
	sed -i -e 's:gcc $(CFLAGS):$(CC) $(CFLAGS):' Makefile
	sed -i -e 's:make:$(MAKE):' Makefile
}

src_compile() {
	emake CC="$(tc-getCC)" CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" \
		all || die
	emake CC="$(tc-getCC)" CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" \
		btrfstune btrfs-image || die
	if use acl; then
		emake CC="$(tc-getCC)" CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" \
			convert || die
	fi
}

src_install() {
	into /
	dosbin btrfs
	dosbin btrfs-show
	dosbin btrfs-vol
	dosbin btrfsctl
	dosbin btrfsck
	dosbin btrfstune
	dosbin btrfs-image
	# fsck will segfault if invoked at boot, so do not make this link
	#dosym btrfsck /sbin/fsck.btrfs
	newsbin mkfs.btrfs mkbtrfs
	dosym mkbtrfs /sbin/mkfs.btrfs
	if use acl; then
		dosbin btrfs-convert
	else
		ewarn "Note: btrfs-convert not built/installed (requires acl USE flag)"
	fi

	if use debug-utils; then
		dobin btrfs-debug-tree
	else
		ewarn "Note: btrfs-debug-tree not installed (requires debug-utils USE flag)"
	fi

	into /usr
	newbin bcp btrfs-bcp

	if use debug-utils; then
		newbin show-blocks btrfs-show-blocks
	else
		ewarn "Note: btrfs-show-blocks not installed (requires debug-utils USE flag)"
	fi

	dodoc INSTALL
	emake prefix="${D}/usr/share" install-man
}

pkg_postinst() {
	ewarn "WARNING: This version of btrfs-progs corresponds to and should only"
	ewarn "         be used with the version of btrfs included in the"
	ewarn "         Linux kernel (2.6.31 and above)."
	ewarn ""
	ewarn "         This version should NOT be used with earlier versions"
	ewarn "         of the standalone btrfs module!"
}
