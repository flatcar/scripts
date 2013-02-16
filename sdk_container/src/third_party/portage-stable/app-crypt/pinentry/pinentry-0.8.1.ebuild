# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-crypt/pinentry/pinentry-0.8.1.ebuild,v 1.13 2012/09/09 15:20:18 armin76 Exp $

EAPI=3

inherit multilib eutils flag-o-matic

DESCRIPTION="Collection of simple PIN or passphrase entry dialogs which utilize the Assuan protocol"
HOMEPAGE="http://gnupg.org/aegypten2/index.html"
SRC_URI="mirror://gnupg/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~amd64-fbsd ~x86-fbsd ~x64-freebsd ~x86-freebsd ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE="gtk ncurses qt4 caps static"

RDEPEND="app-admin/eselect-pinentry
	static? ( >=sys-libs/ncurses-5.7-r5[static-libs] )
	!static? (
		gtk? ( x11-libs/gtk+:2 )
		ncurses? ( sys-libs/ncurses )
		qt4? ( >=x11-libs/qt-gui-4.4.1:4 )
		!gtk? ( !qt4? ( !ncurses? ( sys-libs/ncurses ) ) )
	)
	caps? ( sys-libs/libcap )"
DEPEND="${RDEPEND}
	!static? (
		gtk? ( virtual/pkgconfig )
		qt4? ( virtual/pkgconfig )
	)"

pkg_setup() {
	use static && append-ldflags -static

	if use static && { use gtk || use qt4; }; then
		ewarn
		ewarn "The static USE flag is only supported with the ncurses USE flags, disabling the gtk and qt4 USE flags."
		ewarn
	fi
}

src_prepare() {
	if use qt4; then
		local file
		for file in qt4/*.moc; do
			"${EPREFIX}"/usr/bin/moc ${file/.moc/.h} > ${file} || die
		done
	fi
}

src_configure() {
	local myconf=""

	if ! { use qt4 || use gtk || use ncurses; }
	then
		myconf="--enable-pinentry-curses --enable-fallback-curses"
	elif use static
	then
		myconf="--enable-pinentry-curses --enable-fallback-curses --disable-pinentry-gtk2 --disable-pinentry-qt4"
	fi

	# Issues finding qt on multilib systems
	export QTLIB="${QTDIR}/$(get_libdir)"

	econf \
		--disable-dependency-tracking \
		--enable-maintainer-mode \
		--disable-pinentry-gtk \
		$(use_enable gtk pinentry-gtk2) \
		--disable-pinentry-qt \
		$(use_enable ncurses pinentry-curses) \
		$(use_enable ncurses fallback-curses) \
		$(use_enable qt4 pinentry-qt4) \
		$(use_with caps libcap) \
		--without-x \
		${myconf}
}

src_install() {
	emake DESTDIR="${D}" install || die
	dodoc AUTHORS ChangeLog NEWS README THANKS TODO
	rm -f "${ED}"/usr/bin/pinentry || die
}

pkg_postinst() {
	elog "We no longer install pinentry-curses and pinentry-qt SUID root by default."
	elog "Linux kernels >=2.6.9 support memory locking for unprivileged processes."
	elog "The soft resource limit for memory locking specifies the limit an"
	elog "unprivileged process may lock into memory. You can also use POSIX"
	elog "capabilities to allow pinentry to lock memory. To do so activate the caps"
	elog "USE flag and add the CAP_IPC_LOCK capability to the permitted set of"
	elog "your users."
	eselect pinentry update ifunset
}

pkg_postrm() {
	eselect pinentry update ifunset
}
