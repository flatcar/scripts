# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-util/ctags/ctags-5.7.ebuild,v 1.10 2008/11/04 09:37:40 vapier Exp $

inherit eutils

DESCRIPTION="Exuberant Ctags creates tags files for code browsing in editors"
HOMEPAGE="http://ctags.sourceforge.net"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz
	ada? ( mirror://sourceforge/gnuada/ctags-ada-mode-4.3.3.tar.bz2 )"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 sh sparc ~sparc-fbsd x86 ~x86-fbsd"
IUSE="ada"

DEPEND="app-admin/eselect-ctags"

src_unpack() {
	unpack ${A}
	cd "${S}"

	epatch "${FILESDIR}/${PN}-5.6-ebuilds.patch"

	# enabling Ada support
	if use ada; then
		cp "${WORKDIR}/${PN}-ada-mode-4.3.3/ada.c" "${S}"
		epatch "${FILESDIR}/${PN}-ada.patch"
	fi
}

src_compile() {
	econf \
		--with-posix-regex \
		--without-readlib \
		--disable-etags \
		--enable-tmpdir=/tmp \
		|| die "econf failed"
	emake || die "emake failed"
}

src_install() {
	einstall || die "einstall failed"

	# namepace collision with X/Emacs-provided /usr/bin/ctags -- we
	# rename ctags to exuberant-ctags (Mandrake does this also).
	mv "${D}"/usr/bin/{ctags,exuberant-ctags}
	mv "${D}"/usr/share/man/man1/{ctags,exuberant-ctags}.1

	dodoc FAQ NEWS README
	dohtml EXTENDING.html ctags.html
}

pkg_postinst() {
	eselect ctags update
	elog "You can set the version to be started by /usr/bin/ctags through"
	elog "the ctags eselect module. \"man ctags.eselect\" for details."
}

pkg_postrm() {
	eselect ctags update
}
