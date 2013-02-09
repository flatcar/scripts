# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/lilv/lilv-0.14.2.ebuild,v 1.4 2012/05/22 16:09:15 johu Exp $

EAPI=4

inherit base waf-utils bash-completion-r1

DESCRIPTION="Library to make the use of LV2 plugins as simple as possible for applications"
HOMEPAGE="http://drobilla.net/software/lilv/"
SRC_URI="http://download.drobilla.net/${P}.tar.bz2"

LICENSE="ISC"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="doc +dyn-manifest static-libs test"

RDEPEND="media-libs/lv2
	media-libs/sratom
	>=dev-libs/serd-0.14.0
	>=dev-libs/sord-0.8.0"
DEPEND="${RDEPEND}
	doc? ( app-doc/doxygen )
	virtual/pkgconfig"

PATCHES=( "${FILESDIR}/ldconfig.patch" )
DOCS=( "AUTHORS" "NEWS" "README" )

src_configure() {
	waf-utils_src_configure \
		--docdir="${EPREFIX}"/usr/share/doc/${PF} \
		--no-bash-completion \
		$(use test && echo "--test") \
		$(use doc && echo "--docs") \
		$(use static-libs && echo "--static") \
		$(use dyn-manifest && echo "--dyn-manifest")
}

src_test() {
	./waf test || die
}

src_install() {
	waf-utils_src_install
	newbashcomp utils/lilv.bash_completion ${PN}
}
