# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-dialup/minicom/minicom-2.3-r2.ebuild,v 1.5 2009/07/11 20:35:53 josejx Exp $

EAPI="2"

inherit eutils

STUPID_NUM="2332"

DESCRIPTION="Serial Communication Program"
HOMEPAGE="http://alioth.debian.org/projects/minicom"
SRC_URI="http://alioth.debian.org/download.php/${STUPID_NUM}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86"
IUSE="nls"

COMMON_DEPEND="sys-libs/ncurses"
DEPEND="${COMMON_DEPEND}
	nls? ( sys-devel/gettext )"
RDEPEND="${COMMON_DEPEND}
	net-dialup/lrzsz"

# Supported languages and translated documentation
# Be sure all languages are prefixed with a single space!
MY_AVAILABLE_LINGUAS=" cs da de es fi fr hu ja nb pl pt_BR ro ru rw sv vi zh_TW"
IUSE="${IUSE} ${MY_AVAILABLE_LINGUAS// / linguas_}"

src_prepare() {
	epatch "${FILESDIR}"/${P}-gentoo-runscript.patch

	#glibc name conflict
	epatch "${FILESDIR}"/${P}-getline-rename.patch
}

src_configure() {
	econf --sysconfdir=/etc/${PN} \
		$(use_enable nls) \
		|| die "econf failed"
}

src_install() {
	emake install DESTDIR="${D}" || die "einstall failed"

	dodoc AUTHORS ChangeLog NEWS README doc/minicom.FAQ
	insinto /etc/minicom
	doins "${FILESDIR}"/minirc.dfl
}

pkg_preinst() {
	[[ -s ${ROOT}/etc/minicom/minirc.dfl ]] \
		&& rm -f "${D}"/etc/minicom/minirc.dfl
}
