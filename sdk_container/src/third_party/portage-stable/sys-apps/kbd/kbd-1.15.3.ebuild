# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/kbd/kbd-1.15.3.ebuild,v 1.7 2011/10/11 16:44:58 jer Exp $

DESCRIPTION="Keyboard and console utilities"
HOMEPAGE="http://freshmeat.net/projects/kbd/"
SRC_URI="ftp://ftp.altlinux.org/pub/people/legion/kbd/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86"
IUSE="nls"

RDEPEND=""
DEPEND="${RDEPEND}
	nls? ( sys-devel/gettext )"

src_unpack() {
	unpack ${A}
	cd "${S}"

	# broken file ... upstream git punted it
	rm po/es.po

	# Rename conflicting keymaps to have unique names, bug #293228
	cd "${S}"/data/keymaps/i386
	mv dvorak/no.map dvorak/no-dvorak.map
	mv fgGIod/trf.map fgGIod/trf-fgGIod.map
	mv olpc/es.map olpc/es-olpc.map
	mv olpc/pt.map olpc/pt-olpc.map
	mv qwerty/cz.map qwerty/cz-qwerty.map

	# bundled timestamps are broken
	find "${S}" -type f -exec touch -r "${S}"/configure {} +
}

src_compile() {
	econf $(use_enable nls) || die
	emake || die
}

src_install() {
	emake DESTDIR="${D}" install || die
	dodoc AUTHORS ChangeLog INSTALL NEWS README
	dohtml doc/*.html
}
