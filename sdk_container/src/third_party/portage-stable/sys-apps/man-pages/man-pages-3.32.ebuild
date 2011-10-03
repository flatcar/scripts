# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/man-pages/man-pages-3.32.ebuild,v 1.7 2011/09/16 17:17:41 jer Exp $

EAPI=3

GENTOO_PATCH=2

DESCRIPTION="A somewhat comprehensive collection of Linux man pages"
HOMEPAGE="http://www.kernel.org/doc/man-pages/"
SRC_URI="mirror://kernel/linux/docs/manpages/Archive/${P}.tar.bz2
	mirror://gentoo/man-pages-gentoo-${GENTOO_PATCH}.tar.bz2
	http://dev.gentoo.org/~cardoe/files/man-pages-gentoo-${GENTOO_PATCH}.tar.bz2"

LICENSE="as-is GPL-2 BSD"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ~ppc64 s390 sh sparc x86 ~amd64-linux ~ia64-linux ~x86-linux"
IUSE_LINGUAS=" cs da de fr it ja nl pl ro ru zh_CN"
IUSE="nls ${IUSE_LINGUAS// / linguas_}"
RESTRICT="binchecks"

RDEPEND="virtual/man
	!<dev-libs/libaio-0.3.109-r2" #341953
PDEPEND="nls? (
	linguas_cs? ( app-i18n/man-pages-cs )
	linguas_da? ( app-i18n/man-pages-da )
	linguas_de? ( app-i18n/man-pages-de )
	linguas_fr? ( app-i18n/man-pages-fr )
	linguas_it? ( app-i18n/man-pages-it )
	linguas_ja? ( app-i18n/man-pages-ja )
	linguas_nl? ( app-i18n/man-pages-nl )
	linguas_pl? ( app-i18n/man-pages-pl )
	linguas_ro? ( app-i18n/man-pages-ro )
	linguas_ru? ( app-i18n/man-pages-ru )
	linguas_zh_CN? ( app-i18n/man-pages-zh_CN )
	)
	sys-apps/man-pages-posix"

src_configure() { :; }

src_compile() { :; }

src_install() {
	emake install prefix="${EPREFIX}/usr" DESTDIR="${D}" || die
	dodoc man-pages-*.Announce README Changes*

	# Override with Gentoo specific or additional Gentoo pages
	cd "${WORKDIR}"/man-pages-gentoo
	doman */* || die
	dodoc README.Gentoo
}

pkg_postinst() {
	einfo "If you don't have a makewhatis cronjob, then you"
	einfo "should update the whatis database yourself:"
	einfo " # makewhatis -u"
}
