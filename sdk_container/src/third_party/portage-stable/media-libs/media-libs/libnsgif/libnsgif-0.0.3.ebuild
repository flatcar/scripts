# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libnsgif/libnsgif-0.0.3.ebuild,v 1.2 2012/07/17 23:25:46 xmw Exp $

EAPI=4

inherit multilib toolchain-funcs

DESCRIPTION="decoding library for the GIF image file format, written in C"
HOMEPAGE="http://www.netsurf-browser.org/projects/libnsgif/"
SRC_URI="http://download.netsurf-browser.org/libs/releases/${P}-src.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm"
IUSE="static-libs"

RDEPEND=""
DEPEND=""

src_prepare() {
	sed -e "/^INSTALL_ITEMS/s: /lib: /$(get_libdir):g" \
		-e "s:-Werror::g" \
		-i Makefile || die
	sed -e "/^libdir/s:/lib:/$(get_libdir):g" \
		-i ${PN}.pc.in || die
	echo "Q := " >> Makefile.config.override
	echo "CC := $(tc-getCC)" >> Makefile.config.override
	echo "AR := $(tc-getAR)" >> Makefile.config.override
}

src_compile() {
	emake COMPONENT_TYPE=lib-shared
	use static-libs && emake COMPONENT_TYPE=lib-static
}

src_test() {
	emake COMPONENT_TYPE=lib-shared test
	use static-libs && emake COMPONENT_TYPE=lib-static test
}

src_install() {
	emake COMPONENT_TYPE=lib-shared DESTDIR="${D}" PREFIX=/usr install
	use static-libs && \
		emake COMPONENT_TYPE=lib-static DESTDIR="${D}" PREFIX=/usr install
}
