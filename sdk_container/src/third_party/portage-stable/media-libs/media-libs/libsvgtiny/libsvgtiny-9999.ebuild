# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libsvgtiny/libsvgtiny-9999.ebuild,v 1.2 2012/07/18 11:04:24 xmw Exp $

EAPI=4

inherit git-2 multilib toolchain-funcs

DESCRIPTION="framebuffer abstraction library, written in C"
HOMEPAGE="http://www.netsurf-browser.org/projects/libsvgtiny/"
SRC_URI="mirror://gentoo/netsurf-buildsystem-0_p20120717.tar.gz"
EGIT_REPO_URI="git://git.netsurf-browser.org/${PN}.git"

LICENSE="MIT"
SLOT="0"
KEYWORDS=""
IUSE="static-libs"

RDEPEND=""
DEPEND="dev-util/gperf
	virtual/pkgconfig"

src_unpack() {
	default
	git-2_src_unpack
	mv build "${S}" || die
}

src_prepare() {
	sed -e "/^INSTALL_ITEMS/s: /lib: /$(get_libdir):g" \
		-e "s:-Werror::g" \
		-e "1iNSSHARED=${S}/build" \
		-e "1iNSBUILD=${S}/build/makefiles" \
		-i Makefile || die
	sed -e "/^libdir/s:/lib:/$(get_libdir):g" \
		-i ${PN}.pc.in || die
	echo "Q := " >> Makefile.config.override
	echo "CC := $(tc-getCC)" >> Makefile.config.override
	echo "AR := $(tc-getAR)" >> Makefile.config.override
}

src_compile() {
	emake COMPONENT_TYPE=lib-shared
	use static-libs && \
		emake COMPONENT_TYPE=lib-static
}

src_test() {
	emake COMPONENT_TYPE=lib-shared test
	use static-libs && \
		emake COMPONENT_TYPE=lib-static test
}

src_install() {
	emake DESTDIR="${D}" PREFIX=/usr COMPONENT_TYPE=lib-shared install
	use static-libs && \
		emake DESTDIR="${D}" PREFIX=/usr COMPONENT_TYPE=lib-static install
	dodoc README
}
