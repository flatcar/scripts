# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-process/procps/procps-3.3.3.ebuild,v 1.2 2012/07/29 21:29:38 ottxor Exp $

EAPI="4"

inherit eutils toolchain-funcs autotools

DEB_VER=${PV#*_p}
MY_PV=${PV%_p*}
DESCRIPTION="standard informational utilities and process-handling tools"
HOMEPAGE="http://procps.sourceforge.net/ http://gitorious.org/procps http://packages.debian.org/sid/procps"
SRC_URI="http://gitorious.org/procps/procps/archive-tarball/v${PV} -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-linux ~ia64-linux ~x86-linux"
IUSE="+ncurses static-libs unicode"

RDEPEND="ncurses? ( >=sys-libs/ncurses-5.2-r2[unicode?] )"
DEPEND="${RDEPEND}
	ncurses? ( virtual/pkgconfig )"

S=${WORKDIR}/${PN}-${PN}

src_prepare() {
	epatch "${FILESDIR}"/${P}-watch-8bit.patch

	po/update-potfiles || die
	eautoreconf
}

src_configure() {
	econf \
		--exec-prefix="${EPREFIX}/" \
		--docdir='$(datarootdir)'/doc/${PF} \
		$(use_with ncurses) \
		$(use_enable static-libs static) \
		$(use_enable unicode watch8bit)
}

src_install() {
	default
	dodoc sysctl.conf

	# The configure script is completely whacked in the head
	mv "${ED}"/lib* "${ED}"/usr/ || die
	gen_usr_ldscript -a procps
	find "${ED}"/usr -name '*.la' -delete
}
