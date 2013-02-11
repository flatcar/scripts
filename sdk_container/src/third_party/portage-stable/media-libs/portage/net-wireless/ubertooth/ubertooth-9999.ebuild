# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-wireless/ubertooth/ubertooth-9999.ebuild,v 1.17 2012/12/05 00:17:43 zerochaos Exp $

EAPI="4"

PYTHON_DEPEND="python? 2"
SUPPORT_PYTHON_ABIS="1"
RESTRICT_PYTHON_ABIS="3.*"

inherit multilib distutils

HOMEPAGE="http://ubertooth.sourceforge.net/"

LICENSE="GPL-2"
SLOT="0"
IUSE="+dfu clock_debug +specan +python ubertooth0-firmware +ubertooth1-firmware"
REQUIRED_USE="dfu? ( python )
		specan? ( python )
		ubertooth0-firmware? ( dfu )
		ubertooth1-firmware? ( dfu )
		python? ( || ( dfu specan ) )"
DEPEND="clock_debug? ( net-wireless/bluez )"
RDEPEND="${DEPEND}
	specan? ( virtual/libusb:1
		 >=x11-libs/qt-gui-4.7.2:4
		>=dev-python/pyside-1.0.2
		>=dev-python/numpy-1.3
		>=dev-python/pyusb-1.0.0_alpha1 )
	dfu? ( virtual/libusb:1
		>=dev-python/pyusb-1.0.0_alpha1 )"

if [[ ${PV} == "9999" ]] ; then
	EGIT_REPO_URI="http://git.code.sf.net/p/ubertooth/code"
	SRC_URI=""
	inherit git-2
	KEYWORDS=""
	DEPEND="=net-libs/libbtbb-9999"
	RDEPEND="${RDEPEND}
		=net-libs/libbtbb-9999"
	DEPEND="ubertooth0-firmware? ( sys-devel/crossdev )
		ubertooth1-firmware? ( sys-devel/crossdev )"
else
	MY_P=${P/\./-}
	MY_P=${MY_P/./-R}
	S=${WORKDIR}/${MY_P}
	SRC_URI="mirror://sourceforge/${PN}/${MY_P}.tar.xz"
	#re-add arm keyword after making a lib-only target
	KEYWORDS="~amd64 ~arm ~x86"
	DEPEND=">=net-libs/libbtbb-${PV}"
	RDEPEND="${RDEPEND}
		>=net-libs/libbtbb-${PV}"
fi
DESCRIPTION="An open source wireless development platform suitable for Bluetooth experimentation"

have_clock_debug() {
	use clock_debug && echo "true" || echo "false"
}

pkg_setup() {
if [[ ${PV} == "9999" ]] ; then
	#ebegin "arm-none-eabi-gcc"
	#if type -p arm-none-eabi-gcc > /dev/null ; then
	#	eend 0
	#else
	#	eend 1
	#	eerror "Failed to locate 'arm-none-eabi-gcc' in \$PATH. You can install the needed toolchain using:"
	#	eerror "  $ crossdev --genv 'USE=\"-openmp -fortran\"' -s4 -t arm-none-eabi"
	#	die "arm-none-eabi toolchain not found"
	#fi
	ewarn "bypassing live pkg_setup because firmware building doesn't work"
fi
	if use python; then
	#I would prefer like this but we can't multiconditional PYTHON_DEPEND in EAPI4
	#if use dfu || use specan; then
		python_pkg_setup;
		DISTUTILS_SETUP_FILES=()
		if use dfu; then
			DISTUTILS_SETUP_FILES+=("${S}/host/usb_dfu|setup.py")
			PYTHON_MODNAME="dfu"
		fi
		if use specan; then
			DISTUTILS_SETUP_FILES+=("${S}/host/specan_ui|setup.py")
			PYTHON_MODNAME+=" specan"
		fi
	fi
}

src_prepare() {
	use python && distutils_src_prepare
}

src_compile() {
	cd "${S}/host/bluetooth_rxtx" || die
	emake \
	clock_debug="$(have_clock_debug)"

	use python && distutils_src_compile
	if [[ ${PV} == "9999" ]] ; then
		#cd "${S}"/firmware/bluetooth_rxtx || die
		#if use ubertooth0-firmware; then
		#	SVN_REV_NUM="-D'SVN_REV_NUM'=${ESVN_WC_REVISION}" BOARD=UBERTOOTH_ZERO emake -j1
		#	mv bluetooth_rxtx.bin bluetooth_rxtx_U0.bin || die
		#	emake clean
		#fi
		#if use ubertooth1-firmware; then
		#	SVN_REV_NUM="-D'SVN_REV_NUM'=${ESVN_WC_REVISION}" emake -j1
		#	mv bluetooth_rxtx.bin bluetooth_rxtx_U1.bin || die
		#fi
		ewarn "bypassing firmware build because the resulting firmware fails"
	fi
}

src_install() {
	cd host || die
	dobin bluetooth_rxtx/ubertooth-dump bluetooth_rxtx/ubertooth-lap \
		bluetooth_rxtx/ubertooth-btle bluetooth_rxtx/ubertooth-uap \
		bluetooth_rxtx/ubertooth-hop bluetooth_rxtx/ubertooth-util
	use clock_debug && dobin bluetooth_rxtx/ubertooth-follow bluetooth_rxtx/ubertooth-scan

	use python && distutils_src_install
	use specan && dobin specan_ui/ubertooth-specan-ui
	use dfu && dobin usb_dfu/ubertooth-dfu

	dolib.so bluetooth_rxtx/libubertooth.so.0.1
	dosym libubertooth.so.0.1 /usr/$(get_libdir)/libubertooth.so.0
	dosym libubertooth.so.0.1 /usr/$(get_libdir)/libubertooth.so

	insinto /lib/firmware
	cd "${S}"
	if [[ ${PV} == "9999" ]] ; then
		#use ubertooth0-firmware && doins firmware/bluetooth_rxtx/bluetooth_rxtx_U0.bin
	        #use ubertooth1-firmware && doins firmware/bluetooth_rxtx/bluetooth_rxtx_U1.bin
		ewarn "bypassing firmware install because the built firmware doesn't work"
	else
		use ubertooth0-firmware && newins ubertooth-zero-firmware-bin/bluetooth_rxtx.bin bluetooth_rxtx_U0.bin
	        use ubertooth1-firmware && newins ubertooth-one-firmware-bin/bluetooth_rxtx.bin bluetooth_rxtx_U1.bin
	fi

	insinto /lib/udev/rules.d/
	doins "${S}"/host/bluetooth_rxtx/40-ubertooth.rules

	elog "Everyone can read from the ubertooth, but to talk to it"
	elog "your user needs to be in the usb group."
}

pkg_postinst() {
	use python && distutils_pkg_postinst

	#if use ubertooth0-firmware || use ubertooth1-firmware; then
	#	ewarn "currently the firmware builds using cross dev but is completely"
	#	ewarn "NON-FUNCTIONAL.  This is supported for development only."
	#	ewarn "If you do not know what you are doing to NOT install this version"
	#	ewarn "of the firmware. If you ignore this warning and break your device"
	#	ewarn "you can find repair instructions at ${HOMEPAGE}"
	#	ewarn "You have been warned."
	#fi
}

pkg_postrm() {
	use python && distutils_pkg_postrm
}
