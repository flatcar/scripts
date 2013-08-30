# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-crypt/pesign/pesign-0.108.ebuild,v 1.1 2013/08/29 23:18:55 gregkh Exp $

EAPI="4"
inherit eutils multilib

DESCRIPTION="Tools for manipulating signed PE-COFF binaries"
HOMEPAGE="https://github.com/vathpela/pesign"
SRC_URI="https://github.com/vathpela/${PN}/archive/${PV}.tar.gz"


LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

RDEPEND="dev-libs/openssl
	sys-apps/util-linux"
DEPEND="${RDEPEND}
	sys-apps/help2man
	sys-boot/gnu-efi
	virtual/pkgconfig"

src_prepare() {
	epatch "${FILESDIR}"/destdir.patch
}

src_install() {
	emake DESTDIR="${D}" install || die "Install failed"
	dodoc README COPYING TODO || die

	# remove some files that don't make sense for Gentoo installs
	rm -rf ${D}/etc/
	rm -rf ${D}/usr/share/doc/pesign/

	# create .so symlink
	cd ${D}/usr/$(get_libdir)/
	#cd ${D}/lib64/
	ln -s libdpe.so libdpe.so.0
}
#
#src_prepare() {
#	local iarch
#	case ${ARCH} in
#		ia64)  iarch=ia64 ;;
#		x86)   iarch=ia32 ;;
#		amd64) iarch=x86_64 ;;
#		*)     die "unsupported architecture: ${ARCH}" ;;
#	esac
#	sed -i "/^EFI_ARCH=/s:=.*:=${iarch}:" configure || die
#	sed -i 's/-m64$/& -march=x86-64/' tests/Makefile.in || die
#}
