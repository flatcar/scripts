# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libaio/libaio-0.3.109-r3.ebuild,v 1.10 2012/12/29 20:33:56 vapier Exp $

EAPI=3

inherit eutils multilib toolchain-funcs

DESCRIPTION="Asynchronous input/output library that uses the kernels native interface"
HOMEPAGE="http://www.kernel.org/pub/linux/kernel/people/andrea/libaio/ http://lse.sourceforge.net/io/aio.html"
SRC_URI="mirror://kernel/linux/libs/aio/${P}.tar.bz2"

LICENSE="LGPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~amd64-linux ~x86-linux"
IUSE="multilib static-libs"

EMULTILIB_PKG="true"

aio_get_install_abis() {
	use multilib && get_install_abis || echo ${ABI:-default}
}

src_unpack() {
	local OABI=${ABI}
	for ABI in $(aio_get_install_abis)
	do
		mkdir -p "${WORKDIR}"/${ABI} || die
		cd "${WORKDIR}"/${ABI} || die
		unpack ${A}
	done
	ABI=${OABI}
}

src_prepare() {
	local OABI=${ABI}
	for ABI in $(aio_get_install_abis)
	do
		einfo "Preparing ${ABI} ABI ..."
		cd "${WORKDIR}"/${ABI}/${P} || die

		# remove stuff provided by man-pages now
		rm man/{lio_listio,aio_{cancel,error,fsync,init,read,return,suspend,write}}.* || die

		epatch "${FILESDIR}"/${PN}-0.3.109-unify-bits-endian.patch
		epatch "${FILESDIR}"/${PN}-0.3.109-generic-arch.patch
		epatch "${FILESDIR}"/${PN}-0.3.106-build.patch
		epatch "${FILESDIR}"/${PN}-0.3.107-ar-ranlib.patch
		epatch "${FILESDIR}"/${PN}-0.3.109-install.patch
		epatch "${FILESDIR}"/${PN}-0.3.109-x32.patch
		epatch "${FILESDIR}"/${PN}-0.3.109-testcase-8.patch
		declare -a extra_sed
		if ! use static-libs; then
			extra_sed[${#extra_sed[@]}]='-e'
			extra_sed[${#extra_sed[@]}]='/\tinstall .*\/libaio.a/d'
			# Tests require the static library to be built.
			if ! use test; then
				extra_sed[${#extra_sed[@]}]='-e'
				extra_sed[${#extra_sed[@]}]='/^all_targets +=/s/ libaio.a//'
			fi
		fi
		sed -i \
			-e "/^libdir=/s:lib$:$(get_libdir):" \
			-e "/^prefix=/s:/usr:${EPREFIX}/usr:" \
			-e '/:=.*strip.*shell.*git/s:=.*:=:' \
			"${extra_sed[@]}" \
			src/Makefile Makefile || die

		sed -i -e "s:-Werror::g" harness/Makefile || die
	done
	ABI=${OABI}
}

emake_libaio() {
	# The Makefiles need these environments, but multilib_toolchain_setup()
	# does not export anything when there is only one default abi available.
	CC="$(tc-getCC) $(get_abi_CFLAGS)" \
	AR=$(tc-getAR) \
	RANLIB=$(tc-getRANLIB) \
	emake "$@" || die
}

src_compile() {
	local OABI=${ABI}
	for ABI in $(aio_get_install_abis)
	do
		einfo "Compiling ${ABI} ABI ..."
		cd "${WORKDIR}"/${ABI}/${P} || die
		emake_libaio
	done
	ABI=${OABI}
}

src_test() {
	local OABI=${ABI}
	for ABI in $(aio_get_install_abis)
	do
		einfo "Testing ${ABI} ABI ..."
		cd "${WORKDIR}"/${ABI}/${P}/harness || die
		mkdir testdir || die
		# 'make check' breaks with sandbox, 'make partcheck' works
		emake_libaio partcheck prefix="${S}/src" libdir="${S}/src"
	done
	ABI=${OABI}
}

src_install() {
	local OABI=${ABI}
	for ABI in $(aio_get_install_abis)
	do
		einfo "Installing ${ABI} ABI ..."
		cd "${WORKDIR}"/${ABI}/${P} || die

		# Don't use ED for emake, src_prepare already inserts EPREFIX in the correct
		# place
		emake_libaio install DESTDIR="${D}"

		doman man/*
		dodoc ChangeLog TODO

		# move crap to / for multipath-tools #325355
		gen_usr_ldscript -a aio
	done
	ABI=${OABI}
}
