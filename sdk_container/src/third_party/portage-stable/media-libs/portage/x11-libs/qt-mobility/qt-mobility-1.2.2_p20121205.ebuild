# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/qt-mobility/qt-mobility-1.2.2_p20121205.ebuild,v 1.1 2012/12/05 13:38:04 kensington Exp $

EAPI=4

inherit multilib qt4-r2 toolchain-funcs

DESCRIPTION="Additional Qt APIs for mobile devices and desktop platforms"
HOMEPAGE="http://qt.nokia.com/products/qt-addons/mobility"
SRC_URI="http://dev.gentoo.org/~kensington/distfiles/${P}.tar.gz"
LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64 ~x86"

QT_MOBILITY_MODULES=(bearer connectivity +contacts feedback gallery
		location messaging multimedia organizer publishsubscribe
		sensors serviceframework systeminfo versit)
IUSE="bluetooth debug doc networkmanager pulseaudio qml +tools
	${QT_MOBILITY_MODULES[@]}"

REQUIRED_USE="
	|| ( ${QT_MOBILITY_MODULES[@]#[+-]} )
	versit? ( contacts )
"

RDEPEND="
	>=x11-libs/qt-core-4.7.0:4
	bearer? (
		networkmanager? (
			net-misc/networkmanager
			>=x11-libs/qt-dbus-4.7.0:4
		)
	)
	connectivity? (
		>=x11-libs/qt-dbus-4.7.0:4
		bluetooth? ( net-wireless/bluez )
	)
	contacts? ( >=x11-libs/qt-gui-4.7.0:4 )
	gallery? ( >=x11-libs/qt-dbus-4.7.0:4 )
	location? (
		>=x11-libs/qt-declarative-4.7.0:4
		>=x11-libs/qt-gui-4.7.0:4
		>=x11-libs/qt-sql-4.7.0:4[sqlite]
	)
	messaging? ( >=net-libs/qmf-2.0_p201209 )
	multimedia? (
		media-libs/alsa-lib
		media-libs/gstreamer:0.10
		media-libs/gst-plugins-bad:0.10
		media-libs/gst-plugins-base:0.10
		x11-libs/libX11
		x11-libs/libXext
		x11-libs/libXv
		>=x11-libs/qt-gui-4.8.0-r4:4[xv]
		>=x11-libs/qt-opengl-4.8.0:4
		pulseaudio? ( media-sound/pulseaudio[alsa] )
	)
	publishsubscribe? (
		tools? ( >=x11-libs/qt-gui-4.7.0:4 )
	)
	qml? ( >=x11-libs/qt-declarative-4.7.0:4 )
	serviceframework? (
		>=x11-libs/qt-dbus-4.7.0:4
		>=x11-libs/qt-sql-4.7.0:4[sqlite]
		tools? ( >=x11-libs/qt-gui-4.7.0:4 )
	)
	systeminfo? (
		sys-apps/util-linux
		virtual/udev
		x11-libs/libX11
		x11-libs/libXrandr
		>=x11-libs/qt-dbus-4.7.0:4
		>=x11-libs/qt-gui-4.7.0:4
		bluetooth? ( net-wireless/bluez )
		networkmanager? ( net-misc/networkmanager )
	)
	versit? ( >=x11-libs/qt-gui-4.7.0:4 )
"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	multimedia? (
		sys-kernel/linux-headers
		x11-proto/videoproto
	)
	systeminfo? ( sys-kernel/linux-headers )
"
PDEPEND="
	connectivity? (
		bluetooth? ( app-mobilephone/obexd )
	)
"

src_prepare() {
	qt4-r2_src_prepare

	# disable building of code snippets in doc/
	# and translations (they aren't actually translated)
	sed -i -re '/SUBDIRS \+= (doc|translations)/d' qtmobility.pro || die

	# fix automagic dependency on qt-declarative
	if ! use qml; then
		sed -i -e '/SUBDIRS += declarative/d' plugins/plugins.pro || die
	fi
}

src_configure() {
	# figure out which modules to build
	local modules=
	for mod in "${QT_MOBILITY_MODULES[@]#[+-]}"; do
		use ${mod} && modules+="${mod} "
	done

	if use messaging; then
		# tell qmake where QMF is installed
		export QMF_INCLUDEDIR=$($(tc-getPKG_CONFIG) --variable includedir qmfclient)
		export QMF_LIBDIR=$($(tc-getPKG_CONFIG) --variable libdir qmfclient)
	fi

	# custom configure script
	local myconf=(
		./configure
		-prefix "${EPREFIX}/usr"
		-headerdir "${EPREFIX}/usr/include/qt4"
		-libdir "${EPREFIX}/usr/$(get_libdir)/qt4"
		-plugindir "${EPREFIX}/usr/$(get_libdir)/qt4/plugins"
		$(use debug && echo -debug || echo -release)
		$(use doc || echo -no-docs)
		$(use tools || echo -no-tools)
		-modules "${modules}"
	)
	echo "${myconf[@]}"
	"${myconf[@]}" || die "configure failed"

	# fix automagic dependency on bluez
	if ! use bluetooth; then
		sed -i -e '/^bluez_enabled =/s:yes:no:' config.pri || die
	fi
	# fix automagic dependency on networkmanager
	if ! use networkmanager; then
		sed -i -e '/^networkmanager_enabled =/s:yes:no:' config.pri || die
	fi
	# fix automagic dependency on pulseaudio
	if ! use pulseaudio; then
		sed -i -e '/^pulseaudio_enabled =/s:yes:no:' config.pri || die
	fi

	eqmake4 -recursive
}

src_compile() {
	qt4-r2_src_compile

	use doc && emake docs
}

src_install() {
	qt4-r2_src_install

	if use doc; then
		dohtml -r doc/html/*
		dodoc doc/qch/qtmobility.qch
		docompress -x /usr/share/doc/${PF}/qtmobility.qch
	fi
}
