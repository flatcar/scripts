# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-fs/avfs/avfs-1.0.0.ebuild,v 1.1 2011/07/12 00:31:58 radhermit Exp $

EAPI=4
inherit eutils

DESCRIPTION="AVFS is a virtual filesystem that allows browsing of compressed files."
HOMEPAGE="http://sourceforge.net/projects/avf"
SRC_URI="mirror://sourceforge/avf/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~hppa ~ppc ~ppc64 ~x86"
IUSE="static-libs +lzma"

DEPEND=">=sys-fs/fuse-2.4
	sys-libs/zlib
	app-arch/bzip2
	lzma? ( app-arch/xz-utils )"
RDEPEND="${DEPEND}"

src_prepare() {
	# Fixes bug #258295
	epatch "${FILESDIR}/${PN}-0.9.8-gcc43_fix_open_missing_mode.patch"
}

src_configure() {
	econf \
		--enable-fuse \
		--enable-library \
		--enable-shared \
		--with-system-zlib \
		--with-system-bzlib \
		$(use_enable static-libs static) \
		$(use_with lzma xz)
}

src_install() {
	default

	# remove cruft
	rm "${D}"/usr/bin/{davpass,ftppass} || die "rm failed"

	# install docs
	dodoc doc/{api-overview,background,FORMAT,INSTALL.*,README.avfs-fuse}
	dosym /usr/lib/avfs/extfs/README /usr/share/doc/${PF}/README.extfs

	docinto scripts
	dodoc scripts/{avfscoda*,*pass}

	use static-libs || find "${ED}" -name '*.la' -exec rm -f {} +
}

pkg_postinst() {
	einfo "This version of AVFS includes FUSE support. It is user-based."
	einfo "To execute:"
	einfo "1) as user, mkdir ~/.avfs"
	einfo "2) make sure fuse is either compiled into the kernel OR"
	einfo "   modprobe fuse or add to startup."
	einfo "3) run mountavfs"
	einfo "To unload daemon, type umountavfs"
	echo
	einfo "READ the documentation! Enjoy :)"
}
