# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-irc/hexchat/hexchat-2.9.4.ebuild,v 1.2 2013/01/14 07:14:11 polynomial-c Exp $

EAPI=5

inherit eutils gnome2 multilib

DESCRIPTION="Graphical IRC client based on XChat"
SRC_URI="mirror://github/${PN}/${PN}/${P}.tar.xz"
HOMEPAGE="http://www.hexchat.org/"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~ppc ~ppc64 ~sparc ~x86 ~amd64-linux"
IUSE="dbus fastscroll +gtk ipv6 libnotify libproxy nls ntlm perl +plugins python spell ssl threads"

RDEPEND="dev-libs/glib:2
	x11-libs/pango
	dbus? ( >=dev-libs/dbus-glib-0.98 )
	gtk? ( x11-libs/gtk+:2 )
	libnotify? ( x11-libs/libnotify )
	ntlm? ( net-libs/libntlm )
	perl? ( >=dev-lang/perl-5.8.0 )
	python? ( =dev-lang/python-2* )
	spell? ( dev-libs/libxml2 )
	libproxy? ( net-libs/libproxy )
	ssl? ( >=dev-libs/openssl-0.9.8u )"
DEPEND="${RDEPEND}
	sys-devel/gettext
	virtual/pkgconfig"

DOCS="share/doc/changelog.md share/doc/readme.md"

pkg_setup() {
	# Added for to fix a sparc seg fault issue by Jason Wever <weeve@gentoo.org>
	if [[ ${ARCH} = sparc ]] ; then
		replace-flags "-O[3-9]" "-O2"
	fi
}

src_prepare() {
	epatch "${FILESDIR}"/${PN}-2.9.1-input-box.patch \
		"${FILESDIR}"/${PN}-2.9.3-cflags.patch

	# use $libdir/hexchat/plugins as the plugin directory
	if [[ $(get_libdir) != "lib" ]] ; then
		sed -e 's:${prefix}/lib/hexchat:${libdir}/hexchat:' \
			-i configure.ac || die 'sed failed'
	fi

	mkdir "m4" || die "mkdir failed"
	./autogen.sh || die "autogen.sh failed"
}

src_configure() {
	econf --enable-shm \
		$(use_enable dbus) \
		$(use_enable ipv6) \
		$(use_enable nls) \
		$(use_enable ntlm) \
		$(use_enable perl) \
		$(use_enable python) \
		$(use_enable spell spell static) \
		$(use_enable ssl openssl) \
		$(use_enable gtk gtkfe) \
		$(use_enable !gtk textfe) \
		$(use_enable fastscroll xft) \
		$(use_enable plugins plugin) \
		$(use_enable plugins checksum) \
		$(use_enable plugins doat) \
		$(use_enable plugins fishlim) \
		$(use_enable plugins sysinfo) \
		$(use_enable libproxy) \
		$(use_enable libproxy socks) \
		$(use_enable threads)
}

src_install() {
	default
	prune_libtool_files --all

	# install plugin development header
	doheader src/common/"${PN}"-plugin.h

	# remove useless desktop entry when gtk USE flag is unset
	use gtk || rm "${ED}"/usr/share/applications -rf
}

pkg_postinst() {
	if use !gtk ; then
		elog "You have disabled the gtk USE flag. This means you don't have"
		elog "the GTK-GUI for HexChat but only a text interface called \"hexchat-text\"."
	fi

	ewarn "If you're upgrading from hexchat <=2.9.3 remember to rename"
	ewarn "the xchat.conf file found in ~/.config/hexchat/ to hexchat.conf"

	gnome2_icon_cache_update
}
