# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-wireless/wpa_supplicant/wpa_supplicant-0.7.3-r5.ebuild,v 1.18 2012/05/22 07:17:10 gurligebis Exp $

EAPI=4

inherit eutils toolchain-funcs qt4-r2 systemd multilib

DESCRIPTION="IEEE 802.1X/WPA supplicant for secure wireless transfers"
HOMEPAGE="http://hostap.epitest.fi/wpa_supplicant/"
SRC_URI="http://hostap.epitest.fi/releases/${P}.tar.gz"
LICENSE="|| ( GPL-2 BSD )"

SLOT="0"
KEYWORDS="amd64 arm ~mips ppc ppc64 x86 ~x86-fbsd"
IUSE="dbus debug gnutls eap-sim fasteap madwifi ps3 qt4 readline selinux ssl wimax wps kernel_linux kernel_FreeBSD"

RDEPEND="dbus? ( sys-apps/dbus )
	kernel_linux? (
		eap-sim? ( sys-apps/pcsc-lite )
		madwifi? ( >net-wireless/madwifi-ng-tools-0.9.3 )
		dev-libs/libnl:1.1
	)
	!kernel_linux? ( net-libs/libpcap )
	qt4? (
		x11-libs/qt-gui:4
		x11-libs/qt-svg:4
	)
	readline? (
		sys-libs/ncurses
		sys-libs/readline
	)
	ssl? ( dev-libs/openssl )
	!ssl? ( gnutls? ( net-libs/gnutls ) )
	!ssl? ( !gnutls? ( dev-libs/libtommath ) )
	selinux? ( sec-policy/selinux-networkmanager )"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

S="${WORKDIR}/${P}/${PN}"

pkg_setup() {
	if use fasteap && (use gnutls || use ssl) ; then
		die "If you use fasteap, you must build with wpa_supplicant's internal TLS implementation.  That is, both 'gnutls' and 'ssl' USE flags must be disabled"
	fi

	if use gnutls && use ssl ; then
		einfo "You have both 'gnutls' and 'ssl' USE flags enabled: defaulting to USE=\"ssl\""
	fi
}

