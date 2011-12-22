# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-arch/cabextract/cabextract-1.4.ebuild,v 1.8 2011/08/25 12:22:12 jer Exp $

EAPI="4"

DESCRIPTION="Extracts files from Microsoft .cab files"
HOMEPAGE="http://www.cabextract.org.uk/"
SRC_URI="http://www.cabextract.org.uk/${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~x86-fbsd"
IUSE="extra-tools"

RDEPEND="extra-tools? ( dev-lang/perl )"

# the code attempts to set up a fnmatch replacement, but then fails to code
# it properly leading to undefined references to rpl_fnmatch().  This may be
# removed in the future if building still works by setting "yes" to "no".
export ac_cv_func_fnmatch_works=yes

src_install() {
	emake DESTDIR="${D}" install
	dodoc AUTHORS ChangeLog INSTALL NEWS README TODO doc/magic
	dohtml doc/wince_cab_format.html
	if use extra-tools; then
		dobin src/{wince_info,wince_rename,cabinfo}
	fi
}
