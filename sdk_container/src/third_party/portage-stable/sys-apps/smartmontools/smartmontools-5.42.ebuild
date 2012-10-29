# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/smartmontools/smartmontools-5.42.ebuild,v 1.7 2012/04/14 17:18:25 zmedico Exp $

EAPI="3"

inherit flag-o-matic
if [[ ${PV} == "9999" ]] ; then
	ESVN_REPO_URI="https://smartmontools.svn.sourceforge.net/svnroot/smartmontools/trunk/smartmontools"
	ESVN_PROJECT="smartmontools"
	inherit subversion autotools
	SRC_URI=""
else
	SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"
	KEYWORDS="alpha amd64 arm hppa ia64 ppc ~ppc64 sparc x86 ~x86-fbsd ~amd64-linux ~x86-linux ~x64-macos"
fi

DESCRIPTION="Self-Monitoring, Analysis and Reporting Technology System (S.M.A.R.T.) monitoring tools"
HOMEPAGE="http://smartmontools.sourceforge.net/"

LICENSE="GPL-2"
SLOT="0"
IUSE="static minimal caps"

DEPEND="!minimal? ( caps? ( sys-libs/libcap-ng ) )"
RDEPEND="${DEPEND}
	!minimal? ( virtual/mailx )"

src_prepare() {
	if [[ ${PV} == "9999" ]] ; then
		#./autogen.sh
		eautoreconf
	fi
}

src_configure() {
	local myconf
	use minimal && einfo "Skipping the monitoring daemon for minimal build."
	use static && append-ldflags -static

	if ! use minimal; then
		myconf="${myconf} $(use_with caps libcap-ng)"
	else
		# disable it so that we stay safe
		myconf="${myconf} --without-libcap-ng"
	fi

	econf \
		--with-docdir="${EPREFIX}/usr/share/doc/${PF}" \
		--with-initscriptdir="/toss-it-away" \
		${myconf} \
		|| die
}

src_install() {
	if use minimal ; then
		dosbin smartctl || die
		doman smartctl.8
	else
		emake install DESTDIR="${D}" || die
		rm -rf "${D}"/toss-it-away
		newinitd "${FILESDIR}"/smartd.rc smartd
		newconfd "${FILESDIR}"/smartd.confd smartd
	fi
}
