# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-process/lsof/lsof-4.82.ebuild,v 1.9 2010/02/01 17:58:35 hwoarang Exp $

inherit flag-o-matic toolchain-funcs

MY_P=${P/-/_}
DESCRIPTION="Lists open files for running Unix processes"
HOMEPAGE="ftp://lsof.itap.purdue.edu/pub/tools/unix/lsof/"
SRC_URI="ftp://lsof.itap.purdue.edu/pub/tools/unix/lsof/${MY_P}.tar.bz2
	ftp://vic.cc.purdue.edu/pub/tools/unix/lsof/${MY_P}.tar.bz2
	ftp://ftp.cerias.purdue.edu/pub/tools/unix/sysutils/lsof/${MY_P}.tar.bz2"

LICENSE="lsof"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~x86-fbsd"
IUSE="static selinux"

DEPEND="selinux? ( sys-libs/libselinux )"

S=${WORKDIR}/${MY_P}/${MY_P}_src

src_unpack() {
	unpack ${A}
	cd ${MY_P}
	unpack ./${MY_P}_src.tar
	cd "${S}"

	sed -i \
		-e '/LSOF_CFGF="-/s:=":="$LSOF_CFGF :' \
		-e '/^LSOF_CFGF=/s:$:" ${CFLAGS} ${CPPFLAGS}":' \
		-e "/^LSOF_CFGL=/s:\$:' \$(LDFLAGS)':" \
		-e "/^LSOF_RANLIB/s:ranlib:$(tc-getRANLIB):" \
		Configure
}

yesno() { use $1 && echo y || echo n ; }
target() { use kernel_FreeBSD && echo freebsd || echo linux ; }

src_compile() {
	use static && append-ldflags -static

	touch .neverInv
	LINUX_HASSELINUX=$(yesno selinux) \
	LSOF_CC=$(tc-getCC) \
	LSOF_AR="$(tc-getAR) rc" \
	./Configure -n $(target) || die

	emake DEBUG="" all || die "emake failed"
}

src_install() {
	dobin lsof || die "dosbin"

	insinto /usr/share/lsof/scripts
	doins scripts/*

	doman lsof.8
	dodoc 00*
}
