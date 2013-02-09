# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/vo-amrwbenc/vo-amrwbenc-9999.ebuild,v 1.5 2012/05/15 13:09:37 aballier Exp $

EAPI=4

if [[ ${PV} == *9999 ]] ; then
	SCM="git-2"
	EGIT_REPO_URI="git://github.com/mstorsjo/${PN}.git"
	[[ ${PV%9999} != "" ]] && EGIT_BRANCH="release/${PV%.9999}"
fi

inherit eutils multilib autotools ${SCM}

DESCRIPTION="VisualOn AMR-WB encoder library"
HOMEPAGE="http://sourceforge.net/projects/opencore-amr/"

if [[ ${PV} == *9999 ]] ; then
	SRC_URI=""
elif [[ ${PV%_p*} != ${PV} ]] ; then # Gentoo snapshot
	SRC_URI="mirror://gentoo/${P}.tar.xz"
else # Official release
	SRC_URI="mirror://sourceforge/opencore-amr/${P}.tar.gz"
fi

LICENSE="Apache-2.0"
SLOT="0"

[[ ${PV} == *9999 ]] || \
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~ppc ~ppc64 ~sparc ~x86 ~amd64-fbsd ~x86-fbsd ~x64-macos"
IUSE="examples static-libs"

src_prepare() {
	[[ ${PV} == *9999 ]] && eautoreconf
}

src_configure() {
	econf \
		--disable-dependency-tracking \
		$(use_enable examples example) \
		$(use_enable static-libs static)
}

src_install() {
	emake DESTDIR="${D}" install || die
	find "${D}"usr/$(get_libdir) -name '*.la' -delete
}
