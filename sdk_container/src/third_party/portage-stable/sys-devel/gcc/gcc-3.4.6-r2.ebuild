# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/gcc/gcc-3.4.6-r2.ebuild,v 1.38 2014/10/23 23:48:17 vapier Exp $

EAPI="2"

PATCH_VER="1.7"
UCLIBC_VER="1.1"
UCLIBC_GCC_VER="3.4.5"
HTB_VER="1.00.1"
HTB_GCC_VER="3.4.4"
D_VER="0.24"

inherit eutils toolchain

KEYWORDS="-* alpha amd64 arm ~ia64 ~mips ppc ppc64 ~s390 ~sh sparc x86 ~x86-fbsd"
IUSE="ip28 ip32r10k n32 n64"

# we need a proper glibc version for the Scrt1.o provided to the pie-ssp specs
# NOTE: we SHOULD be using at least binutils 2.15.90.0.1 everywhere for proper
# .eh_frame ld optimisation and symbol visibility support, but it hasnt been
# well tested in gentoo on any arch other than amd64!!
RDEPEND=""
DEPEND="${RDEPEND}
	>=sys-devel/binutils-2.14.90.0.8-r1
	amd64? ( >=sys-devel/binutils-2.15.90.0.1.1-r1 )"

src_prepare() {
	toolchain_src_prepare

	# Anything useful and objc will require libffi. Seriously. Lets just force
	# libffi to install with USE="objc", even though it normally only installs
	# if you attempt to build gcj.
	if ! use build && use objc && ! use gcj ; then
		epatch "${FILESDIR}"/3.4.3/libffi-without-libgcj.patch
		#epatch ${FILESDIR}/3.4.3/libffi-nogcj-lib-path-fix.patch
	fi

	# Fix cross-compiling
	epatch "${FILESDIR}"/3.4.4/gcc-3.4.4-cross-compile.patch

	# Arch stuff
	case $(tc-arch) in
		mips)
			# If mips, and we DON'T want multilib, then rig gcc to only use n32 OR n64
			if ! is_multilib; then
				use n32 && epatch "${FILESDIR}"/3.4.1/gcc-3.4.1-mips-n32only.patch
				use n64 && epatch "${FILESDIR}"/3.4.1/gcc-3.4.1-mips-n64only.patch
			fi

			# Patch forward-ported from a gcc-3.0.x patch that adds -march=r10000 and
			# -mtune=r10000 support to gcc (Allows the compiler to generate code to
			# take advantage of R10k's second ALU, perform shifts, etc..
			#
			# Needs re-porting to DFA in gcc-4.0 - Any Volunteers? :)
			epatch "${FILESDIR}"/3.4.2/gcc-3.4.x-mips-add-march-r10k.patch

			# This is a very special patch -- it allows us to build semi-usable kernels
			# on SGI IP28 (Indigo2 Impact R10000) systems.  The patch is henceforth
			# regarded as a kludge by upstream, and thus, it will never get accepted upstream,
			# but for our purposes of building a kernel, it works.
			# Unless you're building an IP28 kernel, you really don't need care about what
			# this patch does, because if you are, you are probably already aware of what
			# it does.
			# All that said, the abilities of this patch are disabled by default and need
			# to be enabled by passing -mip28-cache-barrier.  Only used to build kernels,
			# There is the possibility it may be used for very specific userland apps too.
			if use ip28 || use ip32r10k; then
				epatch "${FILESDIR}"/3.4.2/gcc-3.4.2-mips-ip28_cache_barriers-v4.patch
			fi
			;;
		amd64)
			if is_multilib ; then
				sed -i -e '/GLIBCXX_IS_NATIVE=/s:false:true:' libstdc++-v3/configure || die
			fi
			;;
	esac
}
