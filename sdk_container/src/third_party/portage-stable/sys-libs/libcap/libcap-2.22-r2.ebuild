# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-libs/libcap/libcap-2.22-r2.ebuild,v 1.3 2013/12/03 19:45:03 floppym Exp $

EAPI="4"

inherit eutils multilib multilib-minimal toolchain-funcs pam

DESCRIPTION="POSIX 1003.1e capabilities"
HOMEPAGE="http://www.friedhoff.org/posixfilecaps.html"
SRC_URI="mirror://gentoo/${P}.tar.bz2"

# it's available under either of the licenses
LICENSE="|| ( GPL-2 BSD )"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-linux ~arm-linux ~ia64-linux ~x86-linux"
IUSE="pam"

RDEPEND="sys-apps/attr[${MULTILIB_USEDEP}]
	pam? ( virtual/pam )"
DEPEND="${RDEPEND}
	sys-kernel/linux-headers"

src_prepare() {
	epatch "${FILESDIR}"/${PN}-2.22-build-system-fixes.patch
	epatch "${FILESDIR}"/${PN}-2.22-no-perl.patch
	epatch "${FILESDIR}"/${PN}-2.20-ignore-RAISE_SETFCAP-install-failures.patch
	epatch "${FILESDIR}"/${PN}-2.21-include.patch

	multilib_copy_sources
}

multilib_src_configure() {
	if multilib_build_binaries && use pam; then
		pam=yes
	else
		pam=no
	fi

	sed -i \
		-e "/^PAM_CAP/s:=.*:=${pam}:" \
		-e '/^DYNAMIC/s:=.*:=yes:' \
		-e "/^lib=/s:=.*:=/usr/$(get_libdir):" \
		Make.Rules
}

multilib_src_compile() {
	tc-export_build_env BUILD_CC
	tc-export AR CC RANLIB

	default
}

multilib_src_install() {
	# no configure, needs explicit install line #444724#c3
	emake install DESTDIR="${ED}"

	multilib_build_binaries && gen_usr_ldscript -a cap

	rm -rf "${ED}"/usr/$(get_libdir)/security
	if multilib_build_binaries && use pam; then
		dopammod pam_cap/pam_cap.so
		dopamsecurity '' pam_cap/capability.conf
	fi
}

multilib_src_install_all() {
	dodoc CHANGELOG README doc/capability.notes
}
