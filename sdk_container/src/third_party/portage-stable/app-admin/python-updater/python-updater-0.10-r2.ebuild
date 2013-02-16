# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-admin/python-updater/python-updater-0.10-r2.ebuild,v 1.2 2012/04/26 14:54:37 aballier Exp $

inherit eutils

if [[ "${PV}" == "9999" ]]; then
	inherit subversion
fi

DESCRIPTION="Script used to reinstall Python packages after changing of active Python versions"
HOMEPAGE="http://www.gentoo.org/proj/en/Python/"
if [[ "${PV}" == "9999" ]]; then
	SRC_URI=""
	ESVN_REPO_URI="https://gentoo-progress.googlecode.com/svn/projects/python-updater/trunk"
else
	SRC_URI="http://people.apache.org/~Arfrever/gentoo/${P}.tar.bz2"
fi

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-fbsd ~sparc-fbsd ~x86-fbsd"
IUSE=""

DEPEND="$([[ "${PV}" == "9999" ]] && echo "sys-apps/help2man")"
RDEPEND="dev-lang/python
	|| ( >=sys-apps/portage-2.1.6 >=sys-apps/paludis-0.56.0 )"

src_unpack() {
	unpack ${A}
	cd "${S}"
	epatch "${FILESDIR}"/${P}-expand-aliases.patch
	epatch "${FILESDIR}"/${P}-only-alias-sed-if-exists.patch
}

src_compile() {
	if [[ "${PV}" == "9999" ]]; then
		emake ${PN}.1 || die "Generation of man page failed"
	fi
}

src_install() {
	dosbin ${PN} || die "dosbin failed"
	doman ${PN}.1 || die "doman failed"
	dodoc AUTHORS || die "dodoc failed"
}
