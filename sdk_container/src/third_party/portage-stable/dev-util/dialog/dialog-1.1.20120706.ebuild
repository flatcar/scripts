# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-util/dialog/dialog-1.1.20120706.ebuild,v 1.7 2012/11/05 20:03:55 vapier Exp $

EAPI="4"

inherit multilib eutils

MY_PV="${PV/1.1./1.1-}"
S=${WORKDIR}/${PN}-${MY_PV}
DESCRIPTION="tool to display dialog boxes from a shell"
HOMEPAGE="http://invisible-island.net/dialog/dialog.html"
SRC_URI="ftp://invisible-island.net/${PN}/${PN}-${MY_PV}.tgz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k mips ppc ppc64 s390 sh sparc x86 ~amd64-fbsd ~sparc-fbsd ~x86-fbsd"
IUSE="examples minimal nls static-libs unicode"

RDEPEND="
	>=sys-libs/ncurses-5.2-r5
	unicode? ( sys-libs/ncurses[unicode] )
"
DEPEND="
	${RDEPEND}
	nls? ( sys-devel/gettext )
	!minimal? ( sys-devel/libtool )
	!<=sys-freebsd/freebsd-contrib-8.9999
"

src_prepare() {
	sed -i configure -e '/LIB_CREATE=/s:${CC}:& ${LDFLAGS}:g' || die
	sed -i '/$(LIBTOOL_COMPILE)/s:$: $(LIBTOOL_OPTS):' makefile.in || die
}

src_configure() {
	econf \
		--disable-rpath-hack \
		$(use_enable nls) \
		$(use_with !minimal libtool) \
		--with-libtool-opts=$(usex static-libs '' '-shared') \
		--with-ncurses$(usex unicode w '')
}

src_install() {
	if use minimal; then
		emake DESTDIR="${D}" install
	else
		emake DESTDIR="${D}" install-full
	fi

	dodoc CHANGES README

	if use examples; then
		docinto samples
		dodoc $( find samples -maxdepth 1 -type f )
		docinto samples/copifuncs
		dodoc $( find samples/copifuncs -maxdepth 1 -type f )
		docinto samples/install
		dodoc $( find samples/install -type f )
	fi

	if ! use static-libs; then
		rm -f "${ED}"usr/$(get_libdir)/libdialog.{la,a}
	fi
}
