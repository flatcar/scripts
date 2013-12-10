# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-libs/e2fsprogs-libs/e2fsprogs-libs-1.42.8.ebuild,v 1.1 2013/10/08 12:55:02 chainsaw Exp $

EAPI="4"

case ${PV} in
*_pre*) UP_PV="${PV%_pre*}-WIP-${PV#*_pre}" ;;
*)      UP_PV=${PV} ;;
esac

inherit toolchain-funcs eutils multilib-minimal

DESCRIPTION="e2fsprogs libraries (common error and subsystem)"
HOMEPAGE="http://e2fsprogs.sourceforge.net/"
SRC_URI="mirror://sourceforge/e2fsprogs/${PN}-${UP_PV}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-fbsd ~x86-fbsd ~amd64-linux ~arm-linux ~x86-linux"
IUSE="nls static-libs"

RDEPEND="!sys-libs/com_err
	!sys-libs/ss
	!<sys-fs/e2fsprogs-1.41.8
	abi_x86_32? (
		!<=app-emulation/emul-linux-x86-baselibs-20130224-r12
		!app-emulation/emul-linux-x86-baselibs[-abi_x86_32(-)]
	)"
DEPEND="nls? ( sys-devel/gettext )
	virtual/pkgconfig"

S=${WORKDIR}/${P%_pre*}

src_prepare() {
	printf 'all:\n%%:;@:\n' > doc/Makefile.in # don't bother with docs #305613
}

multilib_src_configure() {
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
	QUOTA_CMT='#' \
	ECONF_SOURCE="${S}" \
	econf \
		--disable-lib{blkid,uuid} \
		--disable-quota \
		--enable-${libtype}-shlibs \
		$(tc-has-tls || echo --disable-tls) \
		$(use_enable nls)
}

multilib_src_install() {
	emake STRIP=: DESTDIR="${D}" install || die
	multilib_is_native_abi && gen_usr_ldscript -a com_err ss
	# configure doesn't have an option to disable static libs :/
	use static-libs || find "${ED}" -name '*.a' -delete
}
