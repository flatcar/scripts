# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/miscfiles/miscfiles-1.4.2-r1.ebuild,v 1.10 2010/03/04 17:42:43 jer Exp $

inherit eutils

UNI_PV=5.2.0
DESCRIPTION="Miscellaneous files"
HOMEPAGE="http://www.gnu.org/directory/miscfiles.html"
# updated unicode data file from:
# http://www.unicode.org/Public/${UNI_PV}/ucd/UnicodeData.txt
SRC_URI="mirror://gnu/miscfiles/${P}.tar.gz
	mirror://gentoo/UnicodeData-${UNI_PV}.txt.bz2"

LICENSE="GPL-2 unicode"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~sparc-fbsd ~x86-fbsd"
IUSE="minimal"
# Collides with older versions/revisions
RDEPEND="!<sys-freebsd/freebsd-share-7.2-r1"

src_unpack() {
	unpack ${A}
	cd "${S}"
	mv "${WORKDIR}"/UnicodeData-${UNI_PV}.txt unicode || die
	epatch "${FILESDIR}"/miscfiles-1.3-Makefile.diff
}

src_install() {
	emake install prefix="${D}/usr" || die
	dodoc NEWS ORIGIN README dict-README
	rm -f "${D}"/usr/share/dict/README

	if use minimal ; then
		cd "${D}"/usr/share/dict
		rm -f words extra.words
		gzip -9 *
		ln -s web2.gz words
		ln -s web2a.gz extra.words
		ln -s connectives{.gz,}
		ln -s propernames{.gz,}
		cd ..
		rm -r misc rfc
	fi
}

pkg_postinst() {
	if [[ ${ROOT} == "/" ]] && type -P create-cracklib-dict >/dev/null ; then
		ebegin "Regenerating cracklib dictionary"
		create-cracklib-dict /usr/share/dict/* > /dev/null
		eend $?
	fi
}
