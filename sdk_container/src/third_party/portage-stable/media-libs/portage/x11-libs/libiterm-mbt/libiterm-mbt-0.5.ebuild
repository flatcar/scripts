# Copyright 1999-2004 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/libiterm-mbt/libiterm-mbt-0.5.ebuild,v 1.3 2004/06/24 22:05:04 agriffis Exp $

DESCRIPTION="Hacked version of libiterm -- Internationalized Terminal Emulator Library"
HOMEPAGE="http://www.doc.ic.ac.uk/~mbt99/Y/
	http://www-124.ibm.com/linux/projects/iterm/"
SRC_URI="http://www.doc.ic.ac.uk/~mbt99/Y/src/iterm-${PV}-mbt.tar.gz"
LICENSE="CPL-1.0"
SLOT="0"
KEYWORDS="~x86 ~ppc ~amd64"

IUSE=""

S=${WORKDIR}/iterm-${PV}-mbt/lib/

src_compile() {
	econf || die
	emake || die
}

src_install() {
	einstall || die
	dodoc README INSTALL
}
