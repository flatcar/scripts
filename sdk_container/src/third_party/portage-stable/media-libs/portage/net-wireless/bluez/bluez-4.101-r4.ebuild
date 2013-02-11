# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-wireless/bluez/bluez-4.101-r4.ebuild,v 1.1 2012/12/02 09:42:12 ssuominen Exp $

EAPI=5
PYTHON_DEPEND="test-programs? 2:2.6"
inherit eutils multilib python systemd user

DESCRIPTION="Bluetooth Tools and System Daemons for Linux"
HOMEPAGE="http://www.bluez.org/"
SRC_URI="mirror://kernel/linux/bluetooth/${P}.tar.xz"

LICENSE="GPL-2 LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64 ~arm ~hppa ~ppc ~ppc64 ~x86"
IUSE="alsa +consolekit cups debug gstreamer pcmcia readline selinux test-programs usb"

CDEPEND="
	>=dev-libs/glib-2.28
	>=sys-apps/dbus-1.6
	>=sys-apps/hwids-20121202.2
	>=virtual/udev-171
	alsa? (
		media-libs/alsa-lib[alsa_pcm_plugins_extplug(+),alsa_pcm_plugins_ioplug(+)]
		media-libs/libsndfile
	)
	cups? ( net-print/cups )
	gstreamer? (
		>=media-libs/gstreamer-0.10:0.10
		>=media-libs/gst-plugins-base-0.10:0.10
	)
	readline? ( sys-libs/readline )
	selinux? ( sec-policy/selinux-bluetooth )
	usb? ( virtual/libusb:0 )
"
DEPEND="${CDEPEND}
	sys-devel/flex
	virtual/pkgconfig
	test-programs? ( >=dev-libs/check-0.9.6 )
"
RDEPEND="${CDEPEND}
	consolekit? ( || ( sys-auth/consolekit sys-apps/systemd ) )
	test-programs? (
		>=dev-python/dbus-python-1
		dev-python/pygobject:2
	)
"

DOCS=( AUTHORS ChangeLog README )

pkg_setup() {
	use consolekit || enewgroup plugdev
	use test-programs && python_pkg_setup
}

src_prepare() {
	epatch "${FILESDIR}"/${P}-network{1,2,3,4}.patch

	# Use static group "plugdev" if there is no ConsoleKit (or systemd logind)
	use consolekit || epatch "${FILESDIR}"/bluez-plugdev.patch

	if use cups; then
		sed -i \
			-e "s:cupsdir = \$(libdir)/cups:cupsdir = `cups-config --serverbin`:" \
			Makefile.{in,tools} || die
	fi
}

src_configure() {
	export ac_cv_header_readline_readline_h=$(usex readline)

	# Missing flags: --enable-{sap,hidd,pand,dund,dbusoob,gatt}
	# Keep this in ./configure --help order!
	econf \
		--localstatedir=/var \
		--enable-network \
		--enable-serial \
		--enable-input \
		--enable-audio \
		--enable-service \
		--enable-health \
		--enable-pnat \
		$(use_enable gstreamer) \
		$(use_enable alsa) \
		$(use_enable usb) \
		--enable-tools \
		--enable-bccmd \
		$(use_enable pcmcia) \
		--enable-hid2hci \
		--enable-dfutool \
		$(use_enable cups) \
		$(use_enable test-programs test) \
		--enable-datafiles \
		$(use_enable debug) \
		--enable-maemo6 \
		--enable-wiimote \
		--disable-hal \
		--with-ouifile=/usr/share/misc/oui.txt \
		--with-systemdunitdir="$(systemd_get_unitdir)"
}

src_install() {
	default

	if use test-programs; then
		pushd test >/dev/null
		dobin simple-agent simple-service monitor-bluetooth
		newbin list-devices list-bluetooth-devices
		rm test-textfile.{c,o} || die #356529
		local b
		for b in hsmicro hsplay test-*; do
			newbin "${b}" bluez-"${b}"
		done
		insinto /usr/share/doc/${PF}/test-services
		doins service-*
		python_convert_shebangs -r 2 "${ED}"
		popd >/dev/null
	fi

	insinto /etc/bluetooth
	local d
	for d in input audio network serial; do
		doins ${d}/${d}.conf
	done

	newinitd "${FILESDIR}"/bluetooth-init.d-r2 bluetooth
	newinitd "${FILESDIR}"/rfcomm-init.d rfcomm
	newconfd "${FILESDIR}"/rfcomm-conf.d rfcomm

	prune_libtool_files --all
}

pkg_postinst() {
	udevadm control --reload-rules

	has_version net-dialup/ppp || elog "To use dial up networking you must install net-dialup/ppp."

	if use consolekit; then
		elog "If you want to use rfcomm as a normal user, you need to add the user"
		elog "to the uucp group."
	else
		elog "Since you have the consolekit use flag disabled, you will only be able to run"
		elog "bluetooth clients as root. If you want to be able to run bluetooth clientes as "
		elog "a regular user, you need to enable the consolekit use flag for this package or"
		elog "to add the user to the plugdev group."
	fi

	if [ "$(rc-config list default | grep bluetooth)" = "" ]; then
		elog "You will need to add bluetooth service to default runlevel"
		elog "for getting your devices detected. For that please run:"
		elog "'rc-update add bluetooth default'"
	fi
}
