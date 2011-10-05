# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-text/texi2html/texi2html-1.78.ebuild,v 1.12 2011/10/04 17:40:10 jer Exp $

EAPI=3

DESCRIPTION="Perl script that converts Texinfo to HTML"
HOMEPAGE="http://www.nongnu.org/texi2html/"
SRC_URI="http://download.savannah.gnu.org/releases/texi2html/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~x86-fbsd ~x64-freebsd ~x86-freebsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE=""

DEPEND=">=dev-lang/perl-5.6.1"

src_install() {
	#yes, htmldir line is correct, no ${D}
	emake DESTDIR="${D}" \
		htmldir="${EPREFIX}"/usr/share/doc/${PF}/html \
		install || die "Installation Failed"

	dodoc AUTHORS ChangeLog NEWS README TODO
}

pkg_preinst() {
	rm -f "${EROOT}"/usr/bin/texi2html
}
