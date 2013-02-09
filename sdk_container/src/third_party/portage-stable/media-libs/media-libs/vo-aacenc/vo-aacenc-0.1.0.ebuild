# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/vo-aacenc/vo-aacenc-0.1.0.ebuild,v 1.3 2012/11/16 19:55:56 ago Exp $

EAPI=4

if [[ ${PV} == *9999 ]] ; then
	SCM="git"
	EGIT_REPO_URI="git://github.com/mstorsjo/${PN}.git"
	[[ ${PV%9999} != "" ]] && EGIT_BRANCH="release/${PV%.9999}"
fi

inherit eutils multilib autotools ${SCM}

DESCRIPTION="VisualOn AAC encoder library"
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

# Don't move KEYWORDS on the previous line or ekeyword won't work # 399061
[[ ${PV} == *9999 ]] || \
KEYWORDS="~amd64 ~arm ~x86-fbsd ~x64-macos"

IUSE="examples static-libs neon"

src_prepare() {
	[[ ${PV} == *9999 ]] && eautoreconf
}

src_configure() {
	econf \
		--disable-silent-rules \
		--disable-dependency-tracking \
		$(use_enable examples example) \
		$(use_enable neon armv7neon) \
		$(use_enable static-libs static)
}

src_install() {
	emake DESTDIR="${D}" install || die
	find "${D}"usr/$(get_libdir) -name '*.la' -delete
}
