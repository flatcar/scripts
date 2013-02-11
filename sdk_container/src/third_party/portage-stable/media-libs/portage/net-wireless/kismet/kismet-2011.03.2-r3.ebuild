# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-wireless/kismet/kismet-2011.03.2-r3.ebuild,v 1.6 2012/07/23 17:13:22 zerochaos Exp $

EAPI=4

inherit eutils multilib user

MY_P=${P/\./-}
MY_P=${MY_P/./-R}
S=${WORKDIR}/${MY_P}

if [[ ${PV} == "9999" ]] ; then
	ESVN_REPO_URI="https://www.kismetwireless.net/code/svn/trunk"
	inherit subversion
	KEYWORDS=""
else
	SRC_URI="http://www.kismetwireless.net/code/${MY_P}.tar.gz"
	KEYWORDS="amd64 ~arm ppc x86"
fi

DESCRIPTION="IEEE 802.11 wireless LAN sniffer"
HOMEPAGE="http://www.kismetwireless.net/"

LICENSE="GPL-2"
SLOT="0"
IUSE="+client +pcre speech +plugin-autowep +plugin-btscan +plugin-dot15d4 +plugin-ptw +plugin-spectools +ruby +suid"

# Bluez 4.98 breaks c++ building, so we choose to use -r2 which has the patch
# or 4.96 which still builds properly.
RDEPEND="net-wireless/wireless-tools
	kernel_linux? ( sys-libs/libcap
		>=dev-libs/libnl-1.1 )
	net-libs/libpcap
	pcre? ( dev-libs/libpcre )
	suid? ( sys-libs/libcap )
	client? ( sys-libs/ncurses )
	!arm? ( speech? ( app-accessibility/flite ) )
	ruby? ( dev-lang/ruby )
	plugin-btscan? ( || (
			>=net-wireless/bluez-4.98-r2
			=net-wireless/bluez-4.96
			) )
	plugin-dot15d4? ( virtual/libusb:0 )
	plugin-spectools? ( net-wireless/spectools )"

DEPEND="${RDEPEND}
	virtual/pkgconfig"

src_prepare() {
	sed -i -e "s:^\(logtemplate\)=\(.*\):\1=/tmp/\2:" \
		conf/kismet.conf.in

	# Don't strip and set correct mangrp
	sed -i -e 's| -s||g' \
		-e 's|@mangrp@|root|g' Makefile.in

	epatch "${FILESDIR}"/makefile.patch
	epatch "${FILESDIR}"/plugins-ldflags.patch
	epatch "${FILESDIR}"/bluechanfix_r3184.patch
	epatch "${FILESDIR}"/kismet-console-scrolling-backport.patch
	epatch "${FILESDIR}"/header_alignment_r3326.patch
	epatch "${FILESDIR}"/use-hostname-by-default.patch
	epatch "${FILESDIR}"/${P}-cflags-backport.patch
}

src_configure() {
	econf \
		$(use_enable client) \
		$(use_enable pcre)
}

src_compile() {
	emake

	if use plugin-autowep; then
		cd "${S}"/plugin-autowep
		KIS_SRC_DIR="${S}" emake
	fi
	if use plugin-btscan; then
		cd "${S}"/plugin-btscan
		KIS_SRC_DIR="${S}" emake
	fi
	if use plugin-dot15d4; then
		cd "${S}"/plugin-dot15d4
		KIS_SRC_DIR="${S}" emake
	fi
	if use plugin-ptw; then
		cd "${S}"/plugin-ptw
		KIS_SRC_DIR="${S}" emake
	fi
	if use plugin-spectools; then
		cd "${S}"/plugin-spectools
		KIS_SRC_DIR="${S}" emake
	fi
}

src_install() {
	if use plugin-autowep; then
		cd "${S}"/plugin-autowep
		KIS_SRC_DIR="${S}" emake DESTDIR="${ED}" LIBDIR="$(get_libdir)" install
	fi
	if use plugin-btscan; then
		cd "${S}"/plugin-btscan
		KIS_SRC_DIR="${S}" emake DESTDIR="${ED}" LIBDIR="$(get_libdir)" install
	fi
	if use plugin-dot15d4; then
		cd "${S}"/plugin-dot15d4
		KIS_SRC_DIR="${S}" emake DESTDIR="${ED}" LIBDIR="$(get_libdir)" install
	fi
	if use plugin-ptw; then
		cd "${S}"/plugin-ptw
		KIS_SRC_DIR="${S}" emake DESTDIR="${ED}" LIBDIR="$(get_libdir)" install
	fi
	if use plugin-spectools; then
		cd "${S}"/plugin-spectools
		KIS_SRC_DIR="${S}" emake DESTDIR="${ED}" LIBDIR="$(get_libdir)" install
	fi
	if use ruby; then
		cd "${S}"/ruby
		dobin *.rb
	fi

	cd "${S}"
	emake DESTDIR="${D}" commoninstall

	##dragorn would prefer I set fire to my head than do this, but it works
	##all external kismet plugins (read: kismet-ubertooth) must be rebuilt when kismet is
	##is there an automatic way to force this?
	# install headers for external plugins
	insinto /usr/include/kismet
	doins *.h || die "Header installation failed"
	doins Makefile.inc
	#todo write a plugin finder that tells you what needs to be rebuilt when kismet is updated, etc

	dodoc CHANGELOG RELEASENOTES.txt README* docs/DEVEL.client docs/README.newcore || die
	newinitd "${FILESDIR}"/${PN}.initd kismet
	newconfd "${FILESDIR}"/${PN}.confd kismet

	insinto /etc
	doins conf/kismet{,_drone}.conf || die

	if use suid; then
	dobin kismet_capture || die
	fi
}

pkg_preinst() {
	if use suid; then
		enewgroup kismet
		fowners root:kismet /usr/bin/kismet_capture || die
		# Need to set the permissions after chowning.
		# See chown(2)
		fperms 4550 /usr/bin/kismet_capture || die
		elog "Kismet has been installed with a setuid-root helper binary"
		elog "to enable minimal-root operation.  Users need to be part of"
		elog "the 'kismet' group to perform captures from physical devices."
	fi
}
