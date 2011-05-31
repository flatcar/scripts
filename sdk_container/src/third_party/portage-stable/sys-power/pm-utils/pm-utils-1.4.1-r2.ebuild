# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-power/pm-utils/pm-utils-1.4.1-r2.ebuild,v 1.1 2011/04/21 15:03:19 scarabeus Exp $

EAPI=4

inherit eutils

DESCRIPTION="Suspend and hibernation utilities"
HOMEPAGE="http://pm-utils.freedesktop.org/"
SRC_URI="http://pm-utils.freedesktop.org/releases/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~ia64 ~ppc ~ppc64 ~sparc ~x86"
IUSE="alsa debug ntp video_cards_intel video_cards_radeon"

vbetool="!video_cards_intel? ( sys-apps/vbetool )"
RDEPEND="!<app-laptop/laptop-mode-tools-1.55-r1
	!sys-power/powermgmt-base[-pm-utils(+)]
	sys-apps/dbus
	>=sys-apps/util-linux-2.13
	sys-power/pm-quirks
	alsa? ( media-sound/alsa-utils )
	ntp? ( || ( net-misc/ntp net-misc/openntpd ) )
	amd64? ( ${vbetool} )
	x86? ( ${vbetool} )
	video_cards_radeon? ( app-laptop/radeontool )"
DEPEND="${RDEPEND}"

src_prepare() {
	local ignore="01grub"
	use ntp || ignore+=" 90clock"

	use debug && echo 'PM_DEBUG="true"' > "${T}"/gentoo
	echo "HOOK_BLACKLIST=\"${ignore}\"" >> "${T}"/gentoo

	epatch "${FILESDIR}"/${PV}-bluetooth-sync.patch \
		"${FILESDIR}"/${PV}-disable-sata-alpm.patch \
		"${FILESDIR}"/${PV}-fix-intel-audio-powersave-hook.patch \
		"${FILESDIR}"/${PV}-logging-append.patch

}

src_configure() {
	econf \
		--disable-doc
}

src_install() {
	emake DESTDIR="${D}" install
	dodoc AUTHORS ChangeLog NEWS pm/HOWTO* README* TODO
	doman man/*.{1,8}

	insinto /etc/pm/config.d
	doins "${T}"/gentoo

	# NetworkManager 0.8.2 is handling suspend/resume on it's own with UPower
	find "${D}" -type f -name 55NetworkManager -exec rm -f '{}' +
}
