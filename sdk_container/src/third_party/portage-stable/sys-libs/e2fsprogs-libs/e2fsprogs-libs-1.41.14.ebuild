# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-libs/e2fsprogs-libs/e2fsprogs-libs-1.41.14.ebuild,v 1.4 2011/08/29 06:12:49 jer Exp $

EAPI="2"

inherit toolchain-funcs

DESCRIPTION="e2fsprogs libraries (common error and subsystem)"
HOMEPAGE="http://e2fsprogs.sourceforge.net/"
SRC_URI="mirror://sourceforge/e2fsprogs/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha amd64 arm hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc x86 ~x86-fbsd"
IUSE="nls elibc_glibc"

RDEPEND="elibc_glibc? ( >=sys-libs/glibc-2.6 )
	!sys-libs/com_err
	!sys-libs/ss
	!<sys-fs/e2fsprogs-1.41.8"
DEPEND="nls? ( sys-devel/gettext )
	dev-util/pkgconfig"

src_prepare() {
	printf 'all:\n%%:;@:\n' > doc/Makefile.in # don't bother with docs #305613
}

src_configure() {
	# We want to use the "bsd" libraries while building on Darwin, but while
	# building on other Gentoo/*BSD we prefer elf-naming scheme.
	local libtype
	case ${CHOST} in
		*-darwin*) libtype=bsd;;
		*)         libtype=elf;;
	esac

	# we use blkid/uuid from util-linux now
	ac_cv_lib_uuid_uuid_generate=yes \
	ac_cv_lib_blkid_blkid_get_cache=yes \
	ac_cv_path_LDCONFIG=: \
	econf \
		--disable-libblkid \
		--disable-libuuid \
		--enable-${libtype}-shlibs \
		$(tc-has-tls || echo --disable-tls) \
		$(use_enable nls)
}

src_install() {
	emake STRIP=: DESTDIR="${D}" install || die
	gen_usr_ldscript -a com_err ss
}
