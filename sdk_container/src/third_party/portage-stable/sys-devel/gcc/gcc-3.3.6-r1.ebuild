# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/gcc/gcc-3.3.6-r1.ebuild,v 1.24 2012/07/23 16:00:30 vapier Exp $

PATCH_VER="1.8"
UCLIBC_VER="1.0"
HTB_VER="1.00-r2"

inherit toolchain eutils

DESCRIPTION="The GNU Compiler Collection"

# ia64 - broken static handling; USE=static emerge busybox
KEYWORDS="~amd64 ~x86"

# NOTE: we SHOULD be using at least binutils 2.15.90.0.1 everywhere for proper
# .eh_frame ld optimisation and symbol visibility support, but it hasnt been
# well tested in gentoo on any arch other than amd64!!
RDEPEND=">=sys-devel/binutils-2.14.90.0.6-r1"
DEPEND="${RDEPEND}
	amd64? ( >=sys-devel/binutils-2.15.90.0.1.1-r1 )"

src_unpack() {
	toolchain_src_unpack

	if [[ -n ${UCLIBC_VER} ]] && [[ ${CTARGET} == *-uclibc* ]] ; then
		mv "${S}"/gcc-3.3.2/libstdc++-v3/config/os/uclibc "${S}"/libstdc++-v3/config/os/ || die
		mv "${S}"/gcc-3.3.2/libstdc++-v3/config/locale/uclibc "${S}"/libstdc++-v3/config/locale/ || die
	fi

	# misc patches that havent made it into a patch tarball yet
	[[ ${CHOST} == ${CTARGET} ]] && epatch "${FILESDIR}"/gcc-spec-env.patch

	# Anything useful and objc will require libffi. Seriously. Lets just force
	# libffi to install with USE="objc", even though it normally only installs
	# if you attempt to build gcj.
	if ! use build && use objc && ! use gcj ; then
		epatch "${FILESDIR}"/3.3.4/libffi-without-libgcj.patch
		#epatch "${FILESDIR}"/3.4.3/libffi-nogcj-lib-path-fix.patch
	fi
}
