# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-process/procps/procps-3.3.6.ebuild,v 1.17 2014/01/18 03:48:20 vapier Exp $

EAPI="5"

inherit eutils toolchain-funcs

DESCRIPTION="standard informational utilities and process-handling tools"
# http://packages.debian.org/sid/procps
HOMEPAGE="http://procps.sourceforge.net/ http://gitorious.org/procps"
# SRC_URI="mirror://debian/pool/main/p/${PN}/${PN}_${PV}.orig.tar.xz"
SRC_URI="http://pkgs.fedoraproject.org/repo/pkgs/${PN}-ng/${PN}-ng-${PV}.tar.xz/0a050d9be531921db3cd38f1371e73e3/${PN}-ng-${PV}.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~amd64-linux ~ia64-linux ~x86-linux"
IUSE="+ncurses nls static-libs test unicode"

RDEPEND="ncurses? ( >=sys-libs/ncurses-5.7-r7[unicode?] )"
DEPEND="${RDEPEND}
	ncurses? ( virtual/pkgconfig )
	test? ( dev-util/dejagnu )"

S=${WORKDIR}/${PN}-ng-${PV}

src_prepare() {
	epatch "${FILESDIR}"/${P}-error_at_line.patch
}

src_configure() {
	econf \
		--exec-prefix="${EPREFIX}" \
		--docdir='$(datarootdir)'/doc/${PF} \
		$(use_with ncurses) \
		$(use_enable nls) \
		$(use_enable static-libs static) \
		$(use_enable unicode watch8bit)
}

src_install() {
	default
#	dodoc sysctl.conf

	# The configure script is completely whacked in the head
	mv "${ED}"/lib* "${ED}"/usr/ || die
	gen_usr_ldscript -a procps
	prune_libtool_files
}