src_prepare() {
	# net/bpf.h needed for net-libs/libpcap on Gentoo/FreeBSD
	sed -i \
		-e "s:\(#include <pcap\.h>\):#include <net/bpf.h>\n\1:" \
		../src/l2_packet/l2_packet_freebsd.c || die

	# People seem to take the example configuration file too literally (bug #102361)
	sed -i \
		-e "s:^\(opensc_engine_path\):#\1:" \
		-e "s:^\(pkcs11_engine_path\):#\1:" \
		-e "s:^\(pkcs11_module_path\):#\1:" \
		wpa_supplicant.conf || die

	# Change configuration to match Gentoo locations (bug #143750)
	sed -i \
		-e "s:/usr/lib/opensc:/usr/$(get_libdir):" \
		-e "s:/usr/lib/pkcs11:/usr/$(get_libdir):" \
		wpa_supplicant.conf || die

	epatch "${FILESDIR}/${P}-dbus_path_fix.patch"

	# systemd entries to D-Bus service files (bug #372877)
	echo 'SystemdService=wpa_supplicant.service' \
		| tee -a dbus/*.service >/dev/null || die

	if use wimax; then
		cd "${WORKDIR}/${P}"
		epatch "${FILESDIR}/${P}-generate-libeap-peer.patch"

		# multilib-strict fix (bug #373685)
		sed -e "s/\/usr\/lib/\/usr\/$(get_libdir)/" -i src/eap_peer/Makefile
	fi

	# bug (320097)
	epatch "${FILESDIR}/do-not-call-dbus-functions-with-NULL-path.patch"
	# https://bugzilla.gnome.org/show_bug.cgi?id=644634
	epatch "${FILESDIR}/${P}-dbus-api-changes.patch"
	# bug (374089)
	epatch "${FILESDIR}/${P}-dbus-WPAIE-fix.patch"
	# bug (409285)
	epatch "${FILESDIR}/wpa_supplicant-gcc470.patch"
}

src_configure() {
	# Toolchain setup
	tc-export CC

	# Basic setup
	echo "CONFIG_CTRL_IFACE=y" >> .config
	echo "CONFIG_BACKEND=file" >> .config

	# Basic authentication methods
	# NOTE: we don't set GPSK or SAKE as they conflict
	# with the below options
	echo "CONFIG_EAP_GTC=y"         >> .config
	echo "CONFIG_EAP_MD5=y"         >> .config
	echo "CONFIG_EAP_OTP=y"         >> .config
	echo "CONFIG_EAP_PAX=y"         >> .config
	echo "CONFIG_EAP_PSK=y"         >> .config
	echo "CONFIG_EAP_TLV=y"         >> .config
	echo "CONFIG_IEEE8021X_EAPOL=y" >> .config
	echo "CONFIG_PKCS12=y"          >> .config
	echo "CONFIG_PEERKEY=y"         >> .config
	echo "CONFIG_EAP_LEAP=y"        >> .config
	echo "CONFIG_EAP_MSCHAPV2=y"    >> .config
	echo "CONFIG_EAP_PEAP=y"        >> .config
	echo "CONFIG_EAP_TLS=y"         >> .config
	echo "CONFIG_EAP_TTLS=y"        >> .config

	if use dbus ; then
		echo "CONFIG_CTRL_IFACE_DBUS=y" >> .config
		echo "CONFIG_CTRL_IFACE_DBUS_NEW=y" >> .config
		echo "CONFIG_CTRL_IFACE_DBUS_INTRO=y" >> .config
	fi

	if use debug ; then
		echo "CONFIG_DEBUG_FILE=y" >> .config
	fi

	if use eap-sim ; then
		# Smart card authentication
		echo "CONFIG_EAP_SIM=y"       >> .config
		echo "CONFIG_EAP_AKA=y"       >> .config
		echo "CONFIG_EAP_AKA_PRIME=y" >> .config
		echo "CONFIG_PCSC=y"          >> .config
	fi

	if use fasteap ; then
		echo "CONFIG_EAP_FAST=y" >> .config
	fi

	if use readline ; then
		# readline/history support for wpa_cli
		echo "CONFIG_READLINE=y" >> .config
	fi

	# SSL authentication methods
	if use ssl ; then
		echo "CONFIG_TLS=openssl"    >> .config
		echo "CONFIG_SMARTCARD=y"    >> .config
	elif use gnutls ; then
		echo "CONFIG_TLS=gnutls"     >> .config
		echo "CONFIG_GNUTLS_EXTRA=y" >> .config
	else
		echo "CONFIG_TLS=internal"   >> .config
	fi

	if use kernel_linux ; then
		# Linux specific drivers
		echo "CONFIG_DRIVER_ATMEL=y"       >> .config
		#echo "CONFIG_DRIVER_BROADCOM=y"   >> .config
		#echo "CONFIG_DRIVER_HERMES=y"	   >> .config
		echo "CONFIG_DRIVER_HOSTAP=y"      >> .config
		echo "CONFIG_DRIVER_IPW=y"         >> .config
		echo "CONFIG_DRIVER_NDISWRAPPER=y" >> .config
		echo "CONFIG_DRIVER_NL80211=y"     >> .config
		#echo "CONFIG_DRIVER_PRISM54=y"    >> .config
		echo "CONFIG_DRIVER_RALINK=y"      >> .config
		echo "CONFIG_DRIVER_WEXT=y"        >> .config
		echo "CONFIG_DRIVER_WIRED=y"       >> .config

		if use madwifi ; then
			# Add include path for madwifi-driver headers
			echo "CFLAGS += -I/usr/include/madwifi" >> .config
			echo "CONFIG_DRIVER_MADWIFI=y"          >> .config
		fi

		if use ps3 ; then
			echo "CONFIG_DRIVER_PS3=y" >> .config
		fi

	elif use kernel_FreeBSD ; then
		# FreeBSD specific driver
		echo "CONFIG_DRIVER_BSD=y" >> .config
	fi

	# Wi-Fi Protected Setup (WPS)
	if use wps ; then
		echo "CONFIG_WPS=y" >> .config
	fi

	# Enable mitigation against certain attacks against TKIP
	echo "CONFIG_DELAYED_MIC_ERROR_REPORT=y" >> .config

	# If we are using libnl 2.0 and above, enable support for it
	# Bug 382159
	# Removed for now, since the 3.2 version is broken, and we don't
	# support it.
	#if has_version ">=dev-libs/libnl-2.0"; then
	#	echo "CONFIG_LIBNL20=y" >> .config
	#fi

	if use qt4 ; then
		pushd "${S}"/wpa_gui-qt4 > /dev/null
		eqmake4 wpa_gui.pro
		popd > /dev/null
	fi
}

src_compile() {
	einfo "Building wpa_supplicant"
	emake

	if use wimax; then
		emake -C ../src/eap_peer clean
		emake -C ../src/eap_peer
	fi

	if use qt4 ; then
		pushd "${S}"/wpa_gui-qt4 > /dev/null
		einfo "Building wpa_gui"
		emake
		popd > /dev/null
	fi
}

src_install() {
	dosbin wpa_supplicant
	dobin wpa_cli wpa_passphrase

	# baselayout-1 compat
	if has_version "<sys-apps/baselayout-2.0.0"; then
		dodir /sbin
		dosym /usr/sbin/wpa_supplicant /sbin/wpa_supplicant
		dodir /bin
		dosym /usr/bin/wpa_cli /bin/wpa_cli
	fi

	if has_version ">=sys-apps/openrc-0.5.0"; then
		newinitd "${FILESDIR}/${PN}-init.d" wpa_supplicant
		newconfd "${FILESDIR}/${PN}-conf.d" wpa_supplicant
	fi

	exeinto /etc/wpa_supplicant/
	newexe "${FILESDIR}/wpa_cli.sh" wpa_cli.sh

	dodoc ChangeLog {eap_testing,todo}.txt README{,-WPS} \
		wpa_supplicant.conf

	doman doc/docbook/*.{5,8}

	if use qt4 ; then
		into /usr
		dobin wpa_gui-qt4/wpa_gui
		doicon wpa_gui-qt4/icons/wpa_gui.svg
		make_desktop_entry wpa_gui "WPA Supplicant Administration GUI" "wpa_gui" "Qt;Network;"
	fi

	use wimax && emake DESTDIR="${D}" -C ../src/eap_peer install

	if use dbus ; then
		pushd "${S}"/dbus > /dev/null
		insinto /etc/dbus-1/system.d
		newins dbus-wpa_supplicant.conf wpa_supplicant.conf
		insinto /usr/share/dbus-1/system-services
		doins fi.epitest.hostap.WPASupplicant.service fi.w1.wpa_supplicant1.service
		keepdir /var/run/wpa_supplicant
		popd > /dev/null
	fi

	# systemd stuff
	systemd_dounit "${FILESDIR}"/wpa_supplicant.service
	systemd_newunit "${FILESDIR}"/wpa_supplicant_at.service 'wpa_supplicant@.service'
}

pkg_postinst() {
	einfo "If this is a clean installation of wpa_supplicant, you"
	einfo "have to create a configuration file named"
	einfo "/etc/wpa_supplicant/wpa_supplicant.conf"
	einfo
	einfo "An example configuration file is available for reference in"
	einfo "/usr/share/doc/${PF}/"

	if [[ -e ${ROOT}etc/wpa_supplicant.conf ]] ; then
		echo
		ewarn "WARNING: your old configuration file ${ROOT}etc/wpa_supplicant.conf"
		ewarn "needs to be moved to ${ROOT}etc/wpa_supplicant/wpa_supplicant.conf"
	fi

	if use madwifi ; then
		echo
		einfo "This package compiles against the headers installed by"
		einfo "madwifi-old, madwifi-ng or madwifi-ng-tools."
		einfo "You should re-emerge ${PN} after upgrading these packages."
	fi

	# Mea culpa, feel free to remove that after some time --mgorny.
	local fn
	for fn in wpa_supplicant{,@wlan0}.service; do
		if [[ -e "${ROOT}"/etc/systemd/system/network.target.wants/${fn} ]]
		then
			ebegin "Moving ${fn} to multi-user.target"
			mv "${ROOT}"/etc/systemd/system/network.target.wants/${fn} \
				"${ROOT}"/etc/systemd/system/multi-user.target.wants/
			eend ${?} \
				"Please try to re-enable ${fn}"
		fi
	done
}
