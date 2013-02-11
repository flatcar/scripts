# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-wireless/bluez/bluez-4.99.ebuild,v 1.14 2012/12/11 09:44:00 ssuominen Exp $

EAPI="4"
PYTHON_DEPEND="test-programs? 2"

inherit multilib eutils systemd python user

DESCRIPTION="Bluetooth Tools and System Daemons for Linux"
HOMEPAGE="http://www.bluez.org/"

# Because of oui.txt changing from time to time without noticement, we need to supply it
# ourselves instead of using http://standards.ieee.org/regauth/oui/oui.txt directly.
# See bugs #345263 and #349473 for reference.
OUIDATE="20120308"
SRC_URI="mirror://kernel/linux/bluetooth/${P}.tar.xz
	http://dev.gentoo.org/~pacho/bluez/oui-${OUIDATE}.txt.xz"

LICENSE="GPL-2 LGPL-2.1"
SLOT="0"
KEYWORDS="amd64 arm hppa ppc ppc64 x86"
IUSE="alsa caps +consolekit cups debug gstreamer pcmcia selinux test-programs usb readline"

CDEPEND="
	>=dev-libs/glib-2.14:2
	sys-apps/dbus
	~virtual/udev-171
	alsa? (
		media-libs/alsa-lib[alsa_pcm_plugins_extplug(+),alsa_pcm_plugins_ioplug(+)]
		media-libs/libsndfile
	)
	caps? ( >=sys-libs/libcap-ng-0.6.2 )
	cups? ( net-print/cups )
	gstreamer? (
		>=media-libs/gstreamer-0.10:0.10
		>=media-libs/gst-plugins-base-0.10:0.10
	)
	selinux? ( sec-policy/selinux-bluetooth )
	usb? ( virtual/libusb:0 )
	readline? ( sys-libs/readline )
"
DEPEND="${CDEPEND}
	virtual/pkgconfig
	sys-devel/flex
	test-programs? ( >=dev-libs/check-0.9.6 )
"
RDEPEND="${CDEPEND}
	!net-wireless/bluez-libs
	!net-wireless/bluez-utils
	consolekit? (
		|| ( sys-auth/consolekit
			>=sys-apps/systemd-37 )
	)
	test-programs? (
		dev-python/dbus-python
		dev-python/pygobject:2
	)
"

DOCS=( AUTHORS ChangeLog README )

pkg_setup() {
	if ! use consolekit; then
		enewgroup plugdev
	fi

	if use test-programs; then
		python_pkg_setup
	fi
}

src_prepare() {
	if ! use consolekit; then
		# No consolekit for at_console etc, so we grant plugdev the rights
		epatch	"${FILESDIR}/bluez-plugdev.patch"
	fi

	if use cups; then
		sed -i \
			-e "s:cupsdir = \$(libdir)/cups:cupsdir = `cups-config --serverbin`:" \
			Makefile.tools Makefile.in || die
	fi
}

src_configure() {
	use readline || export ac_cv_header_readline_readline_h=no

	econf \
		--enable-hid2hci \
		--enable-audio \
		--enable-bccmd \
		--enable-datafiles \
		--enable-dfutool \
		--enable-input \
		--enable-network \
		--enable-serial \
		--enable-service \
		--enable-tools \
		--disable-hal \
		--localstatedir=/var \
		--with-systemdunitdir="$(systemd_get_unitdir)" \
		$(use_enable alsa) \
		$(use_enable caps capng) \
		$(use_enable cups) \
		$(use_enable debug) \
		$(use_enable gstreamer) \
		$(use_enable pcmcia) \
		$(use_enable test-programs test) \
		$(use_enable usb) \
		--enable-health \
		--enable-maemo6 \
		--enable-pnat \
		--enable-wiimote
}

src_install() {
	default

	if use test-programs ; then
		cd "${S}/test"
		dobin simple-agent simple-service monitor-bluetooth
		newbin list-devices list-bluetooth-devices
		rm test-textfile.{c,o} || die # bug #356529
		for b in apitest hsmicro hsplay test-* ; do
			newbin "${b}" "bluez-${b}"
		done
		insinto /usr/share/doc/${PF}/test-services
		doins service-*

		python_convert_shebangs -r 2 "${ED}"
		cd "${S}"
	fi

	insinto /etc/bluetooth
	doins \
		input/input.conf \
		audio/audio.conf \
		network/network.conf \
		serial/serial.conf

	newinitd "${FILESDIR}/bluetooth-init.d-r1" bluetooth
	newinitd "${FILESDIR}/rfcomm-init.d" rfcomm
	newconfd "${FILESDIR}/rfcomm-conf.d" rfcomm

	# Install oui.txt as requested in bug #283791 and approved by upstream
	insinto /var/lib/misc
	newins "${WORKDIR}/oui-${OUIDATE}.txt" oui.txt

	find "${D}" -name "*.la" -delete
}

pkg_postinst() {
	udevadm control --reload-rules && udevadm trigger --subsystem-match=bluetooth

	if ! has_version "net-dialup/ppp"; then
		elog "To use dial up networking you must install net-dialup/ppp."
	fi

	if use consolekit; then
		elog "If you want to use rfcomm as a normal user, you need to add the user"
		elog "to the uucp group."
	else
		elog "Since you have the consolekit use flag disabled, you will only be able to run"
		elog "bluetooth clients as root. If you want to be able to run bluetooth clientes as "
		elog "a regular user, you need to enable the consolekit use flag for this package or"
		elog "to add the user to the plugdev group."
	fi

	if [ "$(rc-config list default | grep bluetooth)" = "" ] ; then
		elog "You will need to add bluetooth service to default runlevel"
		elog "for getting your devices detected from startup without needing"
		elog "to reconnect them. For that please run:"
		elog "'rc-update add bluetooth default'"
	fi
}
