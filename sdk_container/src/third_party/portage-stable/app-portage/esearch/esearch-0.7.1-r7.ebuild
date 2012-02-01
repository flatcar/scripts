# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-portage/esearch/esearch-0.7.1-r7.ebuild,v 1.2 2009/03/07 19:54:57 betelgeuse Exp $

EAPI="2"

inherit base eutils

DESCRIPTION="Replacement for 'emerge --search' with search-index"
HOMEPAGE="http://david-peter.de/esearch.html"
SRC_URI="http://david-peter.de/downloads/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 mips ppc ppc64 s390 sh sparc x86 ~x86-fbsd"
IUSE="linguas_it"

RDEPEND=">=dev-lang/python-2.2[readline]
	>=sys-apps/portage-2.0.50"

PATCHES=( "${FILESDIR}"/97462-esearch-metadata.patch
	"${FILESDIR}"/97969-ignore-missing-ebuilds.patch
	"${FILESDIR}"/120817-unset-emergedefaultopts.patch
	"${FILESDIR}"/124601-remove-deprecated-syntax.patch
	"${FILESDIR}"/132548-multiple-overlay.patch
	"${FILESDIR}"/231223-fix-deprecated.patch
	"${FILESDIR}"/253216-fix-ebuild-option.patch
	"${FILESDIR}"/186994-esync-quiet.patch
	"${FILESDIR}"/146555-esearch-manifest2.patch )

src_compile() { :; }

src_install() {
	dodir /usr/bin/ /usr/sbin/ || die "dodir failed"

	exeinto /usr/lib/esearch
	doexe eupdatedb.py esearch.py esync.py common.py || die "doexe failed"

	dosym /usr/lib/esearch/esearch.py /usr/bin/esearch || die "dosym failed"
	dosym /usr/lib/esearch/eupdatedb.py /usr/sbin/eupdatedb || die "dosym failed"
	dosym /usr/lib/esearch/esync.py /usr/sbin/esync || die "dosym failed"

	doman en/{esearch,eupdatedb,esync}.1 || die "doman failed"
	dodoc ChangeLog "${FILESDIR}/eupdatedb.cron" || die "dodoc failed"

	if use linguas_it ; then
		insinto /usr/share/man/it/man1
		doins it/{esearch,eupdatedb,esync}.1 || die "doins failed"
	fi
}
